function [ coeff ] = PolyEquivalent( order )
%POLYEQUIVALENT Builds the matrix of coefficients of the bi-dimensional
%polynomial equivalent to the given order Zernike term.
%   The formula used to define the zernike polynomials in terms of
%   cartesian polynomials is extracted from:
%   http://www.visualopticslab.com/OPTI515L/Background/Zernike%20Notes%2017Feb2011.pdf
%   But beware that there are errate there. The m in the convinatorial
%   values for m<0 should be |m|.
    
    %Determine final matrix dimensions
    N=max(ceil((-3 + sqrt(9+8*order))/2))+1;
    coeff = zeros(N, N, length(order));
    for ind=1:length(order);
        n = ceil((-3 + sqrt(9+8*order(ind)))/2);
        m = 2*order(ind) - n.*(n + 2);
        switch sign(m)
            case 1
                L1 = (n-m)/2;
                for s = 0:L1
                    for j = 0:(L1-s)
                        for k = 0:(m/2)
                            c = (-1)^(s+k);
                            c = c*factorial(n-s)/(factorial(s)*factorial((n+abs(m))/2-s)*factorial(L1-s));
                            c = c*nchoosek((n-m)/2-s,j)*nchoosek(abs(m),2*k);
                            row = n - 2*(s+j+k);
                            col = 2*(j+k);
                            coeff(row+1,col+1,ind) = coeff(row+1,col+1,ind)+c;
                        end
                    end
                end
            case -1
                L1 = (n-abs(m))/2;
                for s = 0:L1
                    for j = 0:(L1-s)
                        for k = 0:((abs(m)-1)/2)
                            c = (-1)^(s+k)*factorial(n-s);
                            c = c/(factorial(s)*factorial((n+abs(m))/2-s)*factorial(L1-s));
                            c = c*nchoosek((n-abs(m))/2-s,j)*nchoosek(abs(m),2*k+1);
                            row = n - 2*(s+j+k)-1;
                            col = 2*(j+k) + 1;
                            coeff(row+1,col+1,ind) = coeff(row+1,col+1,ind)+c;
                        end
                    end
                end
            case 0
                n2 = floor(n/2);
                for s = 0:n2
                    for j = 0:(n2-s)
                        c = (-1)^s;
                        c = c*factorial(n-s)/(factorial(n2-s)*factorial(s));
                        c = c/(factorial(n2-s-j)*factorial(j));
                        row = n - 2*(s+j);
                        col = 2*j;
                        coeff(row+1,col+1,ind) = coeff(row+1,col+1,ind)+c;
                    end
                end
        end
        %coeff(:,:,ind) = coeff(:,:,ind)./(n+1)^2;
    end
end

