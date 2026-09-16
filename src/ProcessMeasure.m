classdef ProcessMeasure < handle
    % ProcessMeasure static utilities for surface fitting/processing:
    % Zernike coefficient fitting (with optional curvature regularization),
    % bivariate polynomial evaluation/derivatives, ball-radius correction,
    % spline surface fitting, and .hmf file export.
    %
    % Note: only ProcessMeasure.Polyval2 and Polyder2 are actually
    % called from elsewhere in this codebase (verified via grep,
    % 2026-09-16) - the rest may be dead code kept for reference.
    properties(Access='private', Constant)
        spatialPeriod=1;
        meshLimits=[-40 40]
    end
        
        
    methods(Access='public', Static=true)
        
        function [Xa,Ya]=AlignToLaserMarks(offset,angle, X,Y)
            % AlignToLaserMarks corrects (X, Y) for lens position/orientation:
            % translates by -offset then rotates by -angle
            % Coordinates of the geometrical center of the lens
            X0 = offset(1);
            Y0 = offset(2);
            % Translation to the geometrical center
            X = X - X0;
            Y = Y - Y0;
            % Rotation of coordinates
            Rot = [cos(angle), sin(angle); -sin(angle), cos(angle)];
            Xa = Rot(1,1)*X + Rot(1,2)*Y;
            Ya = Rot(2,1)*X + Rot(2,2)*Y;
        end
        
        function [C, res] = AdjustToZernike(X,Y,Z,ZOrder)
            % AdjustToZernike fits Zernike coefficients C (order ZOrder)
            % to the cloud of points (X,Y,Z), returning fit residuals res
            C = ProcessMeasure.ZernikeCoefficients(X,Y,Z,ZOrder);
            %Calculate the sagitas that correspond to the interpolating
            %zernike polynomial
            Zpol = ProcessMeasure.Zernike(X,Y,C);
            %Calculate the residuals as the difference between the
            %measured data and the data obtained from the zernike
            res = Z - Zpol;
        end
        
        function [C, res] = AdjustToZernikeReg(X,Y,Z,ZOrder,lambda, mu)
            % AdjustToZernikeReg fits curvature-regularized Zernike
            % coefficients C (order ZOrder, lambda/mu regularization) to
            % the cloud of points (X,Y,Z), returning fit residuals res
            C = ProcessMeasure.ZernikeCoefficientsRegCurv(X,Y,Z,ZOrder,lambda,mu);
            %Calculate the sagitas that correspond to the interpolating
            %zernike polynomial
            Zpol = ProcessMeasure.Zernike(X,Y,C);
            %Calculate the residuals as the difference between the
            %measured data and the data obtained from the zernike
            res = Z - Zpol;
        end
    
        function [X,Y,Z,C,res, resStats]=FilterNoisyPoints(X,Y,Z, ZOrder, filterThresholds, lambda, mu)
            % FilterNoisyPoints iteratively fits a regularized Zernike
            % surface (AdjustToZernikeReg) and removes points whose
            % residual exceeds each successive filterThresholds entry,
            % returning the cleaned data plus the final fit and residual stats
            if(nargin<7)
                mu=0;
            elseif (nargin<6)
                lambda=0;
                mu=0;
            end
            
            inPointNumber=length(X);
            filterThresholds=[filterThresholds, Inf];   %We do this to add an extra iteration that does not remove any point.
            iterations=length(filterThresholds);            
            for iterNumber=1:iterations
                [C, res] = ProcessMeasure.AdjustToZernikeReg(X,Y,Z,ZOrder,lambda,mu);
                resStats.max=max(abs(res));
                resStats.mean=mean(res);
                resStats.std=std(res);             

                %Clear any point whose residue is greater than the given
                %threshold for the current iteration
                I = find(abs(res) > filterThresholds(iterNumber));
                X(I) = [];
                Y(I) = [];
                Z(I) = [];
            end
            outPointNumber=length(X);
            removedPointNumber=inPointNumber-outPointNumber;
            resStats.remPercent=(removedPointNumber/inPointNumber)*100;
        end
        
        
        function [xx,yy,zz]=BuildSquareGrid(C,ZernikeRegionParams, safetyMargin)
            % BuildSquareGrid evaluates Zernike surface C on a fresh
            % square mesh, extrapolating outside ZernikeRegionParams
            % (shrunk by safetyMargin) via Rescepol
            %Generate a new clean and complete mesh
            meshIndexs=ProcessMeasure.meshLimits(1):ProcessMeasure.spatialPeriod:ProcessMeasure.meshLimits(2);
            [xx,yy] = meshgrid(meshIndexs);
            rho = 3*[0.01,0.02,0.03];
            regionLimitFunc=ProcessMeasure.GetRegionLimitFunction(ZernikeRegionParams, safetyMargin);
            zz = ProcessMeasure.Rescepol(xx,yy,C,rho,regionLimitFunc);
        end
        
        function [zzOut]= CorrectBallRadius(xx,yy,zz,rad, waitbarDomain)
            % CorrectBallRadius compensates surface zz for the finite
            % probe-ball radius rad, fitting a spline (ApspCoefficients)
            % to get the local normal and offsetting each point along it
            % before resampling back onto the original grid. Optional
            % waitbarDomain=[start,end] drives a progress waitbar.
            if nargin<5
               waitbarDomain=[]; 
            end
            if(~isempty(waitbarDomain))
                waitbar(waitbarDomain(1));
            end
            % Compensaci�n del radio de la bola
            C = ProcessMeasure.ApspCoefficients(xx,yy,zz,'pval', 0.9);
            if(~isempty(waitbarDomain))
                waitbar(waitbarDomain(1)+(waitbarDomain(2)-waitbarDomain(1))*0.2);
            end
            Nx = ProcessMeasure.Apsp(xx,yy,fnder(C,[1,0]));
            if(~isempty(waitbarDomain))
                waitbar(waitbarDomain(1)+(waitbarDomain(2)-waitbarDomain(1))*0.4);
            end
            Ny = ProcessMeasure.Apsp(xx,yy,fnder(C,[0,1]));
            if(~isempty(waitbarDomain))
                waitbar(waitbarDomain(1)+(waitbarDomain(2)-waitbarDomain(1))*0.6);
            end
            Nz = 1./sqrt(1 + Nx.*Nx + Ny.*Ny);
            Nx = -Nx.*Nz;
            Ny = -Ny.*Nz;
            xxc = xx - Nx*rad;
            yyc = yy - Ny*rad;
            zzc = zz - Nz*rad;
            %Resample surface in the original grid.
            zzOut = griddata(xxc, yyc, zzc, xx, yy,'v4');
            if(~isempty(waitbarDomain))
                waitbar(waitbarDomain(2));
            end
        end
        
         function [zzOut, COut, ZerPoly]= CorrectBallRadiusZer(xx, yy, zz,rad,ZOrder, lambda, mu)
            % CorrectBallRadiusZer compensates (xx,yy,zz) for probe-ball
            % radius rad, using a fitted ClassifierZernikes surface
            % (order ZOrder, lambda/mu regularization) for the local
            % normal instead of a spline (compare CorrectBallRadius)
            xx=xx(:);   yy=yy(:);     zz=zz(:);            
             
            cl=ClassifierZernikes();
            cl.Set(char(ClassifierProps.zOrder),ZOrder);
            cl.Set(char(ClassifierProps.lambda),lambda);
            cl.Set(char(ClassifierProps.mu),mu);

            cl.Train([xx yy], zz);
            zz=cl.Predict([xx yy]);
            CMatrix=cl.GetSurfCoeff();
            
            CMX=ProcessMeasure.Polyder2(CMatrix,1);
            CMY=ProcessMeasure.Polyder2(CMatrix,2);

            Nx = ProcessMeasure.Polyval2(xx,yy,CMX);

            Ny = ProcessMeasure.Polyval2(xx,yy,CMY);

            Nz = 1./sqrt(1 + Nx.*Nx + Ny.*Ny);
            Nx = -Nx.*Nz;
            Ny = -Ny.*Nz;
            xxc = xx - Nx*rad;
            yyc = yy - Ny*rad;
            zzc = zz - Nz*rad;
            
            cl.Train([xxc yyc], zzc);
            zzOut=cl.Predict([xx yy]);
            COut=cl.GetSurfCoeff();
            ZerPoly=cl.GetTheta();
            
        end
        
        function [zzOut]= CorrectBallRadiusZerSph(xx, yy, CMatrix,R0,X0,Y0,rad)
            % CorrectBallRadiusZerSph compensates for probe-ball radius
            % rad on a surface given as a polynomial CMatrix plus a base
            % sphere (radius R0, center X0/Y0), combining both terms'
            % gradients for the local normal
            zz=ProcessMeasure.Polyval2(xx,yy,CMatrix)+ CalibSphere.mSphere(R0,0,0,0, 0,0,0, xx, yy);
            CMX=Polyder2(CMatrix,1);
            CMY=Polyder2(CMatrix,2);

            Nx = ProcessMeasure.Polyval2(xx,yy,CMX);

            Ny = ProcessMeasure.Polyval2(xx,yy,CMY);
            
            NxSph=-2*(xx-X0)./(R0*sqrt(1-((xx-X0).^2+(yy-Y0).^2)/R0^2));
            NySph=-2*(yy-Y0)./(R0*sqrt(1-((xx-X0).^2+(yy-Y0).^2)/R0^2));
            
            Nx=Nx+NxSph;
            Ny=Ny+NySph;
            
            Nz = 1./sqrt(1 + Nx.*Nx + Ny.*Ny);
            Nx = -Nx.*Nz;
            Ny = -Ny.*Nz;
            xxc = xx - Nx*rad;
            yyc = yy - Ny*rad;
            zzc = zz - Nz*rad;
            
            
            %Resample surface in the original grid.
            zzOut = griddata(xxc, yyc, zzc, xx, yy,'v4');
        end

        
        function zzAdj=AdjustBaseHeight(zz)
            % AdjustBaseHeight zeroes zz at its center point, then flips
            % its sign if the mean is negative (so the surface is convex)
            n0 = (size(zz,1)+1)/2;
            zz = zz - zz(n0,n0);
            if mean(zz(:)) < 0;
                zz = -zz;
            end
            zzAdj=zz;
        end
        
        function C=ZernikeCoefficients(X,Y,Z,ZOrder)
            % ZernikeCoefficients fits a Zernike expansion (up to ZOrder,
            % OSA/ANSI indexing) to the cloud of points (X,Y,Z) via
            % pseudoinverse least squares, returning a coefficient
            % struct C (with C.A the equivalent XY-monomial matrix for
            % fast evaluation via Zernike/Polyval2)
            r = sqrt(max(X.*X + Y.*Y));
            K = length(X);
            % Normalization to the unit circle
            X = X/r; Y = Y/r; Z = Z/r;
            % Computing double indexes and max size of conversion matrices
            j = (0:ZOrder)';
            n = ceil((-3 + sqrt(9+8*j))/2);
            m = 2*j - n.*(n + 2);
            D = max(n) + 1;
            C.Indices = [j, n, m];
            % Computing the Zernike polynomials at the grid points
            % This function doesn't use normalization of the Zernike polynomials
            Zpoly = zeros(K, ZOrder+1);
            
            %Scaling to compensate the normalization to the unit circle
            [n, m] = ndgrid(1:D);
            ScalingMatrix = (1/r).^(n + m - 3);
            
            % Storage for all individual Zernike matrices in a single 3D
            % array.
            Zmatrix = zeros(D, D, ZOrder+1);      
            for s = 1:(ZOrder+1)
                % Individual Zernike matrix
                aux = ProcessMeasure.ZernikeMatrix(s-1);
                % Evaluation of the individual Zernike polynomial
                Zpoly(:,s) = ProcessMeasure.Polyval2(X,Y,aux,'tr');
                
                add = D - length(aux);
                % Storage of individual Zernike matrices.Padded so all 
                % matrices have the same dimension.
                Zmatrix(:,:,s) = ProcessMeasure.PadArray(aux,[add,add],0,'post').*ScalingMatrix;
            end
            
            % Coefficients by means of the Moore-Penrose pseudoinverse
            S = pinv(Zpoly)*Z;
            
            % Matrix of monomial coefficients. Represents the obtained
            % Zernike polynomial as an XY polynomial so it is faster to
            % compute. A stores the coefficients of the resulting polynomial.
            A = zeros(D);
            for n = 1:(ZOrder+1);
                A = A + S(n)*Zmatrix(:,:,n);
            end
            
            % Coefficient structure
            C.S = S;
            C.A = A;
            C.M = Zmatrix;
            C.Order = ZOrder;
            C.ScaleFactor = r;
            C.Type = 'Zernike';
            C.Squeme = 'osa';
        end
        
        function [C]=ZernikeCoefficientsReg(X,Y,Z,ZOrder, lambda)
            % ZernikeCoefficientsReg is ZernikeCoefficients with L2
            % (Tikhonov) regularization strength lambda, fitted via
            % RegresionByNormalEqn instead of a plain pseudoinverse
            r = sqrt(max(X.*X + Y.*Y));
            K = length(X);
            % Normalization to the unit circle
            X = X/r; Y = Y/r; Z = Z/r;
            %dinRange=max(Z)-min(Z);
            %Z=Z/dinRange;
            % Computing double indexes and max size of conversion matrices
            j = (0:ZOrder)';
            n = ceil((-3 + sqrt(9+8*j))/2);
            m = 2*j - n.*(n + 2);
            D = max(n) + 1;
            C.Indices = [j, n, m];
            
            % Computing the Zernike polynomials at the grid points
            % This function doesn't use normalization of the Zernike polynomials
            Zpoly = zeros(K, ZOrder+1);
            
            %Scaling to compensate the normalization to the unit circle
            [n, m] = ndgrid(1:D);
            ScalingMatrix = (1/r).^(n + m - 3);
            
            % Storage for all individual Zernike matrices in a single 3D
            % array.
            Zmatrix = zeros(D, D, ZOrder+1);
            
            for s = 1:(ZOrder+1)
                % Individual Zernike matrix
                aux = ProcessMeasure.ZernikeMatrix(s-1);
                % Evaluation of the individual Zernike polynomial
                Zpoly(:,s) = ProcessMeasure.Polyval2(X,Y,aux,'tr');
                add = D - length(aux);
                % Storage of individual Zernike matrices.Padded so all 
                % matrices have the same dimension.
                Zmatrix(:,:,s) = ProcessMeasure.PadArray(aux,[add,add],0,'post').*ScalingMatrix;
            end
                        
            S=ProcessMeasure.RegresionByNormalEqn(Zpoly,Z,lambda);
            %S=S*dinRange;
