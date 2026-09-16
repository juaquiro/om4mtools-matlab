classdef ClassifierNN < Classifier
    % ClassifierNN neural network classifier backed by MATLAB's Deep
    % Learning Toolbox (patternnet), supervised

    %% private props
    properties (Access=private)
        net; %MATLAB network object
    end

    properties
        pm
    end

    %% public methods
    methods
        function  this=ClassifierNN()
            % ClassifierNN constructs a NN classifier; errors if the nnet
            % (Deep Learning) toolbox is not installed
            %%% Pre Initialization %%%
            % Any code not using first output argument (this)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            v=ver('nnet');
            if isempty(v)
                 retErrorMsg=['nnet toolbox is not installed: ' callFunc];
                error([retErrorMsg]);
            end
            
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
            % isSupervised: true, needs labeled data to train the network
            r=true;
        end

        function r=isRegression(this)
            % isRegression: false, this is a pattern-recognition classifier
            r=false;
        end

    end

    %% protected abstract interface
    methods (Access=protected)
        function [pred,prb]=HypothesisP(this, X)
            % HypothesisP runs X through the trained network and returns
            % the argmax class pred and its output activation prb
            pm=this.net(X');
            this.pm=pm;
            % p=vec2ind(pm); pred=p';
            [prb, pred] = max(pm, [], 1);
            prb=prb(:);
            pred=pred(:);
        end
        
        function CalculateTheta(this, X,y)
            % CalculateTheta creates the patternnet (on first call, sized
            % per hiddenSizes) and trains it on X/y with regularization = lambda

            %once the Taing is launched the number of hidden layers can not
            %be changed
            if isempty(this.net)
                hS=this.Get(char(ClassifierProps.hiddenSizes));
                this.net = patternnet(hS);
                this.net.performFcn = 'mse';
                this.net.trainFcn = 'traingd';
            end
            
            lambda=this.Get(char(ClassifierProps.lambda));
            if lambda <0, lambda=0; end
            if lambda>1, lambda=1; end
            if verLessThan('nnet', '8.0.1')
                % for former versions ratio=1 ->no reg
                this.net.performParam.ratio=1-lambda;
            else
                % regularization=0 ->no reg
                this.net.performParam.regularization=lambda;                
            end
            
            
            this.net.trainParam.showWindow=false;
            
            [this.net, ~] = train(this.net,X',full(ind2vec(y')));
            
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
            % isTrained returns true once this.net has been created/trained
            if this.isemptyNet
                r=false;
            else
                r=true;
            end
        end
    end


    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init clears this.net and sets the default hidden-layer size (10)

            this.net=[];
            %default is 1 hidden later with 10 neurons
            this.Set(char(ClassifierProps.hiddenSizes), [10]);

        end

         function st=isemptyNet(this)
             % isemptyNet returns true if this.net has not been created yet
            try
                st=isempty(this.net);
            catch ME
                throw(ME)
            end
        end
    end
end
