classdef testFPADemodulatorLSEquispacedPSA < matlab.unittest.TestCase
    % testFPADemodulatorLSEquispacedPSA tests DemodulatorLSEquispacedPSA
    % (least-squares equispaced-step phase-shifting demodulation)
    %run(testFPADemodulatorLSEquispacedPSA)
    
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
            %run(testFPADemodulatorLSEquispacedPSA, 'testAllDemodulatorsConstructors')
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
            % testConstructor checks DemodulatorLSEquispacedPSA's default
            % Tx/NIgrams/deltaList, and that changing NIgrams recomputes
            % deltaList as equispaced steps
            %run(testFPADemodulatorLSEquispacedPSA, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            
            testCase.assertTrue(isa(d, 'DemodulatorLSEquispacedPSA'));
            testCase.assertClass(d, 'DemodulatorLSEquispacedPSA');
            
            %check def values
            Tx=8;
            testCase.assertEqual(Tx, d.Get(char(DemodulatorProps.Tx)));
            NIgrams=round(0.5*Tx);
            testCase.assertEqual(NIgrams, d.Get(char(DemodulatorProps.NIgrams)));
            
            deltaList=[0:NIgrams-1]'*2*pi/NIgrams;
            testCase.assertEqual(deltaList, d.Get(char(DemodulatorProps.deltaList)));
            
            %change NIgrams and check deltaList
            NIgrams=8;
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);
            
            testCase.assertEqual(NIgrams, d.Get(char(DemodulatorProps.NIgrams)));
            deltaList=[0:NIgrams-1]'*2*pi/NIgrams;
            testCase.assertEqual(deltaList, d.Get(char(DemodulatorProps.deltaList)));
            
        end
        
        
        function testGenFPsWithBiasAndMod(testCase)
            % testGenFPsWithBiasAndMod checks GenerateFPs' output GV
            % range follows biasFP/modFP (default, reduced modFP, shifted
            % biasFP, and a modFP large enough to clip against [0,255])
            %run(testFPADemodulatorLSEquispacedPSA,'testGenFPsWithBiasAndMod')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            
            testCase.assertTrue(isa(d, 'DemodulatorLSEquispacedPSA'));
            testCase.assertClass(d, 'DemodulatorLSEquispacedPSA');
            
            %check bias and mod def values
            biasFP=127.5;
            testCase.assertEqual(biasFP, d.biasFP);
                
            modFP=127.5;
            testCase.assertEqual(modFP, d.modFP);
            
            %create display  
            NIgrams=1;
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);

            %create also a disp projecto
            dp=DisplayProjector();
            
            %generate the FPS and store them in the projector
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            %check output value
            testCase.assertEqual(uint8(255), max(max(rgb2gray(dp.gList{1,1}))));
            testCase.assertEqual(uint8(0), min(min(rgb2gray(dp.gList{1,1}))));
            
            %change bias and mod values
            d.modFP=40;
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            testCase.assertEqual(uint8(167.5), max(max(rgb2gray(dp.gList{1,1}))));
            testCase.assertEqual(uint8(87.5), min(min(rgb2gray(dp.gList{1,1}))));
            
            d.biasFP=100;
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            testCase.assertEqual(uint8(140), max(max(rgb2gray(dp.gList{1,1}))));
            testCase.assertEqual(uint8(60), min(min(rgb2gray(dp.gList{1,1}))));
            
            %que pasa si el bias es 127.5 y la modulacion 200, el FP se
            %mocha?
            d.biasFP=127.5;
            d.modFP=200;
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            testCase.assertEqual(uint8(255), max(max(rgb2gray(dp.gList{1,1}))));
            testCase.assertEqual(uint8(0), min(min(rgb2gray(dp.gList{1,1}))));
        end
        
        
        function testGenShape(testCase)
            % testGenShape checks d.shape=1 makes GenerateFPs produce a
            % square wave (constant +/-127.5 offset from bias) instead
            % of the default sine wave
            %run(testFPADemodulatorLSEquispacedPSA,'testGenShape')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            
            testCase.assertTrue(isa(d, 'DemodulatorLSEquispacedPSA'));
            testCase.assertClass(d, 'DemodulatorLSEquispacedPSA');
            
            %comprovar que se genera una onda cuadrada
            d.shape = 1;
            
            %create display  
            NIgrams=1;
            d.Set(char(DemodulatorProps.NIgrams), NIgrams); 

            %create also a disp projecto
            dp=DisplayProjector();
            
            %generate the FPS and store them in the projector
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            %check output value
            Q = abs(double(rgb2gray(dp.gList{1,1}))-127.5);
            J = ones(size(Q))*127.5;
            testCase.assertEqual(true, isequal(J,Q));
        end
        
        
        function testGenSteps(testCase)
            % testGenSteps checks GetStepValues() matches deltaList
            % rescaled by StepsTwoPwiRange
            %run(testFPADemodulatorLSEquispacedPSA,'testGenSteps')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            %dt types and dn are names for demodulators
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            d.Set(char(DemodulatorProps.StepsTwoPwiRange), 2*pi);
            
            
            valRange=d.Get(char(DemodulatorProps.StepsTwoPwiRange));
            deltaList=d.Get(char(DemodulatorProps.deltaList));
            steps=deltaList*valRange/(2*pi);
            stepsToTest=d.GetStepValues();
            
            testCase.assertEqual(steps, stepsToTest);
        end
        
        
        function testSetNSteps(testCase)
            % testSetNSteps checks setting an arbitrary deltaList
            % directly round-trips through Get unchanged
            %run(testFPADemodulatorLSEquispacedPSA,'testSetNSteps')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            %dt types and dn are names for demodulators
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            
            N=10;
            deltaList=rand(N,1);
            d.Set(char(DemodulatorProps.deltaList), deltaList);
            
            
            deltaList1=d.Get(char(DemodulatorProps.deltaList));
            
            testCase.assertEqual(deltaList, deltaList1);
        end
        
        
        function testGenFPsAndProcess(testCase)
            % testGenFPsAndProcess generates and processes 6-step
            % patterns for both scan directions, checking the phase
            % gradient is ~0 along the constant-phase direction and
            % visually comparing the recovered directional derivative
            % (phaseGradientDirect) histogram against the known ground
            % truth spatial frequency
            %run(testFPADemodulatorLSEquispacedPSA,'testGenFPsAndProcess')
            %se incluye posible binarizacion
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=188;
            
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            d.Set(char(DemodulatorProps.Tx), 20); %set period in px
            d.Set(char(DemodulatorProps.Ty), 20);            
          
            NIgrams=6;
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);
            
            %ROI
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);
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
                
                testCase.assertEqual(NIgrams, length(gList));
                
                % "capture" the FPS
                IList=cell(1,length(gList));
                for n=1:length(gList)
                    
                    I=gList{n};
                    [~, ~, NB]=size(I);
                    if NB==3
                        I=modFP.*mat2gray(rgb2gray(I));
                        %non-linear processing
                        I=mat2gray(power(I, 1.0));                        
                        %a�adimos ruido
                        I=0.0*randn(size(I))+I;
                        %mochamos los maximos
                        TH=1;                        
                        I(I>TH)=TH;
                        
                    end
                    IList{n}=I;
                end
                
                figure; imagesc(IList{1}); colormap gray
                
                %process them
                d.Process(IList);
                
                zList=d.Get(char(DemodulatorProps.zList));
                z=zList{1};
                %the phasor must be complex by default
                testCase.assertTrue(not(isreal(z)));            
                
                p=angle(z);
                figure; imagesc(p); colormap gray; title('phase');
                m=abs(z);
                figure; imagesc(m.*M./M); colormap jet; colorbar; title('modulation');
                
                
                if PSdir==0
                    dp=diff(p,1,1);%py
                else
                    dp=diff(p,1,2);%px
                end
                
                absTol=1e-5;
                testCase.assertEqual(mean(dp(:)),0, 'AbsTol', absTol);
                
                [pzx, pzy, Mxy]=UtilFunFPA.phaseGradientDirect(z, M, 1, 1);
                
                x=linspace(-0.2*pi, 0.2*pi, 150);
                hx=mat2gray(hist(pzx(Mxy), x));
                if PSdir==0 %X dir
                    dxGT=2*pi/d.Get(char(DemodulatorProps.Tx)); %ground Truth
                else
                    dxGT=0;
                end
                    
                figure; plot(x,hx, '.-', dxGT, 1, 'o-'); title(['Dir: ' num2str(PSdir) ' hist dx'])
                legend('PSA', 'Ground truth');
                
                hy=mat2gray(hist(pzy(Mxy), x));
                if PSdir==0 %X dir
                    dyGT=0;
                else
                    dyGT=-2*pi/d.Get(char(DemodulatorProps.Ty)); %ground Truth
                end
                figure; plot(x,hy, '.-',dyGT, 1, 'o-'); title(['Dir: ' num2str(PSdir) ' hist dy'])    
                legend('PSA', 'Ground truth');
                
            end
            
            
        end
        
        
        
        function testGenFPsAndProcessOnlyModulation(testCase)
            % testGenFPsAndProcessOnlyModulation repeats
            % testGenFPsAndProcess with onlyModFlag=true, checking the
            % output is real (modulation only, no phase)
            %run(testFPADemodulatorLSEquispacedPSA,'testGenFPsAndProcessOnlyModulation')
            %se incluye posible binarizacion
            %aqui solo se calcula la modulacion
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=188;           
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            d.Set(char(DemodulatorProps.Tx), 20); %set period in px
            d.Set(char(DemodulatorProps.Ty), 20);           
            
            %we are going to calculate only the modulation
            %the demodulation result wull be a real number
            d.onlyModFlag=true;
          
            NIgrams=6;
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);
            
            %ROI
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);
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
                
                testCase.assertEqual(NIgrams, length(gList));
                
                % "capture" the FPS
                IList=cell(1,length(gList));
                for n=1:length(gList)
                    
                    I=gList{n};
                    [~, ~, NB]=size(I);
                    if NB==3
                        I=modFP.*mat2gray(rgb2gray(I));
                        %non-linear processing
                        I=mat2gray(power(I, 1.0));                        
                        %a�adimos ruido
                        I=0.0*randn(size(I))+I;
                        %mochamos los maximos
                        TH=1;                        
                        I(I>TH)=TH;
                        
                    end
                    IList{n}=I;
                end
                
                figure; imagesc(IList{1}); colormap gray
                
                %process them
                d.Process(IList);
                
                zList=d.Get(char(DemodulatorProps.zList));
                z=zList{1};
                %the phasor must be complex by default
                testCase.assertTrue(isreal(z));            
                
                m=z;
                figure; imagesc(m.*M./M); colormap jet; colorbar; title('modulation');
                
            end
            
            
        end
        
        
        function testProcessOnlyModulationLSvsEquispaced(testCase)
            % testProcessOnlyModulationLSvsEquispaced times
            % modulation-only processing (onlyModFlag=true) on a large
            % image for both DemodulatorLSEquispacedPSA and
            % DemodulatorLSPSA, checking both outputs are real
            %run(testFPADemodulatorLSEquispacedPSA,'testProcessOnlyModulationLSvsEquispaced')
            %se incluye posible binarizacion
            %aqui solo se calcula la modulacion para dos demoduladores y se
            %compara su velocidad
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=1910;
            NC=1880;
            
            
            d={DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA), DemodulatorFactory.Create(DemodulatorTypes.LSPSA)};
            for j=1:length(d)
                d{j}.Set(char(DemodulatorProps.Tx), 20); %set period in px
                d{j}.Set(char(DemodulatorProps.Ty), 20);
            end
            
            
            
            
            %we are going to calculate only the modulation
            %the demodulation result wull be a real number
            for j=1:length(d)
                d{j}.onlyModFlag=true;
            end
            
            NIgrams=6;
            for j=1:length(d)
                d{j}.Set(char(DemodulatorProps.NIgrams), NIgrams);
            end
            
            %ROI
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);
            for j=1:length(d)
                d{j}.Set(char(DemodulatorProps.M), M);
            end
            
            %modulation for the "capture"
            modFP=mat2gray(abs(peaks(max([NR, NC])))); modFP=imresize(modFP, [NR, NC]);
            
            %generate the FPS
            gList=d{1}.GenerateFPs([NR, NC]);
            
            testCase.assertEqual(NIgrams, length(gList));
            
            % "capture" the FPS
            IList=cell(1,length(gList));
            for n=1:length(gList)
                
                I=gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=modFP.*mat2gray(rgb2gray(I));
                    %non-linear processing
                    I=mat2gray(power(I, 1.0));
                    %a�adimos ruido
                    I=0.0*randn(size(I))+I;
                    %mochamos los maximos
                    TH=1;
                    I(I>TH)=TH;
                    
                end
                IList{n}=I;
            end
            
            figure; imagesc(IList{1}); colormap gray
            
            %process them
            tic
            d{2}.Process(IList);
            toc
            
            tic
            d{1}.Process(IList);
            toc
            
 
            
            for j=1:length(d)
                zList=d{j}.Get(char(DemodulatorProps.zList));
                z{j}=zList{1};
                %the phasor must be complex by default
                testCase.assertTrue(isreal(z{j}));
            end
            
            for j=1:length(d)
                m=z{j};
                figure; imagesc(m.*M./M); colormap jet; colorbar; title('modulation');
            end
            
            
            
        end
        
        function testGenFPsAndProcessWithProjector(testCase)
            % testGenFPsAndProcessWithProjector generates 4-step patterns
            % for both scan directions, displays them on a real
            % DisplayProjector, and checks the recovered phase gradient
            % is ~0 along each constant-phase direction
            %run(testFPADemodulatorLSEquispacedPSA,'testGenFPsAndProcessWithProjector')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            
            %create also a disp projector to check FP generation
            dp=DisplayProjector();
            
            %check all PSFilterTypes
            
            %change direction to X
            PSdir=0;
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            
            NIgrams=4;
            %set NIgrams and set the vaule of deltaList as NIgrams equispaced
            %values beween 0 and 2*pi(1-1/NIgrams)
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);
                 
            
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
            figure; imagesc(p); colormap gray; title('\phi_x')                                   
            
            
            hx=1; %1 mm/px
            hy=1; %mm/px
            [px, py, ~]=UtilFunFPA.phaseGradientDirect(z, ones(size(z)), hx, hy);
                       
            absTol=1e-5;
            testCase.assertEqual(mean(py(:)),0, 'AbsTol', absTol);
            
            figure; imagesc(px); colormap gray, title('\phi_(xx)')          
            
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
            figure; imagesc(p); colormap gray, title('\phi_y')          
            
            hx=1; %1 mm/px
            hy=1; %mm/px
            [px, py, ~]=UtilFunFPA.phaseGradientDirect(z, ones(size(z)), hx, hy);
            
            absTol=1e-5;
            testCase.assertEqual(mean(px(:)),0, 'AbsTol', absTol);
            
            figure; imagesc(py); colormap gray, title('\phi_(yy)')          
                        
            dp.CloseScreen;
            
        end
               
               
    end
    
end
