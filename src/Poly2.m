classdef Poly2
    % Poly2 static utilities for bivariate polynomials represented by
    % their coefficient matrix C

    properties
    end

    methods (Static=true)
        function z = Evaluate(x, y, C)
            % Evaluate evaluates the bivariate polynomial C at
            % coordinates (x, y); z has the same shape as x and y
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
        
        function [ Cder ] = Derive(C, dim)
            % Derive returns the coefficient matrix Cder of polynomial C
            % differentiated along dimension dim (1=x, 2=y)
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
        
        function [ L ] = Laplacian(C)
            % Laplacian returns the coefficient matrix L of the
            % Laplacian of bivariate polynomial C
            Px=Poly2.Derive(C,1);
            Py=Poly2.Derive(C,2);

            Pxx=Poly2.Derive(Px,1);
            Pyy=Poly2.Derive(Py,2);

            L=Pxx+Pyy;
        end
    end
    
    methods(Static=true, Access=private)
       function Cder=DeriveCoeff(C)
           % DeriveCoeff computes the actual derivative coefficients for
           % Derive, differentiating along the first dimension of C
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

