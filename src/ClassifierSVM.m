classdef ClassifierSVM < Classifier
    % ClassifierSVM multi-class SVM classifier via MATLAB's Statistics
    % and Machine Learning Toolbox (fitcsvm, one-vs-all), supervised

    %% private props
    properties (Access=private)
        SVMstruct; %cell array of fitcsvm ClassificationSVM models, one per class -- ClassificationSVM doesn't support growing into a plain object array
        clr; %logistic regression classifier to calculate posterior probabilities
    end

    %% public methods
    methods
        function  this=ClassifierSVM()
            % ClassifierSVM constructs a multi-class SVM classifier;
            % errors if the Statistics Toolbox is missing or too old
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
            % isSupervised: true, needs labeled data to train the SVMs
            r=true;
        end

        function r=isRegression(this)
            % isRegression: false, this is a one-vs-all classifier
            r=false;
        end


    end

    %% protected abstract interface
    methods (Access=protected)
        function [pred,prb]=HypothesisP(this, X)
            % HypothesisP scores X against every per-class binary SVM,
            % returns the one-vs-all argmax pred and the posterior
            % probability prb from the inner LR classifier (this.clr)

            num_labels=length(this.SVMstruct);
            m = size(X, 1); % Number of training examples
            f=zeros(m, num_labels);

            for c=1:num_labels
                %f is the the SVM decision function for every sample, is an
                %array of m rows and num_labels columns
                %we need to calculate it to train the LR classfier
                [~, scores]=predict(this.SVMstruct{c}, X);
                f(:, c)=scores(:, 2);
            end

            %here we make a one-vs-all classification of X
            [~,pred]=max(f,[], 2);
            
            %posterior probability from the LR clasiifier
            [~, prb]=this.clr.Predict(f);
                       
        end
        
        function CalculateTheta(this, X,y)
            % CalculateTheta trains one binary SVM per class (one-vs-all),
            % then trains the inner LR classifier (this.clr) on their
            % scores to produce posterior probabilities

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

            for c=1:num_labels
                if sp
                    figure;
                end
                this.SVMstruct{c}=this.trainBinarySVM(X, y==c, KF, C, sigma, p);

                %f is the the SVM decision function for every sample, is an
                %array of m rows and num_labels columns
                %we need to calculate it to train the LR classfier
                [~, scores]=predict(this.SVMstruct{c}, X);
                f(:, c)=scores(:, 2);
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
            % RawDataErrorFun returns accuracy-based error plus F1/precision/recall
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
            % isTrained returns true once the per-class SVMs have been fitted
            if isempty(this.SVMstruct)
                r=false;
            else
                r=true;
            end
        end
    end


    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init sets the default SVM/kernel props and creates the inner LR classifier

            this.Set(char(ClassifierProps.lambda), 1); %the C param of SVM
            this.Set(char(ClassifierProps.KF), 'rbf');
            this.Set(char(ClassifierProps.KFp), 1);
            this.Set(char(ClassifierProps.sigma), 1);
            this.Set(char(ClassifierProps.showplot), false);
            
            %logistic regression default params
            this.clr=ClassifierFactory.Create(ClassifierTypes.LogR);
            this.clr.Set(char(ClassifierProps.lambda), 1);
            
        end
                
        
        function model=trainBinarySVM(~, X, yBinary, KF, C, sigma, polyOrder)
            % trainBinarySVM trains one fitcsvm model, passing only the
            % kernel-specific option that matches KF (fitcsvm errors if
            % given an option that doesn't apply to the selected kernel --
            % svmtrain, which this replaces, tolerated passing all of
            % them regardless of kernel).
            args={'KernelFunction', KF, 'BoxConstraint', C, 'Standardize', true};
            if strcmpi(KF, 'polynomial')
                args=[args, {'PolynomialOrder', polyOrder}];
            else
                args=[args, {'KernelScale', sigma}];
            end
            model=fitcsvm(X, yBinary, args{:});
        end

    end
end
