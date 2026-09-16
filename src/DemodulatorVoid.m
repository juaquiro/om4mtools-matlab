classdef DemodulatorVoid < Demodulator
    % DemodulatorVoid dummy demodulator for testing purposes only -
    % returns a synthetic radial phasor, independent of the input igrams

    %% public methods
    methods
        function  this=DemodulatorVoid()
            % DemodulatorVoid constructs a dummy test demodulator
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
            % Process ignores the actual igram content of FPList{1} and
            % returns a synthetic radial phasor of the same size, for
            % testing pipelines without a real demodulator
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            g=FPList{1};
            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            phi=atan2(-y,x);
            b=abs(x+1i*y);
            z=b.*exp(1i*phi);
            zList={z, z};
            this.Set(char(DemodulatorProps.zList), zList);
            
            M=this.Get(char(DemodulatorProps.M));
            if isempty(M)
                M=true(size(g));
                this.Set(char(DemodulatorProps.M), M)
            end
            
        end
        
        function FPList=GenerateFPs(this, imSize)
            % GenerateFPs returns a crossed-grid pattern (period 8px)
            % plus its vertical and horizontal components
            NR=imSize(1);
            NC=imSize(2);
            
            [x,y]=meshgrid(1:NC, 1:NR);
            Tx=8; %pixels
            Ty=8; %pixels
                       
            px=2*pi*x/Tx;
            py=2*pi*y/Ty;
            
            FPList{1}=uint8(255*0.25*(1+cos(px)).*(1+cos(py))); %crossed grids
            FPList{2}=uint8(255*0.5*(1+cos(px))); %vertical grid
            FPList{3}=uint8(255*0.25*(1+cos(py))); %horizontal grids            
        end
        
        function stepsVals=GetStepValues(this)
            % GetStepValues returns 4 dummy steps, evenly dividing StepsTwoPwiRange
            stepsVals=this.steps;
        end


    end

    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init computes 4 dummy step values from StepsTwoPwiRange
            s=(0:3)/4;
            valRange=this.Get(char(DemodulatorProps.StepsTwoPwiRange));
            this.steps=valRange./s;

        end
    end
    
    
end

