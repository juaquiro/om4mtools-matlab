%> @file LensMapperMeasurement.m
%> @brief this file contain the class LensMapperMeasurement used to descrive the IOT Mapper measurments
%> @details NA
%> @copyright 2016 IOT
%> @author AQ


% ======================================================================
%> @brief this class describes a complete measurement of the IOT Lens Mapper
%> @details And here we can put some more detailed informations about the class.
%> @see file testFPA_UtilFunMapperMeasure.m for unit tests with mtest
%> testFPA_UtilFunMapperMeasureClassVer for unit test with MATLAB framework
%> and UtilFunFPA.m for related functions aux functions
%> @author AQ 21MAR16
% ======================================================================
classdef LensMapperMeasurement < handle
    %% public props
    properties
        %> fringe pattern (it can be a cell array) g=b+m*cos(2*pi/Tx*(Deltax*Z + w0)*x))
        g;
        %> reference fringe pattern (it can be a cell array) gr=b+m*cos(2*pi/Tx*w0*x))
        gr;
        %> deflectometric phasor X direction zx=bx*exp(i*phix) phix=2*pi/Tx*Deltax*Z,
        zx;
        %> deflectometric phasor Y direction zy=by*exp(i*phiy) phiy=2*pi/Ty*Deltay*Z,
        zy;
        %> sqrt(abs(zx)^2+abs(zy)^2)
        zAbs;
        %> x carrier phasor zrx=bx*exp(2*pi/Tx*w0*x)
        zrx;
        %> y carrier phasor zry=by*exp(2*pi/Ty*w0*y)
        zry;
        %>  sphere
        S,
        %>  cylinder
        C,
        %>  axis
        A,
        %>  medium or equivalent sphere
        Seq,
        %>  xx comp of the DPM
        Pxx ,
        %>  yy comp of the DPM
        Pyy,
        %>  xy comp of the DPM
        Pxy,
        %>  yx comp of the DPM
        Pyx,
        %> afther CalculatePower ROI with valid DPM values
        M,
        %> Quality map for the Dx and Dy deflections, log scale, @see GradientConsistency
        Q,
        %> Quality ma for the DPM, it checks for symetry of the DMP relative error
        Qdpm;
        %> nominal power in D, this is used only in the case of a calibration procedure with a set of monofocal lenes
        Pnom,
        %> Measurement parameters, init as empty is a structure with the
        %> relevant measurement parameters that are particular for each
        %> measurement technique
        measurementParams
    end
    
    properties (Constant)
        %> sign used for calculation of the relation between calculated
        %gradients and power
        DerSign=-1;
    end
    
    
    %% public methods
    methods
        % ======================================================================
        %> @brief constructor,
        %> @details NA
        %> @author AQ
        % ======================================================================
        function this = LensMapperMeasurement()
            this.Init();
        end
        % ======================================================================
        %> @brief resets LMM props, init properties to default
        %> @details NA
        %> @param this self reference to the class
        %> @author AQ 2/6/2020
        % ======================================================================
        function this = Init(this)
            for p = properties(this)'
                %check for DerSign becauses is a constat, this is a ñapa
                %the good solution will be to  create a meta.class object using the ? operator with the class name
                if not(strcmp(p{1}, 'DerSign'))
                    this.(p{1})=[];
                end
            end
        end
        
        
        % ======================================================================
        %> @brief Calculates the DPM from the measurement
        %> @details here the phasors Dx and Dy are bx*exp(i*phix), zy=by*exp(i*phiy);
        %> @param this self reference to the class
        %> @param M ROI for calculation (optional delfault ones(size(zx)))
        %> @param K (optional def [1 1]) convesion factor between phase-rad/px to deflection*rad/mm. K is the constant in mm^-1/rad*px^-1 to transform from phase derivative to power
        %> for square pixels K is a scalar K=Kx=Ky, for non square pixels K
        %> is a 1x2 vector [Kx, Ky]
        %> @param options optional pairs of name-vales 'Nmed' (2)(px  median
        %> filter size for filtering outliers), 'NS' (1)(2*NS+1 is the
        %> neigbouhoord size for phasor filtering at the period estimation from the reference, 
        %> afther this is recalculated using the ref fringe period) fields, 'LPCycles' (2)
        %> is the number of low pass cycles used for filtering the phase
        %> derivatives, extendedRange (false) this parameter determines if
        %> filter or not the phasors zx and zy for power > 5-6 D it is
        %> recomended to set highPowerLens to false, for power higer than 6 D it
        %> is recomenden to set highPowerLens to true
        %> @see function Calibrate for K calculation
        %> @copyright 2016 IOT
        %> @author AQ 2/6/20
        %> @details NOTE: in our deflectoemter the image direction and the signs of the gradient produce a sign change of the DPM
        %> that only affects tr because t1 and t2 are squared
        %> In future mappers image direction can change and therefore the sign of tr
        % ======================================================================
        function this = CalculateLensPower(this, M, K, options)
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
               
        % ======================================================================
        %> @brief automatic calculation of the region of interest (ROI)
        %> from the phasor modulation
        %> @param options optional pairs of name-vales 'P0' (0.5*(size(M))(this point selects the label for the ROI
        %> 'GVTh' (10)(threshold for zrx and zry, 'seSize' (20)
        %> structuring ellement sise for closing and opening the mask,
        %> 'normModTh' (0.5) normalized modulation threshold
        %> @author AQ
        %> @copyright 2016 IOT
        % ======================================================================
        function this=calculateROIFromPhasor(this, options)
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
        
        
        % ======================================================================
        %> @brief converts structure s to an object of class LensMapperMeasurement.
        %> @details This function copy the fields of struct s into the
        %> public properties of LMM that have the same name
        %> @param this self reference to the class
        %> @param s input struct
        %> @see LensMapperMeasurement.load and LensMapperMeasurement.save
        %> @copyright 2016 IOT
        %> @author AQ 2/6/20
        % ======================================================================
        function this = struct2class(this, s)
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
        
        % ======================================================================
        %> @brief converts LMM public properties to a structure s
        %> @details This function copy the public propuierties of LMM to a
        %> struct using the same names
        %> @param this self reference to the class
        %> @param s input struct
        %> @see LensMapperMeasurement.load and LensMapperMeasurement.save
        %> @copyright 2016 IOT
        %> @author AQ 2/6/20
        % ======================================================================
        function s = class2struct(this)
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
        
        % ======================================================================
        %> @brief this function save the object LMM and optionally accepts a fileName
        %> @details This function saves a LMM object, therefore you need in the path the LMM constructor
        %> @param LMM LensMapperMeasurement object
        %> @param varargin optional file name. Default value is set by defFileName4Saving
        %> @see LensMapperMeasurement.load
        %> @author AQ
        % ======================================================================
        function save(LMM,varargin)
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
        
        % ======================================================================
        %> @brief this function loads a LMM object from fileName
        %> @details This function loads a LMM object, therefore you need in the path the LMM constructor
        %> @param fileName file with the LMM object
        %> @see LensMapperMeasurement.save
        %> @author AQ
        % ======================================================================
        function LMM=load(fileName)
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
            LMMClassName='LensMapperMeasurement';
            fileName=[LMMClassName '_' date '.mat'];
        end
        
        
        % ======================================================================
        %> @brief calibration between rad/px and D
        %> @details here we assume that a list of calibrated monofocal
        %> lenses is input with known power in D. Rhe output is the calibration
        %> param such P(mm^-1)=polyval(Km P(rad/px)); aditionally Calibrate returns
        %> Pmr(n) an array with the mean power in rad/px (using K=1) and Pnd(n) the nominal power in mm^-1
        %> @param LMMList cell list of LMM of monofocal lenses with known paraxial power at the center
        %> @param varargin optional input parameters, verbose(true) shows
        %> fitting results
        %> @retval K calibration param
        %> @retval Pmr cell array with the mean power in rad/px
        %> @retval Pnd cell array with the mean power in mm^-1
        %> @see LensMapperMeasurement.save
        %> @author AQ
        % ======================================================================
        function [K, Pmrx, Pmry, Pnd]=Calibrate(LMMList, varargin)
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