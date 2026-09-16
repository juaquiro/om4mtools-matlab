classdef ClassifierKmeansCluster < Classifier
    % ClassifierKmeansCluster k-means clustering (unsupervised), backed by
    % a supervised Classifier (per ClassifierProps.svcType, default LogR)
    % to classify further points into the clusters found by k-means

    %% private props
    properties (Access=private)
        svc; %supervised classifier used for further classification in the custers defined by the kmeans clustering
        d; %mean inter cluster distance
    end

    %% public methods
    methods
        function  this=ClassifierKmeansCluster()
            % ClassifierKmeansCluster constructs a k-means clustering classifier
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
            % isSupervised: false, k-means clustering needs no labels
            r=false;
        end

        function r=isRegression(this)
            % isRegression: false, this is a clustering classifier
            r=false;
        end

    end

    %% protected abstract interface
    methods (Access=protected)
        function [pred,prb]=HypothesisP(this, X)
            % HypothesisP delegates prediction to the inner supervised
            % classifier (this.svc) trained on the k-means cluster labels
            [pred,prb]=this.svc.HypothesisP(X);

        end

        function CalculateTheta(this, X, K)
            % CalculateTheta clusters X into K groups via kmeans, then
            % trains the inner supervised classifier (this.svc) on those labels
            
            
            y=kmeans(X,K, 'display','off', 'replicates',5);
            silh = silhouette(X,y);
            this.d=mean(silh);
            this.Set(char(ClassifierProps.d),this.d);
            
            %get svc type
            svcType=this.Get(char(ClassifierProps.svcType));
            this.svc=ClassifierFactory.Create(svcType);
            
            %set all necessry props to this.svc
            this.setProps(this.svc); 
            
            %train svc
            this.svc.Train(X,y);            
        end
        
        function errStruct=RawDataErrorFun(this, X, y)
            % RawDataErrorFun delegates to the inner supervised classifier
            errStruct=this.svc.RawDataErrorFun(X, y);
        end

       function st=isTrained(this)
             % isTrained returns true once the inner supervised classifier is trained
             st=this.svc.isTrained();
       end

    end


    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init creates the inner supervised classifier (per svcType)
            % and copies this classifier's props onto it
            
                       
            % init svc
            svcType=this.Get(char(ClassifierProps.svcType));
            this.svc=ClassifierFactory.Create(svcType);
            
            % set props to this.c
            this.setProps(this.svc);                 
            
        end                
        
        
    end
end
