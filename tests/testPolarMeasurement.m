classdef testPolarMeasurement < matlab.unittest.TestCase
    % testPolarMeasurement tests PolarMeasurement (combined isoclinic
    % angle + retardation photoelastic measurement pipeline)
    %run(testPolarMeasurement)
    
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            setupPath();
        end
    end
    
    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m), not MATLAB's factory path
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end
    
    
    methods (Test)
        
        function testDemodRetarSimulImages(testCase)
            % testDemodRetarSimulImages runs PolarMeasurement's full
            % isoclinic-angle + retardation chain on synthetic fringe
            % patterns for a teoretical loaded-disk stress distribution,
            % visually comparing the measured maps against the
            % theoretical ones
            %run(testPolarMeasurement, 'testDemodRetarSimulImages')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %here we test a complete angle and retardation measurement
            %using simulated fringe patterns from a loaded disk
            
            NR=568;
            NC=576;
            
            %teo stress distribution for a loaded disk
            [delta, w2alpha, sx, sy, sxy, s1, s2, M]=UtilFunFPA.StressDisk(NR, NC);
            w4alpha=angle(exp(1i*2*w2alpha));
            
            %isoclinic demodulator
            alphaDem=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            alphaDem.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
            %set the variation range to pi/2 for isoclinics
            alphaDem.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %delta demodulator
            deltaDem=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA);
            
            %phase unwrapper
            deltaPu=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            
            %create PolarMeasurement
            PM=PolarMeasurement(alphaDem, deltaDem, deltaPu);
            %set ROI
            PM.M=M;
            
            
            steps=PM.GetAlphaSteps();
            nl=1;%noise level
            %generate LBF patterns
            PM.alphaImList=UtilFunFPA.LBFPattern(delta, 0.5*w2alpha, steps, PM.M, nl);
            PM.calc4Alpha();
            
            
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*angle(PM.z4alpha), D, sameColorFlag); title('w4alpha Measured');
            UtilFunFPA.DrawAlpha(0.25*w4alpha, D, sameColorFlag); title('w4alpha Teoretical');
            
            unwrapp2Alpha=true;
            PM.calc2Alpha(unwrapp2Alpha);
            
            
            UtilFunFPA.DrawAlpha(0.5*angle(PM.z2alpha), D, sameColorFlag); title('w2alpha Measured');
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColorFlag); title('w2alpha Teoretical');
            
            %get retar steps
            steps=PM.GetDeltaSteps();
            
            %in this case steps is a List of position for the circular
            %polariscope P Q1 Q2 A
            N=length(steps);
            phi=zeros(1, N);
            psi=zeros(1,N);
            for n=1:N
                PQQA=steps{n};
                phi(n)=pi*PQQA(3)/180;
                psi(n)=pi*PQQA(4)/180;
            end
            
            %generate images
            PM.deltaImList=UtilFunFPA.CircPol(delta, w2alpha, psi, phi, M);
            
            PM.calcWrapRetar();
            figure; imagesc(angle(PM.zdelta)); title('mesured Retar'); colormap gray
            figure; imagesc(angle(exp(1i*delta))); title('Teo Retar'); colormap gray
            
            %unwrapp result
            PM.calcUnwRetar();
            figure; imagesc(PM.udelta.*PM.M); title('Measured Retar'); colormap jet
            
        end
        
        
        function testSaveLoad(testCase)
            % testSaveLoad runs a partial isoclinic + wrapped-retardation
            % measurement, then checks PolarMeasurement.save/load
            % round-trips every property unchanged, both with the
            % default file name and with an explicit one
            %run(testPolarMeasurement, 'testSaveLoad')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %here we test a complete angle and retardation measurement
            %using simulated fringe patterns from a loaded disk
            
            NR=568;
            NC=576;
            
            %teo stress distribution for a loaded disk
            [delta, w2alpha, sx, sy, sxy, s1, s2, M]=UtilFunFPA.StressDisk(NR, NC);
            w4alpha=angle(exp(1i*2*w2alpha));
            
            %isoclinic demodulator
            alphaDem=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            alphaDem.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
            %set the variation range to pi/2 for isoclinics
            alphaDem.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %delta demodulator
            deltaDem=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA);
            
            %phase unwrapper
            deltaPu=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            
            %create PolarMeasurement
            PM=PolarMeasurement(alphaDem, deltaDem, deltaPu);
            %set ROI
            PM.M=M;
            
            
            steps=PM.GetAlphaSteps();
            nl=1;%noise level
            %generate LBF patterns
            PM.alphaImList=UtilFunFPA.LBFPattern(delta, 0.5*w2alpha, steps, PM.M, nl);
            PM.calc4Alpha();
            
            unwrapp2Alpha=false;
            PM.calc2Alpha(unwrapp2Alpha);
            
            %get retar steps
            steps=PM.GetDeltaSteps();
            
            %in this case steps is a List of position for the circular
            %polariscope P Q1 Q2 A
            N=length(steps);
            phi=zeros(1, N);
            psi=zeros(1,N);
            for n=1:N
                PQQA=steps{n};
                phi(n)=pi*PQQA(3)/180;
                psi(n)=pi*PQQA(4)/180;
            end
            
            %generate images
            PM.deltaImList=UtilFunFPA.CircPol(delta, w2alpha, psi, phi, M);
            PM.calcWrapRetar();
            
            
            % save and load test
            PolarMeasurement.save(PM);
            
            fileName=PolarMeasurement.defFileName4Saving;;
            testCase.assertTrue( exist(fileName, 'file')==2 );
            
            PM2=PolarMeasurement.load(fileName);
            
            %check all the props are equal
            propList=properties(PM);
            for n=1:length(propList)
                testCase.assertEqual(PM2.(propList{n}), PM.(propList{n}));
            end
            
            clear('PM2');
            delete(fileName);
            
            %given fileName
            fileName='AQTestPM.mat';
            PolarMeasurement.save(PM, fileName);
            testCase.assertTrue( exist(fileName, 'file')==2 );
            
            PM2=PolarMeasurement.load(fileName);
            
            %check all the props are equal
            propList=properties(PM);
            for n=1:length(propList)
                testCase.assertEqual(PM2.(propList{n}), PM.(propList{n}));
            end
            
            
            delete(fileName);
            
        end
        
        
        function testDemodRetarDisk(testCase)
            % testDemodRetarDisk runs PolarMeasurement's full isoclinic
            % angle + retardation chain (including phasor filtering and
            % ROI auto-detection via calcROI) on real acquired fringe
            % patterns of a loaded disk (DiscoPolariscopio fixtures)
            %run(testPolarMeasurement, 'testDemodRetarDisk')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            baseDir=fullfile(fixturesRoot(),'DiscoPolariscopio');
            
            %here we test a complete angle and retardation measurement
            
            %isoclinic demodulator
            alphaDem=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            alphaDem.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %set the variation range to pi/2 for isoclinics
            alphaDem.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %delta demodulator
            deltaDem=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA);
            
            %phase unwrapper
            deltaPu=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %create PolarMeasurement
            PM=PolarMeasurement(alphaDem, deltaDem, deltaPu);
            
            %AQDEBUG set ROI manually (see calcROI bellow)
            %MaskFileName='Mask.mat';
            %S=load(fullfile(baseDir,MaskFileName), 'BW');
            %PM.M=S.BW;
            
            %just for document
            steps=PM.GetAlphaSteps();
            %generate LBF patterns and calc 4alpha
            isoclinMeasure='Isoclin4PSBlanca.mat';
            S=load(fullfile(baseDir, isoclinMeasure));
            PM.alphaImList=S.isoclinIm;
            PM.calc4Alpha();
            
            %filter phase
            PM.NFilt=20;
            PM.filtPhasor(PolarMeasPhasorType.z4alpha);
            
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*angle(PM.z4alpha), D, sameColorFlag); title('w4alpha Measured');            
            
            %calculate ROI from z4alpha
            %the normalized threshold is controlled by this.ROINormTH
            PM.calcROI(PolarMeasPhasorType.z4alpha);
            
            %calc 2alpha
            unwrapp2Alpha=true;
            PM.calc2Alpha(unwrapp2Alpha);
            
            
            UtilFunFPA.DrawAlpha(0.5*angle(PM.z2alpha), D, sameColorFlag); title('w2alpha Measured');
            
            %get retar steps just for documentation
            steps=PM.GetDeltaSteps();
            
            %in this case steps is a List of position for the circular
            %polariscope P Q1 Q2 A
            N=length(steps);
            phi=zeros(1, N);
            psi=zeros(1,N);
            for n=1:N
                PQQA=steps{n};
                phi(n)=pi*PQQA(3)/180;
                psi(n)=pi*PQQA(4)/180;
            end
            
            %generate images
            retarMeasure='Isochrom8PSNa.mat';
            S=load(fullfile(baseDir, retarMeasure));
            gList=S.isochromIm;
            for n=1:length(gList)
                t=gList{n};
                gList{n}=t(:, :, 1); %get R image for Na light
            end
            
            PM.deltaImList=gList;
            
            %calc retar
            PM.calcWrapRetar();
            figure; imagesc(angle(PM.zdelta)); title('mesured Retar'); colormap gray
            
            %unwrapp result
            PM.calcUnwRetar();
            figure; imagesc(PM.udelta.*PM.M); title('Measured Retar'); colormap jet
        end
        
        
        function testDemodRetarRing(testCase)
            % testDemodRetarRing repeats testDemodRetarDisk's isoclinic
            % angle + retardation chain on real acquired fringe patterns
            % of a loaded ring (AnilloPolariscopio fixtures)
            %run(testPolarMeasurement, 'testDemodRetarRing')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            baseDir=fullfile(fixturesRoot(),'AnilloPolariscopio');
            
            %here we test a complete angle and retardation measurement
            
            %isoclinic demodulator
            alphaDem=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            alphaDem.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %set the variation range to pi/2 for isoclinics
            alphaDem.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %delta demodulator
            deltaDem=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA);
            
            %phase unwrapper
            deltaPu=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %create PolarMeasurement
            PM=PolarMeasurement(alphaDem, deltaDem, deltaPu);
            
            %AQDEBUG set ROI manually (see calcROI bellow)
            %MaskFileName='Mask.mat';
            %S=load(fullfile(baseDir,MaskFileName), 'BW');
            %PM.M=S.BW;
            
            %just for document
            steps=PM.GetAlphaSteps();
            %generate LBF patterns and calc 4alpha
            isoclinMeasure='Isoclin4PSBlanca.mat';
            S=load(fullfile(baseDir, isoclinMeasure));
            PM.alphaImList=S.isoclinIm;
            PM.calc4Alpha();
            
            %filter phase
            PM.NFilt=5;
            PM.filtPhasor(PolarMeasPhasorType.z4alpha);
            
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*angle(PM.z4alpha), D, sameColorFlag); title('w4alpha Measured');
            
            %calculate ROI from z4alpha
            %the normalized threshold is controlled by this.ROINormTH
            PM.calcROI(PolarMeasPhasorType.z4alpha);
            
            %calc 2alpha
            unwrapp2Alpha=true;
            PM.calc2Alpha(unwrapp2Alpha);
            
            
            UtilFunFPA.DrawAlpha(0.5*angle(PM.z2alpha), D, sameColorFlag); title('w2alpha Measured');
            
            %get retar steps just for documentation
            steps=PM.GetDeltaSteps();
            
            %in this case steps is a List of position for the circular
            %polariscope P Q1 Q2 A
            N=length(steps);
            phi=zeros(1, N);
            psi=zeros(1,N);
            for n=1:N
                PQQA=steps{n};
                phi(n)=pi*PQQA(3)/180;
                psi(n)=pi*PQQA(4)/180;
            end
            
            %generate images
            retarMeasure='Isochrom8PSNa.mat';
            S=load(fullfile(baseDir, retarMeasure));
            gList=S.isochromIm;
            for n=1:length(gList)
                t=gList{n};
                gList{n}=t(:, :, 1); %get R image for Na light
            end
            
            PM.deltaImList=gList;
            
            %calc retar
            PM.calcWrapRetar();
            figure; imagesc(angle(PM.zdelta)); title('mesured Retar'); colormap gray
            
            %unwrapp result
            PM.calcUnwRetar();
            figure; imagesc(PM.udelta.*PM.M); title('Measured Retar'); colormap jet
        end
        
        
        
        function testFTTemporalDemodSimul(testCase)
            % testFTTemporalDemodSimul runs PolarMeasurement's
            % retardation-only chain with DemodulatorTypes.FTTempAnalysis
            % (spatio-temporal FT demodulation, no isoclinic step or
            % unwrapping) on a 50-frame simulated loading ramp
            %run(testPolarMeasurement, 'testFTTemporalDemodSimul')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            baseDir=fullfile(fixturesRoot(),'AnilloPolariscopio');
            
            %here we test a FT temporal demodulation 
            
            %isoclinic demodulator N/A
            alphaDem=[];
            
            %delta demodulator
            deltaDem=DemodulatorFactory.Create(DemodulatorTypes.FTTempAnalysis);
            
            %phase unwrapper for the moment N/A for spatio temporal signals
            deltaPu=[];
            %UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %create PolarMeasurement
            PM=PolarMeasurement(alphaDem, deltaDem, deltaPu);
                                    
            %generate simulated images 
            NR=168;
            NC=176;
            
            %teo stress distribution for a loaded disk (10 fringes by default
            [delta, w2alpha, ~, ~, ~, ~, ~, M]=UtilFunFPA.StressDisk(NR, NC);
            
            %retar demodulator
            dretar=DemodulatorFactory.Create(DemodulatorTypes.FTTempAnalysis);
            %set ROI
            dretar.Set(char(DemodulatorProps.M),M);
            
            % Circulular polariscope configurations
            % [ 90 45 -45   0] CBF
            % [ 90 45  45   0] CDF
            
            %set CDF
            phi=45*pi/180;
            psi=0*pi/180;
            
            tempLoad=linspace(0, 2, 50);
            NIgrams=length(tempLoad);
            gList=cell(1, NIgrams);
            for n=1:NIgrams
                gList(n)=UtilFunFPA.CircPol(delta*tempLoad(n), w2alpha, psi, phi, M);
            end
            
            %process the list           
            PM.deltaImList=gList;
            
            %calc retar
            PM.calcWrapRetar();
            figure; imagesc(angle(PM.zdelta(:,:, NIgrams-1))); title('mesured Retar'); colormap gray
            
            %unwrapp result N/A AQ debug use varargin for the case of a
            %spatio temporal signal
            %PM.calcUnwRetar();
            %figure; imagesc(PM.udelta.*PM.M); title('Measured Retar'); colormap jet
        end
        
        
        
        
        
        %         function testDemodRetarDisk(testCase)
        %             %run(testFPADemodulatorPSFotoel, 'testDemodRetarDisk')
        %             import OM4MClassLib.Util.*;
        %             fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
        %
        %             %here we test a complete angle and retardation measurement
        %             %using simulated fringe patterns from a loaded disk
        %
        %
        %
        %             %get isoclinic angle
        %             d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
        %             %set the PSA to a 4 step method see PSFilterTypes
        %             d.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
        %             %another option is the 5 step hariraran
        %             %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
        %
        %             %set the variation range to pi/2 for isoclinics
        %             d.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
        %
        %             %get steps
        %             steps=d.GetStepValues();
        %
        %             %set ROI
        %             baseDir=fullfile(fixturesRoot(),'DiscoPolariscopio');
        %             MaskFileName='Mask.mat';
        %             S=load(fullfile(baseDir,MaskFileName), 'BW');
        %             M=S.BW;
        %             d.Set(char(DemodulatorProps.M),M);
        %
        %             %generate LBF patterns
        %             isoclinMeasure='Isoclin4PSBlanca.mat';
        %             S=load(fullfile(baseDir, isoclinMeasure));
        %             FPList=S.isoclinIm;
        %
        %             %demodulate
        %             d.Process(FPList);
        %             zList=d.Get(char(DemodulatorProps.zList));
        %             z4alphaM=zList{1};
        %             z4alphaM=conv2(z4alphaM, ones(30,30)/900, 'same'); %phasor filtering
        %             w4alphaM=angle(z4alphaM);
        %
        %             %unwrap w4alpha
        %             QM=mat2gray(abs(z4alphaM)); %relacion se�al ruido: la calidad
        %             %M=M.*(abs(z4alphaM)>30);
        %             [NR, NC, ~]=size(FPList{1});
        %             QM(round(0.5*NR), round(0.5*NC))=2; %setting starting point
        %             t=5; % neighbouhood 2t+1
        %             mu=1; % regularization
        %             w2alphaM=UtilFunFPA.Calc2Alpha(w4alphaM,QM,M,t,mu);
        %             %w2alphaM=w4alphaM; %AQTesting
        %
        %             D=20;
        %             sameColorFlag=false;
        %             UtilFunFPA.DrawAlpha(0.25*w4alphaM, D, sameColorFlag); title('w4alpha Measured');
        %             UtilFunFPA.DrawAlpha(0.5*w2alphaM, D, sameColorFlag); title('w2alpha Measured');
        %
        %             z2alphaM=QM.*exp(1i*w2alphaM); %Measured isoclinic phasor
        %
        %
        %             %retar demodulator
        %             dretar=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA);
        %             %set ROI
        %             dretar.Set(char(DemodulatorProps.M),M);
        %             %get steps
        %             steps=dretar.GetStepValues();
        %
        %             %in this case steps is a List of position for the circular
        %             %polariscope P Q1 Q2 A
        %             N=length(steps);
        %             phi=zeros(1, N);
        %             psi=zeros(1,N);
        %             for n=1:N
        %                 PQQA=steps{n};
        %                 phi(n)=pi*PQQA(3)/180;
        %                 psi(n)=pi*PQQA(4)/180;
        %             end
        %
        %             baseDir=fullfile(fixturesRoot(),'DiscoPolariscopio');
        %             retarMeasure='Isochrom8PSNa.mat';
        %             S=load(fullfile(baseDir, retarMeasure));
        %             gList=S.isochromIm;
        %             for n=1:length(gList)
        %                 t=gList{n};
        %                 gList{n}=t(:, :, 1); %get R image for Na light
        %             end
        %
        %             %set 2alpha
        %             dretar.Set(char(DemodulatorProps.z2alpha), z2alphaM);
        %
        %             %demodulate retar
        %             dretar.Process(gList);
        %             zList=dretar.Get(char(DemodulatorProps.zList));
        %             zdelta=zList{1};
        %             wdeltaM=angle(zdelta);
        %
        %             figure; imagesc(wdeltaM); title('mesured Retar'); colormap gray
        %
        %             %Unwrapp delta
        %             u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
        %
        %             %process
        %             u.Process(wdeltaM, M, M);
        %             %get results
        %             deltaM=u.Get(char(UnwrapperProps.unw));
        %             figure; imagesc(deltaM.*M); title('Measured Retar'); colormap jet
        %
        %
        %         end
        %
        %
        %         function testDemodRetarRing(testCase)
        %             %run(testFPADemodulatorPSFotoel, 'testDemodRetarRing')
        %             import OM4MClassLib.Util.*;
        %             fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
        %
        %             %here we test a complete angle and retardation measurement
        %             %using simulated fringe patterns from a loaded disk
        %
        %
        %
        %             %get isoclinic angle
        %             d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
        %             %set the PSA to a 4 step method see PSFilterTypes
        %             d.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
        %             %another option is the 5 step hariraran
        %             %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
        %
        %             %set the variation range to pi/2 for isoclinics
        %             d.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
        %
        %             %get steps
        %             steps=d.GetStepValues();
        %
        %             %set ROI
        %             baseDir=fullfile(fixturesRoot(),'AnilloPolariscopio');
        %             MaskFileName='Mask.mat';
        %             S=load(fullfile(baseDir,MaskFileName), 'BW');
        %             M=S.BW;
        %             d.Set(char(DemodulatorProps.M),M);
        %
        %             %generate LBF patterns
        %             isoclinMeasure='Isoclin4PSBlanca.mat';
        %             S=load(fullfile(baseDir, isoclinMeasure));
        %             FPList=S.isoclinIm;
        %
        %             %demodulate
        %             d.Process(FPList);
        %             zList=d.Get(char(DemodulatorProps.zList));
        %             z4alphaM=zList{1};
        %             z4alphaM=conv2(z4alphaM, ones(5,5)/25, 'same'); %phasor filtering
        %             w4alphaM=angle(z4alphaM);
        %
        %             %unwrap w4alpha
        %             QM=mat2gray(abs(z4alphaM)); %relacion se�al ruido: la calidad
        %             %M=M.*(abs(z4alphaM)>30);
        %             [NR, NC, ~]=size(FPList{1});
        %             QM(round(0.5*NR), round(0.5*NC))=2; %setting starting point
        %             t=5; % neighbouhood 2t+1
        %             mu=1; % regularization
        %             w2alphaM=UtilFunFPA.Calc2Alpha(w4alphaM,QM,M,t,mu);
        %             %w2alphaM=w4alphaM; %AQTesting
        %
        %             D=20;
        %             sameColorFlag=false;
        %             UtilFunFPA.DrawAlpha(0.25*w4alphaM, D, sameColorFlag); title('w4alpha Measured');
        %             UtilFunFPA.DrawAlpha(0.5*w2alphaM, D, sameColorFlag); title('w2alpha Measured');
        %
        %             z2alphaM=QM.*exp(1i*w2alphaM); %Measured isoclinic phasor
        %
        %
        %             %retar demodulator
        %             dretar=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA);
        %             %set ROI
        %             dretar.Set(char(DemodulatorProps.M),M);
        %             %get steps
        %             steps=dretar.GetStepValues();
        %
        %             %in this case steps is a List of position for the circular
        %             %polariscope P Q1 Q2 A
        %             N=length(steps);
        %             phi=zeros(1, N);
        %             psi=zeros(1,N);
        %             for n=1:N
        %                 PQQA=steps{n};
        %                 phi(n)=pi*PQQA(3)/180;
        %                 psi(n)=pi*PQQA(4)/180;
        %             end
        %
        %             baseDir=fullfile(fixturesRoot(),'AnilloPolariscopio');
        %             retarMeasure='Isochrom8PSNa.mat';
        %             S=load(fullfile(baseDir, retarMeasure));
        %             gList=S.isochromIm;
        %             for n=1:length(gList)
        %                 t=gList{n};
        %                 gList{n}=t(:, :, 1); %get R image for Na light
        %             end
        %
        %             %set 2alpha
        %             dretar.Set(char(DemodulatorProps.z2alpha), z2alphaM);
        %
        %             %demodulate retar
        %             dretar.Process(gList);
        %             zList=dretar.Get(char(DemodulatorProps.zList));
        %             zdelta=zList{1};
        %             wdeltaM=angle(zdelta);
        %
        %             figure; imagesc(wdeltaM); title('mesured Retar'); colormap gray
        %
        %             %Unwrapp delta
        %             u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
        %
        %             %process
        %             u.Process(wdeltaM, M, M);
        %             %get results
        %             deltaM=u.Get(char(UnwrapperProps.unw));
        %             figure; imagesc(deltaM.*M); title('Measured Retar'); colormap jet
        %
        %
        %         end
        
    end
    
end
