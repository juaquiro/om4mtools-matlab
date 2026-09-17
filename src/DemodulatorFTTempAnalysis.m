classdef DemodulatorFTTempAnalysis < Demodulator
    % DemodulatorFTTempAnalysis temporal-FT fringe demodulator: each
    % igram pixel is demodulated across time rather than space
    %
    % Description:
    %   Process assumes uniform temporal sampling and a monotonic phase.

    %% props
    %private set
    properties (GetAccess=public, SetAccess=private)
        w0; % temporal carrier frequency in rad/sample
    end

    %% public methods
    methods
        function  this=DemodulatorFTTempAnalysis()
            % DemodulatorFTTempAnalysis constructs a temporal-FT demodulator
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
            % Process demodulates the temporal sequence FPList (one igram
            % per time sample) pixel-by-pixel via 1D FFT along time,
            % skipping pixels outside the mask M
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end            
            
            NIgrams=length(FPList);                        
            %make convolution and get phasor
            [NR, NC, NP]=size(FPList{1});
            g=zeros(NR, NC, NIgrams);
            
            for n=1:length(FPList)
                if NP==3
                    g(:, :, n)=rgb2gray(uint8(FPList{n}));
                else
                    g(:, :, n)=double(FPList{n});
                end
            end
            
            M=this.Get(char(DemodulatorProps.M));
            if isempty(M)
                M=true(NR, NC);
                this.Set(char(DemodulatorProps.M), M);
            end

            FFCut=this.Get(char(DemodulatorProps.FFCut));
            %demodulate each temporal line for all locations
            z=zeros(NR, NC, NIgrams);                       
            for r=1:NR
                for c=1:NC
                    if M(r,c)
                    gt=reshape(g(r,c, :), [1 NIgrams]);                    
                    %assume 2 FF as background
                    zt=UtilFunFPA.Temp1DFFTDemod(gt, FFCut);
                    z(r, c, :)=zt;
                    else
                        z(r, c, :)=zeros(1, NIgrams);
                    end
                end
            end
            
            zList{1}=z;
            this.Set(char(DemodulatorProps.zList), zList);                        
        end
        
        function stepVals=GetStepValues(this)
            % GetStepValues returns NIgrams evenly-spaced steps over
            % TempRange (units: volts, degrees, etc. depending on the setup)
            N=this.Get(char(DemodulatorProps.NIgrams));
            Range=this.Get(char(DemodulatorProps.TempRange));
            %in units of tempRange  that can be Volts for a piezo o 90 degrees for the polariscope etc
            this.steps=(0:N-1)*Range/(N-1);
            
            stepVals=this.steps;
        end
        
        function FPList=GenerateFPs(this, imSize)
            % GenerateFPs generates NIgrams grayscale fringe patterns
            % (period Tx or Ty, per PSDir), each phase-shifted in time by
            % w0 rad from the previous one
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
            
            N=this.Get(char(DemodulatorProps.NIgrams));
            FPList=cell(1,N);
            for n=1:N
                g=zeros(imSize, 'uint8');
                nDigits=6;  
                g(:, :, 1)=uint8(255*0.5*(1+round(cos(p-(n-1)*this.w0), nDigits)));
                g(:, :, 2)=g(:, :, 1);
                g(:, :, 3)=g(:, :, 1);
                
                FPList{n}=g;
            end
            
        end
                
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init sets default NIgrams/PSDir props and the temporal carrier w0
            %default number of patterns
            this.Set(char(DemodulatorProps.NIgrams), 50);
            
            %default direction for patterns vertical
            this.Set(char(DemodulatorProps.PSDir), 0);
            
            %default value for the temporal carrier in rads/px
            this.w0=pi/4;
        end
               
    end
    
    
end

