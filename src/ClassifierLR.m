classdef ClassifierLR < Classifier
    % ClassifierLR multi-class logistic regression classifier (supervised)

    %% private props
    properties (Access=private)
    end

    %% public methods
    methods
        function  this=ClassifierLR()
            % ClassifierLR constructs a logistic regression classifier
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
            this.Init();
        end
        
        function r=isSupervised(this)
            % isSupervised: true, logistic regression needs labeled data
            r=true;
        end

        function r=isRegression(this)
            % isRegression: false, this is a classifier, not a regressor
            r=false;
        end

    end

    %% protected abstract interface
    methods (Access=protected)
        function [pred,prb]=HypothesisP(this, X)
            % HypothesisP predicts pred (argmax class) and prb (its
            % probability) via the sigmoid of X*theta'

            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];
            
            pn=Xbias*this.theta';
            gn=UtilFunML.sigmoid(pn);
            [prb,pred]=max(gn,[], 2);
            
        end
        
        function CalculateTheta(this, X,y)
            % CalculateTheta fits one-vs-all theta rows via fmincg, one
            % per class in y, minimizing UtilFunML.CostFunctionLR

            m = size(X, 1); % Number of training examples
            n = size(X, 2); % features number
            num_labels=length(unique(y));
            
            % Set Initial theta
            initial_theta = zeros(n + 1, 1);
            
            lambda=this.Get(char(ClassifierProps.lambda));
            
            % Set options for fminunc
            options = optimset('GradObj', 'on', 'MaxIter', 50);
            fh=@UtilFunML.CostFunctionLR;
            %we have to reset this.theta in order to make succesive calls to Train 
            this.theta=zeros(num_labels, n + 1);
            %here we assume the labels are 1,...,n
            %in "for c=1:num_labels", "this.theta(c, :)" and "(y == c)"
            for c=1:num_labels
                % Run fmincg to obtain the optimal theta
                % This function will return theta and the cost
                this.theta(c,:) = UtilFunML.fmincg(@(t)(fh(t, X, (y == c), lambda)), initial_theta, options);
                %this.theta(c, :) = fminunc(@(t)(fh(t, X, (y == c), lambda)), initial_theta, options);
            end
            
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
            % isTrained returns true once theta has been fitted
            if isempty(this.theta)
                r=false;
            else
                r=true;
            end
        end
    end


    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init no-op: ClassifierLR needs no extra state beyond Classifier's
        end
    end
end
