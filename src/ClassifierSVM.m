classdef ClassifierSVM < Classifier
    %ClassifierSVN
    %   This class describes a SNV classifier from the MATLAB stats toolbox
    
    %% private props
    properties (Access=private)
        SVMstruct; %MATLAB SVM struct
        clr; %logistic regression classifier to calculate posterior probabilities
    end
    
    %% public methods
    methods
        % constructor
        function  this=ClassifierSVM()
            %%% Pre Initialization %%%
            % Any code not using first output argument (this)
            
            %%% no hay
            
            %%% Object Initialization %%%
            % Call superclass constructor before accessing object
            % You cannot conditionalize this statement
            
            % para pasar los varargin hay que serializarlos {:}
            this = this@Classifier();
            
            %%% Post Initialization %%%
            % Any code, including access to object
            
            this.checkSVM_Toolbox();
            this.Init();
        end
        
        function r=isSupervised(this)
            r=true;
        end
        
        function r=isRegression(this)
            r=false;
        end


    end
    
    %% protected abstract interface
    methods (Access=protected)
        %Classfier hypothesis h_theta(X)
        function [pred,prb]=HypothesisP(this, X)
            
            num_labels=length(this.SVMstruct);
            m = size(X, 1); % Number of training examples
            f=zeros(m, num_labels);
            
            for c=1:num_labels                               
                %f is the the SVM decision function for every sample, is an
                %array of m rows and num_labels columns
                %we need to calculate it to train the LR classfier
                [~, f(:, c)]=this.svmdecision(X, this.SVMstruct(c));
            end
            
            %here we make a one-vs-all classification of X
            [~,pred]=max(f,[], 2);
            
            %posterior probability from the LR clasiifier
            [~, prb]=this.clr.Predict(f);
                       
        end
        
        %function used to compute the parameters theta
        function CalculateTheta(this, X,y)
            
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            C=this.Get(char(ClassifierProps.lambda));
            KF=this.Get(char(ClassifierProps.KF));
            p=this.Get(char(ClassifierProps.KFp));
            sigma=this.Get(char(ClassifierProps.sigma));
            sp=this.Get(char(ClassifierProps.showplot));
            
            m = size(X, 1); % Number of training examples
            n = size(X, 2); % features number
            num_labels=length(unique(y));
            f=zeros(m, num_labels);
            this.InitSVMstruct(num_labels);
            
            for c=1:num_labels
                if sp
                    figure;
                end
                this.SVMstruct(c)=svmtrain(X,(y==c),'Kernel_Function', KF, 'showplot',sp, 'boxconstraint', C, 'rbf_sigma', sigma, 'polyorder', p);
                
                %f is the the SVM decision function for every sample, is an
                %array of m rows and num_labels columns
                %we need to calculate it to train the LR classfier
                [~, f(:, c)]=this.svmdecision(X, this.SVMstruct(c));
            end
                        
            %here we make a one-vs-all classification of Xnorm
            [~,p]=max(f,[], 2);
            
            %here we filt the SVM output (binary) to a LR using default
            %params for this.clr (see Init()) 
            Xlr=f;
            ylr=p;

            this.clr.Set(char(ClassifierProps.normalize),false);
            this.clr.Train(Xlr,ylr);
                        
            % for further calculation of posterior probabilities
            % 1) calculate f using this.svmdecision (this include data
            % normalization with this.SVMstruct
            % 2) calculate posterior probability using [pp, ~]=this.clr.Predict(f);
            
        end
        
        function errStruct=RawDataErrorFun(this, X, y)
            
            %[J, JGrad]=UtilFunML.CostFunctionLR(theta, X, y, lambda);
            %given a
            p = this.HypothesisP(X);
            J=100-UtilFunML.Accuracy(y,p);
            
            %compute F1 score, Precission and Recall for each class in y
            [F1s, P, R]=UtilFunML.Fscore(y,p);
            
            errStruct=UtilFunML.genErrorStruct(length(p));
            errStruct.J=J;
            errStruct.F1s=F1s;
            errStruct.P=P;
            errStruct.R=R;
        end
        
        function r=isTrained(this)
            if isempty(this.SVMstruct)
                r=false;
            else
                r=true;
            end
        end
    end
    
    
    %% private methods
    methods (Access=private)
        %Initialize
        function this=Init(this)
            
            
            %remove warning
            warning('off', 'stats:svmtrain:RBFParamNotRBFKernel');
            warning('off', 'stats:svmtrain:PolyOrderNotPolyKernel');
            
            this.Set(char(ClassifierProps.lambda), 1); %the C param of SVM
            this.Set(char(ClassifierProps.KF), 'rbf');
            this.Set(char(ClassifierProps.KFp), 1);
            this.Set(char(ClassifierProps.sigma), 1);
            this.Set(char(ClassifierProps.showplot), false);
            
            %logistic regression default params
            this.clr=ClassifierFactory.Create(ClassifierTypes.LogR);
            this.clr.Set(char(ClassifierProps.lambda), 1);
            
        end
                
        
        function this=InitSVMstruct(this, num_labels)
            this.SVMstruct(num_labels).SupportVectors=[];
            this.SVMstruct(num_labels).Alpha = [];
            this.SVMstruct(num_labels).Bias = [];
            this.SVMstruct(num_labels).KernelFunction = [];
            this.SVMstruct(num_labels).KernelFunctionArgs = [];
            this.SVMstruct(num_labels).GroupNames = [];
            this.SVMstruct(num_labels).SupportVectorIndices = [];
            this.SVMstruct(num_labels).ScaleData = [];
            this.SVMstruct(num_labels).FigureHandles = [];                        
        end
        
        function [out,f]=svmdecision(this, X, SVMstruct)
            %SVMDECISION Evaluates the SVM decision function
            %first normalize
            n = size(X, 2); % features number
            Xnorm=zeros(size(X));
            for k = 1:n
                Xnorm(:,k) = SVMstruct.ScaleData.scaleFactor(k)*(X(:,k) +  SVMstruct.ScaleData.shift(k));
            end
            
            sv = SVMstruct.SupportVectors;
            alphaHat = SVMstruct.Alpha;
            bias = SVMstruct.Bias;
            kfun = SVMstruct.KernelFunction;
            kfunargs = SVMstruct.KernelFunctionArgs;
            
            %evaluate f
            f = -1.0*((feval(kfun,sv,Xnorm,kfunargs{:})'*alphaHat(:)) + bias);
            % points on the boundary are assigned to class 1
            out = sign(f);
            out(out==0) = 1;
            
        end
        
    end
end
