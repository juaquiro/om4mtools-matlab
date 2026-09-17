classdef testFPADemodulatorFTTempAnalysis < matlab.unittest.TestCase
    % testFPADemodulatorFTTempAnalysis tests DemodulatorFTTempAnalysis
    % (spatio-temporal FT-based demodulation across a stack of igrams)
    %run(testFPADemodulatorFTTempAnalysis)
    
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
            %run(testFPADemodulatorFTTempAnalysis, 'testAllDemodulatorsConstructors')
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
        
        
        function testConstructor(testCase)
            % testConstructor checks the factory returns a
            % DemodulatorFTTempAnalysis instance for DemodulatorTypes.FTTempAnalysis
            %run(testFPADemodulatorFTTempAnalysis, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FTTempAnalysis);
            
            testCase.assertTrue(isa(d, 'DemodulatorFTTempAnalysis'));
            testCase.assertClass(d, 'DemodulatorFTTempAnalysis');
            
        end
        
        function testDemodRetarSimulImages(testCase)
            % testDemodRetarSimulImages demodulates a simulated 50-frame
            % circular-polariscope loading ramp on a teoretical loaded
            % disk, visually inspecting a single frame's retardation/
            % modulation maps and one pixel's temporal phase evolution
            % against the theoretical ramp
            %run(testFPADemodulatorFTTempAnalysis, 'testDemodRetarSimulImages')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %here we test a complete angle and retardation measurement
            %using simulated fringe patterns from a loaded disk
            
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
            gList=cell(1, length(tempLoad));
            for n=1:length(tempLoad)
                gList(n)=UtilFunFPA.CircPol(delta*tempLoad(n), w2alpha, psi, phi, M);
            end
            
            %demodulate retar
            dretar.Process(gList);
            zList=dretar.Get(char(DemodulatorProps.zList));
            zdelta=zList{1};
            wdeltaM=angle(zdelta);
            QdeltaM=abs(zdelta);
            
            figure; imagesc(wdeltaM(:, :, 45)); title('mesured Retar'); colormap gray
            figure; imagesc(QdeltaM(:, :, 45)); title('mesured Modulation'); colormap gray
            
            r=10; c=89;
            zPer=reshape(zdelta(r,c,:),[1,length(tempLoad)]);
            zPerAct=delta(r,c)*tempLoad;
            figure;plot(tempLoad,angle(zPer), '.-');title(['Variaci�n temporal en pixel: ' num2str(r) ',' num2str(c)]);
            figure;plot(tempLoad,unwrap(angle(zPer)), tempLoad, zPerAct, '.-');title(['Variaci�n temporal en pixel: ' num2str(r) ',' num2str(c)]);
            
        end
        
        function testGenSteps(testCase)
            % testGenSteps checks GetStepValues() returns N evenly-spaced
            % steps over [0, TempRange), matching the manual computation
            %run(testFPADemodulatorFTTempAnalysis,'testGenSteps')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FTTempAnalysis);
            d.Set(char(DemodulatorProps.TempRange), 100); %100 temporal steps
            
            
            N=d.Get(char(DemodulatorProps.NIgrams));
            Range=d.Get(char(DemodulatorProps.TempRange));
            %in units of tempRange  that can be Volts for a piezo o 90 degrees for the polariscope etc
            steps=(0:N-1)*Range/(N-1);
            
            stepsToTest=d.GetStepValues();
            
            testCase.assertEqual(steps, stepsToTest);
        end
        
        function testGenFPsAndProcess(testCase)
            % testGenFPsAndProcess generates and processes fringe
            % patterns for both scan directions, checking the phase
            % gradient is ~0 along the constant-phase direction of each
            %run(testFPADemodulatorFTTempAnalysis,'testGenFPsAndProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=188;
            NP=50;
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FTTempAnalysis);
            d.Set(char(DemodulatorProps.Tx), 20); %set period in px
            d.Set(char(DemodulatorProps.Ty), 20);
            d.Set(char(DemodulatorProps.NIgrams), NP);
            
            %set direction to vertical X
            PSdir=0;
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            %generate the FPS
            gList=d.GenerateFPs([NR, NC]);
            
            %"capture" the FPS
            IList=cell(1,length(gList));
            for n=1:length(gList)
                I=gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                IList{n}=I;
            end
            
            %Process
            d.Process(IList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            p=angle(z(:, :, NP-10));
            figure; imagesc(p); colormap gray
            
            py=diff(p,1);
            absTol=1e-5;
            testCase.assertEqual(mean(py(:)),0, 'AbsTol', absTol);
            
            
            %change direction to horizontal Y
            PSdir=1;
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            %generate the FPS
            gList=d.GenerateFPs([NR, NC]);
            
            IList=cell(1,length(gList));
            for n=1:length(gList)
                I=gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                IList{n}=I;
            end
            
            %process them
            d.Process(IList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            p=angle(z(:, :, NP-10));
            figure; imagesc(p); colormap gray
            
            px=diff(p,1,2);
            absTol=1e-5;
            testCase.assertEqual(mean(px(:)),0, 'AbsTol', absTol);
        end
        
        function testGenFPsAndProcessWithProjector(testCase)
            % testGenFPsAndProcessWithProjector repeats
            % testGenFPsAndProcess but displays each pattern on a real
            % DisplayProjector before resampling and processing
            %run(testFPADemodulatorFTTempAnalysis,'testGenFPsAndProcessWithProjector')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=188;
            NP=50;
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FTTempAnalysis);
            d.Set(char(DemodulatorProps.Tx), 120); %set period in px
            d.Set(char(DemodulatorProps.Ty), 120);
            d.Set(char(DemodulatorProps.NIgrams), NP);
            
            %create also a disp projector to check FP generation
            dp=DisplayProjector();
            
            
            %set direction to vertical X
            PSdir=0;
            d.Set(char(DemodulatorProps.PSDir), PSdir);            
            %generate and feed the projector
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            %disp and "capture" the FPS
            IList=cell(1,length(dp.gList));
            for n=1:length(dp.gList)
                %display
                dp.Display(n);
                pause(0.1);
                %resample for procesing
                I=imresize(dp.gList{n}, [NR, NC], 'nearest');
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                IList{n}=I;
            end
            
            %Process
            d.Process(IList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            p=angle(z(:, :, NP-10));
            figure; imagesc(p); colormap gray
            
            py=diff(p,1);
            absTol=1e-5;
            testCase.assertEqual(mean(py(:)),0, 'AbsTol', absTol);
            
            
            %change direction to horizontal Y
            PSdir=1;
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            %generate the FPS and feed the projector
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            IList=cell(1,length(dp.gList));
            for n=1:length(dp.gList)
                %display
                dp.Display(n);
                pause(0.1);
                
                %capture
                %resample for procesing
                I=imresize(dp.gList{n}, [NR, NC], 'nearest');
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                IList{n}=I;
            end
            
            %process them
            d.Process(IList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            p=angle(z(:, :, NP-10));
            figure; imagesc(p); colormap gray
            
            px=diff(p,1,2);
            absTol=1e-5;
            testCase.assertEqual(mean(px(:)),0, 'AbsTol', absTol);
        end
        
        
    end
    
end
