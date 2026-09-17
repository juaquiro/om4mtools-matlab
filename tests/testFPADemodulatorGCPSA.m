classdef testFPADemodulatorGCPSA < matlab.unittest.TestCase
    % testFPADemodulatorGCPSA tests DemodulatorGCPSA (Gray-code +
    % phase-shifting hybrid absolute-phase demodulation)
    %run(testFPADemodulatorGCPSA)
    
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
            %run(testFPADemodulatorGCPSA, 'testAllDemodulatorsConstructors')
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
            % testConstructor checks DemodulatorGCPSA's default inner
            % demodulators (PSADemodulator/GCDemodulator), how
            % AbsolutePhasePSADemType swaps the inner PSA demodulator
            % class, and its default properties
            %run(testFPADemodulatorGCPSA, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GCPSA);
            
            testCase.assertTrue(isa(d, 'DemodulatorGCPSA'));
            testCase.assertClass(d, 'DemodulatorGCPSA');
            
            %default valuE is 'DemodulatorLSEquispacedPSA'
            testCase.assertTrue(isa(d.PSADemodulator, 'DemodulatorLSEquispacedPSA'));
            testCase.assertClass(d.PSADemodulator, 'DemodulatorLSEquispacedPSA');
            
            testCase.assertTrue(isa(d.GCDemodulator, 'DemodulatorGC'));
            testCase.assertClass(d.GCDemodulator, 'DemodulatorGC');
            
            %check for changing DemodulatorProps.AbsolutePhasePSADemType    vList={DemodulatorTypes.LSEquispacedPSA, DemodulatorTypes.LSPSA, DemodulatorTypes.TimePSA};
            d.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.LSPSA);
            testCase.assertTrue(isa(d.PSADemodulator, 'DemodulatorLSPSA'));
            testCase.assertClass(d.PSADemodulator, 'DemodulatorLSPSA');
            
            d.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.TimePSA);
            testCase.assertTrue(isa(d.PSADemodulator, 'DemodulatorTimePSA'));
            testCase.assertClass(d.PSADemodulator, 'DemodulatorTimePSA');
            
            
            %check def values
            Tx=8;
            testCase.assertEqual(Tx, d.Get(char(DemodulatorProps.Tx)));
            Ty=8;
            testCase.assertEqual(Ty, d.Get(char(DemodulatorProps.Ty)));
            
            NIgrams=[];
            testCase.assertEqual(NIgrams, d.Get(char(DemodulatorProps.NIgrams)));
            
            deltaList=[];
            testCase.assertEqual(deltaList, d.Get(char(DemodulatorProps.deltaList)));
            
            biasFP=[];
            testCase.assertEqual(biasFP, d.biasFP);
            
            modFP=[];
            testCase.assertEqual(modFP, d.modFP);
            
        end
        
        
        function testGenFPsAndProcess(testCase)
            % testGenFPsAndProcess generates GCPSA patterns for both scan
            % directions, processes them (optionally simulating a noisy
            % capture) and checks the phasor/phase/order/visibility
            % outputs have the expected real/complex types
            %run(testFPADemodulatorGCPSA,'testGenFPsAndProcess')
            %se incluye posible binarizacion
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=190;
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GCPSA);
            d.Set(char(DemodulatorProps.Tx), 8); %set period in px
            d.Set(char(DemodulatorProps.Ty), 10);
            d.PSADemodulator.Set(char(DemodulatorProps.NIgrams), 4); %default is 4
            
            %choose PSA demodulator: DemodulatorTypes.LSEquispacedPSA; DemodulatorTypes.LSPSA; char(DemodulatorTypes.TimePSA)
            %default value DemodulatorTypes.LSEquispacedPSA
            d.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.LSPSA);
            
            
            %ROI
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.5*min(NR, NC);
            d.Set(char(DemodulatorProps.M), M);
            
            %modulation for the "capture"
            modFP=mat2gray(abs(peaks(max([NR, NC])))); modFP=imresize(modFP, [NR, NC]);
            PSdirVals=[0,1]; %X and Y directions
            for k=1:2
                %change direction to vertical X
                PSdir=PSdirVals(k);
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                %generate the FPS
                gList=d.GenerateFPs([NR, NC]);
                
                %testCase.assertEqual(NIgrams, length(gList));
                
                % "capture" the FPS
                IList=cell(1,length(gList));
                for n=1:length(gList)
                    
                    I=gList{n};
                    AQDEBUG_DISTORT=false; %flag for add noise, non-linearity and distortion
                    if AQDEBUG_DISTORT
                        [~, ~, NB]=size(I);
                        if NB==3
                            I=modFP.*mat2gray(rgb2gray(I));
                            %non-linear processing
                            I=mat2gray(power(I, 1.0));
                            %a�adimos ruido
                            I=0.05*randn(size(I))+I;
                            %mochamos los maximos
                            TH=1;
                            I(I>TH)=TH;
                        end
                    end
                    IList{n}=I;
                end
                
                %process them
                d.Process(IList);
                
                zList=d.Get(char(DemodulatorProps.zList));
                P=zList{1}; %absolute phase from PSA and GC
                D=zList{2}; %absolute order from GC
                V=zList{3}; %Visibility from GC
                z=zList{4}; %PSA phasor
                
                %the phasor must be complex by default
                testCase.assertTrue(not(isreal(z)));
                
                %the others are real
                testCase.assertTrue(isreal(P));
                testCase.assertTrue(isreal(D));
                testCase.assertTrue(isreal(V));
                
                p=angle(z);
                figure; imagesc(p); colormap gray; title('PSA phase');
                m=abs(z);
                figure; imagesc(m.*M./M); colormap jet; colorbar; title('PSA modulation');
                
                figure; imagesc(P.*M./M); colormap jet; colorbar; title('Absolute Phase');
                figure; imagesc(D.*M./M); colormap jet; colorbar; title('Order from GC');
                figure; imagesc(V.*M./M); colormap jet; colorbar; title('Visibility from GC');
                
            end
            
            
        end
        
        
        function testGenFPsAndProcessWithMatlabProjector(testCase)
            % testGenFPsAndProcessWithMatlabProjector repeats
            % testGenFPsAndProcess but displays each GCPSA pattern on a
            % real Matlab-figure "projector" (DisplayFactory) before
            % processing
            %run(testFPADemodulatorGCPSA,'testGenFPsAndProcessWithMatlabProjector')
            %show the FP generation and the use of a proyector
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GCPSA);
            d.Set(char(DemodulatorProps.Tx), 128); %set period in px
            d.Set(char(DemodulatorProps.Ty), 128);
            d.PSADemodulator.Set(char(DemodulatorProps.NIgrams), 4); %default is 4,
            
            %choose PSA demodulator: DemodulatorTypes.LSEquispacedPSA; DemodulatorTypes.LSPSA; char(DemodulatorTypes.TimePSA)
            %default value DemodulatorTypes.LSEquispacedPSA
            d.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.LSEquispacedPSA);
            
            %create display
            dp=DisplayFactory.Create(DisplayTypes.Matlab);
            
            
            %ROI
            PSdirVals=[0,1]; %X and Y directions
            for k=1:2
                %change direction to vertical X
                PSdir=PSdirVals(k);
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                %generate the FPS
                dp.gList=d.GenerateFPs(dp.screenSize);
                
                for n=1:length(dp.gList)
                    dp.Display(n);
                    pause(1)
                end
                
                % "capture" the FPS
                IList=dp.gList;
                
                %process them
                d.Process(IList);
                
                zList=d.Get(char(DemodulatorProps.zList));
                P=zList{1}; %absolute phase from PSA and GC
                D=zList{2}; %absolute order from GC
                V=zList{3}; %Visibility from GC
                z=zList{4}; %PSA phasor
                
                %the phasor must be complex by default
                testCase.assertTrue(not(isreal(z)));
                
                %the others are real
                testCase.assertTrue(isreal(P));
                testCase.assertTrue(isreal(D));
                testCase.assertTrue(isreal(V));
                
                p=angle(z);
                figure; imagesc(p); colormap gray; title('PSA phase');
                m=abs(z);
                figure; imagesc(m); colormap jet; colorbar; title('PSA modulation');
                
                figure; imagesc(P); colormap jet; colorbar; title('Absolute Phase');
                figure; imagesc(D); colormap jet; colorbar; title('Order from GC');
                figure; imagesc(V); colormap jet; colorbar; title('Visibility from GC');
                
                
            end
            
            dp.CloseScreen();
            
            
        end
        
        
        function testGenFPsAndProcessWithProjectorDLLC(testCase)
            % testGenFPsAndProcessWithProjectorDLLC is the same as
            % testGenFPsAndProcessWithMatlabProjector (larger Tx/Ty).
            %  Note: despite its name, the DisplayTypes.CDLL (DLL-backed)
            % projector line is commented out - it currently uses
            % DisplayTypes.Matlab like the other projector test.
            %run(testFPADemodulatorGCPSA,'testGenFPsAndProcessWithProjectorDLLC')
            %show the FP generation and the use of a proyector
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GCPSA);
            d.Set(char(DemodulatorProps.Tx), 150); %set period in px
            d.Set(char(DemodulatorProps.Ty), 160);
            d.PSADemodulator.Set(char(DemodulatorProps.NIgrams), 4); %default is 4
            
            %choose PSA demodulator: DemodulatorTypes.LSEquispacedPSA; DemodulatorTypes.LSPSA; char(DemodulatorTypes.TimePSA)
            %default value DemodulatorTypes.LSEquispacedPSA
            d.Set(char(DemodulatorProps.AbsolutePhasePSADemType), DemodulatorTypes.LSEquispacedPSA);
            
            %create display
            dp=DisplayFactory.Create(DisplayTypes.Matlab);
            %dp=DisplayFactory.Create(DisplayTypes.CDLL);
            
            
            
            %ROI
            PSdirVals=[0,1]; %X and Y directions
            for k=1:2
                %change direction to vertical X
                PSdir=PSdirVals(k);
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                %generate the FPS
                dp.gList=d.GenerateFPs(dp.screenSize);
                
                for n=1:length(dp.gList)
                    dp.Display(n);
                    pause(1)
                end
                
                % "capture" the FPS
                IList=dp.gList;
                
                %process them
                d.Process(IList);
                
                zList=d.Get(char(DemodulatorProps.zList));
                P=zList{1}; %absolute phase from PSA and GC
                D=zList{2}; %absolute order from GC
                V=zList{3}; %Visibility from GC
                z=zList{4}; %PSA phasor
                
                %the phasor must be complex by default
                testCase.assertTrue(not(isreal(z)));
                
                %the others are real
                testCase.assertTrue(isreal(P));
                testCase.assertTrue(isreal(D));
                testCase.assertTrue(isreal(V));
                
                p=angle(z);
                figure; imagesc(p); colormap gray; title('PSA phase');
                m=abs(z);
                figure; imagesc(m); colormap jet; colorbar; title('PSA modulation');
                
                figure; imagesc(P); colormap jet; colorbar; title('Absolute Phase');
                figure; imagesc(D); colormap jet; colorbar; title('Order from GC');
                figure; imagesc(V); colormap jet; colorbar; title('Visibility from GC');
                
                
            end
            
            dp.CloseScreen();
            
            
        end
        
        
        
        
        
        
        
    end
    
end
