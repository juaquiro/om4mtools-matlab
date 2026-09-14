classdef DemodulatorLSEquispacedPSA < Demodulator
    %DemodulatorLSEquispacedPSA Equispaced LS implementation of demodulator
        
    %% props
    %private set
    properties (GetAccess=public, SetAccess=private)
    end
    
    %% public methods
    methods
        % constructor
        function  this=DemodulatorLSEquispacedPSA()
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
            deltaList=this.Get(char(DemodulatorProps.deltaList));
            
            if length(FPList)~=length(deltaList)
                retMsg=[' Incorrect number of patterns'];
                error([callFunc, '->' retMsg]);
            end
            
            %make LS calculation
            M=this.Get(char(DemodulatorProps.M));
            %default value for this.onlyModFlag=false
            [z] = UtilFunFPA.LSDemodEquispaced(FPList, M, deltaList, this.onlyModFlag);      
            
            
            if isempty(M)
                M=true(size(z));
            else
                NFilt=this.Get(char(DemodulatorProps.NFilt));
                ROINormTH=this.Get(char(DemodulatorProps.ROINormTH));
                
                %defalt value for ROINormTH so unless specified here we
                %do nothing
                Mz=Demodulator.GetROIFromModule(z, ROINormTH, NFilt);
                M=M&Mz;
            end
            this.Set(char(DemodulatorProps.M), M);            
            zList{1}=z;
            this.Set(char(DemodulatorProps.zList), zList);            
            
        end
        
        function stepVals=GetStepValues(this)
            stepVals=this.steps;
        end
        
        function FPList=GenerateFPs(this, imSize)
            import OM4MClassLib.Util.*
            NR=imSize(1);
            NC=imSize(2);
            
            [x,y]=meshgrid(1:NC, 1:NR);
            x=x-1; y=y-1;
            
            Tx=this.Get(char(DemodulatorProps.Tx)); %pixels
            Ty=this.Get(char(DemodulatorProps.Ty)); %pixels
            
            if this.Get(char(DemodulatorProps.PSDir))==0
                p=2*pi*x/Tx;
            else
                p=2*pi*y/Ty;
            end            
            
            %reset deltaList
            %this.set_deltaList(); AQDEBUG
            
            deltaList=this.Get(char(DemodulatorProps.deltaList));
            
            N=this.Get(char(DemodulatorProps.NIgrams));   
            FPList=cell(1,N);
            for n=1:N              
                %Aqui necesitamos el round para que para algunos
                %casos como Tx=4 y NIgrams=4 cos(pi/2)=+eps y
                %cos(3pi/2)=-eps y al hacer el uint8 sale 127 o 128
                %esto puede fastidiar el calculo de la fase absoluta
                nDigits=6;
                g(:, :, 1)=uint8(this.biasFP+this.modFP*round(cos(p+deltaList(n)), nDigits));
                
                if this.shape==1
                    g(:, :, 1)=g(:, :, 1)>127.5;
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
            this.props.Set(char(DemodulatorProps.PSDir), 0);
            
            %default number of igrams for the LS demodulator default value
            %for T is 8
            this.props.Set(char(DemodulatorProps.NIgrams), 4);
            
            %default value for deltaList in function of NIgrams
            this.set_deltaList();            

        end
        
        function this=set_deltaList(this)
            %Get Number of Igrams          
            N=this.Get(char(DemodulatorProps.NIgrams));                                  
            %set deltaList whithout using the class Set
            this.props.Set(char(DemodulatorProps.deltaList), [0:N-1]'*2*pi/N); 
            
            valRange=this.Get(char(DemodulatorProps.StepsTwoPwiRange));
                        
            deltaList=this.Get(char(DemodulatorProps.deltaList));
            %in units of valRange  that can be Volts for a piezo o 90 degrees for the polariscope etc
            this.steps=deltaList*valRange/(2*pi);
        end
    end
    
    
end

