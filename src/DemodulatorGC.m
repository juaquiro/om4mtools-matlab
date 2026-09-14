classdef DemodulatorGC < Demodulator
    %DemodulatorGC Demodulador de GCodes
    %This demodulator does not return a phaso. The list has two ellements, first is the Gray Code, and the second the visivility W-K in the
    
    %% props
    %private set
    properties (Access=private)
        LUT_GC2D; %1D LUT to transform Decimal binary codes to Gray binary codes
    end
    
    %% public methods
    methods
        % constructor
        function  this=DemodulatorGC()
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
        
        % abstract interface
        function this=Process(this, FPList)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            %we expect N patterns
            NIgrams=this.Get(char(DemodulatorProps.NIgrams));
            
            if ne(length(FPList),NIgrams)
                retMsg=[' Incorrect number of patterns'];
                error([callFunc, '->' retMsg]);
            end
            
            [NR, NC, NP]=size(FPList{1});
            %transform to double GV if necessary
            if NP==3
                for i=1:NIgrams                    
                    FPList{i}=double(rgb2gray(uint8(FPList{i})));
                end
            end           
            
            
            M=this.Get(char(DemodulatorProps.M));
            D=UtilFunFPA.decodeGC(FPList, this.LUT_GC2D);
            
            W=double(FPList{NIgrams-1});
            K=double(FPList{NIgrams});
            V=W-K; %ampliture of the binary patterns
            
            %first ellement is the order from GC and second the amplitude
            %of the binary fringes
            zList{1}=D;
            zList{2}=V;
            
            this.Set(char(DemodulatorProps.M), M);
            this.Set(char(DemodulatorProps.zList), zList);
        end
        
        function stepVals=GetStepValues(this)
            stepVals=this.steps;
        end
        
        function FPList=GenerateFPs(this, imSize)
            NR=imSize(1);
            NC=imSize(2);
            
            Tx=this.Get(char(DemodulatorProps.Tx)); %pixels
            Ty=this.Get(char(DemodulatorProps.Ty)); %pixels
            
            %GC orientation 0 vertical 1 horizontal
            GCDir=this.Get(char(DemodulatorProps.PSDir));
            
            %GC period
            if GCDir==0
                T=Tx;
            else
                T=Ty;
            end
            
            [FPList, this.LUT_GC2D, ~, ~]=UtilFunFPA.generateGC(T, NR, NC, GCDir);
            
            %FPList is a uint8 GV image
            g=zeros([NR, NC, 3], 'uint8');
            %transform to RGB
            for n=1:length(FPList)
                g(:, :, 1)=FPList{n};
                g(:, :, 2)=FPList{n};
                g(:, :, 3)=FPList{n};
                FPList{n}=g;
            end
            
            %after calculation set NIgrams
            this.Set(char(DemodulatorProps.NIgrams), length(FPList));
        end
        
        %Override Set interface, Not necessary for this Demodulator
        %function this=Set(this, prop, propval)
        %    import OM4MClassLib.Util.*;
        %    callFunc=Logging.WhoCalledMe();
        %
        %    %call superclass function
        %    this.Set@Demodulator(prop, propval);
        %end
        
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
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
            
            %for binary patterns the use of bias and mod N/A but keep
            %default values for compatibility
            this.biasFP=127.5;
            this.modFP=127.5;
            
            %Init LUT
            this.LUT_GC2D=[];
            
            %by definition the GC are binaries
            this.shape=1;
        end
        
    end
    
    
end

