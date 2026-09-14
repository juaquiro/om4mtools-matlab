classdef Poly2
    %POLY2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static=true)
        %Evaluate a bivariate polynomial at given coordinates.
        % x: X coordinates of the evaluation points
        % y: Y coordiantes of the evaluation points
        % C: Coefficient matrix that defines the polynomial
        % z: Returned matrix of calculated values. Same shape as x and y
        function z = Evaluate(x, y, C)
            if nargin < 3
                error('Poly2:Evaluate:tooFewArguments', 'Evaluate expects 3 arguments');
            end

            [N,M] = size(C);
            if(N>M)
                C=padarray(C, [0 N-M], 0, 'post');
            elseif (M>N)
                C=padarray(C, [M-N 0], 0, 'post');
                N=M;
            end
            
            z=zeros(size(x));
            for n = N:-1:1
                B=zeros(size(x));
                for m = (N-n+1):-1:1
                    B=plus(B.*y,C(n,m));
                end
                z=plus(z.*x,B);
            end
        end
        
        %POLYDER2 Derivative of bivariate polynomials
        %   This function returns the coefficient matrix of the given bivariate
        %   polynomial derived along the given dimension
        % C: Coefficient matrix that defines the polynomial
        % dim: Spatial dimension to derve along
        % Cder: Coefficient matrix of the derived polynomial
        function [ Cder ] = Derive(C, dim)       
            switch(dim)
                case 1
                    Cder=Poly2.DeriveCoeff(C);
                case 2
                    C=permute(C,[2 1 3]);
                    Cder=Poly2.DeriveCoeff(C);
                    Cder=ipermute(Cder,[2 1 3]);
            end

            if(isempty(Cder))
                Cder=0;
            end 
        end
        
        %POLYLAPLACIAN Calculates the laplacian of a bivariate polynomial
        %   C: coefficient matrix of the initial polynomial
        %   L:     coefficient matrix of the laplacian
        function [ L ] = Laplacian(C)
            Px=Poly2.Derive(C,1);
            Py=Poly2.Derive(C,2);

            Pxx=Poly2.Derive(Px,1);
            Pyy=Poly2.Derive(Py,2);

            L=Pxx+Pyy;
        end
    end
    
    methods(Static=true, Access=private)
       %Helper function used by Derive. Does the actual calculation of the
       %derived coefficients
       function Cder=DeriveCoeff(C)
            maxOrder=size(C);
            maxOrder(1)=maxOrder(1)-1;
            if(maxOrder(1)==0)
                Cder=zeros([1, maxOrder(2:end)]);
            else
                Cder=zeros(maxOrder);
                for i=1:maxOrder(1)
                   Cder(i,:,:)=i*C(i+1,:,:);
                end
                %Trim extra row of zeros or ad it if nedded to make the matrix
                %square
                if(all(Cder(:,maxOrder(2),:)==0))
                    Cder(:,end,:)=[];
                else
                    Cder(end+1,:,:)=0;
                end
            end        
        end 
    end
    
end

