classdef Demodulator <  handle & OM4MClassLib.DataStructs.IProps
    % Demodulator abstract interface for fringe-pattern demodulators
    %
    % Description:
    %   A demodulator is any object that obtains the phase from igrams
    %   (interferograms/fringe patterns). Concrete subclasses implement
    %   Process/GenerateFPs/GetStepValues below.

    %% props
    %private
    properties (Access=protected)
        props; % demodulator properties, a PropsEnumList of DemodulatorProps (see IProps, PropsEnumList, DemodulatorProps)
        steps; % PSI steps (volts, degrees, etc.) needed to generate the igrams
    end

    %% props
    %public
    properties
        modFP; % modulation of the fringe pattern to be generated
        biasFP; % bias of the fringe pattern to be generated
        shape; % shape of the fringe pattern to be generated (0 cosine, 1 binary)
        onlyModFlag; % if true, only the modulation is computed (not phase); default false
    end

    %% abstract methods
    %public interface
    methods (Abstract=true)
        % Process demodulates the cell array of igrams FPList. If the ROI
        % M is [], all pixels are processed and M is set to ones(); if
        % not, only M=true points are processed. After demodulation, M
        % is combined with a thresholded version of the modulation
        % (GetROIFromModule(z, ROINormTH, NFilt), using the current
        % ROINormTH/NFilt props). Set M to [] before Process to reset the
        % ROI, or copy it first to preserve it.
        this=Process(this, FPList);

        % GenerateFPs generates the igrams (cell array, size imSize) that
        % this demodulator can process, for display/projection
        FPList=GenerateFPs(this, imSize); %

        % GetStepValues returns the PSI step values (voltage, angle, etc.)
        stepVals=GetStepValues(this); %
    end
    
    
    
    %% public methods
    methods
        function this=Demodulator()
            % Demodulator constructs a demodulator with default props (see Init)
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('DemodulatorProps');
            
            % Props Initialization
            this.Init();
        end
        
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init sets every demodulator prop to its default value
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
        function ret=Get(this, props)
            % Get returns the value of props, or the full props struct if
            % called with no props argument
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end
        
        function this=Set(this, props, propvals)
            % Set assigns propvals to props, type/value-checking zList/NL
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            switch props
                case char(DemodulatorProps.zList)
                    if not(iscell(propvals))
                        retErrorMsg=['zList must be a cell array: <<' char(propvals) '>>, ' callFunc];
                        error([class(this) '->' retErrorMsg]);
                    end
                case char(DemodulatorProps.NL)
                    % validate NL
                    % list of valid values for NL
                    vList={2, 4};
                    r=Validation.CheckInputParam(propvals, vList);
            end
            
            this.props.Set(props, propvals);
        end
    end
    
    %%static methods
    methods(Static)
        function Mz=GetROIFromModule(z, ROINormTH, NFilt)
            % GetROIFromModule thresholds phasor z's modulation |z|
            % (box-filtered by NFilt) above ROINormTH, then median-filters
            % the resulting mask
            MQ=conv2(abs(z), ones(NFilt), 'same');
            Mz=mat2gray(MQ)>ROINormTH;
            Mz=medfilt2(Mz, [NFilt, NFilt]);
        end

        function Mz=GetROIFromAngle(z, ROINormTH, NFilt)
            % GetROIFromAngle thresholds phasor z's angle above ROINormTH
            % (after box-filtering z with a fixed 10x10 kernel), then
            % median-filters the resulting mask
            z=conv2(z, ones(10), 'same');
            Mz=abs(angle(z))>ROINormTH;
            Mz=medfilt2(Mz, [NFilt, NFilt]);
        end
        
    end
    
    
    
end

