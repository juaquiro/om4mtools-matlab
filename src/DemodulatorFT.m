classdef DemodulatorFT < Demodulator
    %DemodulatorFT FT implementation of demodulator
    
    %% public methods
    methods
        % constructor
        function  this=DemodulatorFT()
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
            
            %only process first ellement
            g=FPList{1};
            NL=this.Get(char(DemodulatorProps.NL)); %default 4
            w0=this.Get(char(DemodulatorProps.w0));
            R=10;
            %w are the new lobes position closer to w0. If w0 is empty
            %LocateSidelobes uses a default clockwise numbering. 
            w = UtilFunFPA.LocateSidelobes(g, w0, R, NL);

            zList=UtilFunFPA.FFTDemod(g, w);

            this.Set(char(DemodulatorProps.zList), zList);           
            this.Set(char(DemodulatorProps.w0), w0);           
            
            
            M=this.Get(char(DemodulatorProps.M));
            if isempty(M)
                M=true(size(g));
                this.Set(char(DemodulatorProps.M), M)
            end
        end
        
        function stepVals=GetStepValues(this)
            stepVals=this.steps;
        end
        
        function FPList=GenerateFPs(this, imSize)
            NR=imSize(1);
            NC=imSize(2);
            
            [x,y]=meshgrid(1:NC, 1:NR);
                        
            Tx=this.Get(char(DemodulatorProps.Tx)); %pixels
            Ty=Tx; %pixels
                       
            px=2*pi*x/Tx;
            py=2*pi*y/Ty;
            
            FPList{1}=uint8(255*0.25*(2+cos(px)+cos(py))); %crossed grids
            FPList{2}=uint8(255*0.5*(1+cos(px))); %vertical grid
            FPList{3}=uint8(255*0.5*(1+cos(py))); %horizontal grids            
        end
        
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            %default value for NL is 4, it can be 2 or 4
            this.Set(char(DemodulatorProps.NL), 4); 
            
            %default value for sidelobes search starting position
            this.Set(char(DemodulatorProps.w0), []); 
            
            %def value for steps just for compatibility
            this.steps=1;
        end
    end
    
    
end

