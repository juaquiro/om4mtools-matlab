classdef DemodRetarPolPS < Demodulator
    %DemodRetarPolPS this implements the classical 8 step method of
    %photoelastic PSI
    
    %% public methods
    methods
        % constructor
        function  this=DemodRetarPolPS()
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
            
            if not(iscell(FPList)) || length(FPList)~=8
                retMsg=[FPListName ' must be an cell array of 8 phase shifted images'];
                error([callFunc, '->' retMsg]);
            end
            
            %get w2alpha
            z2alpha=this.Get(char(DemodulatorProps.z2alpha));
            w2alpha=angle(z2alpha);
            
            %get Mask
            M=this.Get(char(DemodulatorProps.M));
            if isempty(M)
                M=true(size(g));
                this.Set(char(DemodulatorProps.M), M)
            end
            
            %retardation phase calcular las combinaciones y detectar maxima
            %modulacion
            
            [NR, NC, NP]=size(FPList{1});
            z=zeros(NR, NC);
            for n=1:length(FPList)
                if NP==3
                    RedBand=FPList{n};
                    RedBand=double(RedBand(:, :, 1));
                    FPList{n}=RedBand;
                else
                    FPList{n}=double(FPList{n});
                end
            end
            
            
            zDelta=cell(1,2);
            %get the two possible phasor dependiong on the unwrapped w2alpha
            zDelta{1}=0.5*(FPList{4}-FPList{3} + FPList{8}-FPList{7})+ ...
                1i*((FPList{1}-FPList{2}).*cos(w2alpha) + (FPList{5}-FPList{6}).*sin(w2alpha)) ;
            zDelta{2}=0.5*(FPList{4}-FPList{3} + FPList{8}-FPList{7})+ ...
                1i*((FPList{1}-FPList{2}).*sin(w2alpha) + (FPList{5}-FPList{6}).*cos(w2alpha)) ;
            zDelta{3}=0.5*(FPList{4}-FPList{3} + FPList{8}-FPList{7})+ ...
                1i*((FPList{1}-FPList{2}).*cos(w2alpha) - (FPList{5}-FPList{6}).*sin(w2alpha)) ;
            zDelta{4}=0.5*(FPList{4}-FPList{3} + FPList{8}-FPList{7})+ ...
                1i*((FPList{1}-FPList{2}).*sin(w2alpha) - (FPList{5}-FPList{6}).*cos(w2alpha)) ;
            
            
            W=zeros(1,4);
            ROI=mat2gray(M); ROI=logical(ROI);
            for n=1:4
                W(n)=sum(abs((zDelta{n}(ROI)))); %suma incoherente
            end
            %             W(1)=sum(abs((zDelta{1}(ROI)))); %suma incoherente
            %             W(2)=sum(abs((zDelta{2}(ROI)))); %suma incoherente
            %             W(3)=sum(abs((zDelta{3}(ROI)))); %suma incoherente
            %             W(4)=sum(abs((zDelta{4}(ROI)))); %suma incoherente
            [~, k]=max(W);
            z=zDelta{k};
            
            zList={z};
            this.Set(char(DemodulatorProps.zList), zList);
        end
        
        function FPList=GenerateFPs(this, imSize)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            retMsg=['DemodulatorRetarPol->' callFunc '->not available'];
            error(retMsg);
            
        end
        
        
        function stepsVals=GetStepValues(this)
            stepsVals=this.steps;
        end
        
        
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            this.steps={[ 90 45  45 -45]
                [ 90 45 -45  45]
                [ 90 45 -45   0]
                [ 90 45  45   0]
                [-45 90  90   0]
                [-45 90  90  90]
                [-45 90   0  45]
                [-45 90  90  45]};
            
            z2alpha=NaN;
            %default z2alpha
            this.Set(char(DemodulatorProps.z2alpha), z2alpha);
        end
    end
    
    
end

