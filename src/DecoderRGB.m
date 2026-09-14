classdef DecoderRGB <  handle
    %this class implements the path follower RGB decoder method. Form a RGB calibration table, using a RGB  image the RGBDecoder returns the
    % measurement as codified in the RGB calibration table
    %this class is based in Dropbox\AQ_SYNC\AQ\KIROS\PAPERS\Proyectos\Legacy\Iot-om4m\Om4mLib\Trunk\src\XtremeFringe\PathFollower.cs
    %This class is based in the paper
    %Juan Antonio Quiroga, Ángel Garcia-Botella, and José Antonio Gómez-Pedrero,
    % "Improved method for isochromatic demodulation by RGB calibration," Appl. Opt. 41, 3461-3468 (2002)
    % Beware this is not a fringe demodulator (see Demodulator), and does
    % not follow its interface. However for compatibility we maintain the
    % constructor without parameters and the Process() method. Default
    % params should be OK for the majority of applications
    
    %% props
    %protected
    properties (Access=protected)
        qualityMap; %Quality map to guide the path follower
        RGBCalib; %[Nx4] RGB calibration table, [measurement, R, G, B]
        InterpRGBCalib; %[10Nx4] interpolated calibration table
        RGBCalibMax; % maximum value of measurement in RGBCalib;
        RGBCalibMin; % minimum value of measurement in RGBCalib;
    end
    
    %public
    properties
        Lambda; %regularization param
        DeltaMap; %measurement to decode from g using RGBCalib
        procMask; %processed Point Mask    
        interpFactor; %interpolarion factor for the interpCalib
        dwidth; %width in % of the subArray calibration
    end
    
    %% public methods
    methods
        %constructor
        function this=DecoderRGB(RGBCalib)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            %prop init
            this.RGBCalib=RGBCalib;
            
            % Props default Initialization
            this.Init();
        end
        
        %this function
        function this=Process(this, g, roiMask, varargin)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            if isscalar(g) || isscalar(roiMask)
                retErrorMsg=['RGB image and/or roiMask must be a matrix>'  callFunc];
                error([class(this) '->' retErrorMsg])
            end
            
            [NR, NC, NP]=size(g);
            if NP~=3
                retErrorMsg=['input image must be RGB>'  callFunc];
                error([class(this) '->' retErrorMsg])
            end
            
            numvarargs = length(varargin);
            if numvarargs > 4
                retMsg=[callFunc ': requires at most 4 optional inputs: retardation d0 the starting point P0, deltaMapIn and procMaskIn'];
                error(retMsg);
            end
            
            % set defaults for optional inputs for [d0, P0]
            optargs = {0, [], zeros(size(roiMask)), zeros(size(roiMask))};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            % or ...
            % [optargs{1:numvarargs}] = varargin{:};
            
            % Place optional args in memorable variable names
            [d0, P0, deltaMapIn, procMaskIn] = optargs{:};
            
            %set quality image 1-abs(RGB)
            g=double(g); %for sqrt
            qualityImage=1-mat2gray(sqrt(g(:, :, 1).^2 + g(:, :, 2).^2 + g(:, :, 3).^2 ));
            
            %locate starting point if P0 is empty
            if isempty(P0)
                q=qualityImage;
                q(not(roiMask))=-Inf;
                maxValue=max(q(:));
                [datay, datax] = find(q == maxValue);
                pList=OM4MClassLib.DataStructs.Pixel(datax, datay); %this can be a list of points
                P0=pList(1);
            end
            
            %setup path follower
            nLevels=1;
            followMode=PathFollowerModes.distance2Mask; %path follower mode
            pf=PathFollowerFactory.Create(PathFollowerTypes.CQueue, nLevels, qualityImage, roiMask, followMode);
            
            %set starting point
            pf.AddPoint(P0);
            
            %prepare for decode RGB image
            DRAWRESULTS=1;
            if DRAWRESULTS
                visitedMask=zeros(size(roiMask)); %this mask is only for display and debuging purpuses
                
                f1=figure;
                pos1 = get(gcf,'Position'); % get position of Figure(1)
                set(gcf,'Position', pos1 - [pos1(3)/2,0,0,0]) % Shift position of Figure(1)
                
                f2=figure;
                pos2 = get(gcf,'Position');  % get position of Figure(2)
                set(gcf,'Position', pos2 + [pos1(3)/2,0,0,0]) % Shift position of Figure(2)
                
                m=0;
                M=200;
            end
            
            %init Maps
            this.DeltaMap=deltaMapIn;
            this.procMask=procMaskIn; %AQDEBUG pasar como un parametro a Process asi podemos refinar un resultadotado usando procMask=ones
            
            %get startig point
            P=pf.GetNext();
            
            %we assume that at the starting point retardation relatively known
            %we must set this value for DeltaMap and indicate that procMask=1
            %later in the while, DeltaMap(P) and procMask(P) will be updated
            this.DeltaMap(P.y, P.x)=d0; this.procMask(P.y, P.x)=1;
            NV=4; %11x11
            while not(isempty(P))
                LocalDeltaMap=UtilFunFPA.LocalNeighbourhood(this.DeltaMap, NV, P.y, P.x, NR, NC);
                LocalProcMask=UtilFunFPA.LocalNeighbourhood(this.procMask, NV, P.y, P.x, NR, NC);
                RGBVal=g(P.y, P.x, :);
                
                %re-calculate starting delta from the 2*NVd0+1 neigbouhood of P
                NVd0=3;
                ld=UtilFunFPA.LocalNeighbourhood(this.DeltaMap, NVd0, P.y, P.x, NR, NC);
                lm=UtilFunFPA.LocalNeighbourhood(this.procMask, NVd0, P.y, P.x, NR, NC);
                
                d=ld(lm==1);
                N=length(d);
                
                %d0=mean(d);
                %aqui extrapolamos con el plano de  mejor ajuste
                if N<(NVd0+1) %order zero z = c
                    d0=mean(d);
                else %order 1 z = ax + by + c.
                    [y, x]=find(lm==1);
                    xyz=[x, y, d];
                    B = [ones(N,1), xyz(:,1:2)] \ xyz(:,3);
                    a = B(2); b = B(3); c = B(1);
                    d0=a*(NVd0+1) + b*(NVd0+1) + c ;
                end
                
                %calculate subarray of InterpRGBCalib arrounf d0 +/- dwidth in (%) of the d range
                LocalRGBCalib=this.SubArray(d0, this.InterpRGBCalib, this.dwidth);
                
                %demodulate
                [delta, ~]=this.LocalDecodeFromRGB(RGBVal, LocalRGBCalib, LocalDeltaMap, LocalProcMask, this.Lambda);
                
                %update maps
                this.DeltaMap(P.y, P.x)=delta;
                this.procMask(P.y, P.x)=1;
                
                
                %get next point
                P=pf.GetNext();
                
                %draw results
                if DRAWRESULTS
                    %this is just for drawing
                    if not(isempty(P))
                        visitedMask(P.y, P.x)=round(m/M);
                    end
                    if mod(m, M)==0
                        figure(f1); imagesc(visitedMask); title(['VisitedMask Follow Mode:' char(followMode)]);
                        drawnow
                        
                        figure(f2); imagesc(this.DeltaMap); title(['Delta:' char(followMode)]);
                        drawnow
                    end
                    m=m+1;
                end
            end
        end
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            %defalult value for public props
            this.Lambda=0;
            this.DeltaMap=[];
            this.procMask=[];
            
            this.RGBCalibMax=max(this.RGBCalib(:, 1));
            this.RGBCalibMin=min(this.RGBCalib(:, 1));
            
            this.interpFactor=5;                        
            this.InterpRGBCalib=this.interpRGBCalibration(this.RGBCalib, this.interpFactor);
            
            this.dwidth=0.015;
            
        end
        
        
        %return the 2*NPoints+1 subarray of RGBCalib centred in d0
        function LocalRGBCalib=SubArray(this, d0, RGBCalib, dwidth)
            %import OM4MClassLib.Util.*
            %callFunc=Logging.WhoCalledMe();
            callFunc='UtilFunFPALocalRGBCalib';
            
            N=length(RGBCalib(:, 1));
            %             [~, kStart]=min(abs(RGBCalib(:, 1)-d0-dwidth*(this.RGBCalibMax-this.RGBCalibMin)));
            %             if isempty(k)
            %                 retMsg=['error finding minimum in RGBCalib'];
            %                 error([callFunc, '->' retMsg]);
            %             end
            %
            %make narrow search based in the number of points before and
            %after
            %             kStart=k-NPoints;
            %             kEnd=k+NPoints;
            
            %locate indexes according to max and min values imposed by
            %dwidth
            [~, kStart]=min(abs(RGBCalib(:, 1)-(d0-dwidth*(this.RGBCalibMax-this.RGBCalibMin))));
            if isempty(kStart)
                retMsg=['error finding kStart in RGBCalib'];
                error([callFunc, '->' retMsg]);
            end
            
            [~, kEnd]=min(abs(RGBCalib(:, 1)-(d0+dwidth*(this.RGBCalibMax-this.RGBCalibMin))));
            if isempty(kEnd)
                retMsg=['error finding kEnd in RGBCalib'];
                error([callFunc, '->' retMsg]);
            end
            
            if kStart<=0
                kStart=1;
            end
            
            if kEnd>N
                kEnd=N;
            end
            
            LocalRGBCalib=RGBCalib(kStart:kEnd, :);
            
        end
    end
    
    %% static methods
    methods(Static)
        %this function calculates the RGB calibration from a RGB image g,
        %with valid values en roiMask and a value for each pixel of
        %DeltaMap
        function [RGBCalib, RGBCalibSigma]=ExtractRGBCalib(g, roiMask, DeltaMap)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            if isscalar(g) || isscalar(roiMask) || isscalar(DeltaMap)
                retErrorMsg=['RGB image and/or roiMask must be a matrix>'  callFunc];
                error([class(this) '->' retErrorMsg])
            end
            
            [~, ~, NP]=size(g);
            if NP~=3
                retErrorMsg=['input image must be RGB>'  callFunc];
                error([class(this) '->' retErrorMsg])
            end
            
            %decimate inputs
            DF=1; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);
            DeltaMap=DeltaMap(1:DF:end, 1:DF:end);
            
            %vectorizamos valores en roiMask
            R=g(:, :, 1);
            G=g(:, :, 2);
            B=g(:, :, 3);
            
            dmin=min(DeltaMap(roiMask==1)); if dmin<0, dmin=0; end;
            dmax=max(DeltaMap(roiMask==1));
            Nd=500;
            d=linspace(dmin, dmax, Nd+1)';
            r=zeros(Nd, 1); g=r; b=r;
            sigmar=r; sigmag=r; sigmab=r;
            for n=1:Nd
                m=(DeltaMap<d(n+1)) & (DeltaMap>d(n));
                
                
                r(n)=median(R(m)); sigmar(n)=std(double(R(m)));
                g(n)=median(G(m)); sigmag(n)=std(double(G(m)));
                b(n)=median(B(m)); sigmab(n)=std(double(B(m)));
                
                %AQDEBUG
                %imagesc(100*m + double(R).*roiMask); figure(gcf)
                %figure; plot(R(m)); figure(gcf);
            end
            d=d(1:Nd);
            
            
            RGBCalib=[d, r, g, b];
            RGBCalibSigma=[d, sigmar, sigmag, sigmab];
        end
        
        
        
        % Matlab implementation of the RGB calibration demodulation
        %
        % INPUT:
        %
        %   LocalDeltaMap mapa local con los valores ya medidos de retardo (para el termino de regularizacion)
        %   LocalProcMask mask  indicar los puntos que ya estan procesados en LocalDeltaMap
        %   lambda es el parametro de regularizacion
        %   RGBVal  [1x3] valor RGB para el que se quiere calcular el retardo
        %   LocalDeltaMap [NVecxNVec] mapa local con los valores ya medidos de retardo (para el termino de regularizacion)
        %   LocalProcMask [NVecxNVec] mascara que indica los puntos que ya estan procesados en LocalDeltaMap
        %
        % Outputs:
        %   delta: [1x1] calulated retardation for RGBVal from LocalRGBCalib
        %   Umin: value for the functional
        %
        %REFERENCES
        %
        % [1] Juan Antonio Quiroga, Ángel Garc??a-Botella, and José Antonio Gómez-Pedrero, "Improved method for isochromatic demodulation by RGB calibration," Appl. Opt. 41, 3461-3468 (2002)
        %
        %   AQ 7/6/2018
        %   Copyright 2010 IOT
        %   $ Revision: 1.0.0.0 $
        %   $ Date: 1/6/18 $
        function  [delta, Umin]=LocalDecodeFromRGB(RGBVal, LocalRGBCalib, LocalDeltaMap, LocalProcMask, Lambda)
            %separamos valores R, G, B
            R=RGBVal(:,:,1);
            G=RGBVal(:,:,2);
            B=RGBVal(:,:,3);
            
            %separamos calibracion en R, G y B
            RC=LocalRGBCalib(:, 2);
            GC=LocalRGBCalib(:, 3);
            BC=LocalRGBCalib(:, 4);
            
            %separanos calibracion en delta
            deltaC=LocalRGBCalib(:, 1);
            
            %vectorizamos
            d=LocalDeltaMap(:);
            m=LocalProcMask(:);
            %aqui se calcula el sumatorio sobre la vencidad del termino de
            %regularizacion para todos los valores de RetC (la tabla RGB)
            if Lambda~=0
                Reg=0;
                for i=1:length(d)
                    Reg=Reg+m(i).*(d(i)-deltaC).^2;
                end
            else
                Reg=0;
            end
            
            %aqui se calcula el valor de U para todos los valores RGB de la tabla RC, BC, GC, dado
            %el valor R, G, B del punto de interes
            %esto genera un vector, cuyo minimo indica el indice del retardo que hay
            %que asignar en el punto de interes
            U=(R-RC).^2+(B-BC).^2+(G-GC).^2+Lambda*Reg;
            
            [Umin, k]=min(U);
            delta=deltaC(k);
        end
        
        function InterpRGBCalib=interpRGBCalibration(RGBCalib, interpFactor)
            %interp RGB Calibration
            %interpolamos la calibracion
            dC=RGBCalib(:, 1); %retar from calibration
            dCi=linspace(min(dC), max(dC), interpFactor*length(dC))'; %interpolated retar from calibration
            InterpRGBCalib=zeros(length(dCi), 4);
            InterpRGBCalib(:, 1)=dCi;
            for n=2:4
                gC=RGBCalib(:, n); %channels from calibration
                gCi=interp1(dC, gC, dCi, 'spline'); %interpolated channels from calibration
                InterpRGBCalib(:, n)=gCi;
            end
            
        end
        
    end
    
end