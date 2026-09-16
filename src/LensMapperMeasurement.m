classdef LensMapperMeasurement < handle
    % LensMapperMeasurement describes a complete measurement from the
    % IOT Lens Mapper deflectometer
    %
    % Description:
    %   See testFPA_UtilFunMapperMeasure.m (legacy mtest) and
    %   testFPA_UtilFunMapperMeasureClassVer (matlab.unittest) for unit
    %   tests, and UtilFunFPA.m for related auxiliary functions.
    %% public props
    properties
        g; % fringe pattern (can be a cell array): g=b+m*cos(2*pi/Tx*(Deltax*Z+w0)*x)
        gr; % reference fringe pattern (can be a cell array): gr=b+m*cos(2*pi/Tx*w0*x)
        zx; % deflectometric phasor, X direction: zx=bx*exp(i*phix), phix=2*pi/Tx*Deltax*Z
        zy; % deflectometric phasor, Y direction: zy=by*exp(i*phiy), phiy=2*pi/Ty*Deltay*Z
        zAbs; % sqrt(abs(zx)^2+abs(zy)^2)
        zrx; % X carrier phasor: zrx=bx*exp(2*pi/Tx*w0*x)
        zry; % Y carrier phasor: zry=by*exp(2*pi/Ty*w0*y)
        S, % sphere
        C, % cylinder
        A, % axis
        Seq, % medium/equivalent sphere
        Pxx , % xx component of the DPM
        Pyy, % yy component of the DPM
        Pxy, % xy component of the DPM
        Pyx, % yx component of the DPM
        M, % ROI with valid DPM values, set by CalculateLensPower
        Q, % quality map for the Dx/Dy deflections (log scale, see GradientConsistency)
        Qdpm; % quality map for the DPM (checks symmetry of the DPM relative error)
        Pnom, % nominal power in D, only used in calibration with monofocal lenses
        measurementParams % struct with measurement-technique-specific params, empty by default
    end

    properties (Constant)
        DerSign=-1; % sign used relating calculated gradients to power
    end
    
    
    %% public methods
    methods
        function this = LensMapperMeasurement()
            % LensMapperMeasurement constructs an empty measurement (see Init)
            this.Init();
        end

        function this = Init(this)
            % Init resets every property to [] (except the constant DerSign)
            for p = properties(this)'
                %check for DerSign becauses is a constat, this is a �apa
                %the good solution will be to  create a meta.class object using the ? operator with the class name
                if not(strcmp(p{1}, 'DerSign'))
                    this.(p{1})=[];
                end
            end
        end
        
        
        function this = CalculateLensPower(this, M, K, options)
            % CalculateLensPower computes the DPM (S/C/A/Seq, Pxx/Pyy/
            % Pxy/Pyx) from this.zx/zy (bx*exp(i*phix), by*exp(i*phiy))
            % and the reference phasors zrx/zry (used to estimate the
            % carrier fringe period for filtering).
            %
            % Inputs:
            %   M ROI for calculation (default ones(size(zx)))
            %   K conversion factor phase-rad/px -> deflection-rad*mm^-1
            %     (default [1 1]); scalar for square pixels, [Kx, Ky] for
            %     non-square pixels. See Calibrate for how to obtain it.
            %   options.Nmed (2) median filter size (px) for outlier removal
            %   options.NS (2) half-size of the phasor-filtering
            %     neighborhood used when estimating the carrier period
            %     (recalculated afterwards from the reference fringe period)
            %   options.LPCycles (3) number of low-pass cycles for
            %     filtering the phase derivatives
            %   options.TmedFactor (1) scales NS for the DPM gradient
            %     filtering step (unclear if actually needed beyond 1)
            %   options.highPowerLens (false) no longer used, kept for
            %     backwards compatibility only
            %   options.noRefMethod (false) for demodulation recipes
            %     (e.g. FFV) that never produce separate reference
            %     phasors: copies zx/zy into zrx/zry instead of requiring
            %     them to already be set
            %
            % Note: in this deflectometer, image direction and gradient
            % sign produce a sign change in the DPM that only affects tr
            % (t1/t2 are squared); on a future mapper with different
            % image direction, tr's sign may need to change accordingly.
            arguments
                % g must be double numeric value 
                this 
                %M must be same size zx defaults ones(size(this.zx)
                M (:, :) double {mustBeNumeric} = ones(size(this.zx))
                % K must be a 1x2 vector defaults to [1 1]
                K (1, 2) double {mustBeReal} = [1,1];
                % optional Properties NMed, NS, LPCycles must be real
                % scalar with the indcated default values
                options.Nmed (1,1) double {mustBeReal} = 2
                options.NS (1, 1) double {mustBeReal} = 2
                options.LPCycles (1, 1) double {mustBeReal} = 3
                % AQDEBUG 29JUN23 highPowerLens is no longer used keep for compatibility 
                options.highPowerLens (1,1) logical = false
                options.TmedFactor(1,1) double {mustBeReal} = 1
                %no ref mesurements like FFV do not need ref
                options.noRefMethod(1,1) logical = false
            end                    
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check 2D matrix
            if not(ismatrix(this.zx)) || not(ismatrix(this.zy)) || not(ismatrix(M))
                retMsg=['input deflections must be matrixes'];
                error([callFunc, '->' retMsg]);
            end
            
            %check for size
            Validation.mustBeEqualSize(M, this.zx);
            Validation.mustBeEqualSize(M, this.zy);      
            
                                   
            % Place optional args in memorable variable names
            Nmed=options.Nmed; %outlier removal before calculating diffferences
            NS=options.NS; %LP filter size for LPCycles
            LPCycles=options.LPCycles;  %number of LP Cycles for filtering DPM
            TmedFactor = options.TmedFactor; %AQDebug 28JUN23 this option is 1 by defect not clear necessity
            

            %if the method no needs ref simply copy zx and zy
            if options.noRefMethod
                this.zrx=this.zx;
                this.zry=this.zy;
            end


            %estimate mean fringe period of the carrier for filtering
            if not(isempty(this.zrx)||isempty(this.zry))
                LPCycles4EstimateFrec=1;
                [phirx, ~, Mphirxy]=UtilFunFPA.phaseGradientDirect(this.zrx, M, NS, Nmed, LPCycles4EstimateFrec);
                [~, phiry, ~]=UtilFunFPA.phaseGradientDirect(this.zry, M, NS, Nmed, LPCycles4EstimateFrec);
                
                wx=mean(phirx(Mphirxy)); %spatial freq in rad/px of the ref image
                wy=mean(phiry(Mphirxy)); %spatial freq in rad/px of the ref image
                px=abs(round(2*pi/wx)); %period in px on the ref image
                py=abs(round(2*pi/wy)); %period in px on the ref image     
                
                SIZEFACTOR=0.05; % field size factor for Tx an Ty at least 20 fringes/field for reference
                %check for Tx and Ty and set limkits
                [NR, NC]=size(phirx);
                if py/NR>SIZEFACTOR || px/NC>SIZEFACTOR
                    retMsg=[callFunc sprintf(' Tx and Ty to high: (%d, %d) ', px, py)];
                    warning([callFunc, '->' retMsg]);
                    %for the moment just issue a warning, but both periods
                    %can be controlled as 
                    px=3;
                    py=3;
                end                
                
            else
                  retMsg=[callFunc ' there are no reference phasors'];
                  error([callFunc, '->' retMsg]);
            end                        
            
            
            %calculate gradients of the deflection maps
            %the ROI M is changes to Mdpm (DPM matrix good values)
            %con este nivel de filtrado y LPCycles=3 (por defecto) en el run(testFPA_UtilFunMapperMeasureClassVer, 'testMejoraCaluloDPMUsingLMMClass_APR20_GeomCal')
            %usando la lente NULL sale sigma_Seq 0.01D y sigma_Cyl de 0.03
            %con un valor medio de 0.01D
            NS=max(round(0.5*px*TmedFactor), round(0.5*py*TmedFactor)); %2*NS+1 px filtrado LP derivadas por LPCycles
            [phixx, phixy, Mdpm]=UtilFunFPA.phaseGradientDirect(this.zx, M, NS, Nmed, LPCycles);
            [phiyx,phiyy, ~]=UtilFunFPA.phaseGradientDirect(this.zy, M, NS, Nmed, LPCycles);            
            
            %store the last ROI
            M=Mdpm;
                       
            %get Kx and Ky for scaling from phase-rad/px to deflection-rad*mm^-1,
            Kx=K(1);
            Ky=K(2);
            
            %change from phase-rad/px to deflection-rad*mm^-1,
            this.Pxx=Kx*phixx; %rad/px->mm^-1
            this.Pxy=Ky*phixy; %rad/px->mm^-1
            this.Pyy=Ky*phiyy; %rad/px->mm^-1
            this.Pyx=Kx*phiyx; %rad/px->mm^-1
            
            
            %de la patente "A method and apparatus for testing and mapping
            %optical elements" comentada en Papers_06
            %NOTE: in our deflectoemter the image direction and the signs of the gradient produce a sign change of the DPM
            %that only affects tr because t1 and t2 are squared
            %NOTE in future mappers image direction can change and
            %therefore the sign of tr
            t1=this.Pxx-this.Pyy; %mm^-1
            t2=this.Pxy+this.Pyx; %mm^-1
            tr=this.DerSign*(this.Pxx+this.Pyy); %mm^-1
            
            %calculate the quality of the gradients Q=0 is perfect, log
            %scale
            this.Q=UtilFunFPA.GradientConsistency(angle(this.zx),angle(this.zy));
            this.Q=log(abs(this.Q)+1);
            
            this.C=sqrt(t1.^2+t2.^2); %mm^-1
            this.S=0.5*(tr-this.C); %mm^-1
            this.Seq=0.5*tr; %mm^-1
            this.A=0.5*atan2d(t1,t2); %in deg
            this.M=M;
            
            
            this.zAbs=0.5*(abs(this.zx)+abs(this.zy));
            
            %Now from phase-rad/px to deflection-rad*mm^-1, this is becasue we calibrate from the
            %measurement of the sphere for a set of calibrated lenses, thus
            %the non-linear calculation of S, C, and Seq must be done in
            %rad/pxs and finally transformed to mm^-1
            
            %la dpm debe ser una matriz simetrica por lo tanto es una
            %matriz normal (ver wikipedia) A*conj(A)=conj(A)*A de aqui
            %de \AQ11\Programs\Matlab\DPMProperties\DPMProperties.m
            %the eigenvalue of DPM*DPM'-DPM'*DPM must be zero
            %Qdpm=0 is perfect
            this.Qdpm=abs(this.Pxy - this.Pyx);
        end
               
        function this=calculateROIFromPhasor(this, options)
            % calculateROIFromPhasor computes this.M automatically from
            % the zx/zy/zrx/zry phasor modulation: thresholds zrx/zry by
            % GVTh, thresholds the mean zx/zy modulation by normModTh,
            % combines both, opens/closes the mask (seSize), then keeps
            % only the connected region containing point P0.
            %
            % options: P0 (default 0.5*size(zrx)) point selecting which
            % labeled region becomes the ROI; GVTh (10) threshold for
            % zrx/zry; seSize (20) structuring element size for
            % opening/closing; normModTh (0.5) normalized modulation
            % threshold.
            arguments
                % is compulsory to add 'this' to the argument list
                this
                % P0 selects the Label for ROI must be a 1x2 vector defaults to 0.5*(size(M))
                options.P0 (1, 2) double {mustBeReal} = round(0.5*size(this.zrx));
                % GVTh GV threshold for umbralizn ref signals
                options.GVTh (1,1) double {mustBeReal, mustBePositive, mustBeLessThan(options.GVTh,255)} = 10
                %structural ellement size for opening and closing mask
                options.seSize (1,1) double {mustBeInteger, mustBePositive} = 20
                %normalized modulation threshold
                options.normModTh (1,1) double {mustBeReal, mustBePositive,  mustBeLessThan(options.normModTh,1)} = 0.5
            end
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check 2D matrix
            if not(ismatrix(this.zx)) || not(ismatrix(this.zy)) || not(ismatrix(this.zrx)) || not(ismatrix(this.zry))
                retMsg=['input deflections must be matrixes'];
                error([callFunc, '->' retMsg]);
            end
            
            % Place optional args in memorable variable names
            P0=options.P0;
            GVTh=options.GVTh;
            seSize=options.seSize;
            normModTh=options.normModTh;
            
            %theshold in absolute GV
            M1=abs(this.zrx)>GVTh;
            M2=abs(this.zry)>GVTh;
            
            %calculate average b (bx and by should be equal)
            %b is in [0 1] + noise
            b=0.5*(abs(this.zx)+abs(this.zy));
            %umbralize B with safe threslhold
            Mb=b>normModTh;
            
            %combine with absolute GV threlhold
            Mb=Mb.*M1.*M2;
            
            %try to create gaps
            se = strel('disk',seSize);
            Mb = imopen(Mb,se);
            
            %etiquetamos las zonas segnemtadas en Mb
            L=bwlabel(Mb);
            %escogemos la zona que coincida con un punto de control P0
            r=P0(1); c=P0(2);
            %segment P in M, close for cleaning mask and closing gaps
            ROI=(L==L(r,c)); ROI = imclose(ROI,se);
            
            this.M=ROI;
        end
        
        
        function this = struct2class(this, s)
            % struct2class copies each field of struct s into the public
            % property of this with the same name (see load/save)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %check inputs
            if not(isa(s, 'struct'))
                retMsg=['input vars must be a struct'];
                error([callFunc, '->' retMsg]);
            end
            
            %reset the class
            this.Init();
            
            %copy struct fileds to LMM public properties
            for fn = fieldnames(s)'    %enumerat fields
                try
                    if isprop(this,fn{1})
                        if not(strcmp(fn{1}, 'DerSign'))
                            this.(fn{1}) = s.(fn{1});   %and copy
                        end
                    else
                        retMsg=[fn{1} 'field is not a LensMapperMeasurement property'];
                        error([callFunc, '->' retMsg]);
                    end
                catch
                    retMsg=['Could not copy property ' fn{1}];
                    error([callFunc, '->' retMsg]);
                    
                end
            end
        end
        
        function s = class2struct(this)
            % class2struct copies every public property of this into a
            % struct field of the same name (see load/save)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %copy public props to the struct fileds
            for fn = properties(this)'    %enumerate fields
                try
                    s.(fn{1}) = this.(fn{1});   %and copy
                catch
                    retMsg=['Could not copy property ' fn{1}];
                    error([callFunc, '->' retMsg]);
                end
            end
        end
        
    end
    
    %% Static methods
    methods (Static=true)
        
        function save(LMM,varargin)
            % save writes LMM (a LensMapperMeasurement) to a .mat file,
            % converted to a struct first (see class2struct). varargin{1},
            % if given, is the file name (default: defFileName4Saving()).
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            LMMClassName='LensMapperMeasurement';
            
            if not(isa(LMM, LMMClassName))
                nameLMM = inputname(1);
                retMsg=[nameLMM ' must be a ' LMMClassName ' object'];
                error([callFunc, '->' retMsg]);
            end
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 1
                retMsg=[callFunc ' requires at most 1 optional inputs: fileName'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            % fileName
            fileName=LensMapperMeasurement.defFileName4Saving;
            optargs = {fileName};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [fileName] = optargs{:};
            
            %transform to a struct and save
            sLMM = LMM.class2struct();
            %overwrite LMM to keep the 'LMM' field name
            LMM=sLMM;
            save(fileName,'LMM');
        end
        
        function LMM=load(fileName)
            % load reads a LensMapperMeasurement from fileName, saved by
            % save() either as a struct (new format since 2020-06-02, via
            % struct2class) or as a raw LMM object (legacy format)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            LMMClassName='LensMapperMeasurement';
            
            S=load(fileName);
            
            if isa(S.LMM, 'struct') %new format starting 2JUN20
                LMM=LensMapperMeasurement;
                LMM.struct2class(S.LMM);
            else %backcompatibility
                LMM=S.LMM;
                if not(isa(LMM, LMMClassName))
                    retMsg=[fileName ' does not contain a ' LMMClassName ' object'];
                    error([callFunc, '->' retMsg]);
                end
            end
        end
        
        function fileName=defFileName4Saving()
            % defFileName4Saving returns "LensMapperMeasurement_<date>.mat"
            LMMClassName='LensMapperMeasurement';
            fileName=[LMMClassName '_' date '.mat'];
        end
        
        
        function [K, Pmrx, Pmry, Pnd]=Calibrate(LMMList, varargin)
            % Calibrate derives the rad/px -> D calibration factor K from
            % a cell array LMMList of monofocal lenses with known
            % paraxial power (LMM.Pnom), by linear-fitting (through the
            % origin) the mean measured power at each lens center
            % (K=1 rad/px) against its nominal power.
            %
            % Inputs: LMMList cell array of LensMapperMeasurement for
            % monofocal lenses; varargin{1} verbose (default false) shows
            % fitting plots.
            %
            % Outputs: K=[Kx,Ky] calibration factors (mm^-1/rad, use with
            % CalculateLensPower); Pmrx/Pmry mean measured power at each
            % lens center in rad/px; Pnd the corresponding nominal powers
            % in mm^-1.
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            LMMClassName='LensMapperMeasurement';
            
            if not(iscell(LMMList))
                retMsg=[LMMClassName ': ' inputname(1) ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            % get optional input parameters
            % only want 1 optional inputs at most
            numvarargs = length(varargin);
            if numvarargs > 1
                retMsg=[callFunc ' requires at most 1 optional inputs: verbose'];
                error([callFunc, '->' retMsg]);
            end
            
            % set defaults for optional inputs
            %some small def values just in case of low number of points
            verbose=false;
            optargs = {verbose};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            
            % Place optional args in memorable variable names
            [verbose] = optargs{:};
            
            
            N=length(LMMList);
            D=5; %size mask in px
            Pmrx=zeros(1, N+1); %the N+1 is always (0,0)
            Pmry=zeros(1, N+1); %the N+1 is always (0,0)
            Pnd=zeros(1, N+1);
            for n=1:N
                LMM=LMMList{n};
                M=mat2gray(LMM.M);
                [y,x] = find(M) ;
                xm=round(mean(x));
                ym=round(mean(y));
                
                c=xm-D:xm+D; %square arrounf xm, ym
                r=ym-D:ym+D;
                %they are monofocal lenses and the DPM=P*eye(2)
                Px=LMM.Pxx(r,c); %power at the center
                Py=LMM.Pyy(r,c); %power at the center
                PM=(M(r,c)==1); %check if any ellement inside is masked
                
                %the minus sign comes from the chosen sign for tr in
                %the function CalculateLensPower
                Pmrx(n)=LMMList{1}.DerSign*mean(Px(PM)); %mean power in rad/px (using K=1)
                Pmry(n)=LMMList{1}.DerSign*mean(Py(PM)); %mean power in rad/px (using K=1)
                Pnd(n)=LMM.Pnom; %nominal power in mm^-1 (DPM=Pnom*eye(2))
                
            end
            
            %linear fit to data with intercept at origin
            %1) X dir
            x = Pmrx; y = Pnd;
            Kx = x(:)\y(:); % Estimate Parameter: K*Pmr = Pnd; K is in mm^-1/rad
            
            %2) Y dir
            x = Pmry; y = Pnd;
            Ky = x(:)\y(:); % Estimate Parameter: K*Pmr = Pnd; K is in mm^-1/rad
            
            %return K
            K=[Kx, Ky];
            
            if verbose
                AQDEBUG=false;
                if AQDEBUG
                    disp('measured Px Power in rad/px at the center');
                    disp(Pmrx);
                    
                    disp('mesured Px Power in mm^-1 at the center');
                    disp(Kx*Pmrx);
                    
                    disp('measured Py Power in rad/px at the center');
                    disp(Pmry);
                    
                    disp('mesured Py Power in mm^-1 at the center');
                    disp(Ky*Pmry);
                    
                    disp('Nominal power in mm^-1');
                    disp(Pnd);
                end
                
                %1) X dir
                figure;
                [xb, k]=unique(1000*Pnd);
                yb=1000*Kx*Pmrx(k);
                bar(xb, xb-yb); xlabel('Nominal P_{xx} (D)'); ylabel('\DeltaP_{xx} (D) Nominal-Measured');
                
                %2) Y Dir
                figure;
                yb=1000*Ky*Pmry(k);
                bar(xb, xb-yb); xlabel('Nominal P_{yy} (D)'); ylabel('\DeltaP_{yy} (D) Nominal-Measured');
                
                %1) X Dir
                x=linspace(min(Pmrx), max(Pmrx), 100);
                y=Kx*x;
                figure; plot(Pmrx, 1000*Pnd, 'o', x,1000*y, '.');
                ylabel('P_{xx} (D)'); xlabel('P_{xx} (rad/px)');
                title(sprintf('K_x=%d', Kx));
                grid on;
                
                %2) Y Dir
                x=linspace(min(Pmry), max(Pmry), 100);
                y=Ky*x;
                figure; plot(Pmry, 1000*Pnd, 'o', x,1000*y, '.');
                ylabel('P_{yy} (D)'); xlabel('P_{yy} (rad/px)');
                title(sprintf('K_y=%d', Ky));
                grid on;
                
            end
        end              
   
        
    end
    
end