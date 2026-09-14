function [ Zcoef, CMatrix, J, Jcv] = AdjustSurface( X,Y,Z, Zorder, CVRatio, classif)
%ADJUSTSURFACE Use a least square fit to find the coefficients that
%describe the Zernike polynomial that best adjust the given cloud of points
%   Detailed explanation goes here

    import Zernikes.*;
    % Check input parameters 
        K = length(X);
        orders=0:Zorder;
        n = ceil((-3 + sqrt(9+8*Zorder))/2);
    % Normalize data
        r = sqrt(max(X.*X + Y.*Y));
        Xn = X/r; Yn = Y/r; Zn = Z/r;
    % Randomize order
        rIndexs=randperm(K);
        Xn=Xn(rIndexs); Yn=Yn(rIndexs); Zn=Zn(rIndexs);
    % Calculate Zernike terms
        [ ZeValues, ZeMatrix] = EvaluateTerms( Xn,Yn, orders );
    % Reserve data for CV
        threshold=round(K*(1-CVRatio));
        XT=X(1:threshold); YT=Y(1:threshold); ZT=Z(1:threshold);
        XCV=X(threshold+1:end); YCV=Y(threshold+1:end); ZCV=Z(threshold+1:end);
        
        ZeValuesT=ZeValues(1:threshold,:);  ZnT=Zn(1:threshold);
        %ZeValuesCV=ZeValues(threshold+1:end,:); ZnCV=Zn(threshold+1:end);
    % Resolve Coefficient values
        Zcoef=RegresionByNormalEqn(ZeValuesT,ZnT,3e-3);
        
        %classif.Train(ZeValuesT(:,2:end),ZnT);
        %Zcoef=classif.GetTheta();
    
    % Build Equivalent matrix of monomial coefficients. Represents the 
    % obtained Zernike polynomial as an XY polynomial so it is faster to
    % compute. A stores the coefficients of the resulting polynomial.
        % Compensate for the unit circle normalization
        ScalingMatrix=GetScaling(r,n);
        % Matrix of monomial coefficients. 
         CMatrix = zeros(n+1);
         for index = 1:(Zorder+1);
            CMatrix = CMatrix + Zcoef(index)*ZeMatrix(:,:,index).*ScalingMatrix;
         end
    
    % Calculate J and Jcv
        %J=sqrt(mean((ZT-Polyval2(XT,YT,CMatrix)).^2));
        J=mean((ZnT-ZeValuesT*Zcoef).^2)*r^2;
        Jcv=sqrt(mean((ZCV-Poly2.Evaluate(XCV,YCV,CMatrix)).^2));
        %Jcv=mean((ZnCV-ZeValuesCV*Zcoef).^2)*r^2;
end

