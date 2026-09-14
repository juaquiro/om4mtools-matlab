classdef testFPADemodulatorPSA6MultiplexedXY < matlab.unittest.TestCase
    %run(testFPADemodulatorPSA6MultiplexedXY)
    
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            clc
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
            %run(testFPADemodulatorPSA6MultiplexedXY, 'testAllDemodulatorsConstructors')
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
            %run(testFPADemodulatorPSA6MultiplexedXY, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.PSA6MultiplexedXY);
            
            testCase.assertTrue(isa(d, 'DemodulatorPSA6MultiplexedXY'));
            testCase.assertClass(d, 'DemodulatorPSA6MultiplexedXY');
            
            %check def values
            Tx=8;
            testCase.assertEqual(Tx, d.Get(char(DemodulatorProps.Tx)));
            
            Ty=8;
            testCase.assertEqual(Ty, d.Get(char(DemodulatorProps.Ty)));
            
            %check bias and mod def values
            biasFP=255/2;
            testCase.assertEqual(biasFP, d.biasFP);
            
            modFP=255/4;
            testCase.assertEqual(modFP, d.modFP);
            
            NIgrams=6;
            testCase.assertEqual(NIgrams, d.Get(char(DemodulatorProps.NIgrams)));
            
            %set deltaList whithout using the class Set
            s1=[0, pi, -pi/2, pi/2, 0, -pi/2]; %phase steps p1
            s2=[0, 0, -pi/2, -pi/2, pi, pi/2];  %phase steps p2
            d4check=struct('X', s1, 'Y', s2);
            deltaList=d.Get(char(DemodulatorProps.deltaList));
            testCase.assertEqual(deltaList.X, d4check.X);
            testCase.assertEqual(deltaList.Y, d4check.Y);
            
        end
        
        %here we generate a set of 6 PSA multiplexed patternd and
        %demodulate them by a DemodulatorPSA6MultiplexedXY
        %Here we show that for "perfect igrams" modulation is constant and
        %for rounded igrams appear an error in the modulation of about 1GV
        function testGenFPsRawAndProcess(testCase)
            %run(testFPADemodulatorPSA6MultiplexedXY,'testGenFPsRawAndProcess')
            
            % calculate the igrams
            NR=512; NC=511;
            p=peaks(max(NR, NC)); p=imresize(p, [NR, NC]);
            
            [x,y]=meshgrid(1:NC, 1:NR); %XY in au
            [px, py]=gradient(p);
            
            Z=100; %separation grid lens in au
            T=150; %grid period in px
            K=2*pi*Z/T; %sensitivity
            
            FF1=2*pi/T; %fringes/px
            theta1=90; %orientation in deg
            w1=FF1*[cosd(theta1), sind(theta1)]; %spatial carrier in Fringes/px
            wt1=pi/2; %temporal carrier in rad/sample
            p1=px.*cosd(theta1)+py.*sind(theta1); %directional derivative along n1
            
            
            FF2=2*pi/T; %fringes/px
            theta2=0; %orientation in deg
            w2=FF2*[cosd(theta2), sind(theta2)]; %spatial carrier in Fringes/px
            wt2=pi/4; %temporal carrier in rad/sample
            p2=px.*cosd(theta2)+py.*sind(theta2); %directional derivative along n2
            
            b=252/2; %background
            m=252/4; %modulation
            
            NSteps=6;
            s1=[0, pi, -pi/2, pi/2, 0, -pi/2]; %phase steps p1
            s2=[0, 0, -pi/2, -pi/2, pi, pi/2];  %phase steps p2
            
            %if we use "perfect" igrmams modulation is
            %constant=2*m=252/4=126 for m_x and m_y and 252 for m_x + m_y
            gList=cell(1, NSteps);
            for n=1:NSteps
                gg=(b+m*cos(2*pi*Z*p1/T + w1(1)*x + w1(2)*y + s1(n)) + m*cos(2*pi*Z*p2/T + w2(1)*x + w2(2)*y + s2(n))) ;
                gList{n}=gg;
            end
            
            
            %create demodulator and process
            d=DemodulatorFactory.Create(DemodulatorTypes.PSA6MultiplexedXY);
            d.Process(gList);
            zList=d.Get(char(DemodulatorProps.zList));
            z1=zList{1}; %x deflection
            z2=zList{2}; %y deflection
            
            %figure; imagesc(gg); colormap jet;
            figure; imagesc(angle(z1)); colormap jet; drawnow;  title('\phi_x PSA6');
            figure; imagesc(abs(z1)); colormap jet; drawnow;  title('m_x PSA6');
            xh=0:255; h=hist(abs(z1(:)), xh); plot(xh, h, '.-'); title('m_x histogram PSA6');
            
            figure; imagesc(angle(z2)); colormap jet; drawnow; title('\phi_y PSA6');
            figure; imagesc(abs(z2)); colormap jet; drawnow;  title('m_y PSA6');
            xh=0:255; h=hist(abs(z2(:)), xh); plot(xh, h, '.-'); title('m_y histogram PSA6');
            
            figure; imagesc(abs(z1)+abs(z2)); colormap flag; drawnow;  title('m_x + m_y PSA6');
            
            %if we use "rounded" igrams modulation is
            %constant=2*m=252/4=126 + 1GV noise for m_x and m_y and 252 + 2GV noise for m_x + m_y
            gList=cell(1, NSteps);
            for n=1:NSteps
                gg=round(b+m*cos(2*pi*Z*p1/T + w1(1)*x + w1(2)*y + s1(n)) + m*cos(2*pi*Z*p2/T + w2(1)*x + w2(2)*y + s2(n))) ;
                NN=25;
                gg=conv2(gg, ones(NN)/NN^2, 'same');
                gList{n}=gg;
            end
            
            
            %create demodulator and process
            d=DemodulatorFactory.Create(DemodulatorTypes.PSA6MultiplexedXY);
            d.Process(gList);
            zList=d.Get(char(DemodulatorProps.zList));
            z1=zList{1}; %x deflection
            z2=zList{2}; %y deflection
            
            %figure; imagesc(gg); colormap jet;
            figure; imagesc(angle(z1)); colormap jet; drawnow;  title('\phi_x rounded igram PSA6');
            figure; imagesc(abs(z1)); colormap jet; drawnow;  title('m_x rounded igram PSA6');
            xh=0:255; h=hist(abs(z1(:)), xh); plot(xh, h, '.-'); title('m_x histogram rounded igram PSA6');
            
            figure; imagesc(angle(z2)); colormap jet; drawnow; title('\phi_y rounded igram PSA6');
            figure; imagesc(abs(z2)); colormap jet; drawnow;  title('m_y rounded igram PSA6');
            xh=0:255; h=hist(abs(z2(:)), xh); plot(xh, h, '.-'); title('m_y histogram rounded igram PSA6');
            
            figure; imagesc(abs(z1)+abs(z2)); colormap flag; drawnow;  title('m_x + m_y rounded igram PSA6');
        end      
        
        %here we load a set of experimental PSA multiplexed patterns and
        %demodulate them by a DemodulatorPSA6MultiplexedXY
        %the we load a set of 4 in X and 4 in Y igrams of the same lens and
        %process them using a PSAEq demodulator
        %Here we show how the SNR of the PSA6 modulation looks a little bit
        %worst that the modulation of the equispaced
        function testLoadExpIgramsAndProcess(testCase)
            %run(testFPADemodulatorPSA6MultiplexedXY,'testLoadExpIgramsAndProcess')
            
            %load igrams
            dropboxDir=fixturesRoot();
            measureDir='Imagenes PSA8 y PSA6 Heuristico';
            measureNamePSA6='PSA6AltaFrecuencia.mat';
            %measureNamePSA6='PSA6BajaFrecuencia.mat';
                        
            
            measureNamePSAEq='LSPSAAltaFrecuencia.mat';
            %measureNamePSAEq='LSPSABajaFrecuencia.mat';
            %measureNamePSAEq='LSPSASQBajaFrecuencia.mat';
            
            
            
            fileNamePSA6=fullfile(dropboxDir, measureDir, measureNamePSA6); 
            S=load(fileNamePSA6);
            gList=S.IList;
            
            gpsa6=double(gList{1});
            GPSA6=log(abs(fftshift(fft2(gpsa6)))+1);            
            figure; imagesc(gpsa6); title('PSA6 1st pattern')
            figure; imagesc(GPSA6); title('PSA6 1st pattern spectrum')

            
            
            %create demodulator and process
            dPSA6=DemodulatorFactory.Create(DemodulatorTypes.PSA6MultiplexedXY);
            dPSA6.Process(gList);
            zList=dPSA6.Get(char(DemodulatorProps.zList));
            z1=zList{1}; %x deflection
            z2=zList{2}; %y deflection
            
            %figure; imagesc(gg); colormap jet;
            figure; imagesc(angle(z1)); colormap jet; drawnow;  title('\phi_x PSA6');
            figure; imagesc(abs(z1)); colormap jet; drawnow;  title('m_x PSA6');
            xh=0:255; h=hist(abs(z1(:)), xh); plot(xh, h, '.-'); title('m_x histogram PSA6');
            
            figure; imagesc(angle(z2)); colormap jet; drawnow; title('\phi_y PSA6');
            figure; imagesc(abs(z2)); colormap jet; drawnow;  title('m_y PSA6');
            xh=0:255; h=hist(abs(z2(:)), xh); plot(xh, h, '.-'); title('m_y histogram PSA6');
            
            mxPSA6=abs(z1);
            mxyPSA6=abs(abs(z1)-abs(z2));
            figure; imagesc(mxyPSA6); colormap jet; drawnow;  title('m_x + m_y PSA6');
            figure; imagesc(mxPSA6); colormap jet; drawnow;  title('m_x PSA6');
            
            
            %for comparison purposes we use a X and then Y PS4 equispaced method
            
            %Load igrams            

            fileNamePSAEq=fullfile(dropboxDir, measureDir, measureNamePSAEq); 
            S=load(fileNamePSAEq);
            gListHor=S.IListHor;
            gListVer=S.IListVer;
            
            gpsa4eq=double(gListHor{1})+double(gListVer{1});
            GPSA4EQ=log(abs(fftshift(fft2(gpsa4eq)))+1);            
            figure; imagesc(gpsa4eq); title('PSA4 Eq 1st pattern X+Y')
            figure; imagesc(GPSA4EQ); title('PSA4 Eq 1st pattern X+Y spectrum')

            
                      
            %create demodulator and process           
            dPSAEq=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            %In QCZebra we are using 4 NIgrams
            NIgrams=4;
            dPSAEq.Set(char(DemodulatorProps.NIgrams), NIgrams);
                        
            dPSAEq.Process(gListHor);
            zList=dPSAEq.Get(char(DemodulatorProps.zList));
            z1=zList{1}; %x deflection
            
            dPSAEq.Process(gListVer);
            zList=dPSAEq.Get(char(DemodulatorProps.zList));
            z2=zList{1}; %y deflection                       

            
            %figure; imagesc(gg); colormap jet;
            figure; imagesc(angle(z1)); colormap jet; drawnow;  title('\phi_x PSA Equispaced');
            figure; imagesc(abs(z1)); colormap jet; drawnow;  title('m_x PSA Equispaced');
            xh=0:255; h=hist(abs(z1(:)), xh); plot(xh, h, '.-'); title('m_x histogram PSA Equispaced');
            
            figure; imagesc(angle(z2)); colormap jet; drawnow; title('\phi_y PSA Equispaced');
            figure; imagesc(abs(z2)); colormap jet; drawnow;  title('m_y PSA Equispaced');
            xh=0:255; h=hist(abs(z2(:)), xh); plot(xh, h, '.-'); title('m_y histogram PSA Equispaced');
            
            mxPSAEq=abs(z1);
            mxyPSAEq=abs(abs(z1)-abs(z2));
            figure; imagesc(mxyPSAEq); colormap jet; drawnow;  title('m_x + m_y PSA Equispaced');
            figure; imagesc(mxPSAEq); colormap jet; drawnow;  title('m_x PSA Equispaced');
            
            
            
            [NR, NC]=size(mxyPSAEq);
            r0=681;
            figure; plot(1:NC, mxyPSAEq(r0, :), 1:NC, mxyPSA6(r0, :)); legend({'mxyPSAEq', 'mxyPSA6'});
            figure; plot(1:NC, mxPSAEq(r0, :), 1:NC, mxPSA6(r0, :)); legend({'mxPSAEq', 'mxPSA6'});
            
            
            %example images for DefectClasificationInQCZebra.pptx
            imagesc(gListVer{1}), colormap gray; axis equal
            imagesc(angle(z2)), colormap gray; axis equal
            imagesc(abs(z2)), colormap jet; axis equal          
            
        end      
        
        
        
        
        
        
        
        function testGenFPsAndProcess(testCase)
            %run(testFPADemodulatorPSA6MultiplexedXY,'testGenFPsAndProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.PSA6MultiplexedXY);
            
            testCase.assertTrue(isa(d, 'DemodulatorPSA6MultiplexedXY'));
            testCase.assertClass(d, 'DemodulatorPSA6MultiplexedXY');
            
            %check bias and mod def values
            biasFP=255/2;
            testCase.assertEqual(biasFP, d.biasFP);
            
            modFP=255/4;
            testCase.assertEqual(modFP, d.modFP);
            
            
            %set fringe perios (default 8)
            d.Set(char(DemodulatorProps.Tx), 50);
            d.Set(char(DemodulatorProps.Ty), 100);
                        
            
            %create display
            %create also a disp projecto
            dp=DisplayFactory.Create(DisplayTypes.JavaDisp);                                    
            
            %generate the FPS and store them in the projector
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            N=d.Get(char(DemodulatorProps.NIgrams));
            for n=1:N
                dp.Display(n);
                pause(1);
            end
            
            dp.CloseScreen();
            
            %process the generated FPs
            tic;
            for k=1:10
            d.Process(dp.gList);
            end
            t=toc;
            fprintf('\n Phasor Processing time: %3.3d s \n', t/10 )
            
            zList=d.Get(char(DemodulatorProps.zList));
            zx=zList{1}; zy=zList{2};
            
            %default calulates mod and phase
            testCase.assertTrue(not(isreal(zx)));
            testCase.assertTrue(not(isreal(zy)));
            
            figure; imagesc(angle(zx)); title('\phi_x'); colormap gray;
            figure; imagesc(abs(zx)); title('m_x'); colormap gray;
            
            figure; imagesc(angle(zy)); title('\phi_y'); colormap gray;            
            figure; imagesc(abs(zy)); title('m_y'); colormap gray;      
            
            %now calulate only modulation
            d.onlyModFlag=true;
            tic;
            for k=1:10
            d.Process(dp.gList);
            end
            t=toc;
            fprintf('\n modulation Processing time: %3.3d s \n', t/10 )
            
            zList=d.Get(char(DemodulatorProps.zList));
            mx=zList{1}; my=zList{2};
            
            %default calulates mod and phase
            testCase.assertTrue(isreal(mx));
            testCase.assertTrue(isreal(my));
            
            figure; imagesc(mx); title('m_x'); colormap gray;
            figure; imagesc(my); title('m_y'); colormap gray;
            figure; imagesc(mx+my); title('m_x + m_y'); colormap gray;
            
                        
        end
        
         function testGenFPsAndProcessSquareWave(testCase)
            %run(testFPADemodulatorPSA6MultiplexedXY,'testGenFPsAndProcessSquareWave')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.PSA6MultiplexedXY);
            
            testCase.assertTrue(isa(d, 'DemodulatorPSA6MultiplexedXY'));
            testCase.assertClass(d, 'DemodulatorPSA6MultiplexedXY');
            
            %check bias and mod def values
            biasFP=255/2;
            testCase.assertEqual(biasFP, d.biasFP);
            
            modFP=255/4;
            testCase.assertEqual(modFP, d.modFP);
            
            
            %set fringe perios (default 8)
            d.Set(char(DemodulatorProps.Tx), 50);
            d.Set(char(DemodulatorProps.Ty), 100);
                        
            
            %create display
            %create also a disp projecto
            dp=DisplayFactory.Create(DisplayTypes.JavaDisp);                                    
            
            %generate the FPS and store them in the projector
            d.shape = 1; %square wave defautlt 0 (sine wave)
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            N=d.Get(char(DemodulatorProps.NIgrams));
            for n=1:N
                dp.Display(n);
                pause(1);
            end
            
            dp.CloseScreen();
            
            %process the generated FPs
            tic;
            for k=1:10
            d.Process(dp.gList);
            end
            t=toc;
            fprintf('\n Phasor Processing time: %3.3d s \n', t/10 )
            
            zList=d.Get(char(DemodulatorProps.zList));
            zx=zList{1}; zy=zList{2};
            
            %default calulates mod and phase
            testCase.assertTrue(not(isreal(zx)));
            testCase.assertTrue(not(isreal(zy)));
            
            figure; imagesc(angle(zx)); title('\phi_x'); colormap gray;
            figure; imagesc(abs(zx)); title('m_x'); colormap gray;
            
            figure; imagesc(angle(zy)); title('\phi_y'); colormap gray;            
            figure; imagesc(abs(zy)); title('m_y'); colormap gray;      
            
            %now calulate only modulation
            d.onlyModFlag=true;
            tic;
            for k=1:10
            d.Process(dp.gList);
            end
            t=toc;
            fprintf('\n modulation Processing time: %3.3d s \n', t/10 )
            
            zList=d.Get(char(DemodulatorProps.zList));
            mx=zList{1}; my=zList{2};
            
            %default calulates mod and phase
            testCase.assertTrue(isreal(mx));
            testCase.assertTrue(isreal(my));
            
            figure; imagesc(mx); title('m_x'); colormap gray;
            figure; imagesc(my); title('m_y'); colormap gray;                        
         end        
                            
    end
    
end
