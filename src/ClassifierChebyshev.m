classdef ClassifierChebyshev < ClassifierLinReg
    % ClassifierChebyshev fits a surface (cloud of points) as a bivariate
    % Chebyshev polynomial (supervised, regression)

    %% private props
    properties (Access=private)

        monCoeff;       %Matrix of monomial coeficients that represent the calculated
                        %zernike polinomial
        offset;
        scale;          %Scaling of the training parameters so that they fit in the unit circle

    end

   %% public methods
    methods
        function  this=ClassifierChebyshev()
            % ClassifierChebyshev constructs a Chebyshev-surface classifier

            this = this@ClassifierLinReg();

            % Add chebyshev to the path
            % TODO: The actual path configuration
            this.Init();
        end
        
        function r=isSupervised(this) %#ok<MANU>
            % isSupervised: true, needs labeled (X, y) training data
            r=true;
        end

        function r=isRegression(this) %#ok<MANU>
            % isRegression: true, predicts a continuous surface value
            r=true;
        end

        function coeff=GetSurfCoeff(this)
            % GetSurfCoeff returns the fitted bivariate polynomial's
            % monomial coefficient matrix (the adjusted surface, in XY form)
            coeff=this.monCoeff;
        end

    end
    
    %% protected abstract interface
    methods(Access=protected)

        function CalculateTheta(this, X,y)
            % CalculateTheta fits theta over normalized Chebyshev terms of
            % X, then converts it to an equivalent XY monomial matrix
            % (this.monCoeff) so Predict doesn't need to re-evaluate
            % Chebyshev terms every call

            import OM4MClassLib.Util.*;
            
            %Load and check classifier properties
            cOrder=this.Get((char(ClassifierProps.chebOrder))); %Polynomial order
            %Order must be greater than zero 
            if (cOrder<=0)
                retErrorMsg='Order must be greater than 0';
                error([class(this) '->' retErrorMsg]);
            end   
            
            lambda=this.Get(char(ClassifierProps.lambda));
            %Lambda must be positive
            if (lambda<0)
                retErrorMsg='Regularization parameter lambda can not be negative';
                error([class(this) '->' retErrorMsg]);
            end
            
            % Normalize data
            this.offset=(max(X,[],1)+min(X,[],1))./2;
            XCent=bsxfun(@minus, X, this.offset);
            this.scale=(max(XCent,[],1)-min(XCent,[],1))*1.1/2;
            this.scale(this.scale==0)=1;
            Xnorm = bsxfun(@rdivide, XCent, this.scale);
            
            %Calculate Chebyshev terms and matrix
            xOrders=0; yOrders=0;
            for i=1:cOrder
               xOrders=cat(2,xOrders,i:-1:0);
               yOrders=cat(2,yOrders,0:i);
            end
            [ X_mapped, ChMatrix] = Chebyshev.EvaluateTerms( Xnorm(:,1), Xnorm(:,2), xOrders, yOrders );

            %Solve system to calculate theta
            this.theta = UtilFunML.normalEqnWithoutBias(X_mapped, y, lambda);
            
            % Build Equivalent matrix of monomial coefficients. Represents the 
            % obtained Chebyshev polynomial as an XY polynomial so it is faster to
            % compute. A stores the coefficients of the resulting polynomial.
            A = zeros(size(ChMatrix,1),size(ChMatrix,2));
            for index = 1:size(ChMatrix,3);
             A = A + this.theta(index)*ChMatrix(:,:,index);
            end
             
            %Transformation of X and Y coordinates due to the scale
            Xs=[0       0;          1/this.scale(1)   0];
            Ys=[0 1/this.scale(2);        0           0];
            A = this.PolySubstitution(A, Xs, Ys);
             
            %Compensation of the initial offset
            Xd=[-this.offset(1) 0; 1 0];
            Yd=[-this.offset(2) 1; 0 0];
            A = this.PolySubstitution(A, Xd, Yd);
             
            this.monCoeff=A;
        end
        
        function [pred,prb]=HypothesisP(this, X)
            % HypothesisP predicts pred by evaluating the fitted XY
            % polynomial (this.monCoeff) at X, and prb as its distance to
            % the regression line
            pred=Poly2.Evaluate(X(:,1),X(:,2),this.monCoeff);
            prb=pred/norm(this.theta); % Distance to the regression line
        end

        function errStruct=RawDataErrorFun(this, X, y)
            % RawDataErrorFun returns the regularized cost J (F1/P/R are
            % N/A for a regressor, left at 0)
                                              
                        
            J=this.CostFunction(X, y);
            
            errStruct=UtilFunML.genErrorStruct(1);
            errStruct.J=J;
            
            errStruct.F1s=0;
            errStruct.P=0;
            errStruct.R=0;
        end
        
        function J=CostFunction(this, X, y)
           % CostFunction returns the regularized squared-error cost of
           % predicting X against y

           m = size(X, 1);
           lambda=this.Get(char(ClassifierProps.lambda));
           t=this.theta(2:end);
           res=this.Predict(X)-y;
           
           J=res'*res/(2*m) + lambda*(t')*t/(2*m);
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
            % Init sets this classifier's default lambda/chebOrder/normalize props

            %Default prop values
            this.props.Set(char(ClassifierProps.lambda), 0);
            this.props.Set(char(ClassifierProps.chebOrder), 15);
            this.props.Set(char(ClassifierProps.normalize),  false);
        end

        function outMatrix=PolySubstitution(this, inMatrix, newX, newY)
            % PolySubstitution substitutes each variable of inMatrix's
            % bivariate polynomial with a linear transform (newX/newY,
            % given as [constant; coefficient] pairs), returning the
            % resulting coefficient matrix - used to undo the
            % normalization/offset applied before fitting
            %X and Y maximum order of the current polynomial
            polyGrade=size(inMatrix);
            %reserve memory for the resulting coefficient matrix
            outMatrix=zeros(polyGrade);
            
            %Calculate power of the transformed coordinates
            expandedNewX=cell(polyGrade(1),1);
            expandedNewY=cell(polyGrade(2),1);
            expandedNewX{1}=1;
            for i=2:polyGrade(1)
                expandedNewX{i}=conv2(newX,expandedNewX{i-1});
            end          
            expandedNewY{1}=1;
            for j=2:polyGrade(2)
                expandedNewY{j}=conv2(newY,expandedNewY{j-1});
            end
            
            %For each monomial of the original polynomial
            for i=1:polyGrade(1)
               for j=1:(polyGrade(2)-i+1)
                  equivalentMatrix=conv2(expandedNewX{i},expandedNewY{j});
                  %Pad the equivalent matrix with zeros to equalize size
                  %with the original coefficient matrix
                  padSize=polyGrade-size(equivalentMatrix);
                  equivalentMatrix=padarray(equivalentMatrix,padSize,'post');
                  %Sum the current equivalent matrix multiplied by the
                  %current monomial coefficient to the output matrix
                  outMatrix=outMatrix+inMatrix(i,j)*equivalentMatrix(); 
               end
            end 
        end

    end
    
end