classdef testFPADemodulatorGC < matlab.unittest.TestCase
    % testFPADemodulatorGC tests DemodulatorGC (Gray-code fringe order
    % demodulation)
    %run(testFPADemodulatorGC)
    
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
            %run(testFPADemodulatorGC, 'testAllDemodulatorsConstructors')
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
            % testConstructor checks DemodulatorGC's default properties
            % (Tx, Ty, NIgrams, deltaList, biasFP, modFP)
            %run(testFPADemodulatorGC, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GrayCode);
            
            testCase.assertTrue(isa(d, 'DemodulatorGC'));
            testCase.assertClass(d, 'DemodulatorGC');
            
            %check def values
            Tx=8;
            testCase.assertEqual(Tx, d.Get(char(DemodulatorProps.Tx)));
            Ty=8;
            testCase.assertEqual(Ty, d.Get(char(DemodulatorProps.Ty)));
            
            NIgrams=[];
            testCase.assertEqual(NIgrams, d.Get(char(DemodulatorProps.NIgrams)));
            
            deltaList=[];
            testCase.assertEqual(deltaList, d.Get(char(DemodulatorProps.deltaList)));
            
            biasFP=127.5;
            testCase.assertEqual(biasFP, d.biasFP);
            
            modFP=127.5;
            testCase.assertEqual(modFP, d.modFP);
        end
        
        
        function testGenFPsAndProcess(testCase)
            % testGenFPsAndProcess generates Gray-code patterns for both
            % scan directions, simulates a noisy capture (modulation,
            % bias, non-linearity) and visually inspects the demodulated
            % fringe order and visibility maps
            %run(testFPADemodulatorGC,'testGenFPsAndProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=191;
            NC=188;
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GrayCode);
            d.Set(char(DemodulatorProps.Tx), 21); %set period in px default value is 8
            d.Set(char(DemodulatorProps.Ty), 40); %set period in py default value is 8
            
            %ROI
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);
            d.Set(char(DemodulatorProps.M), M);
            
            %modulation for the "capture"
            modFP=mat2gray(abs(peaks(max([NR, NC])))); modFP=imresize(modFP, [NR, NC]);
            biasFP=23; %GV
            PSdirVals=[0,1]; %X and Y directions
            for k=1:2
                %change direction to vertical X
                PSdir=PSdirVals(k);
                d.Set(char(DemodulatorProps.PSDir), PSdir);
                %generate the GCS
                gList=d.GenerateFPs([NR, NC]);
                
                NIgrams=d.Get(char(DemodulatorProps.NIgrams));
                
                testCase.assertEqual(NIgrams, length(gList));
                
                % "capture" the FPS
                IList=cell(1,length(gList));
                for n=1:length(gList)
                    
                    I=gList{n};
                    [~, ~, NB]=size(I);
                    if NB==3
                        I=modFP.*double(rgb2gray(I))+biasFP;
                    else
                        I=modFP.*double(I)+biasFP;
                    end
                    %non-linear processing
                    I=power(I, 1.0);
                    %a�adimos ruido
                    I=0.0*randn(size(I))+I;
                    
                    IList{n}=I;
                end
                
                for n=1:length(IList)
                    figure; imagesc(IList{n}); colormap gray
                end
                
                %process them
                d.Process(IList);
                
                zList=d.Get(char(DemodulatorProps.zList));
                D=zList{1}; %absolute order fron GC
                V=zList{2}; %Visibility
                
                figure; imagesc(D); colormap gray; title('phase');
                figure; imagesc(V.*M./M); colormap jet; colorbar; title('modulation');
                
            end
            
            
        end
        
        function testGenFPsAndProcessWithProyector(testCase)
            % testGenFPsAndProcessWithProyector repeats
            % testGenFPsAndProcess but displays each Gray-code pattern
            % on a real Matlab-figure "projector" (DisplayFactory) before
            % simulating its noisy capture and demodulating
            %run(testFPADemodulatorGC,'testGenFPsAndProcessWithProyector')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.GrayCode);
            d.Set(char(DemodulatorProps.Tx), 53); %set period in px default value is 8
            d.Set(char(DemodulatorProps.Ty), 201); %set period in px default value is 8
            
            dp=DisplayFactory.Create(DisplayTypes.Matlab);
            
            %ROI
            scDim=dp.screenSize; NR=scDim(1); NC=scDim(2);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);
            d.Set(char(DemodulatorProps.M), M);
            
            %modulation for the "capture"
            modFP=mat2gray(abs(peaks(max([NR, NC])))); modFP=imresize(modFP, [NR, NC]);
            biasFP=23; %GV
            PSdir=0; %0=X, 1=Y
            
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            %generate the FPS and store them in the projector
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            NIgrams=d.Get(char(DemodulatorProps.NIgrams));
            
            testCase.assertEqual(NIgrams, length(dp.gList));
            
            % "capture" the FPS
            IList=cell(1,length(dp.gList));
            for n=1:length(dp.gList)
                
                I=dp.gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=modFP.*double(rgb2gray(I))+biasFP;
                else
                    I=modFP.*double(I)+biasFP;
                end
                %non-linear processing
                I=power(I, 1.3);
                %a�adimos ruido
                I=1.0*randn(size(I))+I;                
                IList{n}=I;
            end
            
            for n=1:length(IList)
                figure; imagesc(IList{n}); colormap gray; title(['GC image #' num2str(n)])
                dp.Display(n);
                pause(1);
            end
            
            dp.CloseScreen();
            
            %process them
            d.Process(IList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            D=zList{1}; %absolute order fron GC
            V=zList{2}; %Visibility
            
            figure; imagesc(D); colormap gray; title('Fringe order');
            figure; imagesc(V); colormap jet; colorbar; title('Visibility');            
                        
        end
        
        
        
        
    end
    
end
