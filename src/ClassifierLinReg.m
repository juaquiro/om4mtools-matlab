classdef ClassifierLinReg < Classifier
    %ClassifierLR
    %   This class describes linear regression
    
    %% private props
    properties (Access=private)
    end
    
    %% public methods
    methods
        % constructor
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
        
        function r=isSupervised(this)
            r=true;
        end
        
        function r=isRegression(this)
            r=true;
        end

    end
    
    %% protected abstract interface
    methods (Access=protected)
        %Classfier hypothesis h_theta(X)
        function [pred,prb]=HypothesisP(this, X)
            
            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];
            
            pred=Xbias*this.theta;
            prb=pred/norm(this.theta); % Distance to the regression line
        end
        
        %function used to compute the parameters theta
        function CalculateTheta(this, X,y)
            
            m = size(X, 1); % Number of training examples
            n = size(X, 2); % features number
            
            lambda=this.Get(char(ClassifierProps.lambda));
            this.theta = UtilFunML.normalEqn(X,y, lambda);
        end
        
        function errStruct=RawDataErrorFun(this, X, y)                               
            lambda=this.Get(char(ClassifierProps.lambda));
                        
            [J, ~]=UtilFunML.CostFunctionLinReg(this.theta, X, y, lambda);
            
            errStruct=UtilFunML.genErrorStruct(1);
            errStruct.J=J;
            
            errStruct.F1s=0;
            errStruct.P=0;
            errStruct.R=0;
        end
        
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
        %Initialize
        function this=Init(this)
        end
    end
end

