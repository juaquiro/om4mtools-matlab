classdef DemodulatorPSA6MultiplexedXY < Demodulator
    %DemodulatorPSA6MultiplexedXY XY Multiplexed PSA 6 steps 
        
    %% props
    %private set
    properties (GetAccess=public, SetAccess=private)
    end
    
    %% public methods
    methods
        % constructor
        function  this=DemodulatorPSA6MultiplexedXY()
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
            
            %reset the deltaList
            %this.set_deltaList(); AQDEBUG
            
            %we expect N patterns
            %here deltaList is a structure with two fields X and Y the
            %phase steps in the X and Y direction
            deltaList=this.Get(char(DemodulatorProps.deltaList));
            
            if ne(length(FPList),length(deltaList.X)) || ne(length(FPList),length(deltaList.Y))
                retMsg=[' Incorrect number of patterns'];
                error([callFunc, '->' retMsg]);
            end
            
            %make XY PSA6 multiplexed calculation
            M=this.Get(char(DemodulatorProps.M));
            %default value for this.onlyModFlag=false
            %this demodulator returns a list of 1x2 cell with two phasors
            %or modulations depending on the onlyModFlag
            zList = UtilFunFPA.PSA6MultiplexedXY(FPList, M, deltaList, this.onlyModFlag);      
            
            if isempty(M)
                M=true(size(zList{1}));
            else
                NFilt=this.Get(char(DemodulatorProps.NFilt));
                ROINormTH=this.Get(char(DemodulatorProps.ROINormTH));
                
                %defalt value for ROINormTH so unless specified here we
                %do nothing
                Mz1=Demodulator.GetROIFromModule(zList{1}, ROINormTH, NFilt);
                Mz2=Demodulator.GetROIFromModule(zList{2}, ROINormTH, NFilt);
                M=M&Mz1&Mz2;
            end
            this.Set(char(DemodulatorProps.M), M);            
            this.Set(char(DemodulatorProps.zList), zList);                        
        end
        
        function stepVals=GetStepValues(this)
            stepVals=this.steps;
        end
        
        function FPList=GenerateFPs(this, imSize)
            NR=imSize(1);
            NC=imSize(2);
            
            [x,y]=meshgrid(1:NC, 1:NR);
            x=x-1; y=y-1;
            
            Tx=this.Get(char(DemodulatorProps.Tx)); %pixels
            Ty=this.Get(char(DemodulatorProps.Ty)); %pixels
            
            px=2*pi*x/Tx;
            py=2*pi*y/Ty;
            
            deltaList=this.Get(char(DemodulatorProps.deltaList));            
            N=this.Get(char(DemodulatorProps.NIgrams));   
            FPList=cell(1,N);
            for n=1:N              
                % default biasFP=255/2; %background
                % default modFP=255/2; %modulation
                
                %Aqui necesitamos el round para que para algunos
                %casos como Tx=4 y NIgrams=4 cos(pi/2)=+eps y
                %cos(3pi/2)=-eps y al hacer el uint8 sale 127 o 128
                %esto puede fastidiar el calculo de la fase absoluta
                nDigits=6;                
                g(:, :, 1)=uint8(this.biasFP+(this.modFP)*round(cos(px+deltaList.X(n)), nDigits)+(this.modFP)*round(cos(py+deltaList.Y(n)), nDigits));
                
                if this.shape==1
                    g(:, :, 1)=g(:, :, 1)>this.biasFP;
                    g(:, :, 1)=uint8(g(:, :, 1))*255;
                end
                
                g(:, :, 2)=g(:, :, 1);
                g(:, :, 3)=g(:, :, 1);
                
                FPList{n}=g;
            end
            
        end
        
        %Override Set interface
        function this=Set(this, prop, propval)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            %call superclass function
            this.Set@Demodulator(prop, propval);
            
            %en caso de que la propo sea deltalist copiar valores y camiar
            %NIgraams
            %every time a prop changes actualize deltaList and steps
            switch prop
                case char(DemodulatorProps.deltaList)
                    %set deltaList whithout using the class Set
                    NIgrams=length(propval);
                    this.props.Set(char(DemodulatorProps.NIgrams), NIgrams);
                    this.props.Set(char(DemodulatorProps.deltaList), propval);
                otherwise
                    this.set_deltaList();  %AQDEBUG
            end
            
        end
        
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)            
            %default direction for patterns vertical, we use the base Set
            %to avoid using the superseeded Set of the class
            %here does not matter because the demodulator is multiplexed
            this.props.Set(char(DemodulatorProps.PSDir), 0);
            
            this.biasFP=255/2; %background
            this.modFP=255/4; %modulation, we add to FPs and abailable modulation is 1/2 of maximum
            
            
            %default number of igrams for the LS demodulator
            T=this.Get(char(DemodulatorProps.Tx));
            this.props.Set(char(DemodulatorProps.NIgrams), 6); 
            
            %default value for deltaList in function of NIgrams
            this.set_deltaList();            

        end
        
        function this=set_deltaList(this)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            %Get Number of Igrams
            N=this.Get(char(DemodulatorProps.NIgrams));
            
            if ne(N,6)
                retMsg=[' Incorrect number of steps'];
                error([callFunc, '->' retMsg]);
            end
            
            %set deltaList whithout using the class Set
            s1=[0, pi, -pi/2, pi/2, 0, -pi/2]; %phase steps p1
            s2=[0, 0, -pi/2, -pi/2, pi, pi/2];  %phase steps p2
            deltaList=struct('X', s1, 'Y', s2);
            this.props.Set(char(DemodulatorProps.deltaList), deltaList);
            
            valRange=this.Get(char(DemodulatorProps.StepsTwoPwiRange));
            %in units of valRange  that can be Volts for a piezo o 90 degrees for the polariscope etc
            this.steps=struct('X', [], 'Y', []); %here steps as deltalist is a s
            this.steps.X=deltaList.X*valRange/(2*pi);
            this.steps.Y=deltaList.Y*valRange/(2*pi);
        end
    end
    
    
end

