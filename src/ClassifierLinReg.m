classdef ClassifierLinReg < Classifier
    % ClassifierLinReg linear regression classifier via the normal
    % equation (supervised, regression)

    %% private props
    properties (Access=private)
    end

    %% public methods
    methods
        % ClassifierLinReg constructs a linear regression classifier
        function  this=ClassifierLinReg()
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
        
        % isSupervised: true, linear regression needs labeled data
        function r=isSupervised(this)
            r=true;
        end

        % isRegression: true, predicts a continuous value
        function r=isRegression(this)
            r=true;
        end

    end

    %% protected abstract interface
    methods (Access=protected)
        % HypothesisP predicts pred = X*theta and prb as its distance to
        % the regression line (pred normalized by norm(theta))
        function [pred,prb]=HypothesisP(this, X)

            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];

            pred=Xbias*this.theta;
            prb=pred/norm(this.theta); % Distance to the regression line
        end

        % CalculateTheta fits theta via the (regularized) normal equation
        function CalculateTheta(this, X,y)

            m = size(X, 1); % Number of training examples
            n = size(X, 2); % features number

            lambda=this.Get(char(ClassifierProps.lambda));
            this.theta = UtilFunML.normalEqn(X,y, lambda);
        end

        % RawDataErrorFun returns the regularized cost J (F1/P/R are N/A
        % for a regressor, left at 0)
        function errStruct=RawDataErrorFun(this, X, y)
            lambda=this.Get(char(ClassifierProps.lambda));
                        
            [J, ~]=UtilFunML.CostFunctionLinReg(this.theta, X, y, lambda);
            
            errStruct=UtilFunML.genErrorStruct(1);
            errStruct.J=J;
            
            errStruct.F1s=0;
            errStruct.P=0;
            errStruct.R=0;
        end
        
        % isTrained returns true once theta has been fitted
        function r=isTrained(this)
            if isempty(this.theta)
                r=false;
            else
                r=true;
            end
        end

    end


    %% private methods
    methods (Access=private)
        % Init no-op: ClassifierLinReg needs no extra state beyond Classifier's
        function this=Init(this)
        end
    end
end