%            [S, stats]=lasso(Zpoly(:,2:end), Z,'lambda',lambda);
%            S=cat(1,stats.Intercept,S);
            
            % Matrix of monomial coefficients. Represents the obtained
            % Zernike polynomial as an XY polynomial so it is faster to
            % compute. A stores the coefficients of the resulting polynomial.
            A = zeros(D);
            for n = 1:(ZOrder+1);
                A = A + S(n)*Zmatrix(:,:,n);
            end
            
            % Coefficient structure
            C.S = S;
            C.A = A;
            C.M = Zmatrix;
            C.Order = ZOrder;
            C.ScaleFactor = r;
            C.Type = 'Zernike';
            C.Squeme = 'osa';
        end
        
        function [C]=ZernikeCoefficientsRegCurv(X,Y,Z,ZOrder, lambda, mu)
            % ZernikeCoefficientsRegCurv is ZernikeCoefficientsReg (L2
            % strength lambda) plus an additional curvature-smoothness
            % penalty (strength mu) evaluated at points near the unit
            % circle boundary, to control edge curl
            r = sqrt(max(X.*X + Y.*Y));
            K = length(X);
            % Normalization to the unit circle
            X = X/r; Y = Y/r; Z = Z/r;
            % Computing double indexes and max size of conversion matrices
            j = (0:ZOrder)';
            n = ceil((-3 + sqrt(9+8*j))/2);
            m = 2*j - n.*(n + 2);
            D = max(n) + 1;
            C.Indices = [j, n, m];
            
            % Computing the Zernike polynomials at the grid points
            % This function doesn't use normalization of the Zernike polynomials
            Zpoly = zeros(K, ZOrder+1);
            
            
            %Points where we evaluate curvatures
            %freq=sqrt(length(X));
            marks=linspace(-0.9,0.9);
            [XC, YC]=meshgrid(marks, marks);
            inPoints=XC.^2+YC.^2>0.9^2;
            XC=XC(inPoints);
            YC=YC(inPoints);
            
            CurvXPoly=zeros(2*length(XC), ZOrder+1);
            CurvYPoly=zeros(2*length(YC), ZOrder+1);
            
            
            %Scaling to compensate the normalization to the unit circle
            [n, m] = ndgrid(1:D);
            ScalingMatrix = (1/r).^(n + m - 3);
            
            % Storage for all individual Zernike matrices in a single 3D
            % array.
            Zmatrix = zeros(D, D, ZOrder+1);
            
            for s = 1:(ZOrder+1)
                % Individual Zernike matrix
                aux = Zernikes.PolyEquivalent(s-1);                
              
                normFactor=max(abs(ProcessMeasure.Polyval2(XC,YC,aux,'tr')));
                aux=aux/normFactor;
                % Evaluation of the individual Zernike polynomial
                Zpoly(:,s) = ProcessMeasure.Polyval2(X,Y,aux,'tr');
                %lapAux = ProcessMeasure.PolyLaplacian(aux);
                [lapX, lapY]=ProcessMeasure.PolyLaplacian(aux);
                CurvXPoly(:,s)=[ProcessMeasure.Polyval2(XC,YC,ProcessMeasure.Polyder2(lapX,1),'tr');ProcessMeasure.Polyval2(XC,YC,ProcessMeasure.Polyder2(lapX,2),'tr')];
                CurvYPoly(:,s)=[ProcessMeasure.Polyval2(XC,YC,ProcessMeasure.Polyder2(lapY,1),'tr');ProcessMeasure.Polyval2(XC,YC,ProcessMeasure.Polyder2(lapY,2),'tr')];
                add = D - length(aux);
                % Storage of individual Zernike matrices.Padded so all 
                % matrices have the same dimension.
                Zmatrix(:,:,s) = ProcessMeasure.PadArray(aux,[add,add],0,'post').*ScalingMatrix;
            end
            
            featMatrix=[Zpoly; mu.*CurvXPoly; mu.*CurvYPoly];
            trainData=[Z; zeros(4*length(XC),1)];
                        
            S=ProcessMeasure.RegresionByNormalEqn(featMatrix,trainData,lambda);
            
            % Matrix of monomial coefficients. Represents the obtained
            % Zernike polynomial as an XY polynomial so it is faster to
            % compute. A stores the coefficients of the resulting polynomial.
            A = zeros(D);
            for n = 1:(ZOrder+1);
                A = A + S(n)*Zmatrix(:,:,n);
            end
            
            % Coefficient structure
            C.S = S;
            C.A = A;
            C.M = Zmatrix;
            C.Order = ZOrder;
            C.ScaleFactor = r;
            C.Type = 'Zernike';
            C.Squeme = 'osa';
        end
        
        function [ou]=PolyPowers(x ,y, SCoeff, n)
            % PolyPowers computes power maps (Pxx/Pyy/Pxy, C, S, Seq,
            % scaled by refractive index n) at (x, y) from the surface's
            % polynomial coefficients SCoeff, via its principal curvatures

            Sx=ProcessMeasure.Polyder2(SCoeff,1);
            Sy=ProcessMeasure.Polyder2(SCoeff,2);
            Sxx=ProcessMeasure.Polyder2(Sx,1);
            Syy=ProcessMeasure.Polyder2(Sy,2);
            Sxy=ProcessMeasure.Polyder2(Sx,2);
            
            zx=ProcessMeasure.Polyval2(x,y,Sx);
            zy=ProcessMeasure.Polyval2(x,y,Sy);
            zxx=ProcessMeasure.Polyval2(x,y,Sxx);
            zyy=ProcessMeasure.Polyval2(x,y,Syy);
            zxy=ProcessMeasure.Polyval2(x,y,Sxy);

            % Curvatures 
            div = (1 + (zx.* zx) + (zy.* zy)).^2;
            div2 = (1 + (zx.* zx) + (zy.* zy)).^3;
            div2 = 2 * sqrt(div2);
            K = ((zxx.* zyy) - (zxy.* zxy))./ div;
            H = (((1 + zx.* zx).* zyy) - (2 * zx.*zy.* zxy) + ((1 + zy.* zy).* zxx))./ (div2);
            diff = H.* H - K;
            diff(diff<0) = 0;
            diff = sqrt(diff);
            
            k1 = H + diff;
            k2 = H - diff;
            
            E = 1 + zx.* zx;
            F = zx.* zy;
            G = 1 + zy.* zy;
            N = sqrt(1 + zx.* zx + zy.* zy);
            e = zxx./ N;
            f = zxy./ N;
            g = zyy./ N;
            %a11 = (f.* F - e.* G)./ (E.* G - F.* F);
            %a12 = (g.* F - f.* G)./ (E.* G - F.* F);
            a22 = (f.* F - g.* E)./ (E.* G - F.* F);
            a21 = (e.* F - f.* E)./ (E.* G - F.* F);
            ax = -a21./ (a22 + k1);
            ax = ax./ sqrt(1 + ax.* ax);
            alpha = asin(ax);
            alpha(isnan(alpha)) = pi/2;
            cosAlpha = cos(alpha);
            sinAlpha = sin(alpha);
            
            pxx= k1 + (k2 - k1).* (sinAlpha.* sinAlpha);
            pyy= k1 + (k2 - k1).* (cosAlpha.* cosAlpha);
            pxy= -(k2 - k1).* sinAlpha.* cosAlpha;
            
            pxx =   - (n-1)*1000*pxx;
            pyy =   - (n-1)*1000*pyy;
            pxy =  -(n-1)*1000*pxy;
            
            %Pxp = pxx - interp2(x, y, pxx, xn, yn);
            %Pyp = pyy - interp2(x, y, pyy, xn, yn);
            %Ptp = pxy - interp2(x, y, pxy, xn, yn);
            %t = Pxp+Pyp;
            %d = Pxp.*Pyp - Ptp.*Ptp;
            %cnp = sqrt(t.*t-4*d);

            ou.Pxx = pxx;
            ou.Pyy = pyy;
            ou.Pxy = pxy;

            ou.C = (abs((pxx-pyy).^2+4*pxy.^2)).^0.5;
            ou.Seq = (pxx + pyy)/2;
            ou.S = ou.Seq - ou.C / 2;

        end
        
        function Z=Zernike(X, Y, Cest)
            % Zernike evaluates surface sags Z at (X, Y) - meshgrid
            % matrices or vectors (column vectors are faster) - from a
            % Zernike coefficient struct Cest (needs at least Cest.A,
            % the equivalent XY-monomial coefficient matrix, per 2D
            % Horner's rule for speed)
            C = Cest.A;
            N = length(C);
            B = X;

            % 2D Horner's rule for triangular matrices
            B(:) = C(N,1);
            Z = B;
            for n = N-1:-1:1
                B(:) = C(n,N-n+1);
                for m = (N-n):-1:1
                    B = B.*Y + C(n,m);
                end
                Z = Z.*X + B;
            end           
        end
        
        
        function WriteHMF(z, filePath, fileName)
            % WriteHMF writes surface sags z (a square matrix, spacing
            % ProcessMeasure.spatialPeriod) to filePath/fileName.hmf
            % (fileName without extension)

            lData=length(z);
            %Open file to write
            fileName=strcat(filePath,fileName);
            fid = fopen([fileName '.hmf'],'w');
            %Print hmf header
            fprintf(fid,'Aspherical base file\nFile Version=1.2\nGeneral height-map properties\n[Properties]\nCount=%d\nInterval=%f\nThe height-map dat begins here\n[Data]\n',...
                lData,ProcessMeasure.spatialPeriod);
            %Write height data
            for i=1:lData
                for j=1:lData
                    %Write value
                    fprintf(fid,'%f',z(i,j));
                    %If we are not at the end of line, write a coma
                    if j~=lData
                        fprintf(fid,'%s',', ');
                    end
                end
               fprintf(fid,'\n');
            end
            %Close file
            fclose(fid);
        end
        
    end
    
    methods(Access='public', Static=true)
        
        function M = ZernikeMatrix(j)
            % ZernikeMatrix returns the monomial coefficient matrix for
            % single-index (OSA/ANSI) Zernike term j, via ZMosa
            n = ceil((-3 + sqrt(9+8*j))/2);
            m = 2*j - n.*(n + 2);
            M = ProcessMeasure.ZMosa(n,m);                
        end
        
        function zz =Rescepol(xx,yy,C,rho,contourFunc)
            % Rescepol evaluates Zernike surface C at (xx, yy), extrapolating
            % points beyond contourFunc's radius via parabolic fits
            % (ParabolaCoefficients) using rho as sample offsets
            rlim = contourFunc;

            sx = size(xx);
            xx = xx(:);
            yy = yy(:);
            zz = ProcessMeasure.Zernike(xx,yy,C);
            [qq, rr] = cart2pol(xx,yy);

            rc = rlim(qq);
            out = (rr >= rc);
            zout = zz(out);
            rout = rr(out);
            rcout = rc(out);
            sout = sin(qq(out));
            cout = cos(qq(out));
            if size(rho, 1) == 1
                rho = rho';
            end
            for n = 1:length(zout);
                rp = rcout(n) - rho;
                zp = ProcessMeasure.Zernike(rp*cout(n),rp*sout(n),C);
                [a,b,c] = ProcessMeasure.ParabolaCoefficients(rp, zp);
                zout(n) = a + b*rout(n) + c*rout(n)^2;
            end
            zz(out) = zout;
            zz = reshape(zz,sx);
        end
        
        function R = GetRegionLimitFunction(regionParams, delta)
            % GetRegionLimitFunction returns a function R(theta) giving
            % the radius of an ellipse (regionParams.a/b/offset/angle,
            % shrunk by delta) at polar angle theta
            x0=regionParams.offset(1);
            y0=regionParams.offset(2);
            a = regionParams.a - delta;
            b = regionParams.b - delta;
            angle=regionParams.angle;
            
            R = @(t) sqrt((a*cos(t-angle) + x0).^2 + (b*sin(t-angle) + y0).^2);
        end
        
        function [a, b, c]=ParabolaCoefficients(x,y)
            % ParabolaCoefficients returns [a,b,c] for the parabola
            % y=a+b*x+c*x^2 passing exactly through the 3 points (x,y)
            det = (x(1)-x(2))*(x(1)-x(3))*(x(2)-x(3));
            a = ( x(1)*x(3)*y(2)*(x(3)-x(1)) + x(2)^2*(x(3)*y(1)-x(1)*y(3))+x(2)*(x(1)^2*y(3)-x(3)^2*y(1)) )/det;
            b = ( x(3)^2*(y(1)-y(2)) + x(1)^2*(y(2)-y(3)) + x(2)^2*(y(3)-y(1)) )/det;
            c = ( x(3)*(y(2)-y(1)) + x(2)*(y(1)-y(3)) + x(1)*(y(3)-y(2)) )/det;
        end
        
        function M = ZMosa(n,m)
            % ZMosa returns the monomial coefficient matrix for the
            % (n,m)-indexed (radial/azimuthal, OSA convention) Zernike
            % polynomial
            N = n + 1;
            M = zeros(N, N);
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
                                M(row+1,col+1) = c;
                            end
                        end
                    end
                case -1
                    m = abs(m);
                    L1 = (n-m)/2;
                    for s = 0:L1
                        for j = 0:(L1-s)
                            for k = 0:((m-1)/2)
                                c = (-1)^(s+k)*factorial(n-s);
                                c = c/(factorial(s)*factorial((n+abs(m))/2-s)*factorial(L1-s));
                                c = c*nchoosek((n-abs(m))/2-s,j)*nchoosek(abs(m),2*k+1);
                                row = n - 2*(s+j+k)-1;
                                col = 2*(j+k) + 1;
                                M(row+1,col+1) = c;
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
                        M(row+1,col+1) = c;
                        end
                    end
            end
        end
        
        function C = ApspCoefficients(X, Y, Z, type, par)
            % ApspCoefficients builds an approximant spline for gridded data
            %
            % DESCRIPTION
            % X,Y,Z are gridded data, in matrix format, as given by meshgrid. Because
            % the MATLAB spline toolbox assumes gridded data generated with ndgrid, the
            % Z matrix is transposed. All the available approximation methods only
            % use the vector X and Y sites, x = X(1,:), y = Y(:,1);
            % The fourth argument "type" is a string that can be:
            % "leastsquares" -> approximant B-spline by least squares (default)
            % "reinsch" -> approximant B-spline using the Reinsch's algorithm.
            % "pval" -> approximant spline using the fitting p-parameter.
            % The last argument depends on the type of approximant.
            % For "leastsquares", it is the number of patches. If pal = N, then the
            % number of patches, N, is equal along x and y. Otherwise, pal = [Nx, Ny].
            % If Ng = length(X), the number of patches must be smaller than Ng - n + 2,
            % n being the order of the splines.
            % For "reinsch", par is the tolerance level, any number between 0.01 and 10
            % microns. Default value is 1 micron.
            % For "pval", par is the value of the p-parameter, which can lie in the
            % interval (0,1] (p = 0 stands for a least squares plane spline, and p = 1
            % gives a perfectly interpolating spline). Default value is 1/(1 + h^3/6),
            % where h is the distance between breaks.
            %
            % Notes
            % 1) The best fitting method is the 'leastsquares', with no edge problems.
            % With break spacing of 4 mm, it provides excelent fit to progressive data.
            % The two other methods have strong oscillation at the edge, that can be
            % improved with weight vectors.
            % 2) All the splines are converted to the pp-form for improved evaluating
            % speed
            % Copyright 2009-2010. IOT S.L.
            % Author: Jos� Alonso
            
            % Data must be gridded
            x = X(1,:);
            y = Y(:,1);
            Npx = length(x);
            Npy = length(y);
            % Transpose Z for ndgrid ordering
            Z = Z';
            
            if nargin == 3
                type = 'leastsquares';
                par = 20;
            elseif nargin == 4
                if ~ischar(type)
                    error('Argument type must be a string')
                end
                if strcmpi(type,'leastsquares')
                    par = 20;
                elseif strcmpi(type,'reinsch')
                    par = 0.001;
                elseif strcmpi(type,'pval')
                    par = 1/(1 + (x(2)-x(1))^3/6);
                else
                    error('Unknown type of approximant spline')
                end
            end
            
            switch lower(type)
                
                case 'pval'
                    if iscell(par)
                        p = par{1};
                        wx = par{2};
                        wy = par{3};
                    else
                        p = par;
                        % Weights vectors. There are two squemes for weights. The first
                        % squeme improves in the inner surface but gives worse results
                        % at the rim
                        %peso = 4;
                        %wx = (abs(x/max(x)) + 1).^peso;
                        %wy = (abs(y/max(y)) + 1).^peso;
                        wx = ones(size(x));
                        %wx([1 end]) = 25; wx([2,end-1]) = 20; wx([3,end-2]) = 5;
                        wy = ones(size(y));
                        %wy([1 end]) = 25; wy([2,end-1]) = 20; wy([3,end-2]) = 5;
                    end
                    if p > 1 || p <= 0
                        error('The value for p must lie in the interval (0, 1]')
                    end
                    % Spline
                    C = csaps({x,y}, Z, p, [], {wx, wy});
                    
                case 'reinsch'
                    if par <= 0.0001 || par >= 0.01
                        error('The tolerance value should lie in (0.0001,0.01)')
                    end
                    tol = par;
                    % Weights vectors. There are two squemes for weights. The first
                    % squeme improves in the inner surface but gives worse results at
                    % the rim
                    peso = 4;
                    wx = (abs(x/max(x)) + 1).^peso;
                    wy = (abs(y/max(y)) + 1).^peso;
                    %wx = ones(size(x));
                    %wx([1 end]) = 25; wx([2,end-1]) = 20; wx([3,end-2]) = 5;
                    %wy = ones(size(y));
                    %wy([1 end]) = 25; wy([2,end-1]) = 20; wy([3,end-2]) = 5;
                    % Spline
                    C = spaps({x,y}, Z, tol, {wx, wy});
                    C = fn2fm(C,'pp');
                    
                case 'leastsquares'
                    n = 4; % Order of the polynomials
                    if length(par) == 2
                        Nx = par(1);
                        Ny = par(2);
                    elseif isscalar(par)
                        Nx = par;
                        Ny = Nx;
                    else
                        error('parameter for "leastsquares" must be scalar or 1x2 vector')
                    end
                    if Nx > (Npx-n+2) || Ny > (Npy-n+2)
                        error('Number of patches does not meet the Schoenberg-Whitney condition. Reduce Nx and/or Ny')
                    end
                    kx = augknt(linspace(min(x),max(x),Nx),n);
                    ky = augknt(linspace(min(y),max(y),Ny),n);
                    C = spap2({kx,ky},[n,n],{x,y},Z);
                    C = fn2fm(C,'pp');                   
            end
        end
        
        function Z = Apsp(X, Y, C)
            % Apsp evaluates a piecewise 2D spline surface
            %
            % DESCRIPTION
            % X and Y can be any size (but equal). Z is the same size than X and Y.
            % C = Structure defining MATLAB spline
            % Copyright 2009-2010. IOT S.L.
            % Author: Jos� Alonso
            
            S = size(X);
            if S(1) == 1
                Z = fnval(C, [X; Y]);
            elseif S(2) == 1
                Z = fnval(C, [X'; Y'])';
            else
                Z = reshape(fnval(C, [Y(:)'; X(:)']), S)';
            end
        end
        
        function z = Polyval2(x, y, C, type)
            % Polyval2 efficiently evaluates bivariate polynomials
            %
            % SINTAX
            % z = Polyval2(x, y, C)
            % z = Polyval2(x, y, C, type)
            %
            % DESCRIPTION
            % x,y are the points at which the polynomials has to be evaluated. They can
            % be vector or gridded data.
            % C is the coefficient matrix. It can be squared or rectangular. C(1,1) is
            % the independent term of the polynomial. Powers of y grows along colunms,
            % whereas powers o x run along rows.
            % type is a string defining the type of the coefficient matrix:
            %   type = 'sq'; bivariate polynomial with total degree (N-1)+(M-1). C is a
            %          NxM matrix. This the default value
            %   type = 'tr'; bivariate polynomial with total degree N-1. C is an
            %          up-left triangular NxN matrix.
            %
            % EXAMPLE
            %
            % ALGORITHM
            % Polyval2 uses Horner's rule applied to each y-polynomial. The resulting
            % values, which are the coefficients of the x-polynomial, are used in final
            % application of Horne's rule to compute the whole polynomial.
            %
            % COPYRIGHT 2009-2010. IOT S.L.
            % AUTHOR: Jos� Alonso
            %__________________________________________________________________________

            if nargin == 3
                type = 'sq';
            elseif nargin < 3
                error('Polyval2: too few arguments')
            end
            type = lower(type);

            [N,M] = size(C);
            B = x;

            switch type

                case 'sq'
                    B(:) = C(N,M);
                    for m = M-1:-1:1
                        B = B.*y + C(N,m);
                    end
                    z = B;
                    for n = N-1:-1:1
                        B(:) = C(n,M);
                        for m = M-1:-1:1
                            B = B.*y + C(n,m);
                        end
                        z = z.*x + B;
                    end

                case 'tr'
                    B(:) = C(N,1);
                    z = B;
                    for n = N-1:-1:1
                        B(:) = C(n,N-n+1);
                        for m = (N-n):-1:1
                            B = B.*y + C(n,m);
                        end
                        z = z.*x + B;
                    end

                otherwise
                    error('Polyval2: unknown type of coefficient matrix')
            end
        end
        
        function [ Cder ] = Polyder2(C, dim)
        % Polyder2 returns the coefficient matrix of bivariate
        % polynomial C differentiated along dimension dim (1=x, 2=y)

            switch(dim)
                case 1
                    Cder=DeriveCoeff(C);

                case 2
                    C=C';
                    Cder=DeriveCoeff(C);
                    Cder=Cder';

            end

            if(isempty(Cder))
                Cder=0;
            end

            function Cder=DeriveCoeff(C)
                maxOrder=size(C)-[1 0];
                if(maxOrder(2)==0)
                    Cder=0;
                else
                    Cder=zeros(maxOrder);
                    for i=1:maxOrder(1)
                       Cder(i,:)=i*C(i+1,:);
                    end
                    %Trim extra row of zeros or ad it if nedded to make the matrix
                    %square
                    if(all(Cder(:,maxOrder(2))==0))
                        Cder(:,end)=[];
                    else
                        Cder(end+1,:)=0;
                    end
                end        
            end

        end
        
        function [ Lx, Ly ] = PolyLaplacian( Pcoeffs )
        % PolyLaplacian returns the second partial derivatives Lx=d2P/dx2
        % and Ly=d2P/dy2 of bivariate polynomial Pcoeffs, as separate
        % coefficient matrices - despite the name, it does NOT sum them
        % into a single Laplacian Lx+Ly (its only caller,
        % ZernikeCoefficientsRegCurv, keeps them separate too)

            Px=ProcessMeasure.Polyder2(Pcoeffs,1);
            Py=ProcessMeasure.Polyder2(Pcoeffs,2);

            Pxx=ProcessMeasure.Polyder2(Px,1);
            Pyy=ProcessMeasure.Polyder2(Py,2);

            Lx=Pxx;
            Ly=Pyy;
        end
        
        function [theta] = RegresionByNormalEqn(X, Y, lambda)
            % RegresionByNormalEqn fits theta via the ridge-regularized
            % normal equation (L2 penalty lambda, not applied to the
            % intercept term) for features X and targets Y

            if(nargin<3)
                lambda=0;
            end

              lMatrix=lambda*eye(size(X,2));
              lMatrix(1)=0;
%             lMatrix=diag(lambda*[0:size(X,2)-1]);

   
             theta=pinv(X'*X+lMatrix)*X'*Y;

            % Algorithms pulled from
            % "http://www.di.ens.fr/~mschmidt/Software/lasso.html"
            %BlockCoordinate
            %IteratedRidge
            %Shooting
            %theta = LassoIteratedRidge(X,Y,lambda,'verbose',0);

        end
        
        function out=PadArray(inArr, padSize, padValue, direction) %#ok<INUSD>
            % PadArray pads inArr with padValue, adding padSize(2)
            % columns and padSize(1) rows (direction argument is unused)
            inSize=size(inArr);
            inter=[inArr ones(inSize(1),padSize(2))*padValue];
            interSize=size(inter);
            out=[inter; ones(padSize(1),interSize(2))*padValue];
        end
        
    end

end