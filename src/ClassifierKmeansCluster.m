classdef ClassifierKmeansCluster < Classifier
    %ClassifierSVN
    %   This class describes a Kmeans unsupervised classifier from the MATLAB stats toolbox
    %   it is composed of a Kmeans clustering methods and a supervised
    %   classifier defined by the svClassifier prop, default is LogR
    
    %% private props
    properties (Access=private)
        svc; %supervised classifier used for further classification in the custers defined by the kmeans clustering
        d; %mean inter cluster distance
    end
    
    %% public methods
    methods
        % constructor
        function  this=ClassifierKmeansCluster()
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
            r=false;
        end
        
        function r=isRegression(this)
            r=false;
        end
        
    end
    
    %% protected abstract interface
    methods (Access=protected)
        %Classfier hypothesis h_theta(X)
        function [pred,prb]=HypothesisP(this, X)
            [pred,prb]=this.svc.HypothesisP(X);
                       
        end
        
        %function used to compute the parameters theta
        function CalculateTheta(this, X, K)        
            
            
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
            errStruct=this.svc.RawDataErrorFun(X, y);
        end
        
       function st=isTrained(this)            
             st=this.svc.isTrained();
       end
        
    end
    
    
    %% private methods
    methods (Access=private)
        %Initialize
        function this=Init(this)
            
                       
            % init svc
            svcType=this.Get(char(ClassifierProps.svcType));
            this.svc=ClassifierFactory.Create(svcType);
            
            % set props to this.c
            this.setProps(this.svc);                 
            
        end                
        
        
    end
end
