%> @file PolarMeasurement.m
%> @brief this file contains the class PolarMeasurement used to describe the measurement of retardation and local orientation in a photoelastic measurement
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16
%> @see testPolarMeasurement.m

% ======================================================================
%> @brief using as input isoclinic and isocromatic PSA images this class
%> calculate isochromatic (delta=2*pi/lambda*d*(n1-n2) and isoclinic 4alpha and 2alpha phase maps
%> @details
%> - for calculation of retardation from PS images see https://www.osapublishing.org/ao/abstract.cfm?uri=ao-36-32-8397
%> - for calculation of isoclinics from PS images see https://www.sciencedirect.com/science/article/abs/pii/S0143816607001819
%> - for stress separation fron isochromatics and isoclinics see https://iopscience.iop.org/article/10.1088/0957-0233/9/8/010
%> @details this class is used toguether with the classes
%> MeasuringStationAppInt and HWPolTB
%> @author AQ
%> @see DemodRetarPolPS DemodRetarPolPS6Step testPolarMeasurement DemodulatorTimePSA
% ======================================================================
classdef PolarMeasurement < handle
    %% props
    % public
    properties
        %> retardation images
        deltaImList;
        %> isoclinic images
        alphaImList;
        %> ROI
        M;
        %>  neighbouhood 2t+1 for w4alpha unwrapping
        t;
        %>  regularization for w4alpha unwrapping
        mu;
        %> filter size for phasor filtering
        NFilt;
        %> normalized threshold [0 1] for ROI calculation
        ROINormTH;
    end
    
    %only get
    properties (SetAccess=private, GetAccess=public)
        %> retardation demodulator @see DemodRetarPolPS DemodRetarPolPS6Step
        deltaDem;
        %> isoclinic demodulator @see DemodulatorTimePSA
        alphaDem;
        %> phase unwrapper (tipically for delta)
        pu;
        %> retardation phasor
        zdelta;
        %> unwrapper retardtion in rads
        udelta;
        %> 4alpha isolinic phasor
        z4alpha;
        %> 2alpha isoclinic phasor
        z2alpha;
    end
    
    %% public methods
    methods
        % ======================================================================
        %> @brief constructor for the PMM class
        %> @details NA
        %> @author AQ
        %> @param aDem demodulator for isoclinics @see DemodRetarPolPS DemodRetarPolPS6Step
        %> @param dDem demodulator for isochromatics @see DemodulatorTimePSA
        %> @param deltaPu Phase unrwapper @see Unwrapper
        % ======================================================================
        function this=PolarMeasurement(aDem, dDem, deltaPu)
            this.deltaDem=dDem;
            this.alphaDem=aDem;
            this.pu=deltaPu;
            
            %for w4alpha unwrapping
            this.t=5; % neighbouhood 2t+1
            this.mu=1; % regularization
            this.NFilt=5;%filter size for phasor and mask filtering
            this.ROINormTH=0.1; %normalized threshold [0 1] for ROI calculation
        end
        
        % ======================================================================
        %> @brief this function get the steps for retardation demodulation
        %> @details NA
                %> @param this self reference to the class
        %> @author AQ
        % ======================================================================
        function steps=GetDeltaSteps(this)
            steps=this.deltaDem.GetStepValues();
        end
        
        % ======================================================================
        %> @brief this function get the steps for isoclinics demodulation
        %> @details NA
                %> @param this self reference to the class
        %> @author AQ
        % ======================================================================

        function steps=GetAlphaSteps(this)
            steps=this.alphaDem.GetStepValues();
        end
        
        % ======================================================================
        %> @brief this function filter the phasor specified by type using a conv2 filter with NFilt size
        %> @details NA
        %> @author AQ
        %> @param type the type of phase to be filtered @see PolarMeasPhasorType
        %> @param this self reference to the class
        % ======================================================================
        function filtPhasor(this, type)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            nameofClass='PolarMeasPhasorType';
            if not(isa(type, nameofClass))
                retErrorMsg=[inputname(1) ' must be of class ' nameofClass];
                error([callFunc '->' retErrorMsg]);
            end
            
            name=char(type);
            N=this.NFilt;
            z=this.(name);
            this.(name)=conv2(z, ones(N,N)/(N*N), 'same');
            
        end
        
        
        % ======================================================================
        %> @brief this function demodulates the retardation phase
        %> @details NA
        %> @author AQ
        %> @param this self reference to the class
        % ======================================================================
        function this=calcWrapRetar(this)
            gList=this.deltaImList;
            
            %set ROI
            this.deltaDem.Set(char(DemodulatorProps.M), this.M);
            %set 2alpha
            this.deltaDem.Set(char(DemodulatorProps.z2alpha), this.z2alpha);
            %demodulate retar
            this.deltaDem.Process(gList);
            zList=this.deltaDem.Get(char(DemodulatorProps.zList));
            this.zdelta=zList{1};
        end
        
        
        % ======================================================================
        %> @brief this function unwraps the retardation phase
        %> @details NA
        %> @author AQ
        %> @param this self reference to the class
        % ======================================================================
        function this=calcUnwRetar(this)
            %process
            this.pu.Process(angle(this.zdelta), this.M, this.M);
            %get results
            this.udelta=this.pu.Get(char(UnwrapperProps.unw));
        end
        
        % ======================================================================
        %> @brief this function demodulates 4Alpha
        %> @details NA
        %> @author AQ
        %> @param this self reference to the class
        % ======================================================================
        function this=calc4Alpha(this)
            gList=this.alphaImList;
            
            %set ROI
            this.alphaDem.Set(char(DemodulatorProps.M), this.M);
            this.alphaDem.Process(gList);
            zList=this.alphaDem.Get(char(DemodulatorProps.zList));
            this.z4alpha=zList{1};
        end
        
        % ======================================================================
        %> @brief this function calculates 2Alpha from 4Alpha
        %> @details NA
        %> @author AQ
        %> @param this self reference to the class
        %> @param unwrapp2Alpha flag for calculatin 2alpha by unwrapping or
        %> dividing by 2
        % ======================================================================
        function this=calc2Alpha(this, unwrapp2Alpha)
            %unwrap w4alpha
            QM=mat2gray(abs(this.z4alpha)); %relacion señal ruido: la calidad
            this.t=5; % neighbouhood 2t+1
            this.mu=1; % regularization
            
            w4alpha=angle(this.z4alpha);
            if unwrapp2Alpha
                w2alphaM=UtilFunFPA.Calc2Alpha(w4alpha,QM,this.M,this.t,this.mu);
            else
                w2alphaM=0.5*w4alpha;
            end
            
            this.z2alpha=abs(this.z4alpha).*exp(1i*w2alphaM);
        end
        
        
        % ======================================================================
        %> @brief this function calculates the ROI from the phasor specified by type
        %> @details NA
        %> @author AQ
        %> @param type the type of phase to be filtered @see PolarMeasPhasorType
        %> @param this self reference to the class
        % ======================================================================
        %this function determines the ROI from phasor type, see PolarMeasPhasorType
        function this=calcROI(this, type)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            nameofClass='PolarMeasPhasorType';
            if not(isa(type, nameofClass))
                retErrorMsg=[inputname(1) ' must be of class ' nameofClass];
                error([callFunc '->' retErrorMsg]);
            end
            
            name=char(type);
            z=this.(name);
            
            QM=mat2gray(abs(z));
            this.M=QM>this.ROINormTH;
            N=this.NFilt;
            this.M=medfilt2(this.M, [N, N]);
        end
        
    end
    
    %% Static methods
    methods (Static=true)
        
        % ======================================================================
        %> @brief this function save the object PM and optionally accepts a fileName
        %> @details This function saves a PM object, therefore you need in the path the PM constructor
        %> @param PM PolarMeasurement object
        %> @param varargin optional file name. Default value is set by defFileName4Saving
        %> @see PolarMeasurement.load
        %> @author AQ
        % ======================================================================
        function save(PM,varargin)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            PMClassName='PolarMeasurement';
            
            if not(isa(PM, PMClassName))
                namePM = inputname(1);
                retMsg=[namePM ' must be a ' PMClassName ' object'];
                error([callFunc, '->' retMsg]);
            end
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 1
                retMsg=[callFunc ' requires at most 1 optional inputs: fileName'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % fileName
            fileName=PolarMeasurement.defFileName4Saving;
            optargs = {fileName};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [fileName] = optargs{:};
            
            save(fileName,'PM');
        end
        
        % ======================================================================
        %> @brief this function loads a PM object from fileName
        %> @details This function loads a PM object, therefore you need in the path the PM constructor
        %> @param fileName file with the PM object
        %> @see PolarMeasurement.save
        %> @author AQ
        % ======================================================================
        function PM=load(fileName)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            PMClassName='PolarMeasurement';
            
            S=load(fileName);
            PM=S.PM;
            
            if not(isa(PM, PMClassName))
                retMsg=[fileName ' does not contain a ' PMClassName ' object'];
                error([callFunc, '->' retMsg]);
            end
        end
        
        function fileName=defFileName4Saving()
            PMClassName='PolarMeasurement';
            fileName=[PMClassName '_' date '.mat'];
        end
        
    end
    
end