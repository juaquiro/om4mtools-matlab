classdef testFPADecoderRGB < matlab.unittest.TestCase
    %run(testFPADecoderRGB)
    
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
        function testFPADecoderRGBConstructor(testCase)
            %run(testFPADecoderRGB, 'testFPADecoderRGBConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %load calibration
            RGBCalib=load('CalibracionRGB.txt'); %[Nx4]
            
            decoRGB=DecoderRGB(RGBCalib);
            
            testCase.assertEqual(0,decoRGB.Lambda);            
            testCase.assertTrue(isempty(decoRGB.DeltaMap));            
            testCase.assertTrue(isempty(decoRGB.procMask));            

        end
        
        %here we use the calibration curve of the paper  "Improved method for isochromatic demodulation by RGB calibration,"
        %to decode the arc image
        function testDecodeArcImage(testCase)
            %run(testFPADecoderRGB, 'testDecodeArcImage')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %load calibration 
            RGBCalib=load('CalibracionRGB.txt'); %[Nx4]            
            decoRGB=DecoderRGB(RGBCalib);                     
            
            %load image and mask
            g=double(imread('Puente1_fluorescencia.tif'));
            roiMask=double(imread('Mask_Puente1_fluorescencia.tif'));
            
            %decimate inputs
            DF=3; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);            
                        
            %default values for d0 0 and starting point P0 automatic
            decoRGB.Process(g, roiMask);
            
            figure; imagesc(decoRGB.DeltaMap); title('decoded RGB image');
            figure; imagesc(decoRGB.procMask); title('processed Mask');                      
        end

        %calculate RGBCalib curve from a image and save it for later use
        function testExtractRGBCalib(testCase)
            %run(testFPADecoderRGB, 'testExtractRGBCalib')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %Load RGB, Delta and Mask
            baseDir=fullfile(fixturesRoot(),'DiscoRGBFluo');
            RGBDeltaMeasureFileName='RGBDeltaMeasure.mat';
            S=load(fullfile(baseDir,RGBDeltaMeasureFileName));
            roiMask=S.M;
            DeltaMap=S.deltaM;
            g=S.cdf;

            [RGBCalib, RGBCalibSigma]=DecoderRGB.ExtractRGBCalib(g, roiMask, DeltaMap);
            
            figure; plot3(RGBCalib(:, 2), RGBCalib(:, 3), RGBCalib(:, 4), '-o'); title('RGCALIB')
            figure; plot3(RGBCalibSigma(:, 2), RGBCalibSigma(:, 3), RGBCalibSigma(:, 4), '-o'); title('RGCALIB SIGMA')
            
            interpFactor=5;
            InterpRGBCalib=DecoderRGB.interpRGBCalibration(RGBCalib, interpFactor);     
            figure; 
            plot3(InterpRGBCalib(:, 2), InterpRGBCalib(:, 3), InterpRGBCalib(:, 4), '.-', RGBCalib(:, 2), RGBCalib(:, 3), RGBCalib(:, 4), 'o')
            title(['RGBCalibration vs interpolation with factor' num2str(interpFactor)]);
            
            %AQDEBUG descomentar para calcular
            %save([Logging.WhoCalledMe() 'CalibrationRGB.txt'], 'RGBCalib', '-ascii');
            
