classdef PolarMeasurement < handle
    % PolarMeasurement measures retardation and local orientation from a
    % photoelastic (polariscope) measurement
    %
    % Description:
    %   From isoclinic and isochromatic PSA images, computes isochromatic
    %   (delta=2*pi/lambda*d*(n1-n2)) and isoclinic (4*alpha, 2*alpha)
    %   phase maps. Used together with MeasuringStationAppInt and
    %   HWPolTB. See testPolarMeasurement.m for unit tests, and
    %   DemodRetarPolPS/DemodRetarPolPS6Step/DemodulatorTimePSA for the
    %   demodulators involved.
    %
    % References:
    %   - Retardation from PS images: https://www.osapublishing.org/ao/abstract.cfm?uri=ao-36-32-8397
    %   - Isoclinics from PS images: https://www.sciencedirect.com/science/article/abs/pii/S0143816607001819
    %   - Stress separation from isochromatics/isoclinics: https://iopscience.iop.org/article/10.1088/0957-0233/9/8/010
    %% props
    % public
    properties
        deltaImList; % retardation images
        alphaImList; % isoclinic images
        M; % ROI
        t; % neighborhood half-size (2t+1) for w4alpha unwrapping
        mu; % regularization for w4alpha unwrapping
        NFilt; % filter size for phasor filtering
        ROINormTH; % normalized threshold [0 1] for ROI calculation
    end

    %only get
    properties (SetAccess=private, GetAccess=public)
        deltaDem; % retardation demodulator (see DemodRetarPolPS, DemodRetarPolPS6Step)
        alphaDem; % isoclinic demodulator (see DemodulatorTimePSA)
        pu; % phase unwrapper (typically for delta)
        zdelta; % retardation phasor
        udelta; % unwrapped retardation, in rad
        z4alpha; % 4*alpha isoclinic phasor
        z2alpha; % 2*alpha isoclinic phasor
    end

    %% public methods
    methods
        function this=PolarMeasurement(aDem, dDem, deltaPu)
            % PolarMeasurement constructs a polarimetric measurement from
            % its isoclinic demodulator aDem (see DemodRetarPolPS,
            % DemodRetarPolPS6Step), isochromatic demodulator dDem (see
            % DemodulatorTimePSA), and phase unwrapper deltaPu (see Unwrapper)
            this.deltaDem=dDem;
            this.alphaDem=aDem;
            this.pu=deltaPu;
            
            %for w4alpha unwrapping
            this.t=5; % neighbouhood 2t+1
            this.mu=1; % regularization
            this.NFilt=5;%filter size for phasor and mask filtering
            this.ROINormTH=0.1; %normalized threshold [0 1] for ROI calculation
        end
        
        function steps=GetDeltaSteps(this)
            % GetDeltaSteps returns the retardation demodulator's step values
            steps=this.deltaDem.GetStepValues();
        end

        function steps=GetAlphaSteps(this)
            % GetAlphaSteps returns the isoclinic demodulator's step values
            steps=this.alphaDem.GetStepValues();
        end

        function filtPhasor(this, type)
            % filtPhasor box-filters (conv2, size NFilt) the phasor
            % property named by type (a PolarMeasPhasorType) in place
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
        
        
        function this=calcWrapRetar(this)
            % calcWrapRetar demodulates deltaImList into the wrapped
            % retardation phasor zdelta (using M and z2alpha as demodulator inputs)
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
        
        
        function this=calcUnwRetar(this)
            % calcUnwRetar unwraps angle(zdelta) within M into udelta
            %process
            this.pu.Process(angle(this.zdelta), this.M, this.M);
            %get results
            this.udelta=this.pu.Get(char(UnwrapperProps.unw));
        end
        
        function this=calc4Alpha(this)
            % calc4Alpha demodulates alphaImList into the 4*alpha
            % isoclinic phasor z4alpha (using M as demodulator input)
            gList=this.alphaImList;
            
            %set ROI
            this.alphaDem.Set(char(DemodulatorProps.M), this.M);
            this.alphaDem.Process(gList);
            zList=this.alphaDem.Get(char(DemodulatorProps.zList));
            this.z4alpha=zList{1};
        end
        
        function this=calc2Alpha(this, unwrapp2Alpha)
            % calc2Alpha derives the 2*alpha isoclinic phasor z2alpha
            % from z4alpha, either by unwrapping w4alpha
            % (UtilFunFPA.Calc2Alpha, if unwrapp2Alpha) or simply halving it
            %unwrap w4alpha
            QM=mat2gray(abs(this.z4alpha)); %relacion se�al ruido: la calidad
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
        
        
        function this=calcROI(this, type)
            % calcROI computes M by thresholding the modulation of the
            % phasor property named by type (a PolarMeasPhasorType)
            % above ROINormTH, then median-filtering (size NFilt)
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
        
        function save(PM,varargin)
            % save writes PM (a PolarMeasurement) to a .mat file.
            % varargin{1}, if given, is the file name (default:
            % defFileName4Saving())
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
        
        function PM=load(fileName)
            % load reads a PolarMeasurement previously saved by save()
            % from fileName
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
            % defFileName4Saving returns "PolarMeasurement_<date>.mat"
            PMClassName='PolarMeasurement';
            fileName=[PMClassName '_' date '.mat'];
        end
        
    end
    
end