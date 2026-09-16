classdef testFPADemodulatorSpatialFT < matlab.unittest.TestCase
    %run(testFPADemodulatorSpatialFT)
    
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
            %run(testFPADemodulatorSpatialFT, 'testAllDemodulatorsConstructors')
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
        
                                
        
        function testDemodulatorFTGenFPs(testCase)
            %run(testFPADemodulatorSpatialFT, 'testDemodulatorFTGenFPs')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=391;
            NC=388;
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FT);
            
            %for FT set FF instead of using default Tx and Ty
            FF=30;
            Tx=round(NC/FF); Ty=round(NR/FF);
            d.Set(char(DemodulatorProps.Tx), Tx);
            d.Set(char(DemodulatorProps.Tx), Ty);
            
            gList=d.GenerateFPs([NR, NC]);
            
            %4 lobes
            FPList=gList(1);
            d.Process(FPList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            zx=zList{1};
            zy=zList{2};
            
            px=angle(zx); py=angle(zy);
            
            figure; imagesc(px); colormap gray
            figure; imagesc(py); colormap gray
            
            
            g=uint8(255*0.25*(2+cos(px)+cos(py)));
            gd=FPList{1}-g;
            
            absTol=1;
            figure; imshow(gd);
            testCase.assertEqual(mean(gd(:)), 0, 'AbsTol', absTol);
            
            
            %2 lobes X
            FPList=gList(2); %vertical
            d.Set(char(DemodulatorProps.NL), 2);
            d.Process(FPList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            p=angle(z);
            figure; imagesc(p); colormap gray
            
            
            g=uint8(255*0.5*(2+cos(p)));
            gd=FPList{1}-g;
            
            absTol=0.5;
            figure; imshow(gd);
            testCase.assertEqual(mean(gd(:)), 0, 'AbsTol', absTol);
            
            %2 lobes Y
            FPList=gList(3); %horizontal
            d.Set(char(DemodulatorProps.NL), 2);
            d.Process(FPList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            p=angle(z);
            figure; imagesc(p); colormap gray
            
            
            g=uint8(255*0.5*(2+cos(p)));
            gd=FPList{1}-g;
            
            absTol=0.5;
            figure; imshow(gd);
            testCase.assertEqual(mean(gd(:)), 0, 'AbsTol', absTol);
            
            
            
            
            
        end
        
        
        

        function testDemodulatorFT(testCase)
            %run(testFPADemodulatorSpatialFT, 'testDemodulatorFT')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FT);
            
            testCase.assertTrue(isa(d, 'Demodulator'));
            testCase.assertClass(d, 'DemodulatorFT');
            
            %check all props are by default empty but NL that is 4 by
            %default
            [pt, pn]=enumeration('DemodulatorProps');
            for n=1:length(pn)
                p=d.Get(pn{n});
                t=pt(n);
                switch t
                    case DemodulatorProps.NL
                        testCase.assertEqual(p,4);
                    case DemodulatorProps.StepsTwoPwiRange
                        testCase.assertEqual(p,2*pi);
                    case {DemodulatorProps.Tx, DemodulatorProps.Ty}
                        testCase.assertEqual(p,8);
                    case DemodulatorProps.FFCut
                        testCase.assertEqual(p,1);
                    case DemodulatorProps.NFilt
                        testCase.assertEqual(p,5);
                    case DemodulatorProps.ROINormTH
                        testCase.assertEqual(p,0);
                    case DemodulatorProps.AbsolutePhasePSADemType
                        testCase.assertEqual(p,DemodulatorTypes.LSEquispacedPSA);
                    otherwise
                        testCase.assertTrue(isempty(p));
                end
            end
        end
        
        function testDemodulatorFTProcess(testCase)
            %run(testFPADemodulatorSpatialFT, 'testDemodulatorFTProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FT);
            
            %input FP and get all lobes
            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            FPList={gr};
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            
            %select lobes for moire deflectometry
            %    2
            %  1 x 3
            %    4
            LobeX=4;
            LobeY=3;
            
            zrx=zr{LobeX};
            zry=zr{LobeY};
            M=d.Get(char(DemodulatorProps.M));
            
            figure; imshow(mat2gray(angle(zrx)).*M); title('ref lobe Delta X');
            figure; imshow(mat2gray(angle(zry)).*M); title('ref lobe Delta Y');
            
            gc=double(imread('YO_D75_SMinus275_C0.bmp')); %low freq
            FPList={gc};
            d.Process(FPList);
            
            zc=d.Get(char(DemodulatorProps.zList));
            zcx=zc{LobeX};
            zcy=zc{LobeY};
            
            figure; imshow(mat2gray(angle(zcx)).*M); title('lens lobe Delta X');
            figure; imshow(mat2gray(angle(zcy)).*M); title('lens lobe Delta Y');
            
            M=gr>90;
            zx=(zcx./zrx); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zcy./zry);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py
            
            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);
            
            figure; imshow(mat2gray(angle(zx).*M)); title('Delta X');
            figure; imshow(mat2gray(angle(zy).*M)); title('Delta Y');
            
            
            %default val K is 1 mm^-1/rad
            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
            else
                K=1;
            end
            
            MLM=LensMapperMeasurement;
            MLM.zx=zx;
            MLM.zy=zy;
            MLM.zrx=zrx;
            MLM.zry=zry;


            MLM.CalculateLensPower(M, K);
            
            C=MLM.C; %mm^-1
            S=MLM.S; %mm^-1
            Seq=MLM.Seq; %mm^-1
            MC=MLM.M; %mask after CalculatePowerFromDefl
            
            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');
            
        end
        
        function testDemodulatorFTProcessExtendedMinusRange(testCase)
            %run(testFPADemodulatorSpatialFT, 'testDemodulatorFTProcessExtendedMinusRange')
            %see testFPA_UtilFunMapperMeasure:test_GetPower_CalibrationLensKPC076;
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FT);
            
            %input FP and get all lobes
            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            FPList={gr};
            %Process locate sidelobes in default positions and store ref lobe
            %positions and get ref phase
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            
            %select default lobes for moire deflectometry
            %    2
            %  1 x 3
            %    4
            LobeX=4;
            LobeY=3;
            
            zrx=zr{LobeX};
            zry=zr{LobeY};
            
            M=d.Get(char(DemodulatorProps.M));
            figure; imshow(mat2gray(angle(zrx)).*M); title('ref lobe Delta X');
            figure; imshow(mat2gray(angle(zry)).*M); title('ref lobe Delta Y');
            
            gc=double(imread('CalibrationLensKPC076.bmp')); %low freq
            M=double(imread('CalibrationLensKPC076_Mask.bmp')); %low freq
            M=mat2gray(M);
            gc=gc.*M;
            d.Set(char(DemodulatorProps.M),M);
            FPList={gc};
            
            %lobes ref position is already stored from former call to d.Process, if
            %default position is needed reset the w0 property to default value
            % by d.Set(char(DemodulatorProps.w0), []);
            d.Process(FPList);
            
            zc=d.Get(char(DemodulatorProps.zList));
            %AQDEBUG en el caso de la lente de -10 los lobulos han girado a lo bestia
            %casi 90 grados
            LobeX=1;
            LobeY=4;
            zcx=zc{LobeX};
            zcy=zc{LobeY};
            
            figure; imshow(mat2gray(angle(zcx)).*M); title('lens lobe Delta X');
            figure; imshow(mat2gray(angle(zcy)).*M); title('lens lobe Delta Y');
            
            zx=(zcx./zrx); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zcy./zry);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py
            
            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);
            
            figure; imshow(mat2gray(angle(zx).*M)); title('Delta X');
            figure; imshow(mat2gray(angle(zy).*M)); title('Delta Y');
            
            
            %default val K is 1 mm^-1/rad
            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
            else
                K=1;
            end
            
            MLM=LensMapperMeasurement;
            MLM.zx=zx;
            MLM.zy=zy;
            MLM.zrx=zrx;
            MLM.zry=zry;

            MLM.CalculateLensPower(M, K);
            
            C=MLM.C; %mm^-1
            S=MLM.S; %mm^-1
            Seq=MLM.Seq; %mm^-1
            MC=MLM.M; %mask after CalculatePowerFromDefl
            
            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');
            
        end
        
        
        function testDemodulatorFTProcessRedLineal(testCase)
            %run(testFPADemodulatorSpatialFT, 'testDemodulatorFTProcessRedLineal')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.FT);
            %set number of lobes
            d.Set(char(DemodulatorProps.NL), 2);
            LobeX=2;
            
            %input FP and get all lobes
            gr=double(imread('Ref_tapa.tif')); %low freq
            FPList={gr};
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zrx=zr{LobeX};
            
            M=d.Get(char(DemodulatorProps.M));
            
            gc=double(imread('Signal_tapa.tif')); %low freq
            FPList={gc};
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcx=zc{LobeX};
            
            
            zx=(zcx./zrx); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            
            figure; imshow(mat2gray(angle(zx).*M)); title('Delta X');
            
        end
        
    end
    
end
