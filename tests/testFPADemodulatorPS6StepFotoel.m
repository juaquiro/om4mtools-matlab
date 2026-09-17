classdef testFPADemodulatorPS6StepFotoel < matlab.unittest.TestCase
    % testFPADemodulatorPS6StepFotoel tests the photoelastic
    % isoclinic-angle + retardation measurement chain (DemodulatorTypes.
    % TimePSA + DemodulatorTypes.RetarPSA6Step)
    %run(testFPADemodulatorPS6StepFotoel)
    
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
        function testAllDemodulatorsConstructors(testCase)
            % testAllDemodulatorsConstructors builds every DemodulatorTypes
            % variant via the factory and checks every DemodulatorProps
            % Get() call succeeds
            %run(testFPADemodulatorPS6StepFotoel, 'testAllDemodulatorsConstructors')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            %dt types and dn are names for demodulators
            [dt, dn]=enumeration('DemodulatorTypes');
            for n=1:length(dn)
                d=DemodulatorFactory.Create(dt(n));
                
                testCase.assertTrue(isa(d, 'Demodulator'));
                
                %check that you can make a get all props
                [~, pn]=enumeration('DemodulatorProps');
                for m=1:length(pn)
                    p=d.Get(pn{m});
                end
            end
        end
        
        function testDemodRetarSimulImages(testCase)
            % testDemodRetarSimulImages runs the full isoclinic angle +
            % retardation chain on synthetic fringe patterns for a
            % teoretical loaded-disk stress distribution
            % (UtilFunFPA.StressDisk), unwrapping 2*alpha and delta and
            % comparing the measured maps against the theoretical ones
            %run(testFPADemodulatorPS6StepFotoel, 'testDemodRetarSimulImages')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %here we test a complete angle and retardation measurement
            %using simulated fringe patterns from a loaded disk
            
            NR=568;
            NC=576;
            
            %teo stress distribution for a loaded disk
            [delta, w2alpha, sx, sy, sxy, s1, s2, M]=UtilFunFPA.StressDisk(NR, NC);
            w4alpha=angle(exp(1i*2*w2alpha));
            
            %get isoclinic angle
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
            
            %set the variation range to pi/2 for isoclinics
            d.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %set ROI
            d.Set(char(DemodulatorProps.M),M);
            
            %get steps
            steps=d.GetStepValues();
            nl=0;%noise level
            %generate LBF patterns
            FPList=UtilFunFPA.LBFPattern(delta, 0.5*w2alpha, steps, M, nl);
            
            %demodulate
            d.Process(FPList);
            zList=d.Get(char(DemodulatorProps.zList));
            z4alphaM=zList{1};
            w4alphaM=angle(z4alphaM);
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*w4alphaM, D, sameColorFlag); title('w4alpha Measured');
            UtilFunFPA.DrawAlpha(0.25*w4alpha, D, sameColorFlag); title('w4alpha Teoretical');
            
            %unwrap w4alpha
            QM=mat2gray(abs(z4alphaM)); %relacion se�al ruido: la calidad
            QM(round(0.5*NR), round(0.5*NC))=2; %setting starting point
            t=5; % neighbouhood 2t+1
            mu=1; % regularization
            w2alphaM=UtilFunFPA.Calc2Alpha(w4alphaM,QM,M,t,mu);
            %w2alphaM=0.5*w4alphaM; just to check in case of not unwrapping
            %4alpha
            z2alphaM=QM.*exp(1i*w2alphaM); %Measured isoclinic phasor
            
            UtilFunFPA.DrawAlpha(0.5*w2alphaM, D, sameColorFlag); title('w2alpha Measured');
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColorFlag); title('w2alpha Teoretical');
            
            %retar demodulator
            dretar=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA6Step);
            %set ROI
            dretar.Set(char(DemodulatorProps.M),M);
            %get steps
            steps=dretar.GetStepValues();
            
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
            
            gList=UtilFunFPA.CircPol(delta, w2alpha, psi, phi, M);
            dretar.Set(char(DemodulatorProps.z2alpha), z2alphaM);
            
            %demodulate retar
            dretar.Process(gList);
            zList=dretar.Get(char(DemodulatorProps.zList));
            zdelta=zList{1};
            wdeltaM=angle(zdelta);
            
            figure; imagesc(wdeltaM); title('mesured Retar'); colormap gray
            figure; imagesc(angle(exp(1i*delta))); title('Teo Retar'); colormap gray
            
            %Unwrapp delta
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %process
            u.Process(wdeltaM, M, M);
            %get results
            deltaM=u.Get(char(UnwrapperProps.unw));
            figure; imagesc(deltaM.*M); title('Measured Retar'); colormap jet
            
            
        end
        
        function testDemodRetarDisk(testCase)
            % testDemodRetarDisk runs the isoclinic angle + retardation
            % chain on real acquired fringe patterns of a loaded disk
            % (DiscoPolariscopio fixtures) and unwraps the measured
            % retardation
            %run(testFPADemodulatorPS6StepFotoel, 'testDemodRetarDisk')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %here we test a complete angle and retardation measurement
            %using simulated fringe patterns from a loaded disk
            
            
            
            %get isoclinic angle
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            d.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
            
            %set the variation range to pi/2 for isoclinics
            d.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %get steps
            steps=d.GetStepValues();
            
            %set ROI
            baseDir=fullfile(fixturesRoot(),'DiscoPolariscopio');
            MaskFileName='Mask.mat';
            S=load(fullfile(baseDir,MaskFileName), 'BW');
            M=S.BW;
            d.Set(char(DemodulatorProps.M),M);
            
            %generate LBF patterns
            isoclinMeasure='Isoclin4PSBlanca.mat';
            S=load(fullfile(baseDir, isoclinMeasure));
            FPList=S.isoclinIm;
            
            %demodulate
            d.Process(FPList);
            zList=d.Get(char(DemodulatorProps.zList));
            z4alphaM=zList{1};
            z4alphaM=conv2(z4alphaM, ones(30,30)/900, 'same'); %phasor filtering            
            w4alphaM=angle(z4alphaM);                                                          
            
            %unwrap w4alpha
            QM=mat2gray(abs(z4alphaM)); %relacion se�al ruido: la calidad
            %M=M.*(abs(z4alphaM)>30);
            [NR, NC, ~]=size(FPList{1});
            QM(round(0.5*NR), round(0.5*NC))=2; %setting starting point
            t=5; % neighbouhood 2t+1
            mu=1; % regularization
            w2alphaM=UtilFunFPA.Calc2Alpha(w4alphaM,QM,M,t,mu);
            %w2alphaM=w4alphaM; %AQTesting
            
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*w4alphaM, D, sameColorFlag); title('w4alpha Measured');
            UtilFunFPA.DrawAlpha(0.5*w2alphaM, D, sameColorFlag); title('w2alpha Measured');
            
            z2alphaM=QM.*exp(1i*w2alphaM); %Measured isoclinic phasor
            
            
            %retar demodulator
            dretar=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA6Step);
            %set ROI
            dretar.Set(char(DemodulatorProps.M),M);
            %get steps
            steps=dretar.GetStepValues();
            
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
            
            baseDir=fullfile(fixturesRoot(),'DiscoPolariscopio');
            retarMeasure='Isochrom8PSNa.mat';
            S=load(fullfile(baseDir, retarMeasure));
            gList=cell(1, length(steps));
            for n=1:length(steps)
                t=S.isochromIm{n};
                gList{n}=t(:, :, 1); %get R image for Na light
            end
                        
            %set 2alpha
            dretar.Set(char(DemodulatorProps.z2alpha), z2alphaM);
            
            %demodulate retar
            dretar.Process(gList);
            zList=dretar.Get(char(DemodulatorProps.zList));
            zdelta=zList{1};
            wdeltaM=angle(zdelta);
            
            figure; imagesc(wdeltaM); title('mesured Retar'); colormap gray
            
            %Unwrapp delta
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %process
            u.Process(wdeltaM, M, M);
            %get results
            deltaM=u.Get(char(UnwrapperProps.unw));
            figure; imagesc(deltaM.*M); title('Measured Retar'); colormap jet
            
            
        end
        
        
        function testDemodRetarRing(testCase)
            % testDemodRetarRing repeats testDemodRetarDisk's isoclinic
            % angle + retardation chain on real acquired fringe patterns
            % of a loaded ring (AnilloPolariscopio fixtures)
            %run(testFPADemodulatorPS6StepFotoel, 'testDemodRetarRing')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %here we test a complete angle and retardation measurement
            %using simulated fringe patterns from a loaded disk
            
            
            
            %get isoclinic angle
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            d.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);
            
            %set the variation range to pi/2 for isoclinics
            d.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);
            
            %get steps
            steps=d.GetStepValues();
            
            %set ROI
            baseDir=fullfile(fixturesRoot(),'AnilloPolariscopio');
            MaskFileName='Mask.mat';
            S=load(fullfile(baseDir,MaskFileName), 'BW');
            M=S.BW;
            d.Set(char(DemodulatorProps.M),M);
            
            %generate LBF patterns
            isoclinMeasure='Isoclin4PSBlanca.mat';
            S=load(fullfile(baseDir, isoclinMeasure));
            FPList=S.isoclinIm;
            
            %demodulate
            d.Process(FPList);
            zList=d.Get(char(DemodulatorProps.zList));
            z4alphaM=zList{1};
            z4alphaM=conv2(z4alphaM, ones(5,5)/25, 'same'); %phasor filtering
            w4alphaM=angle(z4alphaM);
            
            %unwrap w4alpha
            QM=mat2gray(abs(z4alphaM)); %relacion se�al ruido: la calidad
            %M=M.*(abs(z4alphaM)>30);
            [NR, NC, ~]=size(FPList{1});
            QM(round(0.5*NR), round(0.5*NC))=2; %setting starting point
            t=5; % neighbouhood 2t+1
            mu=1; % regularization
            w2alphaM=UtilFunFPA.Calc2Alpha(w4alphaM,QM,M,t,mu);
            %w2alphaM=w4alphaM; %AQTesting
            
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*w4alphaM, D, sameColorFlag); title('w4alpha Measured');
            UtilFunFPA.DrawAlpha(0.5*w2alphaM, D, sameColorFlag); title('w2alpha Measured');
            
            z2alphaM=QM.*exp(1i*w2alphaM); %Measured isoclinic phasor
            
            
            %retar demodulator
            dretar=DemodulatorFactory.Create(DemodulatorTypes.RetarPSA6Step);
            %set ROI
            dretar.Set(char(DemodulatorProps.M),M);
            %get steps
            steps=dretar.GetStepValues();
            
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
            
            baseDir=fullfile(fixturesRoot(),'AnilloPolariscopio');
            retarMeasure='Isochrom8PSNa.mat';
            S=load(fullfile(baseDir, retarMeasure));
            gList=cell(1, length(steps));
            for n=1:length(steps)
                t=S.isochromIm{n};
                gList{n}=t(:, :, 1); %get R image for Na light
            end
            
            %set 2alpha
            dretar.Set(char(DemodulatorProps.z2alpha), z2alphaM);
            
            %demodulate retar
            dretar.Process(gList);
            zList=dretar.Get(char(DemodulatorProps.zList));
            zdelta=zList{1};
            wdeltaM=angle(zdelta);
            
            figure; imagesc(wdeltaM); title('mesured Retar'); colormap gray
            
            %Unwrapp delta
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %process
            u.Process(wdeltaM, M, M);
            %get results
            deltaM=u.Get(char(UnwrapperProps.unw));
            figure; imagesc(deltaM.*M); title('Measured Retar'); colormap jet
            
            
        end
        
    end
    
end
