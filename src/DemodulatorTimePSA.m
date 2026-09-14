classdef DemodulatorTimePSA < Demodulator
    %DemodulatorTimePSA temporal demodulation an PSA using the impulse
    %response and carrier w0 as in the FPA book
    
    %% props
    %private set
    properties (GetAccess=public, SetAccess=private)
        h;
        w0;
    end
    
    %% public methods
    methods
        % constructor
        function  this=DemodulatorTimePSA()
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
            
            %reset the h and w0 for the PS
            this.set_h_w0_4PSFilter();
            
            %we expect N patterns
            if length(FPList)~=length(this.h)
                retMsg=[' Incorrect number of patterns'];
                error([callFunc, '->' retMsg]);
            end
            
            %make convolution and get phasor
            [NR, NC, NP]=size(FPList{1});
            z=zeros(NR, NC);
            for n=1:length(FPList)
                if NP==3
                    FPList{n}=rgb2gray(uint8(FPList{n}));
                end
                z=z+this.h(n)*double(FPList{n});
            end
            
            
            M=this.Get(char(DemodulatorProps.M));
            if isempty(M)
                M=true(size(z));
            else
                NFilt=this.Get(char(DemodulatorProps.NFilt));
                ROINormTH=this.Get(char(DemodulatorProps.ROINormTH));
                
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
            
            %rest the h and w0 for the PS
            this.set_h_w0_4PSFilter();
            
            FPList=cell(1,length(this.h));
            for n=1:length(this.h)
                g=zeros(imSize, 'uint8');
                %Aqui necesitamos el round para que para algunos
                %casos como Tx=4 y NIgrams=4 cos(pi/2)=+eps y
                %cos(3pi/2)=-eps y al hacer el uint8 sale 127 o 128
                %esto puede fastidiar el calculo de la fase absoluta
                nDigits=6;
                %g(:, :, 1)=uint8(this.biasFP+this.modFP*round(cos(p+deltaList(n)), nDigits));
                g(:, :, 1)=uint8(255*0.5*(1+round(cos(p-(n-1)*this.w0), nDigits)));
                g(:, :, 2)=g(:, :, 1);
                g(:, :, 3)=g(:, :, 1);
                
                FPList{n}=g;
            end
            
        end
        
        %Override Set interface
        function this=Set(this, props, propvals)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            %call superclass function
            this.Set@Demodulator(props, propvals);
            
            %if we change any property update h and w0
            this.set_h_w0_4PSFilter();
            
        end
        
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            %default value for PSType is A.5.6 (see apendix A of FPA)
            %first set the default DemodulatorProps.PSType using props
            %becasue we are using a override Set
            this.props.Set(char(DemodulatorProps.PSType), PSFilterTypes.A0502);
            
            %default direction for patterns vertical
            this.Set(char(DemodulatorProps.PSDir), 0);
            
            %set default values
            this.set_h_w0_4PSFilter();
        end
        
        function this=set_h_w0_4PSFilter(this)
            PSType=this.Get(char(DemodulatorProps.PSType));
            
            switch PSType
                case PSFilterTypes.A0502 %w0=2*pi/3
                    this.w0=pi/2;
                    this.h=[1, 2i, -2, -2i, 1];
                case PSFilterTypes.PS4 %w0=pi/2
                    this.w0=pi/2;
                    this.h=[1, 1i, -1, -1i];
                otherwise
                    retMsg=[char(PSType) ' PS filter not recognized'];
                    error([callFunc, '->' retMsg]);
            end
            
            N=length(this.h);
            valRange=this.Get(char(DemodulatorProps.StepsTwoPwiRange));
            %in units of valRange  that can be Volts for a piezo o 90 degrees for the polariscope etc
            deltaList=(0:N-1)*this.w0;
            this.steps=deltaList*valRange/(2*pi);
            
            this.props.Set(char(DemodulatorProps.deltaList), deltaList');
            
        end
    end
    
    
end