%             
%             
% %             g=double(imread('Puente1_fluorescencia.tif'));
% %             roiMask=double(imread('Mask_Puente1_fluorescencia.tif'));
% %             
% %             g=double(imread(fullfile(baseDir,'Disco_resolucion.tif')));
% %             roiMask=double(imread(fullfile(baseDir,'Mask_Disco_resolucion.tif')));
%           
% 
% 
%             decoRGB=DecoderRGB(RGBCalib);      
%             %decimate inputs
%             DF=2; %decimation factor
%             g=g(1:DF:end,1:DF:end, :);
%             roiMask=roiMask(1:DF:end, 1:DF:end);            
%             
%                         
%             %default values for d0 0 and starting point P0 automatic
%             P0.x=2*100; P0.y=2*74; d0=22;
%             %P0.x=96; P0.y=263; d0=0;
%             %P0=[]; d0=0;
%             decoRGB.Lambda=0;           
%             %normalize all channels
% %             gmod=zeros(size(g));
% %             for n=1:3
% %                 [g(:, :, n), gmod(:, :, n)]=UtilFunFPA.IgramNorm(g(:, :, n), R);
% %                 g(:, :, n)=128*(g(:, :, n)+1);
% %             end
% 
%             
%             decoRGB.Process(g, roiMask, d0, P0);
            
        end
        
        
        %here we use the self-calibration determined in run(testFPADecoderRGB, 'testExtractRGBCalib') for the decoding of the same RGB image
        function testDecodeDiskImageWithSelfCalibration(testCase)
            %run(testFPADecoderRGB, 'testDecodeDiskImageWithSelfCalibration')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %load calibration 
            RGBCalib=load('testFPADecoderRGB.testExtractRGBCalibCalibrationRGB.txt'); %[Nx4]            
            decoRGB=DecoderRGB(RGBCalib);                     
            
            %load image and mask
            %Load RGB, Delta and Mask
            baseDir=fullfile(fixturesRoot(),'DiscoRGBFluo');
            RGBDeltaMeasureFileName='RGBDeltaMeasure.mat';
            S=load(fullfile(baseDir,RGBDeltaMeasureFileName));
            roiMask=S.M;
            DeltaMap=S.deltaM;
            g=S.cdf;
            
            %decimate inputs for processing
            DF=4; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);            
            DeltaMap=DeltaMap(1:DF:end, 1:DF:end);
                        
            %Here we set a point at the disk centre with known retardation
            %value
            decoRGB.dwidth=0.015; %in (%) 
            P0.x=99; P0.y=73; d0=22;
            decoRGB.Process(g, roiMask, d0, P0);
            
            figure; imagesc(decoRGB.DeltaMap); title('decoded RGB image');
            figure; imagesc(decoRGB.procMask); title('processed Mask');     
            
            figure; imagesc((decoRGB.DeltaMap-DeltaMap).*decoRGB.procMask); title('decoded RGB image');
            
            x=linspace(-4*pi, 4*pi, 100);
            de=decoRGB.DeltaMap-DeltaMap; de=de(decoRGB.procMask==1);
            h=hist(de, x);
            figure; plot(x, h); title('error histogram'); xlabel('\epsilon(rad)');
            
        end
        
        %here we use the self-calibration determined in run(testFPADecoderRGB, 'testExtractRGBCalib') for the decoding of the same RGB image
        function testDecodeDiskImageWithSelfCalibrationAndRefinement(testCase)
            %run(testFPADecoderRGB, 'testDecodeDiskImageWithSelfCalibrationAndRefinement')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %load calibration 
            RGBCalib=load('testFPADecoderRGB.testExtractRGBCalibCalibrationRGB.txt'); %[Nx4]            
            decoRGB=DecoderRGB(RGBCalib);                     
            
            %load image and mask
            %Load RGB, Delta and Mask
            baseDir=fullfile(fixturesRoot(),'DiscoRGBFluo');
            RGBDeltaMeasureFileName='RGBDeltaMeasure.mat';
            S=load(fullfile(baseDir,RGBDeltaMeasureFileName));
            roiMask=S.M;
            DeltaMap=S.deltaM;
            g=S.cdf;
            
            %decimate inputs for processing
            DF=2; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);            
            DeltaMap=DeltaMap(1:DF:end, 1:DF:end);
                        
            %Here we set a point at the disk centre with known retardation
            %value
            decoRGB.dwidth=0.015; %in (%) 
            P0.x=400/DF; P0.y=284/DF; d0=22;
            decoRGB.Process(g, roiMask, d0, P0);
            
            %refinement
            decoRGB.Lambda=100;
            decoRGB.Process(g, roiMask, d0, P0, decoRGB.DeltaMap, decoRGB.procMask);            
            
            
            figure; imagesc(decoRGB.DeltaMap); title('decoded RGB image');
            figure; imagesc(decoRGB.procMask); title('processed Mask');     
            
            figure; imagesc((decoRGB.DeltaMap-DeltaMap).*decoRGB.procMask); title('decoded RGB image');
            
            x=linspace(-4*pi, 4*pi, 100);
            de=decoRGB.DeltaMap-DeltaMap; de=de(decoRGB.procMask==1);
            h=hist(de, x);
            figure; plot(x, h); title('error histogram'); xlabel('\epsilon(rad)');
            
         
            
        end
        
        %here we use the self-calibration determined in
        %run(testFPADecoderRGB, 'testExtractRGBCalib') for the decoding of
        %the arc
        function testDecodeRingImageWithSelfCalibration(testCase)
            %run(testFPADecoderRGB, 'testDecodeRingImageWithSelfCalibration')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %load calibration 
            RGBCalib=load('testFPADecoderRGB.testExtractRGBCalibCalibrationRGB.txt'); %[Nx4]            
            decoRGB=DecoderRGB(RGBCalib);                     
            
            %load image and mask
            %Load RGB, Delta and Mask
            baseDir=fullfile(fixturesRoot(),'AnilloRGBFluo');
            RGBDeltaMeasureFileName='RGBDeltaMeasure.mat';
            S=load(fullfile(baseDir,RGBDeltaMeasureFileName));
            roiMask=S.M;
            DeltaMap=S.deltaM;
            g=S.cdf;
            
            %decimate inputs for processing
            DF=3; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);            
            DeltaMap=DeltaMap(1:DF:end, 1:DF:end);
                        
            %Here we set a point at the disk centre with known retardation
            %value
            decoRGB.Lambda=1;
            decoRGB.dwidth=0.1; %in (%) 
            d0=15; P0.x=round(350/DF);P0.y=round(76/DF);            
            decoRGB.Process(g, roiMask, d0, P0);              
            
            figure; imagesc(decoRGB.DeltaMap); title('decoded RGB image');
            figure; imagesc(decoRGB.procMask); title('processed Mask');     
            
            figure; imagesc((decoRGB.DeltaMap-DeltaMap).*decoRGB.procMask); title('difference image');
            
            x=linspace(-4*pi, 4*pi, 100);
            de=decoRGB.DeltaMap-DeltaMap; de=de(decoRGB.procMask==1); 
            h=hist(de, x);
            figure; plot(x/(pi), h); title('error histogram'); xlabel('\epsilon(rad)/\pi');
            
        end
        
        
        %here we use the self-calibration determined in
        %run(testFPADecoderRGB, 'testExtractRGBCalib') for the decoding of
        %the arc
        function testDecodeRingImageWithSelfCalibrationAndRefinement(testCase)
            %run(testFPADecoderRGB, 'testDecodeRingImageWithSelfCalibrationAndRefinement')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %load calibration 
            RGBCalib=load('testFPADecoderRGB.testExtractRGBCalibCalibrationRGB.txt'); %[Nx4]            
            decoRGB=DecoderRGB(RGBCalib);                     
            
            %load image and mask
            %Load RGB, Delta and Mask
            baseDir=fullfile(fixturesRoot(),'AnilloRGBFluo');
            RGBDeltaMeasureFileName='RGBDeltaMeasure.mat';
            S=load(fullfile(baseDir,RGBDeltaMeasureFileName));
            roiMask=S.M;
            DeltaMap=S.deltaM;
            g=S.cdf;
            
            %decimate inputs for processing
            DF=2; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);            
            DeltaMap=DeltaMap(1:DF:end, 1:DF:end);
                        
            %Here we set a point at the disk centre with known retardation
            %value
            decoRGB.Lambda=1;
            decoRGB.dwidth=0.1; %in (%) 
            d0=15; P0.x=round(350/DF);P0.y=round(76/DF);            
            decoRGB.Process(g, roiMask, d0, P0);              
            
            %refinement
            decoRGB.Lambda=100;
            decoRGB.dwidth=0.1; %in (%) 
            d0=decoRGB.DeltaMap(P0.y, P0.x);
            decoRGB.Process(g, roiMask, d0, P0, decoRGB.DeltaMap, decoRGB.procMask);             
            
            
            figure; imagesc(decoRGB.DeltaMap); title('decoded RGB image');
            figure; imagesc(decoRGB.procMask); title('processed Mask');     
            
            figure; imagesc((decoRGB.DeltaMap-DeltaMap).*decoRGB.procMask); title('difference image');
            
            x=linspace(-4*pi, 4*pi, 100);
            de=decoRGB.DeltaMap-DeltaMap; de=de(decoRGB.procMask==1); 
            h=hist(de, x);
            figure; plot(x/(pi), h); title('error histogram'); xlabel('\epsilon(rad)/\pi');
            
        end
        
        
        
        %here we use the self-calibration determined in
        %run(testFPADecoderRGB, 'testExtractRGBCalib') for the decoding of
        %the arc image
        function testDecodeArcImageWithSelfCalibration(testCase)
            %run(testFPADecoderRGB, 'testDecodeArcImageWithSelfCalibration')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %load calibration 
            RGBCalib=load('testFPADecoderRGB.testExtractRGBCalibCalibrationRGB.txt'); %[Nx4]            
            decoRGB=DecoderRGB(RGBCalib);                     
            
            %load image and mask
            %Load RGB, Delta and Mask
            g=double(imread('Puente1_fluorescencia.tif'));
             roiMask=double(imread('Mask_Puente1_fluorescencia.tif'));
            
            %decimate inputs for processing
            DF=4; %decimation factor
            g=g(1:DF:end,1:DF:end, :);
            roiMask=roiMask(1:DF:end, 1:DF:end);            
                        
            %Here we set a point at the disk centre with known retardation
            %value
            decoRGB.dwidth=0.015;%in (%) default value     
            d0=0; P0=[];
            decoRGB.Process(g, roiMask, d0, P0);
            
            figure; imagesc(decoRGB.DeltaMap); title('decoded RGB image');
            figure; imagesc(decoRGB.procMask); title('processed Mask');     
                        
        end

        
        
        
    end
    
end
