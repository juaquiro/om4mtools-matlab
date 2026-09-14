classdef polynomicFeatureMapper < handle
    % polynomicFeatureMapper is an objet for polynomic mapping
    % Copyright IOT
    % $Revision: 1 $  $Date: 20/05/2013 $
    % $JJ$
    %% private props
    properties (GetAccess='public', SetAccess='protected')
        % X_mapped is the result of the polynomic mapping
        X_mapped;
        % powers is a cell array which contains the powers for each value
        % of the max power p. For example, for p=3 and X=[x1 x2 x3], the
        % first element of powers contains the possible combinations of the
        % powers of x1, x2 and x3 that sums 1, the second contains the
        % possible combinations of powers of x1, x2 and x3 that sums 3, and
        % so on until the value of p. This property allows user to know
        % easily which value of X_poly corresponds to each combination of
        % variables and powers.
        powers;
    end
    
    %% public methods
    methods
        function this=polynomicFeatureMapper()
            %empty constructor
        end
        
        % This method maps the different Xi given in each row of X to and
        % order p 
        % the input data X has no bias, this is a high level function and bias is not necessary 
        function X_mapped=Go(this,X, p)
            try
                
                % Order p must be greater than zero and bias must be
                % removed if it's contained in input X
                if p<=0
                    error('polFeatMapper:wrongP',['Input '...
                        inputname(3) ' only accepts values equal or greater than 1'])
                end
                
                
                % Obtaining the powers
                n=size(X,2); % Number of features
                powersCell=cell(1,p);
                powersCell{1}=ones(1,n);
                
                for i=2:p
                    
                    c=nchoosek(1:i+n-1,n-1);
                    m=size(c,1);
                    t=ones(m,i+n-1);
                    t(repmat((1:m).',1,n-1)+(c-1)*m)=0;
                    u=[zeros(1,m);t.';zeros(1,m)];
                    v=cumsum(u,1);
                    x=diff(reshape(v(u==0),n+1,m),1).';
                    x=flipud(x);
                    powersCell{i}=x;
                    
                end
                
                this.powers=powersCell;
                
                % Generating the results
                m=size(X,1); % Number of taining sets
                result=cell(1,p);
                X_mapped=cell(m,1);
                
                for i=1:m
                    result{1}=X(i,:);
                    
                    for j=2:p
                        nrows=size(powersCell{j},1);
                        XiMatrix=repmat(result{1},nrows,1);
                        result{j}=prod(XiMatrix.^powersCell{j},2)';
                    end
                    
                    X_mapped{i}=[result{:}];
                    
                end
                
                X_mapped=cell2mat(X_mapped);
                this.X_mapped=X_mapped;
                
            catch ME
                throw(ME);
            end
        end
    end
end
