classdef featureNormalizer < handle
    %featureNormalizer is an objet for normalize feature sets
    
    %% private props
    properties (Access=private)
        mu;
        sigma;
        n; %feature number
    end
    
    %% public methods
    methods
        function this=featureNormalizer()
            %empty constructor
            this.mu=[];
            this.sigma=[];
            this.n=0;
        end
        
        function CalcParams(this, X)
            this.n=size(X,2); %n, feature number
            this.mu=mean(X);
            this.sigma=std(X);
        end
        
        
        function X_norm=Go(this,X)
            try
                
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                if this.n
                    nf=size(X,2);
                    if nf~=this.n
                        retErrorMsg=['feature number missmatch: ' callFunc];
                        error([class(this) '->' retErrorMsg]);
                        
                    end
                    
                    m=size(X,1); %m number of samples, n, feature number
                    X_norm=(X-repmat(this.mu,[m, 1]))./repmat(this.sigma, [m, 1]);
                else
                    X_norm=X;
                end
                
            catch ME
                throw(ME);
            end
        end
        
    end
    
end
