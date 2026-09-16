classdef DemodulatorGCPSA < Demodulator
    % DemodulatorGCPSA combines a Gray Code demodulator with a PSA
    % (phase-shifting) demodulator to get the absolute phase

    %% props
    properties
        PSADemodulator; %PSA demodulator for the smaller GCDemodulator Period
        GCDemodulator; %GC demodulator
    end

    %% public methods
    methods
        function  this=DemodulatorGCPSA()
            % DemodulatorGCPSA constructs a GC+PSA absolute-phase demodulator
            %%% Pre Initialization %%%
            % Any code not using first output argument (this)
            
            %%% no hay
            
            %%% Object Initialization %%%
            % Call superclass constructor before accessing object
            % You cannot conditionalize this statement
            
            % para pasar los varargin hay que serializarlos {:}
            this = this@Demodulator();
            
            %%% Post Initialization %%%
            % Any code, including access to object
            this.Init();
        end
        
        function this=Process(this, FPList)
            % Process splits FPList into the GC sub-sequence and the PSA
            % sub-sequence, demodulates each with its inner demodulator,
            % and combines their results into the absolute phase
            % (PSA phase + 2*pi*GC order)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            %check number of patterns
            if length(FPList)~=this.Get(char(DemodulatorProps.NIgrams))
                retMsg=[' Incorrect number of patterns'];
                error([callFunc, '->' retMsg]);
            end
            
            %make GC calculation
            NIgramsGC=this.GCDemodulator.Get(char(DemodulatorProps.NIgrams));
            %process GC FPList
            this.GCDemodulator.Process(FPList(1:NIgramsGC));
            zListGC=this.GCDemodulator.Get(char(DemodulatorProps.zList));
            D=zListGC{1}; %absolute order fron GC
            V=zListGC{2}; %Visibility
            
            %make PSA calculation
            M=this.Get(char(DemodulatorProps.M));
            NIgrams=this.Get(char(DemodulatorProps.NIgrams));
            this.PSADemodulator.Set(char(DemodulatorProps.M), M);
            this.PSADemodulator.Process(FPList(NIgramsGC+1:NIgrams));
            zListPSA=this.PSADemodulator.Get(char(DemodulatorProps.zList));
            z=zListPSA{1};
            
            zList=cell(1, 4);
            zList{1}=mod(angle(z), 2*pi)+2*pi*D; %absolute phase from PSA and GC el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
            zList{2}=D; %absolute order from GC
            zList{3}=V; %Visibility from GC
            zList{4}=z; %PSA phasor
            
            this.Set(char(DemodulatorProps.zList), zList);
            
        end
        
        function stepVals=GetStepValues(this)
            % GetStepValues delegates to the inner PSA demodulator's steps
            stepVals=this.PSADemodulator.steps;
        end

        function FPList=GenerateFPs(this, imSize)
            % GenerateFPs propagates Tx/Ty/PSDir to both inner
            % demodulators and concatenates their igrams (GC first, then PSA)
            %get Tx, Ty and PSDir
            Tx=this.Get(char(DemodulatorProps.Tx)); %pixels
            Ty=this.Get(char(DemodulatorProps.Ty)); %pixels
            PSDir=this.Get(char(DemodulatorProps.PSDir));
            
            %set Tx, Ty and PSDir for GC and PSA
            this.GCDemodulator.Set(char(DemodulatorProps.Tx), Tx);
            this.GCDemodulator.Set(char(DemodulatorProps.Ty), Ty);
            this.GCDemodulator.Set(char(DemodulatorProps.PSDir), PSDir);
            
            %by default we use for the PSA method 4 NIgrams 
            this.PSADemodulator.Set(char(DemodulatorProps.Tx), Tx);
            this.PSADemodulator.Set(char(DemodulatorProps.Ty), Ty);                                 
            this.PSADemodulator.Set(char(DemodulatorProps.PSDir), PSDir);
            
            %generate FPs
            FPListPSA=this.PSADemodulator.GenerateFPs(imSize);
            FPListGC=this.GCDemodulator.GenerateFPs(imSize);
            
            %primero va la lista de GC y luego la lista de PSA
            FPList=[FPListGC, FPListPSA];
            
            %Set NIGrams
            this.Set(char(DemodulatorProps.NIgrams), length(FPList));
            
        end
        
        
        function this=Set(this, prop, propval)
            % Set overrides the base Set to also recreate PSADemodulator
            % when AbsolutePhasePSADemType changes, and to validate that
            % Tx/Ty stay even (this demodulator's PSA NIgrams = 0.5*Tx).
            % AbsolutePhasePSADemType can't be a superclass property
            % because overriding its set behavior from a subclass
            % requires the property to be declared there too - see
            % https://stackoverflow.com/questions/20822670
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            %call superclass function
            this.Set@Demodulator(prop, propval);
            
            %en caso de que la prop sea AbsolutePhasePSADemType actualizar
            %el objeto this.PSADemodulator
            switch prop
                case char(DemodulatorProps.AbsolutePhasePSADemType)
                    % validate AbsolutePhasePSADemType
                    % list of valid values for AbsolutePhasePSADemType
                    vList={char(DemodulatorTypes.LSEquispacedPSA), char(DemodulatorTypes.LSPSA), char(DemodulatorTypes.TimePSA)};
                    Validation.CheckInputParam(char(propval), vList);
                    this.PSADemodulator=DemodulatorFactory.Create(propval);
                case char(DemodulatorProps.Tx) %for this demodulator Tx must be even because the PSA NIgrams are 0.5*Tx
                    if rem(propval, 2)
                        retMsg=[' Tx perior must be even'];
                        error([callFunc, '->' retMsg]);
                    end
                case char(DemodulatorProps.Ty) %for this demodulator Ty must be even because the PSA NIgrams are 0.5*Tx
                    if rem(propval, 2)
                        retMsg=[' Ty perior must be even'];
                        error([callFunc, '->' retMsg]);
                    end
            end
            
        end
        
        
    end
    
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init sets defaults appropriate for GC+PSA (no steps/bias/
            % mod, NIgrams unknown until GenerateFPs) and creates the
            % default inner GC and PSA demodulators
            %default direction for patterns vertical, we use the base Set
            %to avoid using the superseeded Set of the class
            %here does not matter because the demodulator is multiplexed
            this.props.Set(char(DemodulatorProps.PSDir), 0);
            
            %deltaList doues not apply for this demodulator
            deltaList=[];
            this.props.Set(char(DemodulatorProps.deltaList), deltaList);
            
            %steps do not aplly for this demodulator
            this.steps=[];
            
            %until we do dot generate the GC we don't know the NIgrams
            NIgrams=[];
            this.props.Set(char(DemodulatorProps.NIgrams), NIgrams);
            
            %for binary patterns the use of bias and mod N/A
            this.biasFP=[];
            this.modFP=[];
            
            %default GCDemodulator is DemodulatorTypes.GrayCode
            this.GCDemodulator=DemodulatorFactory.Create(DemodulatorTypes.GrayCode);
            
            %default value for PSADemodulator is DemodulatorTypes.LSPSA; (see
            %demodulator)
            AbsolutePhasePSADemType=this.Get(char(DemodulatorProps.AbsolutePhasePSADemType));
            this.PSADemodulator=DemodulatorFactory.Create(AbsolutePhasePSADemType);
        end
        
    end
    
    
end

