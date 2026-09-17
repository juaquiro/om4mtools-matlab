classdef ClassifierLinReg < Classifier
    % ClassifierLinReg linear regression classifier via the normal
    % equation (supervised, regression)

    %% private props
    properties (Access=private)
    end

    %% public methods
    methods
        function  this=ClassifierLinReg()
            % ClassifierLinReg constructs a linear regression classifier
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
            % isSupervised: true, linear regression needs labeled data
            r=true;
        end

        function r=isRegression(this)
            % isRegression: true, predicts a continuous value
            r=true;
        end

    end

    %% protected abstract interface
    methods (Access=protected)
        function [pred,prb]=HypothesisP(this, X)
            % HypothesisP predicts pred = X*theta and prb as its distance
            % to the regression line (pred normalized by norm(theta))

            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];

            pred=Xbias*this.theta;
            prb=pred/norm(this.theta); % Distance to the regression line
        end

        function CalculateTheta(this, X,y)
            % CalculateTheta fits theta via the (regularized) normal equation

            m = size(X, 1); % Number of training examples
            n = size(X, 2); % features number

            lambda=this.Get(char(ClassifierProps.lambda));
            this.theta = UtilFunML.normalEqn(X,y, lambda);
        end

        function errStruct=RawDataErrorFun(this, X, y)
            % RawDataErrorFun returns the regularized cost J (F1/P/R are
            % N/A for a regressor, left at 0)
            lambda=this.Get(char(ClassifierProps.lambda));
                        
            [J, ~]=UtilFunML.CostFunctionLinReg(this.theta, X, y, lambda);
            
            errStruct=UtilFunML.genErrorStruct(1);
            errStruct.J=J;
            
            errStruct.F1s=0;
            errStruct.P=0;
            errStruct.R=0;
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
            % Init no-op: ClassifierLinReg needs no extra state beyond Classifier's
        end
    end
end

