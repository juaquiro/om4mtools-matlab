classdef ClassifierZernikes < ClassifierLinReg
    % ClassifierZernikes fits a surface (cloud of points) as a bivariate
    % Zernike polynomial expansion (supervised, regression)

    %% private props
    properties (Access=private)

        monCoeff;       %Matrix of monomial coeficients that represent the calculated
                        %zernike polinomial
        scale;          %Scaling of the training parameters so that they fit in the unit circle

    end

   %% public methods
    methods
        function  this=ClassifierZernikes()
            % ClassifierZernikes constructs a Zernike-surface classifier

            this = this@ClassifierLinReg();
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
            % CalculateTheta fits theta over normalized Zernike terms of
            % X (with optional curvature-smoothness virtual points), then
            % converts it to an equivalent XY monomial matrix
            % (this.monCoeff) so Predict doesn't need to re-evaluate
            % Zernike terms every call

            import OM4MClassLib.Util.*;
            
            %Load and check classifier properties
            Zorder=this.Get((char(ClassifierProps.zOrder))); %zernike order
            %Order must be greater than zero 
            if (Zorder<=0)
                retErrorMsg='Zernike order must be greater than 0';
                error([class(this) '->' retErrorMsg]);
            end   
            
            lambda=this.Get(char(ClassifierProps.lambda));
            %Lambda must be positive
            if (lambda<0)
                retErrorMsg='Regularization parameter lambda can not be negative';
                error([class(this) '->' retErrorMsg]);
            end
            
            mu=this.Get(char(ClassifierProps.mu));
            %Mu must be positive 
            if (mu<0)
                retErrorMsg='Regularization parameter mu can not be negative';
                error([class(this) '->' retErrorMsg]);
            end
            
            % Normalize data
            if(this.props.Get(char(ClassifierProps.zernikeRadius))==0)
                r = sqrt(max(X(:,1).*X(:,1) + X(:,2).*X(:,2)))*1.3;
            else
                r=this.props.Get(char(ClassifierProps.zernikeRadius));
            end
            Xn = X/r; yn = y/r; 
            this.scale=r;
            
            %Calculate Zernike terms and matrix
            orders=0:Zorder;
            n = ceil((-3 + sqrt(9+8*Zorder))/2);
            [ X_mapped, ZeMatrix] = Zernikes.EvaluateTerms( Xn(:,1),Xn(:,2), orders );

            
            %Add virtual points to account to the curvature smoothness
            %criteria
            if(mu~=0)
                %Points where we evaluate curvatures
                %freq=sqrt(length(X));
                marks=linspace(-0.9,0.9);
                [XC, YC]=meshgrid(marks, marks);
                inPoints=XC.^2+YC.^2>0.9^2;
                XC=XC(inPoints);
                YC=YC(inPoints);
                CurvDer=Zernikes.CalculateCurvatureDer(XC,YC,ZeMatrix);
                X_mapped=cat(1,X_mapped, CurvDer.*mu);
                yn=cat(1,yn,zeros(size(CurvDer(:,1))));
            end
            
            %Solve system to calculate theta
            this.theta = UtilFunML.normalEqnWithoutBias(X_mapped, yn, lambda);
            
            % Build Equivalent matrix of monomial coefficients. Represents the 
            % obtained Zernike polynomial as an XY polynomial so it is faster to
            % compute. A stores the coefficients of the resulting polynomial.
                % Compensate for the unit circle normalization
                ScalingMatrix=Zernikes.GetScaling(this.scale,n);
                % Matrix of monomial coefficients. 
                A = zeros(n+1);
                for index = 1:(Zorder+1);
                    A = A + this.theta(index)*ZeMatrix(:,:,index).*ScalingMatrix;
                end
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
            % Init sets this classifier's default lambda/zOrder/zernikeRadius props

            %Default prop values
            this.props.Set(char(ClassifierProps.lambda), 0);
            this.props.Set(char(ClassifierProps.zOrder), 209);
            this.props.Set(char(ClassifierProps.zernikeRadius),  0);
        end

    end
    
end

