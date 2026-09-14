classdef ClassifierNN1 < Classifier
    %ClassifierNN
    %   This class describes a NN classifier with one hidden layer from
    %   using the coursera ML course code
    
    %% private props
    properties (Access=private)
    end
    
    %% public methods
    methods
        % constructor
        function  this=ClassifierNN1()
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
            r=false;
        end


    end
    
    %% protected abstract interface
    methods (Access=protected)
        %Classfier hypothesis h_theta(X)
        function [pred,prb]=HypothesisP(this, X)
            
            
            m=size(X, 1);
            Theta1=this.theta{1};
            Theta2=this.theta{2};
            h1=UtilFunML.sigmoid([ones(m,1) X]*Theta1');
            h2=UtilFunML.sigmoid([ones(m,1) h1]*Theta2');
            [prb,pred]=max(h2,[],2);
            
        end
        
        %function used to compute the parameters theta
        function CalculateTheta(this,X,y)
            
            
            
            input_layer_size=size(X,2);
            hidden_layer_size=this.Get(char(ClassifierProps.hiddenSizes));
            if length(hidden_layer_size)>1
                msg='NN1 classifier objects can only have 1 hidden layer';
                error('NN1CalculateTheta:wrongHiddenLayer',msg)
            end
            num_labels=length(unique(y));
            lambda=this.Get(char(ClassifierProps.lambda));
            
            % Obtainining the initial values of theta            
            initial_Theta1 = UtilFunML.randInitializeNNWeights(input_layer_size, hidden_layer_size); 
            initial_Theta2 = UtilFunML.randInitializeNNWeights(hidden_layer_size, num_labels);
            % Unrolling parameters
            initial_nn_params = [initial_Theta1(:) ; initial_Theta2(:)];
            
            % Create "short hand" for the cost function to be minimized
            costFunction = @(p) UtilFunML.nnCostFunction(p, input_layer_size, ...
                hidden_layer_size,  num_labels, X, y, lambda);
            
            % Now, costFunction is a function that takes in only one argument (the
            % neural network parameters)
            options = optimset('MaxIter', 50);
            nn_params = UtilFunML.fmincg(costFunction, initial_nn_params, options);
            
            % Obtain Theta1 and Theta2 back from nn_params
            Theta1 = reshape(nn_params(1:hidden_layer_size * (input_layer_size + 1)), ...
                hidden_layer_size, (input_layer_size + 1));
            
            Theta2 = reshape(nn_params((1 + (hidden_layer_size * (input_layer_size + 1))):end), ...
                num_labels, (hidden_layer_size + 1));
            
            this.theta={Theta1,Theta2};
            this.Set(char(ClassifierProps.thetaFreeStyle),this.theta);
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
            
            
            %default is 1 hidden layer with 10 neurons
            this.Set(char(ClassifierProps.hiddenSizes), 10);
                                  
        end
    end
end

