function [ ZValues, ZMatrix] = EvaluateTerms( X,Y, orders )
%EVALUATETERMS Calculate the value of the given order Zernike term 
%   X and Y are column vectors with the coordinates of the points whose
%   values will be evaluated.
%   Order is a row vector with the orders of the terms we want to evaluate.
%   The returned ZMatrix contains the coefficients of the equivalent XY
%   polynomials for each zernike term

    %Make sure X and Y are inside the unit circle
    if(any((X.^2+Y.^2)>1))
        error('Zernikes:EvaluateTerms:outOfRange',...
            'All points must be inside the unit circle');
    end
    
    % Get number of points to be evaluated
    K = length(X);
    
    %Get equivalent XY polynomials for the given order zernike terms
    ZMatrix = Zernikes.PolyEquivalent(orders);    

    %Evaluate polinomials in given points
    ZValues=zeros(K,length(orders));
    for index = 1:length(orders)
        ZValues(:,index) = Poly2.Evaluate(X,Y,ZMatrix(:,:,index));
    end

end

