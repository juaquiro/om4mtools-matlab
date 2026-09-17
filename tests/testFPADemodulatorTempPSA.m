classdef testFPADemodulatorTempPSA < matlab.unittest.TestCase
    % testFPADemodulatorTempPSA tests DemodulatorTimePSA (temporal
    % phase-shifting demodulation, every PSFilterTypes filter) and its
    % use for FFV deflectometry (feeding LensMapperMeasurement)
    %run(testFPADemodulatorTempPSA)
    
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
            %run(testFPADemodulatorTempPSA, 'testAllDemodulatorsConstructors')
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
            % DemodulatorTimePSA instance for DemodulatorTypes.TimePSA
            %run(testFPADemodulatorTempPSA, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            
            testCase.assertTrue(isa(d, 'DemodulatorTimePSA'));
            testCase.assertClass(d, 'DemodulatorTimePSA');
            
        end
        
        function testGenSteps(testCase)
            % testGenSteps checks GetStepValues() matches the manual
            % step computation from d.h/d.w0, for every PSFilterTypes
            % filter (PS4 tested with a 90-degree StepsTwoPwiRange)
            %run(testFPADemodulatorTempPSA,'testGenSteps')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            %dt types and dn are names for demodulators
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            d.Set(char(DemodulatorProps.StepsTwoPwiRange), 2*pi);
            
            [dt, dn]=enumeration('PSFilterTypes');
            for n=1:length(dn)
                d.Set(char(DemodulatorProps.PSType), dt(n));
                
                switch dt(n)
                    case PSFilterTypes.PS4
                        %as a test set DemodulatorProps.StepsTwoPwiRange to
                        %90 degress as in photoelasticity
                        d.Set(char(DemodulatorProps.StepsTwoPwiRange), 90);
                end
                
                %generate the FPS
                N=length(d.h);
                valRange=d.Get(char(DemodulatorProps.StepsTwoPwiRange));
                %in units of valRange  that can be Volts for a piezo o 90 degrees for the polariscope etc
                steps=(0:N-1)*d.w0*valRange/(2*pi);
                stepsToTest=d.GetStepValues();
                
                testCase.assertEqual(steps, stepsToTest);
            end
            
            
        end
        
        
        
        function testGenFPsAndProcess(testCase)
            % testGenFPsAndProcess generates and processes fringe
            % patterns for every PSFilterTypes filter and both scan
            % directions, checking the phase gradient is ~0 along the
            % constant-phase direction of each
            %run(testFPADemodulatorTempPSA,'testGenFPsAndProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=188;
            
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            d.Set(char(DemodulatorProps.Tx), 20); %set period in px
            d.Set(char(DemodulatorProps.Ty), 20);
            
            [dt, dn]=enumeration('PSFilterTypes');
            for k=1:length(dn)
                %cheal al PSTypes
                d.Set(char(DemodulatorProps.PSType), dt(k));
                
                
                %change direction to vertical X
                PSdir=0;
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                %generate the FPS
                gList=d.GenerateFPs([NR, NC]);
                
                % "capture" the FPS
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
                
                p=angle(z);
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
                
                p=angle(z);
                figure; imagesc(p); colormap gray
                
                px=diff(p,1,2);
                absTol=1e-5;
                testCase.assertEqual(mean(px(:)),0, 'AbsTol', absTol);
            end
            
        end
        
        
        function testGenFPsAndProcessWithProjector(testCase)
            % testGenFPsAndProcessWithProjector repeats
            % testGenFPsAndProcess but displays each pattern on a real
            % DisplayProjector before processing
            %run(testFPADemodulatorTempPSA,'testGenFPsAndProcessWithProjector')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            
            %create also a disp projector to check FP generation
            dp=DisplayProjector();
            
            
            %check all PSFilterTypes
            [dt, dn]=enumeration('PSFilterTypes');
            for k=1:length(dn)
                %cheal al PSTypes
                d.Set(char(DemodulatorProps.PSType), dt(k));
                
                
                %change direction to X
                PSdir=0;
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                %generate the FPS and store them in the projector
                dp.gList=d.GenerateFPs(dp.screenSize);
                
                
                %light on and capture
                IList=cell(1,length(dp.gList));
                for n=1:length(dp.gList)
                    dp.Display(n);
                    pause(1);
                    
                    %condition the captured image
                    I=dp.gList{n};
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
                
                p=angle(z);
                figure; imagesc(p); colormap gray
                
                py=diff(p,1);
                absTol=1e-5;
                testCase.assertEqual(mean(py(:)),0, 'AbsTol', absTol);
                
                
                %change direction to Y
                PSdir=1;
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                
                %generate the FPS and store them in the projector
                dp.gList=d.GenerateFPs(dp.screenSize);
                
                %light on and capture
                IList=cell(1,length(dp.gList));
                for n=1:length(dp.gList)
                    dp.Display(n);
                    pause(1);
                    %condition the captured image
                    I=dp.gList{n};
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
                
                p=angle(z);
                figure; imagesc(p); colormap gray
                
                px=diff(p,1,2);
                absTol=1e-5;
                testCase.assertEqual(mean(px(:)),0, 'AbsTol', absTol);
                
            end
            
            dp.CloseScreen;
            
        end
        
        function testTimePS_A0502_ProcessMontajeHorizontal(testCase)
            % testTimePS_A0502_ProcessMontajeHorizontal demodulates a
            % real transmission-deflectometry LensMapperMeasurement
            % fixture (5-step, MontajeHorizontal setup), refines the ROI
            % from the deflection module and feeds the result into
            % CalculateLensPower, visually inspecting the power maps
            %run(testFPADemodulatorTempPSA,'testTimePS_A0502_ProcessMontajeHorizontal')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            DropboxDir=fixturesRoot();
            AQsrcDir='MontajeHorizontal';
            %LMMFileName='TimePS0506_YOminus2_75_14-Jul-2016.mat';
            LMMFileName='TimePS0506_SwisCoat40L88031L_14-Jul-2016.mat';
            %LMMFileName='TimePS0506_VisionLab565964_15-Jul-2016.mat';
            LMMFile=fullfile(DropboxDir, AQsrcDir, LMMFileName);
            
            testCase.assertTrue(exist(LMMFile, 'file')==2);
            
            S=load(LMMFile);LMM=S.LMM; clear('S');
            
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            d.Set(char(DemodulatorProps.PSType), PSFilterTypes.A0502);
            
            %ref list of 5 PS igrams
            N=0.5*length(LMM.gr);
            grX=LMM.gr(1:N);
            d.Process(grX);
            zList=d.Get(char(DemodulatorProps.zList));
            zrx=zList{1};
            
            grY=LMM.gr(N+1:2*N);
            d.Process(grY);
            zList=d.Get(char(DemodulatorProps.zList));
            zry=zList{1};
            
            
            %list of 5 PS igrams
            gcX=LMM.g(1:N);
            d.Process(gcX);
            zList=d.Get(char(DemodulatorProps.zList));
            zcx=zList{1};
            
            gcY=LMM.g(N+1:2*N);
            d.Process(gcY);
            zList=d.Get(char(DemodulatorProps.zList));
            zcy=zList{1};
            
            %ather the four Process the demodulator has accumulated the ROI
            M=d.Get(char(DemodulatorProps.M));
            figure; imagesc(M); title('M from abs(z)');
            %complete to select only the lens
            NFilt=d.Get(char(DemodulatorProps.NFilt));
            ROINormTH=d.Get(char(DemodulatorProps.ROINormTH));
            Mzd=Demodulator.GetROIFromModule(zrx-zcx, 0.5*ROINormTH, 2*NFilt);
            Mzd=Mzd&Demodulator.GetROIFromModule(zry-zcy, 0.5*ROINormTH, 2*NFilt);
            M=M&Mzd;
            figure; imagesc(M); title('M from abs(z) only lens');
            
                                 
            %AQNOTA
            %en deflectometria por transmision (experimento tipo Massig)
            %los sistemas de ref en X de los patrones
            %(pantalla) y de la captura (CCD) estan cambiados
            %especularmente izda-dcha.
            %En la direccion vertical Y no hay reflexion especular.
            %por eso aplicamos el conjugado a la deflexion en X
            LMM.zx=conj(zcx./zrx);
            LMM.zy=(zcy./zry);

            LMM.zrx=zrx;
            LMM.zry=zry;
            
            K=1;
            LMM.CalculateLensPower(LMM.M, K);
            
            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            M=LMM.M; %mask after CalculatePowerFromDefl
            
            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(M); title('MQ using ellipse tool');
                        
        end
        
        
        function testTimePS_A0502_Process_NuevoMontajeVertical(testCase)
            % testTimePS_A0502_Process_NuevoMontajeVertical repeats
            % testTimePS_A0502_ProcessMontajeHorizontal's demodulation +
            % CalculateLensPower chain on a real fixture from the newer
            % vertical deflectometer setup, using the demodulator's
            % auto-accumulated ROI directly (no extra module-based refinement)
            %run(testFPADemodulatorTempPSA,'testTimePS_A0502_Process_NuevoMontajeVertical')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            DropboxDir=fixturesRoot();
            AQsrcDir='CalibracionDeflectometroVertical-13-OCT-16';
            
            %LMMFileName='TimePSYoungerMinus275_13-Oct-2016.mat';
            LMMFileName='TimePS_GafasAQ_13-Oct-2016.mat';
            %LMMFileName='TimePS_40L88030R_13-Oct-2016.mat';
            %LMMFileName='LensMapperMeasurement_2D.mat';
            
            LMMFile=fullfile(DropboxDir, AQsrcDir, LMMFileName);
            
            testCase.assertTrue(exist(LMMFile, 'file')==2);
            
            S=load(LMMFile);LMM=S.LMM; clear('S');
            
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            d.Set(char(DemodulatorProps.PSType), PSFilterTypes.A0502);
            
            %ref list of 5 PS igrams
            N=0.5*length(LMM.gr);
            grX=LMM.gr(1:N);
            d.Process(grX);
            zList=d.Get(char(DemodulatorProps.zList));
            zrx=zList{1};
            
            grY=LMM.gr(N+1:2*N);
            d.Process(grY);
            zList=d.Get(char(DemodulatorProps.zList));
            zry=zList{1};
            
            
            %list of 5 PS igrams
            gcX=LMM.g(1:N);
            d.Process(gcX);
            zList=d.Get(char(DemodulatorProps.zList));
            zcx=zList{1};
            
            gcY=LMM.g(N+1:2*N);
            d.Process(gcY);
            zList=d.Get(char(DemodulatorProps.zList));
            zcy=zList{1};
            
            %ather the four Process the demodulator has accumulated the ROI
            %al modulation above DemodulatorProps.ROINormTH is processed
            Mz=d.Get(char(DemodulatorProps.M));
            LMM.M=Mz;
            figure; imagesc(Mz); title('M from abs(z)');                  
            
            %AQNOTA
            %en deflectometria por transmision (experimento tipo Massig)
            %los sistemas de ref en X de los patrones
            %(pantalla) y de la captura (CCD) estan cambiados
            %especularmente izda-dcha.
            %En la direccion vertical Y no hay reflexion especular.
            %por eso aplicamos el conjugado a la deflexion en X
            LMM.zx=conj(zcx./zrx);
            LMM.zy=(zcy./zry);


            LMM.zrx=zrx;
            LMM.zry=zry;
            
            K=1;            
            LMM.CalculateLensPower(LMM.M, K);            
            
            %if necessary complete mask to select only the lens
            %             NFilt=d.Get(char(DemodulatorProps.NFilt));
            %             ROINormTH=d.Get(char(DemodulatorProps.ROINormTH));
            %             %Mzd=Demodulator.GetROIFromModule(zcx-zrx, 0.1, NFilt);
            %             %Mzd=Mzd&Demodulator.GetROIFromModule(zcy-zry, 0.5*ROINormTH, 3*NFilt);
            %             Mzd=Demodulator.GetROIFromAngle(zcx./zrx, 0.1, NFilt);
            %             Mz=Mz&Mzd;
            %             figure; imagesc(Mz); title('M from abs(z) only lens');
            %             LMM.M=Mz;
            
            
            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            M=LMM.M; %mask after CalculatePowerFromDefl
            
            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');                        
        end
        
        
    end
    
end
