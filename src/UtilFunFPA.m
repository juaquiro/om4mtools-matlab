classdef UtilFunFPA
    % UtilFunFPA static utility functions for the Fringe Pattern
    % Analysis library (see testFPA_UtilFunFPAClassVer.m,
    % testFPA_UtilFunFPA.m for unit tests)

    %% public methods
    methods(Static)

        function Q=GradientConsistency(dx, dy)
            % GradientConsistency computes the loop-integral inconsistency
            % Q of first-difference pair (dx, dy) around each 2x2 square
            % (Q~=0 flags an inconsistency between the two differences);
            % dx/dy can be continuous or 2*pi-wrapped (as in
            % deflectometry/shearography) - Q is wrapped accordingly.
            %
            % Ref: https://www.wiley.com/en-es/Two+Dimensional+Phase+Unwrapping%3A+Theory%2C+Algorithms%2C+and+Software-p-9780471249351
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            dxName=inputname(1);
            if (not(ismatrix(dx)) || not(isreal(dx)))
                retMsg=[dxName 'must be a real matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            dyName=inputname(2);
            if (not(ismatrix(dy)) || not(isreal(dy)))
                retMsg=[dyName 'must be a real matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            if any(size(dx)~=size(dy))
                retMsg=[dyName 'different size'];
                error([callFunc, '->' retMsg]);
            end
            
            [NR, NC]=size(dx);
            
            %col indexes
            A=[2:NC NC];
            
            %row indexes
            B=[2:NR NR];
            
            Q=dx+dy(:, A)-dx(B, :)-dy;
            
            %if dx and dy are 2pi wrapped we need to correct for the 2pi
            %jumps. If they are contunous this makes no harm
            Q=angle(exp(1i*Q));
        end
        
        function [gZ]=interpInvalidPoints(g, M, varargin)
            % interpInvalidPoints fills in matrix g outside mask M by
            % fitting a Zernike surface (ClassifierZernikes) to the
            % valid (M==1) points and evaluating it everywhere.
            %
            % Optional args (varargin): zOrder (40) Zernike order,
            % lambda (1e-5) regularization, mu (1e-3) curvature
            % regularization weight
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            gName=inputname(1);
            %check 2D matrix
            if not(ismatrix(g)) ||  not(ismatrix(M))
                retMsg=[gName ' must be a matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 3
                retMsg=[callFunc ' requires at most 3 optional inputs: zOrder, lambda, mu'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            %some small def values just in case of low number of points
            lambda=1e-5;
            mu=1e-3;
            zOrder=40;
            optargs = {zOrder, lambda, mu};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [zOrder, lambda, mu] = optargs{:};
            
            %             %create scattered interpolator
            %             [NR, NC]=size(g);
            %             [x,y]=meshgrid(1:NC, 1:NR);
            %
            %             xv=x(M==1);
            %             yv=y(M==1);
            %             gv=g(M==1);
            %
            %             F = scatteredInterpolant(xv,yv,gv, 'natural', 'none');
            %             gZ=F(x,y);
            
            %create Zernike interpolator
            cl=ClassifierFactory.Create(ClassifierTypes.Zernikes);
            cl.Set(char(ClassifierProps.lambda),lambda);
            cl.Set(char(ClassifierProps.mu),mu);
            cl.Set(char(ClassifierProps.zOrder),zOrder);
            
            [NR, NC]=size(g);
            [u,v]=meshgrid(1:NC, 1:NR); u=u-0.5*NC; v=v-0.5*NR;
            M=logical(M);
            X=[u(M), v(M)];
            y=g(M);
            
            cl.Train(X,y);
            %CMatrix son los coeficientoes del polinomio cartesiano que ajusta la
            %superficie
            C=cl.GetSurfCoeff();
            gZ=ProcessMeasure.Polyval2(u,v,C);
            
        end
        
        
        
        function [phix, phiy, Mxy]=phaseGradientDirect(z, M, NS, Nmed, LPCycles)
            % phaseGradientDirect computes the phase gradient [phix,
            % phiy] of phasor z=b*exp(1i*phi) within ROI M (MATLAB
            % gradient() sign convention), via median filtering (Nmed,
            % outlier removal) then low-pass filtering (LPCycles cycles)
            % of the cosine/sine-filtered phasor differences, using a
            % 2*NS+1 phasor-filtering neighborhood. Returns the phase
            % gradients and Mxy, the ROI restricted to valid differences.
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();            
            
            if nargin < 5
                LPCycles = 3; % Set default value
            end
            
            zName=inputname(1);
            if (not(ismatrix(z)) || isreal(z))
                retMsg=[zName 'must be a complex matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            [NR, NC]=size(z);
            
            %dx indexes
            A=[2:NC NC];
            B=[1 1:NC-1];
            
            %dy indexes
            C=[2:NR NR];
            D=[1 1:NR-1];
            
            %by definition set borders to zero for 1st diferences
            M(:, 1:3)=0;
            M(1:3, :)=0;
            M(NR-2:NR, :)=0;
            M(:, NC-2:NC)=0;            

            
            %dx
            %calculate 1st difference
            zd=z(:, A)./z(:, B);
            zd(isnan(zd))=0;
            phix=0.5.*angle(zd);
                                               
            %dy,
            %calculate 1st difference
            zd=z(C, :)./z(D, :);
            zd(isnan(zd))=0;
            phiy=0.5.*angle(zd);
            
            %filter derivatives, if the phasor is well sampled they shuold
            %be continuous and the filtering does not depend strongly on the fringe
            %period of the phasor
            %medfilt for outliers
            if (Nmed>0)
                phix=medfilt2(phix, [Nmed, Nmed]);
                phiy=medfilt2(phiy, [Nmed, Nmed]);
            end
            %mask for the diferences
            Mxy=M(:, A).*M(:, B).*M.*M(C, :).*M(D, :);                      
            %low pass filter
            h=ones(2*NS+1)/(2*NS+1)^2;
            for n=1:LPCycles
                phix=conv2(phix, h, 'same');
                phiy=conv2(phiy, h, 'same');
                Mxy=conv2(Mxy, h, 'same');
            end
            
            Mxy=(Mxy>0.999);
            %trim results with ROI
            phix=Mxy.*phix;
            phiy=Mxy.*phiy;            
            
        end
        
        
        % ======================================================================
        %> @brief direct gradient calculation
        %> @details this function calculates the gradient [phix, phiy] using first differences. It uses the same sign convetion that MATLAB gradient().
        %> Returns a the phase gradient and a Mask with valid differences. For this we use a median filter for outlier removal and gradient after filtering
        %>
        %> @param Nmed median filter size 
        %> @param NS 2*NS+1 is the neigbouhoord size for avg filtering
        %> @param M ROI with valid points
        %> @param g input signal
        %> @param LPCycles are the number of low pass cycles that we apply
        %> to the calculated derivatives
        %> @retval Mxy ROI with valid differences
        %> @retval gx phase x-gradient
        %> @retval gy phase y-gradient
        % ======================================================================
        function [gx, gy, Mxy]=gradientDirect(g, M, NS, Nmed, LPCycles)
            % gradientDirect is phaseGradientDirect's real-valued
            % counterpart: computes the gradient [gx, gy] of real matrix
            % g within ROI M, via median filtering (Nmed) then low-pass
            % filtering (LPCycles cycles, 2*NS+1 neighborhood) of the raw
            % differences. Returns the gradients and Mxy, the ROI
            % restricted to valid differences.
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();

            zName=inputname(1);
            if (not(ismatrix(g)) || not(isreal(g)))
                retMsg=[zName 'must be a real matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            g=double(g);
            
            [NR, NC]=size(g);
            
            %dx indexes
            A=[2:NC NC];
            B=[1 1:NC-1];
            
            %dy indexes
            C=[2:NR NR];
            D=[1 1:NR-1];
            
            %by definition set borders to zero for 1st diferences
            M(:, 1:3)=0;
            M(1:3, :)=0;
            M(NR-2:NR, :)=0;
            M(:, NC-2:NC)=0;            

            
            %dx
            %calculate 1st difference
            gx=0.5*(g(:, A)-g(:, B));
                                               
            %dy,
            %calculate 1st difference
            gy=0.5*(g(C, :)-g(D, :));
            
            %filter derivatives, if the phasor is well sampled they shuold
            %be continuous and the filtering does not depend strongly on the fringe
            %period of the phasor
            %medfilt for outliers
            gx=medfilt2(gx, [Nmed, Nmed]);
            gy=medfilt2(gy, [Nmed, Nmed]);
            
            %mask for the diferences
            Mxy=M(:, A).*M(:, B).*M.*M(C, :).*M(D, :);                      
            %low pass filter
            h=ones(2*NS+1)/(2*NS+1)^2;
            for n=1:LPCycles
                gx=conv2(gx, h, 'same');
                gy=conv2(gy, h, 'same');
                Mxy=conv2(Mxy, h, 'same');
            end
            
            Mxy=(Mxy>0.999);
            %trim results with ROI
            gx=Mxy.*gx;
            gy=Mxy.*gy;            
            
        end
        
        
        
        
        function [phix, phiy, Mxy]=phaseGradientPlaneFit(z, M, NS, Nmed)
            % phaseGradientPlaneFit computes phasor z's phase gradient
            % [phix, phiy] within ROI M by unwrapping (PUFlynMdMex) then
            % plane-fitting the gradient (GradientPlaneFit, median filter
            % Nmed, 2*NS+1 neighborhood).
            %
            % NOT RECOMMENDED: has a spatial-frequency dependency - use
            % phaseGradientDirect instead.
            %
            % Ref: Yang, Yu & Fu, "An algorithm for estimating both
            % fringe orientation and fringe density," Optics
            % Communications 274(2), 286-292 (2007)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            
            zName=inputname(1);
            if (not(ismatrix(z)) || isreal(z))
                retMsg=[zName 'must be a complex matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            
            pw=angle(z); %wrapped phase
            qual=mat2gray(abs(z)); %qulaity-map [0-1]                                  
            thresh_flag=0.5; %therhold the quality map
            fatten=1; %fatten by 1px the zero points in quality map            
            M=double(M);
            %mex file PUFlynMdMex 
            pu=PUFlynMdMex(pw, M, qual, thresh_flag, fatten);
                               
            %get gradient fron continous pu
            [phix, phiy, Mxy]=UtilFunFPA.GradientPlaneFit(pu, M, NS, Nmed);
                        
            %trim            
            phix=phix.*Mxy;
            phiy=phiy.*Mxy;            
        end
        
        
        
        
        function [px, py, Mxy]=GradientPlaneFit(p, M, NS, Nmed)
            % GradientPlaneFit computes matrix p's gradient [px, py]
            % within ROI M via local least-squares plane fitting (2*NS+1
            % neighborhood, after median filtering p/M by Nmed) - same
            % sign convention as MATLAB's gradient().
            %
            % Ref: Yang, Yu & Fu, "An algorithm for estimating both
            % fringe orientation and fringe density," Optics
            % Communications 274(2), 286-292 (2007)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            
            
            pName=inputname(1);
            if (not(ismatrix(p)) || not(isreal(p)))
                retMsg=[pName 'must be a complex matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            %med filter for outlier removal
            p=medfilt2(p, [Nmed Nmed]);
            M=medfilt2(M, [Nmed Nmed]);
            
            %convoution kernels for plane fitting
            [hx,hy]=meshgrid(-NS:NS, -NS:NS);
            
            
            %LS plane fitting
            SXp=conv2(p, -hx, 'same'); %sum(p*x)
            SYp=conv2(p, -hy, 'same'); %sum(p*y)
            SX2=conv2(ones(size(p)), hx.*hx, 'same'); %sum(x^2)
            SY2=conv2(ones(size(p)), hy.*hy, 'same'); %sum(y^2)
            
            %M filtered plane with the same kernel size than the plane
            %fitting
            h=ones(2*NS+3)/(2*NS+3)^2;
            Mxy=conv2(double(M), h, 'same');
            Mxy=(floor(Mxy)==1);
            
            %dx
            px=double(Mxy).*SXp./SX2;
            
            %dy
            py=double(Mxy).*SYp./SY2;
        end
        
        
        function w = LocateSidelobes(g, varargin)
            % LocateSidelobes locates the side lobes of igram g's Fourier
            % transform (2 carriers -> 4 lobes, 1 carrier -> 2 lobes),
            % after filtering out the DC with a fixed low-pass filter.
            %
            % By default the 4 side lobes are numbered clockwise:
            %      2
            %    1 X 3
            %      4
            % or, for a linear fringe pattern (1 carrier), "1 X 2" or
            % "1 / X / 2". If wr (varargin{1}) is given, the lobe closest
            % to wr{1} is numbered 1 instead, with the rest numbered
            % clockwise from there.
            %
            % Optional args: wr reference lobe positions (see above); R
            % radius (in fringes/field) of the DC low-pass filter; NL
            % number of lobes (2 or 4).
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check image_toolbox
            if not(license('test', 'image_toolbox'))
                retMsg=['image processing toolbox must be installed'];
                error([callFunc, '->' retMsg]);
            end
            
            gName=inputname(1);
            %check 2D matrix
            if not(ismatrix(g))
                retMsg=[gName ' must be a matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 3
                retMsg=[callFunc ' requires at most 2 optional inputs: wr, R, NL'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % R %bandpass filter width in FF
            % wr ref pattern freqs in FF
            % NL number of lobes, default is 4
            wr=[];
            R=10;
            NL=4;
            optargs = {wr, R, NL};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [wr, R, NL] = optargs{:};
            
            % validate NL
            % list of valid values for NL
            vList={2, 4};
            r=Validation.CheckInputParam(NL, vList);
            
            
            %convert to double all cases
            g=double(g);
            %get size
            [NR, NC]=size(g);
            
            %prepare frec coordinates
            [u, v]=meshgrid(1:NC, 1:NR);
            u0=floor(NC/2)+1;
            v0=floor(NR/2)+1;
            u=u-u0; v=v-v0;
            HB=1-exp(-0.5*abs(u+1i*v).^2/R^2); %lowpass filter
            
            %HB is already fftshifted from design, if fftshift is used instead, for even
            %dimensions there is no problem, however for odd dimensions fftshift(H)
            %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
            %see help for ifftshift
            G=fft2(g);
            GH=G.*ifftshift(HB);
            
            %get the segmented lobes
            GA=abs(GH);
            GA=conv2(GA, ones(5), 'same');
            GA=mat2gray(fftshift(GA));
            BW=GA>0.5;
            
            w=cell(1,NL);
            %calulate centroids and area of each blob
            s=regionprops(BW, {'centroid', 'Area'});
            A=[s.Area];
            if length(A)<NL
                retMsg=['The number of lobes detected is less than ' num2str(NL)];
                error([callFunc, '->' retMsg]);
            end
            [~, k]=sort(A, 'descend');
            %get the NL bigger blobs
            k=k(1:NL);
            
            %get the centroid of the NL bigger blobs, in other words the
            %lobes spatial freqs in FF in the image reference system
            Cs={s.Centroid};
            C=Cs(k);
            
            %the spatial freq positions in the u,v ref system will be
            w=cell(size(C));
            aw=zeros(size(w));
            for n=1:NL
                %change from i,j to u,v
                p=C{n};
                p=p-[u0,v0];
                w{n}=p;
                aw(n)=atan2(p(2), p(1)); %this is to get the clockwise order
            end
            
            %now order the spatial freqs, 1,2,3,4 clockwise starting in the
            %horizontal left  lobe
            %     2
            %   1 X 3
            %     4
            [aw, k]=sort(angle(exp(1i*(aw+pi/4))));
            C=C(k); %side lobes location in FF in i,j ref system (0,0) at the left upper corner
            w=w(k); %side lobes location in FF in u,v ref system (0,0) at the center
            
            %if we have ref reqs number w with respect wr{1} locating the
            %closet match
            if not(isempty(wr))
                %check sizes
                if not(all(size(wr)==size(w)))
                    retMsg=['incorrect lobe number'];
                    error([callFunc, '->' retMsg]);
                end
                
                %check lobe closest to wr{1}
                d=zeros(1,NL);
                k=(1:NL)'; %column vector for circshift
                for n=1:NL
                    d(n)=norm(w{n}-wr{1});
                end
                [~,l]=min(d);
                m=NL+1-l;
                k=circshift(k, m);
                C=C(k); %side lobes location in FF in i,j ref system (0,0) at the left upper corner
                w=w(k); %side lobes location in FF in u,v ref system (0,0) at the center
            end
            
            AQDEBUG=false;
            if AQDEBUG
                BWdot=false(size(BW));
                
                D = bwdist(BW);
                DL = watershed(D);
                bgm = DL == 0;
                figure; imshow(bgm+GA), title('Watershed ridge lines (bgm)')
                
                
                hold on
                for n=1:NL
                    p=C{n};
                    plot(p(1), p(2), 'r*')
                    text(p(1)+10, p(2), num2str(n), 'Color',[1 0 0], 'FontSize', 20);
                    BWdot(round(p(2)), round(p(1)))=true;
                end
                hold off
                
                
            end
        end
        
        
        
        
        function z = FFTDemod(g, w, varargin)
            % FFTDemod demodulates igram g into a cell array of phasors
            % z, one per carrier lobe position in cell w, by bandpass
            % filtering (radius R in FF, default 0.3*norm(w{1}-w{2}))
            % around each lobe (after a fixed 3-FF DC low-pass) and
            % inverse-FFT'ing.
            %
            % Optional args: flatTopFlag (true) hard-disk passband filter
            % vs. a Gaussian one; R (see above) passband filter radius
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check input params
            gName=inputname(1);
            %check 2D matrix
            if not(ismatrix(g))
                retMsg=[gName ' must be a matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            wName=inputname(2);
            %check is cell array
            if not(iscell(w))
                retMsg=[wName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 2
                retMsg=[callFunc ' requires at most 2 optional inputs: topFlat, R'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % R=1/3 distance between w1 and w2;
            %bandpass filter width in FF
            %sigmaL=paramList{1}; %lobe Half Width in FF
            w1=w{1}; w2=w{2};
            R=0.3*norm(w1-w2);
            optargs = {true, R};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [flatTopFlag, R] = optargs{:};
            
            %convert to double all cases
            g=double(g);
            
            %low pass filter size in Fringes Field, backgroung is not
            %bigger than 3 FF. If necesary filter igram before demodulation
            RLP=3;
            %numbr of lobes
            NL=length(w);
            %get size
            [NR, NC]=size(g);
            
            %prepare frec coordinates
            [u, v]=meshgrid(1:NC, 1:NR);
            u0=floor(NC/2)+1;
            v0=floor(NR/2)+1;
            u=u-u0; v=v-v0;
            HB=1-exp(-0.5*abs(u+1i*v).^2/RLP^2); %lowpass filter
            
            z=cell(1, NL); %phasor List
            for n=1:NL
                %get lobe pos
                wpos=w{n};
                HL=exp(-0.5*abs((u-wpos(1))+1i*(v-wpos(2))).^2/R^2); %bandpass filter
                if flatTopFlag
                    HL=HL>0.67; %threshold, filter is a badpass disk with radius R
                end
                
                %get FFT
                G=fft2(g);
                
                %HB and HL are already fftshifted from design, if fftshift is used instead, for even
                %dimensions there is no problem, however for odd dimensions fftshift(H)
                %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
                %see help for ifftshift
                GH=G.*ifftshift(HL).*ifftshift(HB);
                z{n} = ifft2(GH);
            end
        end
        
        function uH=wRes(uh, w)
            % wRes weighted restriction operator (multigrid schemes/
            % filtering, paired with Pro): downsamples uh by 2 via a
            % Gaussian-weighted relaxation, using w as the pixel weights
            % (handles S==0 divisions specially). uh's dimensions must be
            % even (ideally a power of two, to also work with Pro).
            [NR, NC]=size(uh);
            
            uh=[uh(1,1) uh(1,:); uh(:,1) uh];
            w=[w(1,1) w(1,:); w(:,1) w];
            uh=uh.*w;
            
            %restriction
            NC=NC/2;
            NR=NR/2;
            
            Col=1:NC;
            Row=1:NR;
            
            
            S=0.25*w(2*Row, 2*Col)+...
                0.125*( w(2*Row, 2*Col+1) + w(2*Row, 2*Col-1)+ w(2*Row-1, 2*Col)+w(2*Row+1, 2*Col))+...
                0.0625*(w(2*Row+1, 2*Col+1)+w(2*Row+1, 2*Col-1)+w(2*Row-1, 2*Col+1)+w(2*Row-1, 2*Col-1));
            
            %relaxation
            uH=0.25*uh(2*Row, 2*Col)+...
                0.125*(uh(2*Row, 2*Col+1) + uh(2*Row, 2*Col-1) + uh(2*Row-1, 2*Col) + uh(2*Row+1, 2*Col))+...
                0.0625*(uh(2*Row+1, 2*Col+1)+uh(2*Row+1, 2*Col-1)+uh(2*Row-1, 2*Col+1)+uh(2*Row-1, 2*Col-1));
            
            
            uH(Row,NC)=uh(2*Row+1, 2*NC+1);
            uH(NR,Col)=uh(2*NR+1,2*Col+1);
            uH(Row,1)=uh(2*Row+1, 2);
            uH(1,Col)=uh(2,2*Col+1);
            
            uH=uH./S;
            
            %check for zeros divisions
            [Row, Col]=find(S==0);
            % uH(Row, Col)=...... Da excesivos problemas de memoria
            Tam=length(Row);
            for i=1:Tam
                uH(Row(i), Col(i))=0.25*uh(2*Row(i), 2*Col(i))+...
                    0.125*(uh(2*Row(i), 2*Col(i)+1)+ uh(2*Row(i), 2*Col(i)-1)+uh(2*Row(i)-1, 2*Col(i))+uh(2*Row(i)+1, 2*Col(i)))+...
                    0.0625*(uh(2*Row(i)+1, 2*Col(i)+1)+uh(2*Row(i)+1, 2*Col(i)-1)+uh(2*Row(i)-1, 2*Col(i)+1)+uh(2*Row(i)-1, 2*Col(i)-1));
            end
        end
        
        function uh=Pro(uH)
            % Pro prolongation operator (multigrid schemes/filtering,
            % paired with wRes): upsamples uH by 2
            [NR, NC]=size(uH);
            
            Col=1:NC;
            Row=1:NR;
            
            %prolongation
            uh=zeros(2*size(uH));
            uH=[uH uH(:,NC); uH(NR, :) uH(NR,NC )];
            
            %bilinear interpolation
            uh(2*Row-1, 2*Col-1)=uH(Row, Col);
            uh(2*Row+1-1, 2*Col-1)=0.5*(uH(Row, Col) + uH(Row+1, Col));
            uh(2*Row-1, 2*Col+1-1)=0.5*(uH(Row, Col) + uH(Row, Col+1));
            uh(2*Row+1-1,2*Col+1-1)=0.25*(uH(Row, Col) +uH(Row, Col+1)+uH(Row+1, Col)+uH(Row+1, Col+1));
        end
        
        function uf=VicleFilter(u, w)
            % VicleFilter smooths u (weighted by w) via a 4-level
            % V-cycle multigrid filter (wRes down, Pro back up)
            %for using wRes and Pro dims must be power of two
            [NRows, NCols]=size(u);
            
            %look for the closest power ot 2 to [NRows, NCols]
            n=nextpow2(NCols);
            m=[n, n-1];
            h=2.^m; [~, k]=min(abs(h-NCols));
            NC=2^m(k);
            
            n=nextpow2(NRows);
            m=[n, n-1];
            h=2.^m; [~, k]=min(abs(h-NRows));
            NR=2^m(k);
            
            %resize to a power of two
            w=imresize(w, [NR, NC], 'nearest');
            u=imresize(u, [NR, NC]);
            
            %mask (weights) restriction
            wH=UtilFunFPA.wRes(w, w); w2H=UtilFunFPA.wRes(wH, wH); w3H=UtilFunFPA.wRes(w2H, w2H);
            %w4H=UtilFunFPA.wRes(w3H, w3H);
            
            %signal restriction
            uH=UtilFunFPA.wRes(u, w); u2H=UtilFunFPA.wRes(uH, wH); u3H=UtilFunFPA.wRes(u2H, w2H); u4H=UtilFunFPA.wRes(u3H, w3H);
            %u5H=UtilFunFPA.wRes(u4H, w4H);
            
            %signal prolongation
            %u4H=UtilFunFPA.Pro(u5H);
            u3H=UtilFunFPA.Pro(u4H);u2H=UtilFunFPA.Pro(u3H);uH=UtilFunFPA.Pro(u2H); u=UtilFunFPA.Pro(uH);
            
            %filtered signal
            uf=imresize(u, [NRows, NCols]);
        end
        
        function uf=VicleFilter2(u, w)
            % VicleFilter2 is VicleFilter with a shallower 3-level V-cycle
            %for using wRes and Pro dims must be power of two
            [NRows, NCols]=size(u);
            
            %look for the closest power ot 2 to [NRows, NCols]
            n=nextpow2(NCols);
            m=[n, n-1];
            h=2.^m; [~, k]=min(abs(h-NCols));
            NC=2^m(k);
            
            n=nextpow2(NRows);
            m=[n, n-1];
            h=2.^m; [~, k]=min(abs(h-NRows));
            NR=2^m(k);
            
            %resize to a power of two
            w=imresize(w, [NR, NC], 'nearest');
            u=imresize(u, [NR, NC]);
            
            %mask (weights) restriction
            wH=UtilFunFPA.wRes(w, w); w2H=UtilFunFPA.wRes(wH, wH);
            %w3H=UtilFunFPA.wRes(w2H, w2H);
            %w4H=UtilFunFPA.wRes(w3H, w3H);
            
            %signal restriction
            uH=UtilFunFPA.wRes(u, w); u2H=UtilFunFPA.wRes(uH, wH); u3H=UtilFunFPA.wRes(u2H, w2H);
            %u4H=UtilFunFPA.wRes(u3H, w3H);
            %u5H=UtilFunFPA.wRes(u4H, w4H);
            
            %signal prolongation
            %u4H=UtilFunFPA.Pro(u5H);
            %u3H=UtilFunFPA.Pro(u4H);
            u2H=UtilFunFPA.Pro(u3H);uH=UtilFunFPA.Pro(u2H); u=UtilFunFPA.Pro(uH);
            
            %filtered signal
            uf=imresize(u, [NRows, NCols]);
        end
        
        
        
        function [w2Alpha, M]=Calc2Alpha(w4Alpha,q,m,t,mu)
            % Calc2Alpha is a regularized estimator for the isoclinic
            % phase in photoelasticity: derives the wrapped 2*alpha
            % phase w2Alpha from the wrapped 4*alpha phase w4Alpha.
            %
            % Inputs: w4Alpha wrapped 4*alpha phase; q quality map; m
            % mask; t region size for the estimator (2*t+1); mu
            % regularization parameter.
            % Outputs: w2Alpha wrapped 2*alpha phase; M ROI of points
            % actually processed.
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %AQ TODO poner control de parametros
            %INICIALIZA VALORES
            n=size(w4Alpha);
            px=ones(n);py=ones(n);q=abs(q).*m;
            s=zeros(n);w2Alpha=zeros(n); M=zeros(n);
            dx=cos(w4Alpha/2).*m;dy=sin(w4Alpha/2).*m;
            
            %DEFINE EL TAMA�O DEL ARREGLO PARA EL HISTOGRAMA
            %DEL ALGORITMO DE STR�BEL
            na=10;maxi=0;
            q=round(q./max(max(q))*(na-1))+1;
            for k=1:na
                [ry,rx]=find(q==k);
                if maxi<length(ry) maxi=length(ry);end
            end
            hy=zeros(na,maxi);hx=zeros(na,maxi);
            front=zeros(1,na);final=zeros(1,na);
            
            %ALGORITMO DE STR�BEL PARA SEGUIR EL MAPA
            %DE CALIDAD EN LA ESTIMACION
            cont=0;ind=1;
            [yy,xx]=find(q==(max(q(:))));y=yy(1);x=xx(1); % Determina las coordenadas de arranque de la estimacion
            %x=350;y=200;
            px(y,x)=-dy(y,x);py(y,x)=dx(y,x);
            w2Alpha(y,x)=atan2(dy(y,x),dx(y,x));s(y,x)=1;
            
            while ind>0
                xx=[x-1;x-1;x-1;x;x;x+1;x+1;x+1];yy=[y-1;y;y+1;y-1;y+1;y-1;y;y+1];
                for k=1:8
                    if s(yy(k),xx(k))==0 && m(yy(k),xx(k))>0 && xx(k)>t && xx(k)<n(2)-t+1 && yy(k)>t && yy(k)<n(1)-t+1
                        xt=xx(k);yt=yy(k);
                        dx2=dx(yt-t:yt+t,xt-t:xt+t);dy2=dy(yt-t:yt+t,xt-t:xt+t);
                        s2=s(yt-t:yt+t,xt-t:xt+t);m2=m(yt-t:yt+t,xt-t:xt+t);
                        px2=px(yt-t:yt+t,xt-t:xt+t);py2=py(yt-t:yt+t,xt-t:xt+t);
                        G(1,1)=sum(sum(dx2.^2.*m2))+mu*sum(sum(s2.*m2));
                        G(1,2)=sum(sum(dy2.*dx2.*m2));
                        b(1)=mu*sum(sum(px2.*s2.*m2));
                        G(2,2)=sum(sum(dy2.^2.*m2))+mu*sum(sum(s2.*m2));
                        b(2)=mu*sum(sum(py2.*s2.*m2));
                        G(2,1)=G(1,2);
                        R=inv(G)*b';
                        px(yt,xt)=R(1);py(yt,xt)=R(2);
                        w2Alpha(yt,xt)=atan2(-px(yt,xt),py(yt,xt));
                        M(yt,xt)=1;
                        
                        s(yt,xt)=1;h=q(yt,xt);
                        if final(h)==maxi final(h)=1;
                        else final(h)=final(h)+1;end
                        hx(h,final(h))=xt;hy(h,final(h))=yt;
                        if front(h)==0 front(h)=1;end
                        cont=cont+1;
                    end
                end
                
                %SACA LAS COORDENADAS DEL HISTOGRAMA
                %PARA LA SIGUIENTE ESTIMACI�N
                k=na;ind=0;
                while ind==0 && k>0
                    ind=front(k);
                    if ind>0
                        x=hx(k,front(k));
                        y=hy(k,front(k));
                        if front(k)==final(k)
                            front(k)=0;final(k)=0;
                        else
                            if front(k)==maxi front(k)=1;
                            else front(k)=front(k)+1;end
                        end
                    end
                    k=k-1;
                end
                
                %DESPLIEGA LA IMAGEN DE LA FASE EN LAPSOS
                if cont/500==floor(cont/500)
                    imagesc(w2Alpha);
                    drawnow;
                end
            end
            % toc
            % imagesc(w2Alpha);
            
            
        end
        
        function h=DrawAlpha(Alpha, D, varargin)
            % DrawAlpha draws the two principal stress directions implied
            % by isoclinic angle Alpha, as arrows over Alpha itself (or
            % altImage if given), decimated by D. If Alpha comes from
            % w4Alpha, s1/s2 and their direction are both indeterminate;
            % if from w2Alpha, s1/s2 are distinguishable but direction
            % is still indeterminate.
            %
            % Optional args: sameColor (false) draw both directions in
            % the same color; stressDirections ('both') 's1', 's2' or
            % 'both'; showArrowHead ('on') passed to quiver; altImage
            % ([]) background image to draw over instead of Alpha.
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 4
                retMsg=[callFunc ' requires 4 optional inputs: sameColorFlag stressDirections, showArrowHead and altImage'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs sameColor and
            % BothDirections, showArrowHead and altImage
            optargs = {false, 'both', 'on', []};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [sameColor, stressDirections, showArrowHead, altImage] = optargs{:};
            
            if sameColor
                S1Color=[1 0 0];
                S2Color=S1Color;
            else
                S1Color=[1 0 0];
                S2Color=[0 0 1];
            end
            
            
            [NR, NC]=size(Alpha);
            [x,y]=meshgrid(1:NC, 1:NR);
            R=1:D:NR;
            C=1:D:NC;
            
            
            s1x=cos(Alpha);
            s1y=sin(Alpha);
            s2x=cos(Alpha + pi/2);
            s2y=sin(Alpha + pi/2);
            
            if isempty(altImage)
                h=figure; imagesc(Alpha); colormap gray;
            else
                h=figure; imagesc(altImage); colormap gray;
            end
            
            hold on;
            switch stressDirections
                case 's1'
                    quiver(x(R,C), y(R,C), s1x(R,C), s1y(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',S1Color, 'ShowArrowHead', showArrowHead);
                case 's2'
                    quiver(x(R,C), y(R,C), s2x(R,C), s2y(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',S2Color, 'ShowArrowHead', showArrowHead);
                case 'both'
                    quiver(x(R,C), y(R,C), s1x(R,C), s1y(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',S1Color, 'ShowArrowHead', showArrowHead);
                    quiver(x(R,C), y(R,C), s2x(R,C), s2y(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',S2Color, 'ShowArrowHead', showArrowHead);
            end
            axis image
            hold off;
        end
        
        
        function [d, w2alpha, sx, sy, sxy, s1, s2, M]=StressDisk(NR, NC, varargin)
            % StressDisk computes the theoretical (Brazilian/diametrical
            % compression) stress distribution for an NRxNC disk loaded
            % along a diameter, plus the resulting isochromatic
            % retardation d (scaled to a max of 10 fringes) and wrapped
            % isoclinic angle w2alpha. Also returns the stress
            % components sx/sy/sxy, principal stresses s1/s2, and the
            % disk mask M.
            % setup the theoretical stress distribution
            [x, y]=meshgrid(1:NC, 1:NR);
            x0=round(NC/2); y0=round(NR/2); %origin
            x=x-x0; y=y-y0;
            
            R=0.5*sqrt(NR*NC); %circle radius
            D=2*R; %diameter
            M=(abs(x+1i*y)<R); %disk
            
            Rm=0.1*R; %top and botton disks radius
            x1=0; y1=-R; %pos disk top
            x2=0; y2=+R; %pos disk bottom
            M1=(abs(x-x1+1i*(y-y1))>Rm);
            M2=(abs(x-x1+1i*(y-y2))>Rm);
            M=M1.*M2.*M; %final mask
            
            
            P=1; %normalized load the final constants are set to have 10 fringes in the field of view
            t=1; %thickness
            C=2*P/(pi*t);
            r1=abs(x + 1i*(R-y));
            r2=abs(x + 1i*(R+y));
            
            sx=M.*C.*((R-y).*x.^2./r1.^4 + (R+y).*x.^2./r2.^4 - 1/D);
            sy=M.*C.*((R-y).^3./r1.^4 + (R+y).^3./r2.^4 - 1/D);
            sxy=M.*C.*((R+y).^2.*x./r2.^4 - (R-y).^2.*x./r1.^4);
            
            s1=M.*0.5.*(sx + sy) + 2*sqrt((sx-sy).^2/4 + sxy.^2);
            s2=M.*0.5.*(sx + sy) - 2*sqrt((sx-sy).^2/4 + sxy.^2);
            
            s12=M.*(s1-s2);
            % sum12=M.*(s1+s2);
            % c2alpha=M.*(sx-sy)./s12;
            % s2alpha=M.*2.*sxy./s12;
            w2alpha=M.*atan2(2*sxy,sx-sy); %wrapped isoclinic angle 2x
            
            F=1; %photoelastic constant
            d=M.*F.*s12; %isochromatic retardation in rad
            maxRetar=max(d(:));
            ScaleToTenFringes=10*2*pi/maxRetar;
            d=d*ScaleToTenFringes;
            
        end
        
        function IList=LBFPattern(delta, alpha, step, M, nl)
            % LBFPattern generates length(step) linear-birefringence
            % (LBF) igrams from retardation delta and isoclinic angle
            % alpha, each phase-shifted by step(n), masked by M and with
            % noise level nl added
            N=length(step);
            IList=cell(1,N);
            for n=1:N
                IList{n} = M.*(1 - 0.5*(sin(delta/2)).^2.*(1-cos(4*(alpha-step(n)))))+nl*rand(size(M));
            end
        end
        
        function gList=CircPol(delta, w2alpha, psi, phi, M)
            % CircPol generates length(psi) circular-polariscope igrams
            % from retardation delta and wrapped isoclinic angle
            % w2alpha, for circular input illumination with analyzer
            % angle psi(n) and quarter-wave-plate angle phi(n), masked by M
            %psi=A, phi=QW2
            N=length(psi);
            gList=cell(1, N);
            for n=1:N
                gList{n}=0.5*M.*(1-sin(2*(psi(n)-phi(n))).*cos(delta)-sin(2*phi(n)-w2alpha).*cos(2*(psi(n)-phi(n))).*sin(delta));
            end
        end
        
        %this function makes a temporal demodulation of the 1D signal g
        %this function assumes that the temporal samples of g are uniform
        function z=Temp1DFFTDemod(g, R, varargin)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            if not(isvector(g))
                retMsg=[inputname(1) ' must be a 1D vector'];
                error([callFunc, '->' retMsg]);
            end
            
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 2
                retMsg=[callFunc ' requires 2 optional inputs: R and w0'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs, w0 (FF) and sigma (FF)
            optargs = {pi/2, length(g)/8};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [w0, sigma] = optargs{:};
            
            N=length(g);
            %Fourier Spectrum
            G=fft(g);
            u=(1:N); u0=floor(N/2)+1;
            %hilbert filter
            u=u-u0;
            H=u>0;
            
            %higpass filter
            HP=1-exp(-0.5*u.^2/R^2);
            %HP=abs(u)>R;
            
            %bandpass filter (gaussian)
            if numvarargs>0
                uu=u-w0;
                HG=exp(-0.5*uu.^2/sigma^2);
            else
                HG=ones(size(HP));
            end
            
            %Total filter
            HT=H.*HP.*HG;
            
            %H is already fftshifted from design, if fftshift is used instead, for even
            %dimensions there is no problem, however for odd dimensions fftshift(H)
            %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
            %see help for ifftshift
            GH=G.*ifftshift(HT);
            
            %complex phasor
            z=ifft(GH);
            
        end
        
        % u=unwrapRLS1D(z, lambda, regType) unwraps the 1D phase of the phasor z, uw=angle(z) by
        % minimizing the cost function U=w*|Dx*u- uwx|^2 + lambda*|Dx*u|^2 or
        % lambda*|Dxx*u|^2 depending on regType
        function u=unwrapRLS1D(z, lambda, varargin)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            numvarargs = length(varargin);
            if numvarargs > 1
                retMsg=[callFunc ': requires at most 1 optional inputs the regType'];
                error(retMsg);
            end
            
            % set defaults for optional inputs
            optargs = {'membrane'};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            % or ...
            % [optargs{1:numvarargs}] = varargin{:};
            
            % Place optional args in memorable variable names
            [regType] = optargs{:};
            
            if not(iscolumn(z))
                z=transpose(z); %traspose input ' is traspose conjugate for complex
            end
            
            N=length(z);
            uw=angle(z);
            m=abs(z);
            
            d=2:N;
            w=m(1:N-1).*m(d); %(N-1)x1
            uwx=angle(exp(1i*(uw(d)-uw(1:N-1)))); %(N-1)x1
            
            [Dx, Dxx, Dxxx]=UtilFunFPA.DerOpsFreeBoundary1D(N);
            W=spdiags(w, 0, N-1,N-1);%aqui es importante que w sea columns
            WtW=W'*W;
            
            switch regType
                case 'membrane'
                    H=Dx'*Dx;
                case 'thinplate'
                    H=Dxx'*Dxx;
                case 'Dxxx'
                    H=Dxxx'*Dxxx;
                otherwise
                    retMsg=['invalid regType: ' regType];
                    error([callFunc, '->' retMsg]);
            end
            
            A=Dx'*WtW*Dx+lambda*H;
            b=Dx'*WtW*uwx;
            
            u=A\b;
        end
        
        % [Dx, Dxx, Dxxx]=DerOpsFreeBoundary1D(N) return the (N-1)xN (N-2)xN and (N-1)xN (N-3)xN sparse operators representing the 1D Dx and Dxx and Dxxx operations
        % using free-bounday conditions
        function [Dx, Dxx, Dxxx]=DerOpsFreeBoundary1D(N)
            %the two diagonals for D 0 and +1
            C=[-1*ones(N-1, 1), ones(N-1, 1)];
            d=[0 1];
            Dx=spdiags(C, d, N-1,N); %(N-1)xN
            
            %the 3 diagonals for Dxx 0 +1 and +2
            C=[1*ones(N-2, 1), -2*ones(N-2, 1), 1*ones(N-2, 1)];
            d=[0 1 2];
            Dxx=spdiags(C, d, N-2,N); %(N-2)xN
            
            %the 3 diagonals for Dxxx 0 +1 +2 +3 +4
            C=[1*ones(N-3, 1), -4*ones(N-3, 1), 6*ones(N-3, 1), -4*ones(N-3, 1), 1*ones(N-3, 1)];
            d=[0 1 2 3 4];
            Dxxx=spdiags(C, d, N-3,N); %(N-3)xN
            
            
        end
        
        function [zPCA, deltaListPCA] = PCADemod(FPList, Mask, varargin)
            %PCADEMOD This function obtains the wrapped phase from a sequence of
            %phase-shifted interferograms using the Principal Component Analysis
            %algorithm (PCA). This function is inspired in the work of A. Leonardis,
            %D. Skocaj that is available from CMP Vision Algorithms
            %http://vicos.fri.uni-lj.si/danijels/downloads
            %http://visionbook.felk.cvut.cz
            %
            % PCA is a linear integral transformation that simplifies
            % a multidimensional dataset to a lower dimension.
            % The implementation of the function pca
            % uses the efficient implementation of singular
            % value decomposition (svd).
            %
            % Usage: [zPCA,deltaListPCA] = pcaDemod(FPList,Mask) [NRows x NCols]
            % Inputs:
            %   FPList  1xNFP list of fringe patterns of [NRows x NCols]
            %   Mask is the processing mask [NRows x NCols]
            %   monotonicDelta flag indicating of the deltas are monotonic
            %   default true and optional
            % Outputs:
            %   zPCA   [NRows x NCols]  demodulated phasor z=m*exp(1i*phi) direct result from the PCA.
            %   deltaListPCA [NPx1] array of calculated phase shifts, direct result from the PCA.
            %   zLS  [NRows x NCols]
            
            %   Javier Vargas,
            %   25/11/10
            %   AQ
            %   29/3/2017
            %   Copyright 2017
            %   IOT
            %   $ Revision: 2.0.0.0 $
            %   $ Date: 23/03/2017 $
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            numvarargs = length(varargin);
            if numvarargs > 1
                retMsg=[callFunc ': requires at most 1 optional inputs the monotonicDelta flag'];
                error(retMsg);
            end
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            g=FPList{1};
            [NR, NC, NPlanes]=size(g);
            
            % set defaults for optional inputs
            monotonicDelta=true; %we assume that phase steps are increasing and that delta(1)=0
            optargs = {monotonicDelta};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            % or ...
            % [optargs{1:numvarargs}] = varargin{:};
            
            % Place optional args in memorable variable names
            [monotonicDelta] = optargs{:};
            
            %transform the List in a 2D array for PCA
            %the 2D array is a Compound image formed by the different interferograms columnwise
            %stacked [NR*NC, NFP]
            
            N=length(FPList);% number of FPs
            M=length(find(Mask(:))); %get number os samples by definition M<=NR*NC;
            
            if(M<(3*N/(N-1)))
                retMsg=[callFunc ': images number' num2str(N) 'not enough for solving PCA'];
                error(retMsg);
            end
            
            
            X=zeros(M, N);
            for n=1:N
                %transform to double GV if necessary
                if NPlanes==3
                    FPList{n}=double(rgb2gray(uint8(FPList{n})));
                end
                
                g=FPList{n}; %get FP
                X(:, n)=g(Mask(:)); %vectorize columnwise
            end
            
            
            Xm=mean(X,2);
            Xd=X-repmat(Xm,1,N);
            
            
            CC=Xd'*Xd; %Cross-covariance
            [V, D, Vt]=svd(CC);
            U=Xd*V;
            U=U./repmat(sqrt(diag(D)'),M,1);
            
            U(:,1)=max(U(:,2)).*(U(:,1)./max(U(:,1))); %normalize first PPal component with respect the second
            
            U1 = zeros(NR*NC,1);
            U2 = U1;
            
            U1(Mask)=U(:,1); %first ppal component
            U2(Mask)=U(:,2); %second ppal component
            
            
            phi=atan2(U1, U2);
            m=abs(U2+1i*U1);
            
            zPCA=m.*exp(1i*phi);
            zPCA=reshape(zPCA, NR, NC);
            
            deltaListPCA=atan2(V(:, 2), V(:, 1));
            
            %corregimos signo si monoliticDelta
            if monotonicDelta
                ud=unwrap(deltaListPCA); ud=ud-ud(1);
                if(ud(2)<0)
                    deltaListPCA=angle(exp(-1i*deltaListPCA));
                    zPCA=conj(zPCA);
                end
            end
        end
        
        function [zAIA, deltaListAIA] = AIADemod(FPList, Mask, varargin)
            
            % Matlab implementation of the demodulation method shown in [1]
            %
            % INPUT:
            %   FPList  1xNFP list of fringe patterns of [NRows x NCols]
            %   Mask is the processing mask [NRows x NCols]
            %   deltaList Initial guess for the phase shifts optional
            %   MaxIter maximum number of iterations;
            %   epsilon error tolerance;
            % Outputs:
            %   zAIA   [NRows x NCols]  demodulated phasor z=m*exp(1i*phi) direct result from the AIA.
            %   deltaListAIA [NPx1] array of calculated phase shifts, direct result from the AIA.
            %
            %REFERENCES
            %
            %[1] Z. Wang, B. Han, �Advanced iterative algorithm for phase extraction
            %     of randomly phase-shifted interferograms�,Opt. Lett. 29(14), 1671-1673
            %     (2004)
            %
            %   Javier Vargas, 19/10/10
            %   AQ 10/4/2017
            %   Copyright 2010 IOT
            %   $ Revision: 2.0.0.0 $
            %   $ Date: 10/4/17 $
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            %AQ forzar delltaList columna y ver tema varargin
            
            numvarargs = length(varargin);
            if numvarargs > 3
                retMsg=[callFunc ': requires at most 3 optional inputs [deltaList, epsilon, MaxIter]'];
                error(retMsg);
            end
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            %get dims and chech NFPs
            g=FPList{1};
            [NR, NC, NPlanes]=size(g);
            N=length(FPList);  %steps sumber
            
            
            % set defaults for optional inputs
            deltaList=2*pi*(0:N-1)'/N;
            epsilon =1e-5;
            MaxIter = 15;
            optargs = {deltaList, MaxIter, epsilon};
            
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % or ...
            % [optargs{1:numvarargs}] = varargin{:};
            
            % Place optional args in memorable variable names
            [deltaList, MaxIter, epsilon] = optargs{:};
            
            %check deltaList
            if length(deltaList)~=N
                retMsg=['different number of FPs and phase steps'];
                error([callFunc, '->' retMsg]);
            end
            
            if not(iscolumn(deltaList))
                retMsg=['deltaList must be a column vector'];
                error([callFunc, '->' retMsg]);
            end
            
            %get M
            M=length(find(Mask(:)));   %valid points
            gVec=zeros(N, M);  %vectorized images
            
            %init gVec
            for i=1:N
                %transform to double GV if necessary
                if NPlanes==3
                    FPList{n}=double(rgb2gray(uint8(FPList{n})));
                end
                
                g = FPList{i};
                gVec(i,:) = g(Mask)';
            end
            
            
            %init d and ad (the former iteratuion value)
            d=deltaList';  %traspose
            ad=d;
            %init while control
            err = inf;
            iter = 1;
            while ( (err > epsilon) && (iter  <= MaxIter) )
                
                %reset phi
                phi=zeros(1,M);
                Mod=zeros(1,M);
                
                A = [ N        ,   sum(cos(d)),              sum(sin(d))
                    sum(cos(d)),   sum( cos(d).^2 ),         sum(cos(d).*sin(d) )
                    sum(sin(d)),   sum( sin(d).*cos(d) ),    sum(sin(d).^2)];
                
                %Fisrt setp:
                for i=1:M
                    Bij = [sum(gVec(:,i));  cos(d)*gVec(:,i);    sin(d)*gVec(:,i)];
                    Xj = A\Bij;
                    phi(i) = atan2(-Xj(3),Xj(2));
                    Mod(i) = (abs(Xj(3)+1i*Xj(2)));
                end
                
                %Second  step:
                A = [  M         ,        sum(cos(phi)),               sum(sin(phi))
                    sum(cos(phi)),        sum( cos(phi).^2 ),          sum(cos(phi).*sin(phi) )
                    sum(sin(phi)),        sum( sin(phi).*cos(phi) ),   sum(sin(phi).^2)];
                
                
                for i=1:N
                    Bij = [sum(gVec(i,:));  cos(phi)*gVec(i,:)';    sin(phi)*gVec(i,:)'];
                    Xj = A\Bij;
                    d(i) = atan2(-Xj(3),Xj(2));
                end
                
                err = max(abs(ad -d));
                iter = iter + 1;
                ad = d;
            end
            
            
            p=zeros(size(g));
            m=zeros(size(g));
            
            p(Mask) = phi;
            m(Mask) = Mod;
            
            zAIA=m.*exp(1i*p);
            deltaListAIA = d';
            
        end
        
        
        
        % ======================================================================
        %> @brief LSDemod least squares demodulation using N delta steps with known values
        %> @details @see FPA book and Z. Wang, B. Han, �Advanced iterative algorithm for phase extraction of randomly phase-shifted interferograms�,Opt. Lett. 29(14), 1671-1673
        %> @copyright 2010 IOT
        %> @author JV, 19/10/10
        %> @author AQ 10/4/2017
        %> @param FPList  1xNFP list of fringe patterns of [NRows x NCols]
        %> @param Mask is the processing mask [NRows x NCols] the phasor z is only calculated at M==true,
        %> it is used mainly for accelerate the calculation process. If mask is M==[] then
        %> M=ones() is used and all points are procesed
        %> @param deltaList phase shift values
        %> @param varargin optional params onlyModFlag (false) flag for
        %> computing only the modulation and no phase
        %> @retval zLS   [NRows x NCols]  demodulated phasor z=m*exp(1i*phi)
        % ======================================================================
        function [zLS] = LSDemod(FPList, Mask, deltaList, varargin)
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            numvarargs = length(varargin);
            if numvarargs > 1
                error('OM4M:OrMinDer:TooManyInputs', ...
                    'requires at most 1 optional inputs: onlyModFlag');
            end
            
            % set defaults for optional inputs
            % onlyModFlag = false
            optargs = {false};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [onlyModFlag] = optargs{:};
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            g=FPList{1};
            [NR, NC, NPlanes]=size(g);
            
            %Mask Casting if empty init to ones()
            if isempty(Mask)
                Mask=true(NR, NC);
            end
            
            
            if not(iscolumn(deltaList))
                retMsg=['deltaList must be a column vector'];
                error([callFunc, '->' retMsg]);
            end
            
            %check deltaList
            if length(FPList)~=length(deltaList)
                retMsg=['different number of FPs and phase steps'];
                error([callFunc, '->' retMsg]);
            end
            
            
            %get N, M
            N=length(FPList);  %steps sumber
            M=length(find(Mask(:)));   %valid points
            gVec=zeros(N, M);  %vectorized images
            
            %init gVec
            for i=1:N
                %transform to double GV if necessary
                if NPlanes==3
                    FPList{i}=double(rgb2gray(uint8(FPList{i})));
                end
                
                g = FPList{i};
                gVec(i,:) = g(Mask)';
            end
            %init d as deltaList for more clear code
            d=deltaList'; %traspose
            
            %reset phi
            phi=zeros(1,M);
            Mod=zeros(1,M);
            
            A = [ N        ,   sum(cos(d)),              sum(sin(d))
                sum(cos(d)),   sum( cos(d).^2 ),         sum(cos(d).*sin(d))
                sum(sin(d)),   sum( sin(d).*cos(d) ),    sum(sin(d).^2)];
            
            %LS demod:
            B=[sum(gVec); cos(d)*gVec; sin(d)*gVec]; %=[3xM]  d [1xN] gVec [NxM]
            
            X = A\B; %[3x3][3xM]
            
            %reshape modulation and normalize by the number of samples
            m=zeros(size(g));
            m(Mask) = sqrt(X(3, :).*X(3, :)+X(2, :).*X(2, :));

            %calculate phasor and Normalize by the number of samples 
                      
            if onlyModFlag
                zLS=m;
            else
                %reshape phase
                p=zeros(size(g));
                %Aqui necesitamos el round para que para algunos
                %casos como Tx=28 y NIgrams=28 atan2(0, z) sale -eps y en
                % vez de 0 y al hacer el mod2pi sale 2pi en vez de 0 lo
                % cual puede fastidiar el calculo de la fase absoluta
                nDigits=6;
                p(Mask) = round(atan2(-X(3, :),X(2, :)),nDigits);
                zLS=m.*exp(1i*p);
            end
        end
        
        
        function [z] = LSDemodEquispaced(FPList, Mask, deltaList4check, varargin)
            
            % Matlab implementation of the LS demodulation with equispaced [0 2pi] steps shown the
            % FPA book eq 2.41
            %
            % INPUT:
            %   FPList  1xNFP list of fringe patterns of [NRows x NCols]
            %   Mask is the processing mask [NRows x NCols]
            %   deltaList equispaced phase shifts in [0 2*pi(1-1/N)] for
            %   checking purpouses
            %   onlyModFlag this is logical that indicates the we only
            %   calculate the modulation, this returning in z only the
            %   modulation
            % Outputs:
            %   zLS   [NRows x NCols]  demodulated phasor z=m*exp(1i*phi) direct result from the AIA.
            %
            %REFERENCES
            %
            %   AQ 18/1/2018
            %   Copyright 2010 IOT
            %   $ Revision: 1.0.0.0 $
            %   $ Date: 18/1/18 $
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            numvarargs = length(varargin);
            if numvarargs > 1
                error(callFunc, ...
                    'requires at most 1 optional inputs: onlyModFlag');
            end
            
            % set defaults for optional inputs
            % onlyModFlag = false
            optargs = {false};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [onlyModFlag] = optargs{:};
            
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            g=FPList{1};
            [NR, NC, NPlanes]=size(g);
            
            %Mask Casting
            if isempty(Mask)
                Mask=true(NR, NC);
            end
            
            
            if not(iscolumn(deltaList4check))
                retMsg=['deltaList must be a column vector'];
                error([callFunc, '->' retMsg]);
            end
            
            %check deltaList
            if length(FPList)~=length(deltaList4check)
                retMsg=['different number of FPs and phase steps'];
                error([callFunc, '->' retMsg]);
            end
            
            N=length(FPList);  %steps sumber
            %the deltaList must be N steps equispaced between [0,2pi]
            %we still pass them for compatibility with calling object
            d=[0:N-1]'*2*pi/N;
            if any(d~=deltaList4check)
                retMsg=['The phase steps are not correct, revise them'];
                error([callFunc, '->' retMsg]);
            end
            
            gc=zeros(NR, NC);
            gs=zeros(NR, NC);
            
            for n=1:N
                if NPlanes==3
                    FPList{n}=double(rgb2gray(uint8(FPList{n})));
                end
                if isinteger(FPList{n})
                    FPList{n}=double(FPList{n});
                end
                gs=gs+sin(deltaList4check(n))*FPList{n};
                gc=gc+cos(deltaList4check(n))*FPList{n};
            end
            
            %for a equispaced LS PSA we must normalize modulation by 2/|H(w_0)|
            % for getting the same modulation for same igrams but different number of steps. 
            % See Deflectometry.docx for mmore detail. In particular for a
            % equispaced PSA sum(|c_n|^2) = N           
            m = 2*sqrt(gs.*gs+gc.*gc)/N;
            
            if onlyModFlag
                z=m;
            else
                p = atan2(-gs,gc);
                z=m.*exp(1i*p);
            end
        end
        
        
        function [z] = PSA6MultiplexedXY(FPList, Mask, deltaList4check, varargin)
            % Implementation of the 6 step XY multiplexed PSA.
            %
            % INPUT:
            %   FPList  1x6 list of fringe patterns of [NRows x NCols]
            %   Mask is the processing mask [NRows x NCols]
            %   deltaList structuire with two fields X, Y cell with 6 steps
            %   each for checkong purpouses
            %   onlyModFlag this is logical that indicates the we only
            %   calculate the modulation, this returning in z only the
            %   modulation
            % Outputs:
            %   z   1x2 cell with 2 [NRows x NCols] demodulated phasors z{1}=m*exp(1i*phiX) z{2}=m*exp(1i*phiY)
            %
            %
            %   AQ 18/2/2019
            %   Copyright 2010 IOT
            %   $ Revision: 1.0.0.0 $
            %   $ Date: 18/2/19 $
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            numvarargs = length(varargin);
            if numvarargs > 1
                error(callFunc, ...
                    'requires at most 1 optional inputs: onlyModFlag');
            end
            
            % set defaults for optional inputs
            % onlyModFlag = false
            optargs = {false};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [onlyModFlag] = optargs{:};
            
            
            FPListName=inputname(1);
            %check is cell array
            if not(iscell(FPList))
                retMsg=[FPListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            %check cell array length
            NFPs=6; %number of FPs
            if ne(length(FPList), NFPs)
                retMsg=[FPListName ' must be a 1x6 cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            g=FPList{1};
            [NR, NC, NPlanes]=size(g);
            
            %Mask Casting
            if isempty(Mask)
                Mask=true(NR, NC);
            end
            
            %the deltaList must be 6 steps with specific values
            %we still pass them for compatibility with calling object
            d=struct('X', [0, pi, -pi/2, pi/2, 0, -pi/2],...
                'Y', [0, 0, -pi/2, -pi/2, pi, pi/2]);
            
            if any(ne(d.X, deltaList4check.X)) || any(ne(d.Y, deltaList4check.Y))
                retMsg=['The phase steps are not correct, revise them'];
                error([callFunc, '->' retMsg]);
            end
            
            %solve for RGB images
            for n=1:NFPs
                if NPlanes==3
                    FPList{n}=double(rgb2gray(uint8(FPList{n})));
                end
                if isinteger(FPList{n})
                    FPList{n}=double(FPList{n});
                end
            end
            
            c=struct('X', [], 'Y', []); %cos for X orentation
            s=struct('X', [], 'Y', []); %sin for Y orientation
            c.X=FPList{1}-FPList{2}; s.X=FPList{3}- FPList{4};
            c.Y=FPList{1}- FPList{5}; s.Y=FPList{3}- FPList{6};
            
            m{1} = 0.5*sqrt(c.X.*c.X + s.X.*s.X);
            m{2} = 0.5*sqrt(c.Y.*c.Y + s.Y.*s.Y);
            
            if onlyModFlag
                z=m;
            else
                p{1} = atan2(-s.X,c.X);
                z{1}=m{1}.*exp(1i*p{1});
                
                p{2} = atan2(-s.Y,c.Y);
                z{2}=m{2}.*exp(1i*p{2});
            end
            
        end
        
        
        % AQAQAQ BORRAR PARA 1MAY2020 AQAQAQ
        %         function [zLS] = LSDemod_AQTest(FPList, Mask, deltaList)
        %
        %             % Matlab implementation of the LS demodulation method shown the
        %             % FPA book, also in ref [1]
        %             %
        %             % INPUT:
        %             %   FPList  1xNFP list of fringe patterns of [NRows x NCols]
        %             %   Mask is the processing mask [NRows x NCols]
        %             %   deltaList phase shifts
        %             % Outputs:
        %             %   zLS   [NRows x NCols]  demodulated phasor z=m*exp(1i*phi) direct result from the AIA.
        %             %
        %             %REFERENCES
        %             %
        %             %[1] Z. Wang, B. Han, �Advanced iterative algorithm for phase extraction
        %             %     of randomly phase-shifted interferograms�,Opt. Lett. 29(14), 1671-1673
        %             %     (2004)
        %             %
        %             %   Javier Vargas, 19/10/10
        %             %   AQ 10/4/2017
        %             %   Copyright 2010 IOT
        %             %   $ Revision: 2.0.0.0 $
        %             %   $ Date: 10/4/17 $
        %
        %             import OM4MClassLib.Util.*
        %             callFunc=Logging.WhoCalledMe();
        %
        %             FPListName=inputname(1);
        %             %check is cell array
        %             if not(iscell(FPList))
        %                 retMsg=[FPListName ' must be a cell array'];
        %                 error([callFunc, '->' retMsg]);
        %             end
        %
        %             g=FPList{1};
        %             [NR, NC, NPlanes]=size(g);
        %
        %             %Mask Casting
        %             if isempty(Mask)
        %                 Mask=true(NR, NC);
        %             end
        %
        %
        %             if not(iscolumn(deltaList))
        %                 retMsg=['deltaList must be a column vector'];
        %                 error([callFunc, '->' retMsg]);
        %             end
        %
        %             %check deltaList
        %             if length(FPList)~=length(deltaList)
        %                 retMsg=['different number of FPs and phase steps'];
        %                 error([callFunc, '->' retMsg]);
        %             end
        %
        %
        %             %get N, M
        %             N=length(FPList);  %steps sumber
        %             M=length(find(Mask(:)));   %valid points
        %             gVec=zeros(N, M);  %vectorized images
        %
        %             %init gVec
        %             for i=1:N
        %                 %transform to double GV if necessary
        %                 if NPlanes==3
        %                     FPList{n}=double(rgb2gray(uint8(FPList{n})));
        %                 end
        %
        %                 g = FPList{i};
        %                 gVec(i,:) = g(Mask)';
        %             end
        %             %init d as deltaList for more clear code
        %             d=deltaList'; %traspose
        %
        %             %reset phi
        %             phi=zeros(1,M);
        %             Mod=zeros(1,M);
        %
        %             A = [ N        ,   sum(cos(d)),              sum(sin(d))
        %                 sum(cos(d)),   sum( cos(d).^2 ),         sum(cos(d).*sin(d))
        %                 sum(sin(d)),   sum( sin(d).*cos(d) ),    sum(sin(d).^2)];
        %
        %             %LS demod:
        %             for i=1:M
        %                 Bi = [sum(gVec(:,i));  cos(d)*gVec(:,i);  sin(d)*gVec(:,i)];
        %                 X = A\Bi;
        %                 phi(i) = atan2(-X(3),X(2));
        %                 Mod(i) = (abs(X(3)+1i*X(2)));
        %             end
        %
        %             %reshape phase and modulation
        %             p=zeros(size(g));
        %             m=zeros(size(g));
        %
        %             p(Mask) = phi;
        %             m(Mask) = Mod;
        %             zLS=m.*exp(1i*p);
        %
        %         end
        
        
        % this function returns the 2*NV+1x2*NV+1 Neighbourhood of image I
        % with total size NRxNC
        function NI=LocalNeighbourhood(I, NV, Row, Col, NR, NC)
            StartRow=Row-NV;
            EndRow=Row+NV;
            StartCol=Col-NV;
            EndCol=Col+NV;
            
            if (Row-NV<= 0)
                StartRow=1;
            end
            
            if (Col-NV<= 0)
                StartCol=1;
            end
            
            if (NV+Col-NC>0)
                EndCol=NC;
            end
            
            if (NV+Row-NR>0)
                EndRow=NR;
            end
            
            NI=I(StartRow:EndRow, StartCol:EndCol);
        end
        
        %IgramNorm interferogram normalization
        % [cn, m]=IgramNorm(c, R) computes the normalized version of interferogram
        % c=b+m*cos(phi), cn=cos(phi) and an estimation of the modulation m.
        % R is the radius in fringes/filed of a DC filter to elliminate the DC
        % signal b from the igram c
        
        % Ref: Juan Antonio Quiroga, Manuel Servin, "Isotropic n-dimensional fringe
        % pattern normalization", Optics Communications, 224, Pages 221-227 (2003)
        
        %   AQ, 03/02/11
        %   Copyright 2009 OM4M
        %   $ Revision: 1.0.0.0 $
        %   $ Date: 03-02-2011 $
        function [cn, m]=IgramNorm(c, R)
            %filter DC with a gaussian
            [NR, NC]=size(c);
            [u,v]=meshgrid(1:NC, 1:NR);
            
            u0=floor(NC/2)+1; v0=floor(NR/2)+1;
            u=u-u0; v=v-v0;
            
            H=1-exp(-(u.^2+v.^2)/(2*R^2)); %Gaussian DC filter with sigma=R
            
            C=fft2(c);
            %H is already fftshifted from design, if fftshift is used instead, for even
            %dimensions there is no problem, however for odd dimensions fftshift(H)
            %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
            %see help for ifftshift
            CH=C.*ifftshift(H);
            
            ch=ifft2(CH);
            
            %compute quafrature
            s=abs(UtilFunFPA.SPHT(ch));
            
            %normalized igram
            cn=cos(atan2(s,ch));
            %modulation
            m=abs(ch+1i*s);
        end
        
        function sd=SPHT(c)
            %SPHT spiral phase transform
            % sd=SPHT(c) computes the quadrture term of c still affected by the
            % direction phase factor. Therefore for a real c=b*cos(phi)
            % sd=SPHT(c)=i*exp(i*dir)*b*sin(phi)
            % Ref: Kieran G. Larkin, Donald J. Bone, and Michael A. Oldfield, "Natural
            % demodulation of two-dimensional fringe patterns. I. General background of the spiral phase quadrature transform," J. Opt. Soc. Am. A 18, 1862-1870 (2001)
            
            %   AQ, 19/8/09
            %   Copyright 2009 OM4M
            %   $ Revision: 1.0.0.0 $
            %   $ Date: 19-08-2009 $
            TH=max(abs(c(:)));
            if mean(real(c(:)))>0.01*TH
                warning('OM4M:SPHT:OutOfRange', ...
                    'input must be DC filtered');
            end
            
            [NR, NC]=size(c);
            [u,v]=meshgrid(1:NC, 1:NR);
            u0=floor(NC/2)+1;
            v0=floor(NR/2)+1;
            
            u=u-u0;
            v=v-v0;
            
            H=(u+1i*v)./abs(u+1i*v);
            H(v0, u0)=0; %crop the nan
            
            C=fft2(c);
            %H is already fftshifted from design, if fftshift is used instead, for even
            %dimensions there is no problem, however for odd dimensions fftshift(H)
            %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
            %see help for ifftshift
            CH=C.*ifftshift(H);
            
            %the complex conjugate is due to the changein sign for rows from xy
            %(cartesian) to ij (pixel) systems that generates a change in the
            %sin(dir) signal in both systems
            sd=conj(ifft2(CH));
        end
        
        % FUNCION DE ESTIMADOR REGULARIZADO PARA
        % EL CALCULO DE LA FASE ASOCIADA A LAS ISOCLINAS
        % EN FOTOELASTICIDAD
        % wtheta = mapa del angulo de orientacion (mod pi)
        % wbeta = mapa del angulo de direccion (mod 2pi)
        % q = Mapa de calidad para la estimacion
        % m = mascara
        % t = Tama�o de la region para el estimador (t*2+1)
        % mu = Parametro de regularizacion
        % r0 pto inicial, [] lo busca automaticamente del maximo de q
        
        function [wbeta]=calcDirection(wtheta,q,m,t,mu,r0)
            %% INICIALIZA VALORES
            n=size(wtheta);
            px=ones(n);py=ones(n);q=abs(q).*m;
            s=zeros(n);wbeta=zeros(n);
            dx=cos(wtheta).*m;dy=sin(wtheta).*m;
            
            %% DEFINE EL TAMA�O DEL ARREGLO PARA EL HISTOGRAMA DEL ALGORITMO DE STR�BEL
            na=10;maxi=0;
            q=round(q./max(max(q))*(na-1))+1;
            for k=1:na
                [ry,rx]=find(q==k);
                if maxi<length(ry) maxi=length(ry);end
            end
            hy=zeros(na,maxi);hx=zeros(na,maxi);
            front=zeros(1,na);final=zeros(1,na);
            
            %% ALGORITMO DE STR�BEL PARA SEGUIR EL MAPA DE CALIDAD EN LA ESTIMACION
            cont=0;ind=1;
            
            if isempty(r0)
                [yy,xx]=find(q==(max(q(:))));y=yy(1);x=xx(1); % Determina las coordenadas de arranque de la estimacion
            else
                x=r0(1);
                y=r0(2);
            end
            
            px(y,x)=-dy(y,x);py(y,x)=dx(y,x);
            wbeta(y,x)=atan2(dy(y,x),dx(y,x));s(y,x)=1;
            
            puntos_total=sum(sum(m));
            handle_bar = waitbar(0,'Please wait...');
            
            while ind>0
                xx=[x-1;x-1;x-1;x;x;x+1;x+1;x+1];yy=[y-1;y;y+1;y-1;y+1;y-1;y;y+1];
                for k=1:8
                    if s(yy(k),xx(k))==0 & m(yy(k),xx(k))>0 & xx(k)>t & xx(k)<n(2)-t+1 & yy(k)>t & yy(k)<n(1)-t+1
                        xt=xx(k);yt=yy(k);
                        dx2=dx(yt-t:yt+t,xt-t:xt+t);dy2=dy(yt-t:yt+t,xt-t:xt+t);
                        s2=s(yt-t:yt+t,xt-t:xt+t);m2=m(yt-t:yt+t,xt-t:xt+t);
                        px2=px(yt-t:yt+t,xt-t:xt+t);py2=py(yt-t:yt+t,xt-t:xt+t);
                        G(1,1)=sum(sum(dx2.^2.*m2))+mu*sum(sum(s2.*m2));
                        G(1,2)=sum(sum(dy2.*dx2.*m2));
                        b(1)=mu*sum(sum(px2.*s2.*m2));
                        G(2,2)=sum(sum(dy2.^2.*m2))+mu*sum(sum(s2.*m2));
                        b(2)=mu*sum(sum(py2.*s2.*m2));
                        G(2,1)=G(1,2);
                        R=inv(G)*b';
                        px(yt,xt)=R(1);py(yt,xt)=R(2);
                        wbeta(yt,xt)=atan2(-px(yt,xt),py(yt,xt));
                        
                        s(yt,xt)=1;h=q(yt,xt);
                        if final(h)==maxi final(h)=1;
                        else final(h)=final(h)+1;end
                        hx(h,final(h))=xt;hy(h,final(h))=yt;
                        if front(h)==0 front(h)=1;end
                        cont=cont+1;
                    end
                end
                
                
                %SACA LAS COORDENADAS DEL HISTOGRAMA
                %PARA LA SIGUIENTE ESTIMACI�N
                k=na;ind=0;
                while ind==0 && k>0
                    ind=front(k);
                    if ind>0
                        x=hx(k,front(k));
                        y=hy(k,front(k));
                        if front(k)==final(k)
                            front(k)=0;final(k)=0;
                        else
                            if front(k)==maxi front(k)=1;
                            else front(k)=front(k)+1;end
                        end
                    end
                    k=k-1;
                end
                
                %DESPLIEGA LA IMAGEN DE LA FASE EN LAPSOS
                if mod(cont, 500)==0
                    waitbar(cont/puntos_total)
                    imagesc(wbeta); figure(gcf);
                    drawnow;
                end
            end
            close(handle_bar)
        end
        
        
        function s=Vortex(c, dir)
            %Vortex Vortex transform transform
            % s=Vortex(c, dir) computes the quadrture term of c still corrected by
            % the direction phase factor. Therefore for a real c=b*cos(phi)
            % s=Vortex(c)=b*sin(phi). If we use orientation instead of direction we
            % will obtain s=b*sin(phi).*sign(sin(dir))
            % Ref: Kieran G. Larkin, Donald J. Bone, and Michael A. Oldfield, "Natural
            % demodulation of two-dimensional fringe patterns. I. General background of the spiral phase quadrature transform," J. Opt. Soc. Am. A 18, 1862-1870 (2001)
            
            %   AQ, 19/8/09
            %   Copyright 2009 OM4M
            %   $ Revision: 1.0.0.0 $
            %   $ Date: 19-08-2009 $
            
            
            TH=max(abs(c(:)));
            if mean(real(c(:)))>0.01*TH
                warning('OM4M:SPHT:OutOfRange', ...
                    'C must be DC filtered');
            end
            
            sd=UtilFunFPA.SPHT(c);
            s=-1i.*exp(-1i*dir).*sd;
            
            [NR, NC]=size(c);
            if( sum(abs(imag(s(:))/(NR*NC)))>0.1 )
                warning('OM4M:Vortex:OutOfRange', ...
                    'high imaginary part');
            end
            
            s=real(s);
            
        end
        
        
        function [orn, ornMod]=OrMinDer(FP, varargin)
            %OrMinDer Orientation by minmum diference fit
            % [orn, ornMod]=OrMinDer(FP, N) computes the orientation using a window
            % size N.Default values are N=5 px
            % References
            % [1] Yang, Xia; Yu, Qifeng, and Fu, Sihua. An algorithm for estimating both fringe orientation and fringe density. Optics Communications. 2007 Jun 15; 274(2):286-292
            
            %   AQ, 28/8/09
            %   Copyright 2009 OM4M
            %   $ Revision: 1.0.0.0 $
            %   $ Date: 28-08-2009 $
            
            % get input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 1
                error('OM4M:OrMinDer:TooManyInputs', ...
                    'requires at most 1 optional inputs: N');
            end
            
            % set defaults for optional inputs
            % N = 5 px
            optargs = {5};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [N] = optargs{:};
            
            [NR, NC]=size(FP);
            
            MinusOneC=[2:NC NC];
            PlusOneC=[1 1:NC-1];
            
            MinusOneR=[2:NR NR];
            PlusOneR=[1 1:NR-1];
            
            d0=sqrt(2)*abs(FP(MinusOneR,:)-FP(PlusOneR,:));
            d45=abs(FP(MinusOneR,PlusOneC)-FP(PlusOneR,MinusOneC));
            d90=sqrt(2)*abs(FP(:,MinusOneC)-FP(:,PlusOneC));
            d135=abs(FP(MinusOneR,MinusOneC)-FP(PlusOneR,PlusOneC));
            
            D0=conv2(d0, ones(N,N)/N^2, 'same');
            D45=conv2(d45, ones(N,N)/N^2, 'same');
            D90=conv2(d90, ones(N,N)/N^2, 'same');
            D135=conv2(d135, ones(N,N)/N^2, 'same');
            
            b=0.5*(D0-D90);
            c=-0.5*(D45-D135);%hay que tener en cuenta que la "y" esta downwards
            Or=0.5*atan2(c,b);
            
            %el metodo da la orientacion a lo largo de la franja por eso hau que
            %sumar (o restar) pi/2
            orn = mod(Or+pi/2,pi);
            ornMod=mat2gray(abs(c+1i*b));
            
        end
        
        %DEMIQT  Phase demodulation using the Isotropic Quadrature Transform method.
        %   [z, zo, zd]=DemIQT(g, gm, onlyOrFlag, R, N, Lambda) returns the igram phasor z,
        %   orientation phasor zo and direction phasor zd  associated with
        %   the igram g. gm is the processing mask. onlyOrFlag is a logical flag that indicates if it
        %   is necessary the Direction calculation or Orientation and
        %   Direction should be calculated.
        %   R the DC filter size, N the neigbourhood size for orientation and
        %   lambda the regularization parameter.
        function [z, zor, zdir]=DemIQT(g,varargin)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            % get input parameters
            % only want 4 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 5
                retMsg='requires at most 5 optional inputs: gm, R, N and Lambda';
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % gm = ones()
            % onlyOrFlag=false
            % R= 2 FF
            % N = 5 px
            % Lambda= 1
            optargs = {ones(size(g)), false, 2, 5, 1};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [gm, onlyOrFlag, R, N, Lambda] = optargs{:};
            
            %filter DC with a gaussian R FF
            [NR, NC]=size(g);
            [u,v]=meshgrid(1:NC, 1:NR);
            
            u0=floor(NC/2)+1; v0=floor(NR/2)+1;
            u=u-u0; v=v-v0;
            
            H=1-exp(-(u.^2+v.^2)/(2*R^2)); %Gaussian DC filter with sigma=R
            
            C=fft2(g);
            %H is already fftshifted from design, if fftshift is used instead, for even
            %dimensions there is no problem, however for odd dimensions fftshift(H)
            %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
            %see help for ifftshift
            c=ifft2(C.*ifftshift(H));
            
            %calculo orientacion  Min diff with 2xN+1 size
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);
            %orientation phasor
            zor=ornMod.*exp(1i*orn);
            
            if not(onlyOrFlag)
                %calculo direccion VFR
                q=ornMod;
                m=mat2gray(gm);
                t=5;
                r0=[];
                dirn=UtilFunFPA.calcDirection(orn,q,m,t,Lambda,r0); dirn=dirn+pi;
                
            else
                dirn=orn;
            end
            
            %direction phasor
            zdir=ornMod.*exp(1i*dirn);
            
            %aplico el vortex usando la direccion
            s=UtilFunFPA.Vortex(c, dirn);
            
            %calculo el phasor demodulado
            z=c+1i*s;
        end
        
        
        function [z, Delta] = DemPSAsync5TunOriented(g,varargin)
            
            % DemPSAsync5TunOriented Funci�n para llevar a cabo la demodulaci�n de un patron
            % de franjas usando un metodo asincrono de 5 pasos
            % sintonizable. La demodulacion es orientada vertical u
            % horizontal, es decir segun el caso las franjas verticales u
            % horizontales saldran con muy baja modulacion
            %
            % [z, Delta] = DemPSAsync5TunOriented(g,dir,Nmax) calcula el phasor z y el periodo de muestreo local Delta
            % con un algoritmo de 5 pasos sintonizable a partir el patron de franjas.
            %
            % Argumentos de entrada:
            %
            % I Patron de franjas (obligatorio)
            %
            % Nmax Valor m�ximo del periodo de muestreo (opcional), valor por defecto Nmax=5
            %
            % dir Direccion de demoulacion (opcional):
            %   'horz' direccion horizontal (valor por defecto)
            %   'vert' direccion vertical
            %
            % Ejemplo:
            %
            % % Patron de franjas simulado con 50 franjas/campo
            % N = 340;
            %
            % % Phase
            % [x, y]=meshgrid(1:N, 1:N); x=x-0.5*N; y=y-0.5*N;
            % p=6*peaks(N)+2*pi*50*(x)/N;
            %
            % % Fringe pattern
            % I=128+64*cos(p);
            %
            % % Demodula la fase
            % [z, Delta] = DemPSAsync5Tun(I,5,'horz');
            %
            % @ 2007 AOCG - UCM Infor
            % @ 2019 IOT - AQ
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            % get input parameters
            % only want 2 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 2
                retMsg='requires at most 2 optional inputs: Nmax and dirDemod';
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % Nmax Valor m�ximo del periodo de muestreo (opcional), valor por defecto Nmax=5
            % dirDemod Direccion de demoulacion (opcional) 'horz' direccion horizontal (valor por defecto)
            %   'vert' direccion vertical
            optargs = {5, 'horz'};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [Nmax, dirDemod] = optargs{:};
            
            %validate inputs
            dirDemodValidList={'horz', 'vert'};
            r=Validation.CheckInputParam(dirDemod, dirDemodValidList);
            NmaxValidList=num2cell(1:50);
            r=Validation.CheckInputParam(Nmax, NmaxValidList);
            
            if isvector(g)
                if iscolumn(g)
                    retMsg='for 1D signals, g must be a row-vector and dirDemod=''horz'' (default value)';
                    error([callFunc, '->' retMsg]);
                end
            end
            
            %traspose matrix if necessary
            if (strcmp(dirDemod,'vert'))
                g = g';
            end
            
            % Calculo de la matriz extendida con 'zero padding'
            gex = padarray(g,[0 2*Nmax],'replicate','both'); % Matriz extendida con los bordes replicados
            [NRows, NCols] = size(g);
            
            % Demodulacion de la fase con el salto sintonizable
            
            pmod = zeros(size(g));
            pw = zeros(size(g));
            z=zeros(size(g));
            
            % Punto inicial
            vin = 2*Nmax + 1;
            
            % Matriz de indices
            Mind = [-2; -1; 0; 1; 2]*(1:Nmax);
            n = zeros(size(g));
            
            % Calculo para la primera columna
            
            g1ex = zeros(NRows,Nmax);
            g2ex = zeros(NRows,Nmax);
            g3ex = zeros(NRows,Nmax);
            g4ex = zeros(NRows,Nmax);
            g5ex = zeros(NRows,Nmax);
            g2sig = zeros(NRows,Nmax);
            g4sig = zeros(NRows,Nmax);
            
            for k=1:Nmax
                g1ex(:,k) = gex(:,vin + Mind(1,k));
                g2ex(:,k) = gex(:,vin + Mind(2,k));
                g3ex(:,k) = gex(:,vin + Mind(3,k));
                g4ex(:,k) = gex(:,vin + Mind(4,k));
                g5ex(:,k) = gex(:,vin + Mind(5,k));
                g2sig(:,k) = gex(:,vin - 1);
                g4sig(:,k) = gex(:,vin + 1);
            end
            
            s = sign(g2sig - g4sig).*sqrt(abs(4*(g2ex - g4ex).^2 - (g1ex - g5ex).^2));
            c = 2*g3ex - (g1ex + g5ex) + eps;
            
            % Modulacion y fase para la primera columna
            pmod1 = abs(c + 1i*s);
            [pmod(:,1),n(:,1)] = max(pmod1,[],2);
            for r=1:NRows
                pw(r,1) = atan2(s(r,n(r,1)),c(r,n(r,1)));
            end
            
            % Generacion de las restantes columnas
            
            g1ex = zeros(1,Nmax);
            g2ex = zeros(1,Nmax);
            g3ex = zeros(1,Nmax);
            g4ex = zeros(1,Nmax);
            g5ex = zeros(1,Nmax);
            g2sig = zeros(1,Nmax);
            g4sig = zeros(1,Nmax);
            
            for c=2:NCols
                vin = c + 2*Nmax;
                for r=1:NRows
                    for k=1:Nmax
                        g1ex(k) = gex(r,vin + Mind(1,k));
                        g2ex(k) = gex(r,vin + Mind(2,k));
                        g3ex(k) = gex(r,vin + Mind(3,k));
                        g4ex(k) = gex(r,vin + Mind(4,k));
                        g5ex(k) = gex(r,vin + Mind(5,k));
                        g2sig(k) = gex(r,vin - 1);
                        g4sig(k) = gex(r,vin + 1);
                    end
                    
                    % Numerador y denominador
                    ps = sign(g2sig - g4sig).*sqrt(abs(4*(g2ex - g4ex).^2 - (g1ex - g5ex).^2));
                    pc = 2*g3ex - (g1ex + g5ex) + eps;
                    
                    % Modulacion y fase
                    pmod1 = abs(pc + 1i*ps);
                    [pmod(r,c),n(r,c)] = max(pmod1);
                    pw(r,c) = atan2(ps(n(r,c)),pc(n(r,c)));
                end
            end
            
            % Normalizacion de la modulacion
            
            pmod = mat2gray(pmod);
            
            % Rota los patrones de fase modulo 2pi y modulacion si las franjas son
            % verticales
            
            if (strcmp(dirDemod,'vert'))
                pw = pw';
                pmod = pmod';
                n=n';
            end
            
            %phasor
            z=pmod.*exp(1i*pw);
            % Periodo de muestreo local
            Delta = n;
            
            
        end
        
        function [z, zor, zdir, Delta]=DemAsinc5Tun(g,varargin)
            % DemAsinc5Tun Funci�n para llevar a cabo la demodulaci�n de un patron
            % de franjas usando un metodo asincrono de 5 pasos
            % sintonizable. La demodulacion es 2D incluyendo el calculo de la direccion para hacer
            % el steering del metodo DemPSAsync5TunOriented (solo horizontal o vertical)
            %
            % [z, zor, zdir, Delta]=DemAsinc5Tun(g,gm, NA, N, Lambda) demodula el patron g con modulacion gm, usando NA niveles
            % de diezmado para el proceso adpativo y N vecinos para el
            % calculo de la direccion, Lambda es el parametro de
            % regularizacion usado en el calculo de la direccion
            % la salida consiste en z el fasor, zor el fasor de la
            % orientacuion, zdir el fasor de la direcion y Delta el mapa de
            % diezmado
            
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            % get input parameters
            % only want 4 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 4
                retMsg='requires at most 4 optional inputs: gm, R, N and Lambda';
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % gm = ones()
            % NA=6 %number of decimation leves for adptive method
            % N = 5 px neigbouhoud for orientation calculation
            % Lambda= 1 regularization params for direction
            optargs = {ones(size(g)), 6, 5, 1};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [gm, NA, N, Lambda] = optargs{:};
            
            strDir='horz';
            [zx, Deltax] = UtilFunFPA.DemPSAsync5TunOriented(g, NA, strDir);
            
            strDir='vert';
            [zy, Deltay] = UtilFunFPA.DemPSAsync5TunOriented(g, NA, strDir);
            
            %calculo orientacion  Min diff with 2xN+1 size
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);
            zor=ornMod.*exp(1i*orn);
            
            %calculo direccion VFR
            q=ornMod;
            m=mat2gray(gm);
            t=5;
            r0=[];
            dirn=UtilFunFPA.calcDirection(orn,q,m,t,Lambda,r0); dirn=dirn+pi;
            zdir=ornMod.*exp(1i*dirn);
            
            z=real(zx+zy)+1i*(imag(zx).*cos(dirn) - imag(zy).*sin(dirn));
            Delta=Deltax+1i*Deltay; %decimation levels for each point
        end
        
        function v = homography_solve(pin, pout)
            % HOMOGRAPHY_SOLVE finds a homography from point pairs
            %   V = HOMOGRAPHY_SOLVE(PIN, POUT) takes a 2xN matrix of input vectors and
            %   a 2xN matrix of output vectors, and returns the homogeneous
            %   transformation matrix that maps the inputs to the outputs, to some
            %   approximation if there is noise.
            %
            %   This uses the SVD method of
            %   http://www.robots.ox.ac.uk/%7Evgg/presentations/bmvc97/criminispaper/node3.html
            % David Young, University of Sussex, February 2008
            if ~isequal(size(pin), size(pout))
                error('Points matrices different sizes');
            end
            if size(pin, 1) ~= 2
                error('Points matrices must have two rows');
            end
            n = size(pin, 2);
            if n < 4
                error('Need at least 4 matching points');
            end
            % Solve equations using SVD
            x = pout(1, :); y = pout(2,:); X = pin(1,:); Y = pin(2,:);
            rows0 = zeros(3, n);
            rowsXY = -[X; Y; ones(1,n)];
            hx = [rowsXY; rows0; x.*X; x.*Y; x];
            hy = [rows0; rowsXY; y.*X; y.*Y; y];
            h = [hx hy];
            if n == 4
                [U, ~, ~] = svd(h);
            else
                [U, ~, ~] = svd(h, 'econ');
            end
            v = (reshape(U(:,9), 3, 3)).';
        end
        
        function y = homography_transform(x, v)
            % HOMOGRAPHY_TRANSFORM applies homographic transform to vectors
            %   Y = HOMOGRAPHY_TRANSFORM(X, V) takes a 2xN matrix, each column of which
            %   gives the position of a point in a plane. It returns a 2xN matrix whose
            %   columns are the input vectors transformed according to the homography
            %   V, represented as a 3x3 homogeneous matrix.
            q = v * [x; ones(1, size(x,2))];
            p = q(3,:);
            y = [q(1,:)./p; q(2,:)./p];
        end
        
        function g = bin2gray(b)
            %bin2gray transform binary number b to grey code
            %   from http://www.matrixlab-examples.com/gray-code.html
            %   The input parameter to this function is a binary number (expressed in a string of 0s ans 1s),
            %   the output is the equivalent Gray number (also expressed as
            %   a string of 0 and 1s) with the same length that b
            %   Typically the binary string is calculated from a decimal
            %   number by the MATLAB function dec2bin back to decimal
            %   by bin2dec
            g(1) = b(1);
            for i = 2 : length(b)
                x = xor(str2double(b(i-1)), str2double(b(i)));
                g(i) = num2str(x);
            end
        end
        
        function b = gray2bin(g)
            %gray2bin transform gray code g to binary number b
            %   from http://www.matrixlab-examples.com/gray-code.html
            %   The input parameter to this function is a binary gray number (expressed in a string of 0s and 1s),
            %   the output is the equivalent binary number (also expressed
            %   as a string string of 0s and 1s
            %   Typically the binary string is calculated from a decimal
            %   number by the MATLAB function dec2bin and back to decimal
            %   by bin2dec
            b(1) = g(1);
            for i = 2 : length(g)
                x = xor(str2num(b(i-1)), str2num(g(i)));
                b(i) = num2str(x);
            end
        end
        
        function [PGC, LUT_GC2D, LUT_D2GC, nBits]=generateGC(T, NR, NC, GCDir)
            %generateGC generates a list of nBits + 2 NRxNC GC patterns
            %aligned with X GCDir=0 or Y GCDir=1 with minimum bar width T depending on GCDir
            %The decoded GC will have "bars" of width T and value the order
            %of the bar 0,1,2,...NOrder where NOrder=floor(NC-1)/Tx or
            %floor(NR-1)/Ty depending on GCDir. NBits is calculated to have
            %NOrder the maximum power of two bigger than NR or NC depending
            %on GCDir, nBitsR=nextpow2(NOrder+1);
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check input parameters are positive integers
            retMsg='must be a positive integer';
            assert(floor(abs(T))==T, retMsg);
            assert(floor(abs(NR))==NR, retMsg);
            assert(floor(abs(NC))==NC, retMsg);
            
            % validate GCDir
            % list of valid values for GCDir
            vList={0, 1};
            Validation.CheckInputParam(GCDir, vList);
            
            switch GCDir
                case 0
                    N=NC;
                case 1
                    N=NR;
                otherwise
                    retMsg='Incorrect valur for GCDir';
                    error([callFunc, '->' retMsg]);
            end
            
            %order by columns/rows 0, 1, 2, ....
            n=floor((0:N-1)/T);
            
            %calculamos la siguiente poencia de 2 que es igual o mayor que max(n)
            %esto nos da el numero de bits que necesitamos para describir una barra-columna o
            % una barra-fila de las NRxNC disponibles
            nBits=nextpow2(max(n)+1);  %para el caso de que max(n) sea potencia de 2, si no, el numero de columnas/filas en ng no es consistente
            
            %nb numero de la barra-columna expresado en binario
            %ng numero de la barra-columna expresado en codigo grey
            %each ellement of nb is a string with the dec binary representation of the column/row, with a
            %length of nBits
            %each ellement of ng is a string with the gray code binary representation of the column/row, with a
            %length of nBits
            nb=cell(N, 1);
            ng=cell(N, 1);
            for k=1:N
                %los codigos binario cb y gray cg tienen nBitsC bits
                nb{k}=dec2bin(n(k), nBits);
                ng{k}=UtilFunFPA.bin2gray(nb{k});
            end
            
            %ahora pasamos ng a un array N x nBits y cada una de las columnas del array resultante son los nBits patrones 1D que necesitamos proyectar
            %Pg1D es una matriz de N x nBits
            Pg1D=cell2mat(ng);
            
            %transformamos los patrones X de 1xNC 1D a 2D NRxNC filas
            PGC=cell(1, nBits+2);
            switch GCDir
                case 0 %N==NC
                    for k=1:nBits
                        P=255*uint8(str2num(Pg1D(:, k)))'; % 1xNC
                        PGC{k}=repmat(P, NR, 1); %NRxNC a 8 bits
                    end
                case 1 %N==NR
                    for k=1:nBits
                        P=255*uint8(str2num(Pg1D(:, k))); % NRx1
                        PGC{k}=repmat(P, 1, NC); %NRxNC a 8 bits
                    end
                otherwise
                    retMsg='Incorrect valur for GCDir';
                    error([callFunc, '->' retMsg]);
            end
            
            %solo faltarian dos patrones para poder umbralizar W a 255 y K a 0
            PGC{nBits+1}=255*ones(NR, NC, 'uint8'); %W
            PGC{nBits+2}=zeros(NR, NC, 'uint8'); %Black
            
            % LUT para pasar de grey code (GC) a decimal (D) y viceversa
            %construimos la LUT para pasar de grey code a orden absoluto y viceversa
            NLut=2^nBits;
            LUT_GC2D=zeros(NLut,1); %LUT que pasa de codigo grey (int) a decimal (int) lo que viene siendo el numero de la barra o el orden absoluto en PSA
            LUT_D2GC=zeros(NLut,1); %LUT inversa a LUT_G2D
            
            d=0:NLut-1;
            OFFSET=1;
            %OJO al OFFSET en los arrays!!!!
            for k=0:NLut-1
                db=dec2bin(d(k+OFFSET), nBits); %pasamos dec a binario
                gb=UtilFunFPA.bin2gray(db); %binario dec a binario GC
                g=bin2dec(gb); %binario GC a GC
                LUT_D2GC(k+OFFSET)=g;
                LUT_GC2D(g+OFFSET)=k;
            end
            
        end
        
        function D=decodeGC(PGC, LUT_GC2D)
            %decodeGC decode a list nBits + 2 NRxNC GC patterns generated
            %by genetateGC. So we are assuming here that the 1st patterrn is the MSB
            %the nBit pattern is the LSB and the last two are the W and K
            %images for binarization
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check input parameters
            retMsg=' :input must be a cell';
            assert(isa(PGC, 'cell'), [callFunc retMsg]);
            
            retMsg=' :input must be a vector';
            assert(isvector(LUT_GC2D), retMsg);
            
            [NR, NC, NP]=size(PGC{1});
            retMsg=' :input must be GV';
            assert(NP==1, retMsg);
            
            
            nBits=length(PGC)-2;
            
            W=double(PGC{nBits+1});
            K=double(PGC{nBits+2});
            WK=W-K;
            
            Ib=cell(1, nBits);
            for n=1:nBits
                Ib{n}=((double(PGC{n})-K)./WK)>0.5;
            end
            
            %componemos la imagen con los codigos grey en formato int
            Igc=zeros(NR, NC, 'int64');
            for bit=1:nBits
                %OJO!!! el primer patron es el MSB y el ultimo el LSB
                Igc=bitset(Igc, nBits+1-bit, Ib{bit});
            end
            
            %finalmente decodificamos de Igc al orden absoluto Id
            OFFSET=1;
            D=LUT_GC2D(Igc+OFFSET);
            
            
            
        end
        
        
        function S=LinLUTGV(uv,options)
            % LinLUTGV(uv) linearize the response of a GV
            % transformation system H, like a proyector+camera. u is the
            % imput GV, v the output GV, v=H(u)
            % the (discrete) system response and is a Nx2 table (u,v)
            % for which u=uv(:, 1) is the input GV (i.e. the GVs we sent to a proyector) and v=uv(:, 2)
            % is the measured/transformed GVs. For example in a display/camera combination u
            % will be the GV we sent to the display and v the GV captured
            % by the camera from the projector
            % for this function H must be a monotonically increasing
            % function of u. S is the output structure.
            % S.Tu is a 8bit 255x1 LUT so that H[T(u)] is a linear function
            % OJO S.Tu son GV pero en double
            % between (u0,v0) and (u1,v1), u0 for u<u0 and u1 for u>u1, so
            % that u0=min(Tu) and u1=max(Tu)
            % S.Hu is the interpolated respose, with v0 for v<v0 and v1 for v>v1,
            % NOTA AQ ver seccion 23 "Linearizacion respuesta
            % monitor-camara" del cuaderno de trabajo
            arguments
                uv (:, 2) {mustBeNumeric}
                options.D (1,1) {mustBeNumeric} = 1 %Margen de seguridad de la posicion del vector vs para el maximo y el minimo de la respuesta H(u).
                %Se establece como 1 para evitar problemas con la interpolaci�n
                %de Hv. De esta forma tomamos el valor del max-1 y del
                %min+1 y evita tomar los valores de los m�ximos (y minimos) que no deseamos.
                
            end
            D = options.D;
            S.D = D;
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            [~, NC]=size(uv);
            %check input parameters
            %check that H(u) is Nx2
            retMsg=' :input response H must be Nx2';
            assert(NC==2, [callFunc retMsg]);
            
            %input sampled GVs they must be in [0, NGV-1]
            us=uv(:, 1);
            vs=uv(:, 2);
            %check that H(u) is monotonically increasing
            dH=diff(vs)./diff(us);
            GVTol=1; %we allow 1 GV/GV of noise in the monotonic behaviour
            retMsg=' :input response H must be monotonica';
            assert(all(dH+GVTol)>0, [callFunc retMsg]);
            
            NGV=256; %8 bits
            ONEOFFSET=1; %u,v are GV in [0:NGV-1]
            %check that min(u)>=0 and max(u)<NGV
            retMsg=' :min(u)>=0 and max(u)<NGV';
            assert(min(us)>=0 && max(us)<NGV, [callFunc retMsg]);
            %check that min(v)>=0 and max(v)<NGV
            retMsg=' :min(v)>=0 and max(v)<NGV';
            assert(min(vs)>=0 && max(vs)<NGV, [callFunc retMsg]);
            
            %get v0 and v1 from varagin, if not provided use as default
            %values v0=vmin and v1=vmax%
            % for the interpolation to work v0 and v1 must be "interior" to
            % vs max and min

            %Hallamos la posicion del m�nimo y m�ximo el vector de vs redondeada:
            vunicos=unique(round(vs)); 
            v0=min(vunicos(ONEOFFSET+D:end));
            v1=max(vunicos(ONEOFFSET:end-D));        
               

            S.v0 = v0; %Guardamos v0 y v1
            S.v1 = v1;
            
            %interpolate Hv=(v, u) between v0 and v1
            Hv=zeros(NGV, 1);
            
            vq=(v0:v1)'; 
            %S.vq = vq;
            Hv(vq + ONEOFFSET)=interp1(vs, us, vq);
            %S.Hv = Hv;
            
            u0 = round(min(Hv(vq + ONEOFFSET)));
            u1 = round(max(Hv(vq + ONEOFFSET)));
            S.u0 = u0; %Guardamos u0 y u1
            S.u1 = u1;
            
            %calculate L(u) for equispaced u
            u=(0:NGV-1)'; %NGVx1
            m=(v1-v0)/(u1-u0);
            Lu=m*(u-u0)+v0; %this are the linearized v values
            S.Lu = Lu;
            
            %calculate Tu=Hinv(L(u))
            % if us<u0 Tu=v0, if us>u1 Tu=u1
            Tu=zeros(NGV, 1);
            uq=round(u0:u1)'; %these are GV           
            Tu(uq+ONEOFFSET)=Hv(round(Lu(uq+ONEOFFSET))+ONEOFFSET);
            Tu((u+ONEOFFSET)<=(u0+ONEOFFSET))=u0; %if u<=u0, Tu = Tu(u0+ONEOFFSET)
            Tu((u+ONEOFFSET)>=(u1+ONEOFFSET))=u1; %if u>=u1, Tu = Tu(u1+ONEOFFSET) 
            Tu=round(Tu); %OJO son GV pero doubles no uint8
            S.Tu=Tu; 
            %interpolate H for equispaced u
            Hu=zeros(NGV, 1);
            Hu(uq+ONEOFFSET)=interp1(us, vs, uq);
            Hu((u+ONEOFFSET)<=(u0+ONEOFFSET))=v0; %if u<=u0, Hu = Hu(u0+ONEOFFSET) 
            Hu((u+ONEOFFSET)>=(u1+ONEOFFSET))=v1; %if u>=u1, Hu = Hu(u1+ONEOFFSET)            
            S.Hu=Hu; 
        end
        
        % ======================================================================
        %> @brief DistancePlaneCam
        %> @details static helper function to calculate the distance from the optical centre
        %> of a callibrated camera and the intersection of the optical axis with a plane
        %> with intrincs K, extrinsics R and t and ppal point p0. If M is
        %> a point in the world ref (homogeneous coordinates) and Mc in the camera system Mc=[R|t]M and
        %> s*m=K[R|t]M
        %> @param K camera intrisic matrix px/mm
        %> @param R plane extrinsic rotation matrix
        %> @param t plane extrinsic translation vector mm
        %> @param p0 camera ppal point px
        %> @retval d distance in mm
        %> @retval Hmm2px homography between (undistorted) plane mm and camera px
        %> @retval M0 position in mm of principal point
        %> @author AQ 26/5/2020
        % ======================================================================
        function [d, H, P0]=DistancePlaneCam(K, R, t, p0)
            %euclidean optical centre in plane reference
            O=-R'*t';
            %homography between plane and cam mm2px
            H=K*[R(:, 1), R(:,2), t'];H=H/H(3,3);
            %homogenous coordinates of p0 in plane
            P0=inv(H)*[p0'; 1]; P0=P0/P0(3);
            %euclidean position of p0 in plane
            P0=P0(1:2);
            %distance intersection of optical axis with plane and Camera
            %centre
            d=norm(O-[P0; 0]);
        end
        
        % ======================================================================
        %> @brief this function makes a bar plot of the Reprojection Errors
        %> nut using the cell array of xlabels as x-ticks
        %> @camParams cameraParameters object as obtained from estimateCameraParameters
        %> @camParams cell array with the xlabels, one for each image
        % ======================================================================
        function showReprojectionErrorsWithLabels(camParams,xlabels)
            rpe=camParams.ReprojectionErrors; % NCP (#control points) x 2 (XY) x NP (Number of patterns)
            abs_rpe=abs(rpe(:, 1, :)+ 1i*rpe(:, 2, :)); %NCP (#control points) x 1 (error) x NP (Number of patterns)
            m_abs_rpe=mean(abs_rpe, 1); % 1 (mean error) x 1 x NP (Number of patterns)                
            m_abs_rpe=m_abs_rpe(:); %serialize 1 (mean error) x NP (Number of patterns)
            
            %create a categorical array
            x=categorical(xlabels);

            h=gcf;
            set(h,'defaulttextinterpreter','none');
            set(h, 'defaultAxesTickLabelInterpreter','none');
            set(h, 'defaultLegendInterpreter','none');
            bar(x, m_abs_rpe)
            title('Mean Reprojection Error per Image');
            ylabel('Mean Error in Pixels');
        end
        
        
        %> @brief this function filter spatial frec u=wx and its harmonics with a gausian filter of sigma=R px
        %> @param g input igram or phasor
        %> @param w0 spatial freq in FF
        %> @param options Name-Value Arguments {"R", 0.4*wx/3} R sigma of the gaussian windows centred at n*wx {"M", ones(size(g))} input ROI        
        %> @author AQ 18SEP20
        function [gh, Mh]=filterHarmonicsX(g, wx, options)
            arguments
                % g must be double numeric value 
                g (:, :) double {mustBeNumeric}
                % g must be double real scalar 
                wx (1,1) double {mustBeReal}
                % optional Property R must be real scalar and maximum value
                % is 3*R<0.5*wx
                options.R (1,1) double {mustBeReal} = 0.49*wx/3
                options.M (:, :) double {mustBeNumeric} = ones(size(g))                
            end                                               
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
    
            %get optional values
            R=options.R;
            M=options.M;
            
            %validate optional input argument M
            Validation.mustBeEqualSize(g,M);
            
            %validate R for superposition, the lobes must be isolated
            %the gaussian width must be less than 0.5*wx
            mustBeLessThan(3*R,0.5*wx);
            
            
            %spatial freqs
            [NR, NC]=size(g);
            [u,v]=meshgrid(1:NC, 1:NR);
            u0=floor(NC/2)+1; v0=floor(NR/2)+1;
            u=u-u0; v=v-v0;
            
            %we filter u=wx and all posible X harmonics
            NHarmonics=floor(u0/wx);
            
            H=ones(NR, NC);
            for n=1:NHarmonics
                H=H.*(1-exp(-((u-n*wx).^2+v.^2)/(2*R^2))); %Gaussian DC filter with sigma=R u=wx   
                H=H.*(1-exp(-((u+n*wx).^2+v.^2)/(2*R^2))); %Gaussian DC filter with sigma=R u=-wx   
            end

            %FFT filter g           
            G=fft2(g);
            MG=fft2(M);
            %H is already fftshifted from design, if fftshift is used instead, for even
            %dimensions there is no problem, however for odd dimensions fftshift(H)
            %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
            %see help for ifftshift
            gh=ifft2(G.*ifftshift(H));
            Mh=real(ifft2(MG.*ifftshift(H)));
            
            Th=1e-3;
            RDisk=2;
            %border pixels affectd by the filter
            %TODO repasar esta forma de crear la mascara R=10 vs R=20
            Mh=imclose(abs(M-Mh)>Th, strel('disk',RDisk));
            Mh=M&not(Mh);
            
            if isreal(g)
                gh=real(gh);
            end
            
        end
        
    end
end