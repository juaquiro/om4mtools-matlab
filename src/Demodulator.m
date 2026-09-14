%> @file Demodulator.m
%> @brief Demodulator abstract interface
%> @details NA
%> @copyright 2016 IOT
%> @author AQ


% ======================================================================
%> @brief this class implements the Demodulator abstract interface
%> @details a demodulator is any object that obtains the phase from igrams
% ======================================================================
classdef Demodulator <  handle & OM4MClassLib.DataStructs.IProps
    
    %% props
    %private
    properties (Access=protected)
        %> demodulator properties as a DemodulatorPropStore of DemodulatorProps props @see IProps, DemodulatorPropStore, DemodulatorProps
        props;
        %> PSI steps in Volts, degress etc necessary for the generation of the igrams
        steps;
    end
    
    %% props
    %public
    properties
        %> modulacion del patron de ftanajas que se va a generar
        modFP;
        %> bias del patron de franjas que se va a generar
        biasFP;
        %> Forma del patron de franjas que se va a generar (0 coseno, 1 binario)
        shape;
        %> this flag indicates if the demodulatro will compute obly the modulation or both modulation and phase (default is "false")
        onlyModFlag;
    end
    
    %% abstract methods
    %public interface
    methods (Abstract=true)
        % ======================================================================
        %> @brief abstract Process
        %> @details This method uses the igram list for demodulation.
        %> If M (the ROI) is [] all pixels are processed and M is set ones(). If M is not [],
        %>  only M=true points are processed. Afther demodulation M is combined
        %> with a thersholded version of the modulation calculated using the
        %> static function GetROIFromModule(z, ROINormTH, NFilt)
        %> that uses current values for ROINormTH (def 0) and NFilt (def 5 px). If the ROI must be reset, set to [] before Process.
        %> If the ROI must be saved, copy it before Process
        %> @param FPList Cell array of input igrams
        %> @param this instance of the class.
        %> see GetROIFromModule
        %>
        % ======================================================================
        this=Process(this, FPList);
        
        % ======================================================================
        %> @brief this function must generate FPs to be diplayed/projected that the demodulator can process
        %> @param imSize igram size
        %> @param this instance of the class.
        %> @retval FPList Cell array igrams
        % ======================================================================
        FPList=GenerateFPs(this, imSize); %
        
        % ======================================================================
        %> @brief this function generates the steps vals (voltage, angle) necessary for the PSi method
        %> @retval FPList Cell array igrams
        % ======================================================================
        stepVals=GetStepValues(this); %
    end
    
    
    
    %% public methods
    methods
        %constructor
        function this=Demodulator()
            this.props=DemodulatorPropStore();

            % Props Initialization
            this.Init();
        end
        
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            %             %pn cell array of classifier props names
            %             %pt list of Classifier Prop Types
            %             [pt, pn]=enumeration('DemodulatorProps');
            %             for n=1:length(pn)
            %                 this.Set(pn{n}, NaN);
            %             end
            
            %for all demodulators default value for FF is 30 fringes
            %just to make sure we are not using the Get Set interface
            this.props.Set(char(DemodulatorProps.Tx), 8);
            this.props.Set(char(DemodulatorProps.Ty), 8);
            
            %set default 2pi range
            this.props.Set(char(DemodulatorProps.StepsTwoPwiRange), 2*pi);
            
            %for temporal analysis set FFCut at 1 FF
            this.props.Set(char(DemodulatorProps.FFCut), 1);
            
            %filter size for phasor and mask filtering, default 5 px
            this.props.Set(char(DemodulatorProps.NFilt), 5);
            
            %normalized threshold [0 1] for ROI calculation. default 0.0
            this.props.Set(char(DemodulatorProps.ROINormTH), 0.0);
            
            this.modFP=127.5; % default value modulation
            this.biasFP=127.5;  % default value bias
            
            this.shape=0;  % default value shape
            
            %default value for onlyModFlag
            this.onlyModFlag=false;
            
            %default PSA demodulator for GC absolute pgase measurement
            this.props.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.LSEquispacedPSA);
            %this.props.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.LSPSA);
            
        end
    end
    
    %% public IProps interface
    %check Get implementation��
    methods
        % Get interface, note the no parameter
        function ret=Get(this, props)
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end
        
        %Set interface
        %typechecking against DemodulatorProps is done by props.Set @see DemodulatorPropStore, DemodulatorProps
        function this=Set(this, props, propvals)
            this.props.Set(props, propvals);
        end
    end
    
    %%static methods
    methods(Static)
        function Mz=GetROIFromModule(z, ROINormTH, NFilt)
            MQ=conv2(abs(z), ones(NFilt), 'same');
            Mz=mat2gray(MQ)>ROINormTH;
            Mz=medfilt2(Mz, [NFilt, NFilt]);
        end
        
        function Mz=GetROIFromAngle(z, ROINormTH, NFilt)
            z=conv2(z, ones(10), 'same');
            Mz=abs(angle(z))>ROINormTH;
            Mz=medfilt2(Mz, [NFilt, NFilt]);
        end
        
    end
    
    
    
end

