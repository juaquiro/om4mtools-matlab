%> @file testFPA_UtilFunMapperMeasureClassVer.m
%> @brief File containint the ubnit tests for LensMapperMeasurement using the MATLAB class unit testing
%> @details con  R>R2016 el framework de pruebas mtest ya no funciona no podemos pasar las pruebas de testFPA_UtilFunFPA()
%> este fichero implementa pruebas unitarias de UtilFunFPA usando el test framework de
%> MATLAB basado en clases y compatible copn vers >= R2015
%> @see LensMapperMeasurement.m, testFPA_UtilFunMapperMeasure.m
%> @copyright 2016 IOT
%> @author AQ


% ======================================================================
%> @brief this is the class with the unit tests for LensMapperMeasurement
%> @details the problem is that the mtest unit testing framework does not run on R>2016a
%> @see LensMapperMeasurement
%> @author AQ 14APR20
% ======================================================================
classdef testFPA_UtilFunMapperMeasureClassVer < matlab.unittest.TestCase
    %run(testFPA_UtilFunMapperMeasureClassVer)

    methods(TestMethodSetup)
        function SetUp(testCase)
            close all;
            % close all Figures with the 'HandleVisibility' property set to 'off' will not be closed with "close all". To close these figures, use the command
            % delete(findall(0));
            setupPath();
        end
    end

    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m)
            %NOTE: in case of installing a support package it is very
            %important to make a savepath after the installation so it
            %reflects this change as "permanent" - resetPath itself only
            %ever returns the snapshot taken when this MATLAB session's
            %tests started, so a savepath'd support package stays on the
            %path across sessions either way
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end


    methods (Test)


        function testGenMapperMeasurement(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGenMapperMeasurement')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            LMM=LensMapperMeasurement;
            testCase.assertTrue(isa(LMM, 'LensMapperMeasurement'));
        end

        function testLensMapperMeasurementSaveLoad(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testLensMapperMeasurementSaveLoad')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            LMM=LensMapperMeasurement;
            p=properties(LMM);
            for n=1:length(p)
                if not(strcmp(p{n}, 'DerSign'))
                    testCase.assertTrue(isempty(LMM.(p{n})));
                    LMM.(p{n})=magic(10);
                end
            end

            %default file Name
            LensMapperMeasurement.save(LMM);
            fileName=['LensMapperMeasurement_' date '.mat'];
            testCase.assertTrue( exist(fileName, 'file')==2 );

            %check saved data is a struct with a filed LMM that is a struct
            %with fields the LMM public props
            S=load(fileName);
            testCase.assertTrue(isfield(S, 'LMM'));
            testCase.assertTrue(isa(S.LMM, 'struct'));

            %create LMM instance from the file with a struct
            LMM2=LensMapperMeasurement.load(fileName);
            for n=1:length(p)
                if not(strcmp(p{n}, 'DerSign'))
                    testCase.assertEqual(LMM2.(p{n}), magic(10));
                end
            end
            delete(fileName);

            %given fileName
            fileName='AQTestLMM.mat';
            LensMapperMeasurement.save(LMM, fileName);
            testCase.assertTrue( exist(fileName, 'file')==2 );

            LMM2=LensMapperMeasurement.load(fileName);
            for n=1:length(p)
                if not(strcmp(p{n}, 'DerSign'))
                    testCase.assertEqual(LMM2.(p{n}), magic(10));
                end
            end
            delete(fileName);

        end




        function testGetPowerProgHoya1(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPowerProgHoya1')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            gr=double(imread('ProgHoya1Ref.tif')); %low freq
            figure; imshow(mat2gray(gr));
            % wy=[56,1];
            % wx=[-2, 44];
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zrx=z{1};
            zry=z{2};

            % experimental data
            g=double(imread('ProgHoya1.tif')); %low freq
            figure; imshow(mat2gray(g));
            % wy=[56,-18];
            % wx=[23, 45];
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX}; %wx(1)=wx(1)+15; %AQDEBUG correct for a better lobe centering
            wy=w{LobeY}; %wy(2)=wy(2)-15; %AQDEBUG correct for a better lobe centering
            flatTopFlag=false;
            R=35; %band pass filter fringes field
            z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            zcx=z{1};
            zcy=z{2};



            M=g>35;
            zx=(zcx./zrx); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zcy./zry);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=3;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            K=[1 1]; %Kx, Ky mm^-1/rad
            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.zrx=zrx;
            LMM.zry=zry;

            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');

        end

        function testGetPowerProgHoya(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPowerProgHoya')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;


            gr=double(imread('ProgHoyaRef.tif')); %low freq
            % wy=[56,1];
            % wx=[-2, 44];
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zrx=z{1};
            zry=z{2};


            % experimental data
            g=double(imread('ProgHoya.tif')); %low freq
            % wy=[56,-18];
            % wx=[23, 45];
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX}; wx(1)=wx(1)+10; %AQDEBUG correct for a better lobe centering
            wy=w{LobeY}; wy(2)=wy(2)-10; %AQDEBUG correct for a better lobe centering
            flatTopFlag=true;
            R=35; %band pass filter fringes field
            z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            zcx=z{1};
            zcy=z{2};


            M=g>35;
            zx=(zcx./zrx); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zcy./zry);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=3;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            zx=conv2(zx, ones(3,3), 'same');
            zy=conv2(zy, ones(3,3), 'same');

            K=[1 1]; %Kx, Ky mm^-1/rad
            LMM=LensMapperMeasurement;
            LMM.zx=conv2(zx, ones(3,3), 'same');
            LMM.zy=conv2(zy, ones(3,3), 'same');
            LMM.zry=zry;
            LMM.zrx=zrx;

            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');

        end


        function testGetPowerLente3D_8D(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPowerLente3D_8D')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;


            gr=double(rgb2gray(imread('RefLente3D.bmp'))); %low freq
            % wy=[56,1];
            % wx=[-2, 44];
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            % experimental data
            g=double(rgb2gray(imread('Lente3D_8D.bmp'))); %low freq
            % wy=[56,-18];
            % wx=[23, 45];

            M=double(imread('lente3D_ODMask.bmp'));


            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX}; wx(1)=wx(1)+10; %AQDEBUG correct for a better lobe centering
            wy=w{LobeY}; wy(2)=wy(2)-10; %AQDEBUG correct for a better lobe centering
            flatTopFlag=true;
            R=35; %band pass filter fringes field
            z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            zxc=z{1};
            zyc=z{2};



            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=3;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            zx=conv2(zx, ones(3,3), 'same');
            zy=conv2(zy, ones(3,3), 'same');


            K=[1 1]; %Kx, Ky mm^-1/rad
            LMM=LensMapperMeasurement;

            %set ref fasor
            LMM.zrx=zxr;
            LMM.zry=zyr;

            LMM.zx=conv2(zx, ones(3,3), 'same');
            LMM.zy=conv2(zy, ones(3,3), 'same');
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');

        end



        function testGetPowerLinearPal(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPowerLinearPal')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());


            %select lobes
            %    2
            %  1 x 3
            %    4
            LobeX=3;
            LobeY=4;

            % experimental data generated by GenerateProgressive()
            load LinearPal.mat;
            g=L.g; %low freq


            w = UtilFunFPA.LocateSidelobes(g);
            wx=w{LobeX};
            wy=w{LobeY};
            R=15; %Low pass filter fringes field
            flatTopFlag=false;
            z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            zxc=z{1};
            zyc=z{2};

            gr=L.gr; %low freq
            w = UtilFunFPA.LocateSidelobes(gr);
            wx=w{LobeX};
            wy=w{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy}, flatTopFlag, R);
            zxr=z{1};
            zyr=z{2};

            M=L.M;
            zx=(zxc./zxr);
            zy=(zyc./zyr);

            figure; imagesc(mat2gray(angle(zx))); title('Delta X');
            figure; imagesc(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion
            K=L.px/(2*pi*L.D);

            LMM=LensMapperMeasurement;
            LMM.zx=zx; LMM.zrx=zxr;
            LMM.zy=zy; LMM.zry=zyr;

            LMM.CalculateLensPower(M, K);


            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*MC); title('S (D)');
            figure; imagesc(1000*C.*MC); title('Cyl (D)');
            figure; imagesc(1000*Seq.*MC); title('Seq (D)');
            figure; imagesc(MC); title('MQ');


            %check vs theoretical results
            eS=S-L.S; %error
            eC=C-L.C; %error
            eSeq=Seq-L.Seq; %error

            %eliminamos los bordes
            M=conv2(double(M), ones(50)/2500, 'same')>0.9;
            tol=0.6; %D
            testCase.assertEqual(0, 1e3*std(eS(MC)), 'AbsTol', tol);
            testCase.assertEqual(0, 1e3*std(eC(MC)), 'AbsTol', 2*tol);
            testCase.assertEqual(0, 1e3*std(eSeq(MC)), 'AbsTol', tol);

        end


        function testGetPowerErfPal(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPowerErfPal')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());



            %select lobes
            %    2
            %  1 x 3
            %    4
            LobeX=3;
            LobeY=4;


            % experimental data generated by GenerateProgressive()
            load ErfPal.mat;
            g=L.g; %low freq
            % R=15; %Low pass filter fringes field
            % wy=L.wy;
            % wx=L.wx;
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(g, paramsList);
            w = UtilFunFPA.LocateSidelobes(g);
            wx=w{LobeX};
            wy=w{LobeY};
            R=25; %Low pass filter fringes field
            flatTopFlag=false;
            z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            zxc=z{1};
            zyc=z{2};

            gr=L.gr; %low freq
            % wy=L.wy;
            % wx=L.wx;
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(gr, paramsList);
            w = UtilFunFPA.LocateSidelobes(gr);
            wx=w{LobeX};
            wy=w{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy}, flatTopFlag, R);
            zxr=z{1};
            zyr=z{2};

            M=L.M;
            zx=(zxc./zxr);
            zy=(zyc./zyr);

            figure; imagesc(mat2gray(angle(zx))); title('Delta X');
            figure; imagesc(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            %Cx, Cy Px=Cx*phix, Py=Cy*Phiy
            %in Deflectometry Phix=2*pi/px*P_x/D, so Cx=px/(2*pi*D)
            K=L.px/(2*pi*L.D);
            K=[K K]; %Kx, Ky mm^-1/rad


            LMM=LensMapperMeasurement;
            LMM.zx=zx; LMM.zrx=zxr;
            LMM.zy=zy; LMM.zry=zyr;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');

            %check vs theoretical results
            eS=S-L.S; %error
            eC=C-L.C; %error
            eSeq=Seq-L.Seq; %error


            %eliminamos los bordes
            MC=conv2(double(MC), ones(100)/1e4, 'same')>0.9;
            tol=2; %D
            testCase.assertEqual(0, 1e3*std(eS(logical(MC))), 'AbsTol', tol);
            testCase.assertEqual(0, 1e3*std(eC(logical(MC))), 'AbsTol', 2*tol);
            testCase.assertEqual(0, 1e3*std(eSeq(logical(MC))), 'AbsTol', tol);

        end


        function testGetPower_SwissCoat40L88031L(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_SwissCoat40L88031L')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');


            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data
            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(gr, paramsList);
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            g=double(imread('SwissCoat40L88031L.bmp')); %low freq
            % R=20; %Low pass filter fringes field
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(g, paramsList);
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX};
            wy=w{LobeY};
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};

            M=gr>30;
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %             %filter the phasors
            %             sigma=1;
            %             hsize=3*sigma;
            %             h=fspecial('gaussian', hsize, sigma);
            %             zx=imfilter(zx, h);
            %             zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
                K=[K, K];
            else
                K=[1 1];
            end

            LMM=LensMapperMeasurement;
            LMM.zx=zx; %LMM.zrx=zxr;
            LMM.zy=zy; %LMM.zry=zyr;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M, [-4 4]); title('S (D)');
            figure; imagesc(1000*C.*M, [-4 4]); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M, [-4 4]); title('Seq (D)');
            figure; imagesc(MC); title('MQ');


        end

        function testGetPower_SwissCoat40L88051R(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_SwissCoat40L88051R')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data

            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(gr, paramsList);
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            g=double(imread('SwissCoat40L88051R.bmp')); %low freq
            % R=20; %Low pass filter fringes field
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(g, paramsList);
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX};
            wy=w{LobeY};
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};


            M=medfilt2(abs(gr-g)>10, [15 15]);
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            zp=zx.*zy;
            zm=zx./zy;

            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
                K=[K, K]
            else
                K=[1,1];
            end

            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M, [0 5]); title('S (D)');
            figure; imagesc(1000*C.*M, [0 5]); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M, [0 5]); title('Seq (D)');
            figure; imagesc(MC); title('MQ ROI from TH gr');

        end


        function testGetPower_YO_D75_SMinus275_C0(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_YO_D75_SMinus275_C0')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;


            %% experimental data
            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            g=double(imread('YO_D75_SMinus275_C0.bmp')); %low freq
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX};
            wy=w{LobeY};
            flatTopFlag=false;
            R=35; %band pass filter fringes field
            %z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};



            M=medfilt2(abs(gr-g)>10, [15 15]);
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            %default val K is 1
            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
            else
                %calibration
                % for this lens P=-2.75D m;
                % crop center
                K=[1 1];
                LMM=LensMapperMeasurement;
                LMM.zx=zx;
                LMM.zy=zy;
                LMM.CalculateLensPower(M, K);

                Rs=220:270;
                Cs=290:360;
                PotNom=-2.75*1e-3; %mm^-1 Dato nominal
                VS=mean(mean(LMM.S(Rs,Cs)));
                Cal.K=PotNom/VS; %mm^-1/rad
                Cal.date=date;
                save(calFile, 'Cal');

                K=Cal.K;
                K=[K, K];
            end

            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');


            %load DLM files
            if exist('LoadMapperFile.m', 'file')
                MapperFile='YO_D75_SMinus275_C0.PMF';
                %load right eye, in transmission, for all types
                vaMeas={ 'T',   'M',    'L',    false};
                vaTeo={ 'T',   'T',    'L',    false};
                vaErr={ 'T',   'E',    'L',    false};

                SMeas=LoadMapperFile(MapperFile, vaMeas{:});
                STeo=LoadMapperFile(MapperFile, vaTeo{:});
                SErr=LoadMapperFile(MapperFile, vaErr{:});

                M=not(isnan(SMeas.Seq));
                figure; imagesc(SMeas.S.*M); title('DLM S (D)');
                figure; imagesc(SMeas.C.*M); title('DLM Cyl (D)');
                figure; imagesc(SMeas.Seq.*M); title('DLM Seq (D)');
                figure; imagesc( SMeas.A.*M); title('DLM A (deg)');
            end

        end




        function testGetPower_CalibrationLensKPC076(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_CalibrationLensKPC076')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data
            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            figure; imshow(mat2gray(gr));
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            g=double(imread('CalibrationLensKPC076.bmp')); %low freq
            figure; imshow(mat2gray(g));
            gM=double(imread('CalibrationLensKPC076_Mask.bmp')); %low freq
            gM=mat2gray(gM);
            g=g.*gM;
            R=50; %band pass filter fringes field
            w = UtilFunFPA.LocateSidelobes(g, wr, R);

            %AQDEBUG en el caso de la lente de -10 los lobulos han girado a lo bestia
            %casi 90 grados
            LobeX=1;
            LobeY=4;

            wx=w{LobeX};
            wy=w{LobeY};
            %z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};


            M=gM;%AQDEBUG
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(g.*gr).*M); title('Moire');
            figure; imshow(mat2gray(angle(zx)).*M); title('Delta X');
            figure; imshow(mat2gray(angle(zy)).*M); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
                K=[K, K];
            else
                %calibration
                % for this lens P=-2.75D m;
                % crop center
                K=[1,1];
                LMM=LensMapperMeasurement;
                LMM.zx=zx;
                LMM.zy=zy;
                LMM.CalculateLensPower(M, K);

                Rs=220:270;
                Cs=290:360;
                PotNom=-10*1e-3; %mm^-1 (este dato esta sacado de la especificacion EFL=0.100 m)
                VS=mean(mean(LMM.S(Rs,Cs)));
                Cal.K=PotNom/VS; %mm^-1/rad
                Cal.date=date;
                save(calFile, 'Cal');

                K=Cal.K ;
                K=[K K];
            end

            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl
            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');

        end


        function testGetPower_CalibrationLensKPX223(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_CalibrationLensKPX223')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data
            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            g=double(imread('CalibrationLensKPX223.bmp')); %low freq
            gM=double(imread('CalibrationLensKPX223_Mask.bmp')); %low freq
            gM=mat2gray(gM);
            g=g.*gM;
            R=50; %band pass filter fringes field
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX};
            wy=w{LobeY};
            %z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};


            M=gM;
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
                K=[K, K];
            else
                %calibration
                % for this lens P=-2.75D m;
                % crop center
                K=[1, 1];

                LMM=LensMapperMeasurement;
                LMM.zx=zx;
                LMM.zy=zy;
                LMM.CalculateLensPower(M, K);

                Rs=220:270;
                Cs=290:360;
                PotNom=-2.75*1e-3; %mm^-1
                VS=mean(mean(LMM.S(Rs,Cs)));
                Cal.K=PotNom/VS; %mm^-1/rad
                Cal.date=date;
                save(calFile, 'Cal');

                K=Cal.K;
                K=[K, K];
            end

            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl
            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');


            %load DLM files
            if exist('LoadMapperFile.m', 'file')
                MapperFile='YO_D75_SMinus275_C0.PMF';
                %load right eye, in transmission, for all types
                vaMeas={ 'T',   'M',    'L',    false};
                vaTeo={ 'T',   'T',    'L',    false};
                vaErr={ 'T',   'E',    'L',    false};

                SMeas=LoadMapperFile(MapperFile, vaMeas{:});
                STeo=LoadMapperFile(MapperFile, vaTeo{:});
                SErr=LoadMapperFile(MapperFile, vaErr{:});

                M=not(isnan(SMeas.Seq));
                figure; imagesc(SMeas.S.*M); title('DLM S (D)');
                figure; imagesc(SMeas.C.*M); title('DLM Cyl (D)');
                figure; imagesc(SMeas.Seq.*M); title('DLM Seq (D)');
                figure; imagesc( SMeas.A.*M); title('DLM A (deg)');
            end

        end



        function testGetPower_SwissCoat40L88050R(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_SwissCoat40L88050R')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data
            gr=double(imread('RefB_FFVLidDown11-1-2015.bmp')); %low freq
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(gr, paramsList);
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};

            g=double(imread('SwissCoat40L88050R.bmp')); %low freq
            % R=20; %Low pass filter fringes field
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(g, paramsList);
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX};
            wy=w{LobeY};
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};



            M=gr>40;
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            zp=zx.*zy;
            zm=zx./zy;

            %filter the phasors
            sigma=3;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            K=1;
            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.CalculateLensPower(M, K);


            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');


        end


        function testGetPower_VisionLab565964(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testGetPower_VisionLab565964')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data

            gr=double(imread('RefC_FFVLidDown22-1-2016.bmp')); %low freq
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(gr, paramsList);
            wr = UtilFunFPA.LocateSidelobes(gr);
            wx=wr{LobeX};
            wy=wr{LobeY};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};


            g=double(imread('VisionLab565964.bmp')); %low freq
            % R=20; %Low pass filter fringes field
            % wx=[61, 1];
            % wy=[-2, 46];
            % paramsList={R, {wx, wy}};
            % z=UtilFunFPA.FFTDemod(g, paramsList);
            w = UtilFunFPA.LocateSidelobes(g, wr);
            wx=w{LobeX};
            wy=w{LobeY};
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};



            M=mat2gray(imread('VisionLab565964_Mask.bmp'));
            zx=(zxc./zxr); %zx=bx*exp(i*phix); phix=2*pi*Px*D/px
            zy=(zyc./zyr);  %zy=by*exp(i*phiy); phiy=2*pi*Py*D/py

            %filter the phasors
            sigma=1;
            hsize=3*sigma;
            h=fspecial('gaussian', hsize, sigma);
            zx=imfilter(zx, h);
            zy=imfilter(zy, h);

            figure; imshow(mat2gray(angle(zx))); title('Delta X');
            figure; imshow(mat2gray(angle(zy))); title('Delta Y');

            %las componentes de la potencia son la derivada de la
            %deflexion

            calFile='CalibrationFFV.mat';
            if exist(calFile, 'file')
                v=load(calFile);
                K=v.Cal.K;
                K=[K, K];
            else
                K=[1 1];
            end

            LMM=LensMapperMeasurement;
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.CalculateLensPower(M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            MC=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(MC); title('MQ');

        end


        function testCheckCalibrationLensSpectra(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testCheckCalibrationLensSpectra')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %    2
            %  1 x 3
            %    4

            LobeX=4;
            LobeY=3;

            %% experimental data
            %ref
            gr=double(imread('RefB_FFVLidDown11-1-2015.bmp')); %low freq
            M=gr>30;

            %negative 10D
            g1=double(imread('CalibrationLensKPC076.bmp')); %low freq
            M1=mat2gray(double(imread('CalibrationLensKPC076_Mask.bmp'))); %low freq

            %positive 10D
            g2=double(imread('CalibrationLensKPX223.bmp')); %low freq
            M2=gr>30;

            %figure
            R=170:270; C=260:360;
            figure; imagesc(gr(R,C));
            figure; imagesc(g1(R,C));
            figure; imagesc(g2(R,C));

            UtilFunFPA.LocateSidelobes(gr);
            UtilFunFPA.LocateSidelobes(g1.*M1+0.5*gr);
            UtilFunFPA.LocateSidelobes(g2+0.5*gr);




        end


        function testFringeProjectionLinearGrid(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testFringeProjectionLinearGrid')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            assumeFail(testCase, 'AQDEBUG FFT method  1MAY20 not yet working');

            %select lobes
            %
            %  1 x 2
            %
            LobeY=2;

            %% experimental data
            %ref
            gr=double(imread('Ref_tapa.tif')); %low freq
            g=double(imread('Signal_tapa.tif')); %low freq

            w=[];
            R=10;
            NL=2;
            UtilFunFPA.LocateSidelobes(gr, w, R, NL);
            UtilFunFPA.LocateSidelobes(g, w, R, NL);

        end


        function testCalibration_YO_D75_SMinus275(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testCalibration_YO_D75_SMinus275')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();

            baseFolder='CalibracionFFV-10-6-2016';
            MLMFile='LensMapperMeasurement_YO_D75_SMinus275_10-Jun-2016';
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, MLMFile));

            %for this lens we do not have carrier, load def phasor as
            %carrier for period estimation in LMM.CalculateLensPower
            LMM.zrx=LMM.zx;
            LMM.zry=LMM.zy;


            K=[1 1];
            LMM.CalculateLensPower(LMM.M, K);

            Rs=200:350;
            Cs=320:460;
            PotNom=-2.75*1e-3; %mm^-1
            VS=mean(mean(LMM.S(Rs,Cs)));
            K=PotNom/VS; %mm^-1/rad
            K=[K, K];

            LMM.CalculateLensPower(LMM.M, K);

            C=LMM.C; %mm^-1
            S=LMM.S; %mm^-1
            Seq=LMM.Seq; %mm^-1
            M=LMM.M; %mask after CalculatePowerFromDefl

            figure; imagesc(1000*S.*M); title('S (D)');
            figure; imagesc(1000*C.*M); title('Cyl (D)');
            figure; imagesc(1000*Seq.*M); title('Seq (D)');
            figure; imagesc(M); title('MQ');


            %load DLM files
            if exist('LoadMapperFile.m', 'file')
                MapperFile='YO_D75_SMinus275_C0.PMF';
                %load right eye, in transmission, for all types
                vaMeas={ 'T',   'M',    'L',    false};
                vaTeo={ 'T',   'T',    'L',    false};
                vaErr={ 'T',   'E',    'L',    false};

                SMeas=LoadMapperFile(MapperFile, vaMeas{:});
                STeo=LoadMapperFile(MapperFile, vaTeo{:});
                SErr=LoadMapperFile(MapperFile, vaErr{:});

                M=not(isnan(SMeas.Seq));
                figure; imagesc(SMeas.S.*M); title('DLM S (D)');
                figure; imagesc(SMeas.C.*M); title('DLM Cyl (D)');
                figure; imagesc(SMeas.Seq.*M); title('DLM Seq (D)');
                figure; imagesc( SMeas.A.*M); title('DLM A (deg)');
            end

        end


        function testPowerMonofocalLens2D(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testPowerMonofocalLens2D')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());


            dropboxFolder=fixturesRoot();
            baseFolder='DemoduladorLS';
            MLMFile='LMM_28-Apr-2017-LS8Bifocal.mat';

            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, MLMFile));

            if isempty(LMM.zrx) || isempty(LMM.zry)
                d= DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
                NP=0.5*length(LMM.gr);
                d.Set(char(DemodulatorProps.NIgrams), NP);

                %demodulate ref
                FPList=LMM.gr(1:NP); %X direction
                %d.Set(char(DemodulatorProps.M), []);
                d.Process(FPList);
                zr=d.Get(char(DemodulatorProps.zList));
                LMM.zrx=zr{1};

                FPList=LMM.gr(NP+1:end); %Y direction
                %d.Set(char(DemodulatorProps.M), []);
                d.Process(FPList);
                zr=d.Get(char(DemodulatorProps.zList));
                LMM.zry=zr{1};
            end


            K=[1 1];
            LMM.CalculateLensPower(LMM.M, K);

            figure; imagesc(LMM.Seq.*LMM.M);
            figure; imagesc(LMM.C.*LMM.M);
            figure; imagesc(LMM.zAbs);

        end





        % ======================================================================
        %> @brief testMejoraCaluloDPM_APR20_LowLevel_GeomCal test for checking improved method for
        %> DPM estimation with a PAL, monofocal, bifical and NULL lens
        %> here we make a low level computation that is implemented in
        %> LMM-Calculate()
        %> @details the PAL is mounted in a frame is a old AQ lens with
        %> A~0.5D y far power ~-1.75D. In this test we show how to select
        %> the ROI and use the improved versions for calculation of first differnecenes from a phasor
        %> phaseGradientDirect and phaseGradientPlaneFit.
        %> Here we are using the geometrical calibraction calculated with
        %> run(testFPA_UtilFunFPAClassVer,'testCameraCalibrationCVTbx_5MAY20');
        %> and run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
        %> @see onenote->Mejoras calculo DPM APR20 for experimental
        %> @details the measurement was obtained usin the
        %> TransDeflAppInterface class of the repo https://bitbucket.org/iot_development_es/perseus/src/master/src/Deflectometer/FFVAppInt/
        %> @author AQ 14APR20
        % ======================================================================
        function testMejoraCaluloDPM_APR20_LowLevel_GeomCal(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testMejoraCaluloDPM_APR20_LowLevel_GeomCal')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();

            %set of new measuremnts as measured onenote->Mejoras calculo DPM APR20 for experimental
            %basicallly AGC off
            NewLMMeasures=true;
            if NewLMMeasures
                baseFolder='Medidas_5MAY20';
                imageSource='default'; % other value is  'watec_DFGPro_winvideo_Y800_768x576'
                %LMMFile='LensMapperMeasurement_05-May-2020_comfort_A2_F0.mat';
                %LMMFile='LensMapperMeasurement_05-May-2020_n5.mat';;
                %LMMFile='LensMapperMeasurement_08-Jun-2020-n5-oblicua.mat';
                LMMFile='LensMapperMeasurement_05-May-2020-p5';
                %LMMFile='LensMapperMeasurement_08-Jun-2020-p5-oblicua.mat';
                %LMMFile='LensMapperMeasurement_05-May-2020-p2';
                %LMMFile='LensMapperMeasurement_05-May-2020-n2';
                %LMMFile='LensMapperMeasurement_05-May-2020_NULL.mat';
                %LMMFile='LensMapperMeasurement_05-May-2020_PAL_AQ';
                %LMMFile='LensMapperMeasurement_05-May-2020_SwissCoat_40L88030R_A2_Fn5.mat'; hp=0;

                d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
                d.Set(char(DemodulatorProps.NIgrams), 8);
                d.Set(char(DemodulatorProps.Tx), 16); %pixels
                d.Set(char(DemodulatorProps.Ty), 16); %pixels
            else
                %set of old mesurements, basically AGC on also the demodulator had less igrams
                baseFolder='perseusmedidas\ExperimentosPerseus\Deflectometria\CalibracionDeflectometroVertical-13-OCT-16\';
                %LMMFile='TimePSYoungerMinus275_13-Oct-2016.mat';
                LMMFile='TimePS_GafasAQ_13-Oct-2016.mat';
                %LMMFile='LensMapperMeasurement_n2D.mat'; %for 5D and > use AppInt.AutomaticROIMode=false;
                %LMMFile='TimePS_40L88030R_13-Oct-2016.mat';

                %for this set of measurmenets we used PSFilterTypes.A0502
                %TimePSA
                d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
                d.Set(char(DemodulatorProps.PSType), PSFilterTypes.A0502);
            end

            %load the LMM
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));


            % REPRODUCE THE CALCULATION
            % SEE TransDeflAppInterface->CalculateLensPower in perseus repo
            % from  onenote->Mejoras calculo DPM APR20 for experimental we
            % have "NIgrams": 8,  "Tx": 16,"Ty": 16,


            %check for demodulator default props before use it
            ROINormTH=d.Get(char(DemodulatorProps.ROINormTH));
            testCase.assertEqual(ROINormTH, 0);
            %JUST after creation, the ROI M is []. The first call to process will init the ROI to ones()
            M=d.Get(char(DemodulatorProps.M));
            testCase.assertTrue(isempty(M));

            %calculate the phasors
            %the first half are the X igrams and the second the Y igrams
            NP=0.5*length(LMM.gr);

            %demodulate ref X
            FPList=LMM.gr(1:NP); %X direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zrx=zr{1};

            %check for demodulator props after Process, all remain default
            ROINormTH=d.Get(char(DemodulatorProps.ROINormTH));
            testCase.assertEqual(ROINormTH, 0);
            M=d.Get(char(DemodulatorProps.M));
            %JUST after first call to Process with ROI []. Now the ROI is set to ones()
            testCase.assertTrue(all(M(:)==1));

            %demodulate ref Y
            FPList=LMM.gr(NP+1:end); %Y direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zry=zr{1};

            %check for demodulator props after Process, all remain
            %defaultexcept the ROI M
            ROINormTH=d.Get(char(DemodulatorProps.ROINormTH));
            testCase.assertEqual(ROINormTH, 0);
            M=d.Get(char(DemodulatorProps.M));
            %After the call to Process the ROI is actualized by thresholding
            %the modulation using ROINormTH (def 0) and NFilt (def 5px).
            %even with defaults values few values of the ROI change
            %All demodulators make the same, they modify the ROI M after
            %calculating the phasor by thresholding it using ROINormTH
            testCase.assertFalse(all(M(:)==1));

            %demodulate signal X
            FPList=LMM.g(1:NP); %X direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcx=zc{1};

            %demodulate signal Y
            FPList=LMM.g(NP+1:end); %Y direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcy=zc{1};

            %Calculate defection phasors zx=b*exp(i*2pi*Z*delta_x/p_x) and zy=b*exp(i*2pi*Z*delta_y/p_y) phasors,
            %outside the ROI b=1 and delta_x=0
            zx=zcx./zrx;
            zy=zcy./zry;

            %calculate average b (bx and by should be equal)
            %b is in [0 1] + noise
            b=0.5*(abs(zx)+abs(zy));
            %umbralize B with safe threslhold
            Mb=b>0.5;


            %filter non-linealities on the fringe
            %estimate the fringe period
            Nmed=1; %1 px
            NS=2; %2*NS+1 px phasor filtering
            %get spatial freqs from the ref igram phasor
            LPCycles=3; %number of Low pass cycles
            [phirx, ~, Mphirxy]=UtilFunFPA.phaseGradientDirect(zrx, M, NS, Nmed, LPCycles);
            [~, phiry, ~]=UtilFunFPA.phaseGradientDirect(zry, M, NS, Nmed, LPCycles);
            wx=mean(phirx(Mphirxy)); %rad/px
            wy=mean(phiry(Mphirxy)); %rad/px
            Tx=round(2*pi/wx); %px
            Ty=round(2*pi/wy); %px

            %phasor filter at Tx and Ty, there is a little noise with
            %spatial freq Tx
            hx=ones(Tx)/Tx^2; hy=ones(Ty)/Ty^2;
            zx=conv2(zx, hx, 'same');
            zy=conv2(zy, hy, 'same');


            figure; imagesc(b, [0 1]); title('average modulation');
            figure; imagesc(Mb, [0 1]); title('ROI from average modulation');

            %etiquetamos las zonas segnemtadas en Mb
            L=bwlabel(Mb);
            %escogemos la zona que coincida con un punto de control P0
            %escogemos P0[R,C]=0.5*size
            [NR, NC]=size(Mb); R=round(0.5*NR); C=round(0.5*NC);
            %segment P in M, close for cleaning mask
            M=(L==L(R,C)); se = strel('disk',10); M = imclose(M,se);

            figure; imagesc(M, [0 1]); title('segmented P0 in ROI');


            % calculate DPM components
            %make al calculations in rad/px, transform to mm^-1 in the last
            Nmed=2; %1 px
            NS=max(round(0.5*Tx), round(0.5*Ty)); %2*NS+1 px phasor filtering
            LPCycles=3; %number of LP cycles
            [Pxx, Pxy, Mdpm]=UtilFunFPA.phaseGradientDirect(zx, M, NS, Nmed, LPCycles);
            %we use conj(zy) taking into account the y axis inversion
            [Pyx,Pyy,~]=UtilFunFPA.phaseGradientDirect(zy, M, NS, Nmed, LPCycles);

            %if imageSource if  'watec_DFGPro_winvideo_Y800_768x576' filter
            %phixx and M
            if strcmp(imageSource, 'watec_DFGPro_winvideo_Y800_768x576')
                wx=66; %Tx=768/66=11 px
                [Pxx, Mdpm]=UtilFunFPA.filterHarmonicsX(Pxx, wx, 'M', Mdpm);
            end


            %scale from phase-rad/px to deflection-rad/mm

            %Z y Z medidos "a mano salen unos Z=150 y Zc=140 approx
            Z=151.98; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');
            Zc=146; %mm distance camera-lens



            %monitor resolution from the monitor data in px-camera
            %dx=0.2913; %mm/px-camera lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');
            %dy=0.2941; %mm/px-camera lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');

            %lens plane resolution in px-camera
            %if every thing is OK (not taking into account the displacement
            %due to the supporting glass
            %the pixel size on-the-lens-plane, Z is the distance
            %screen-lens and Zc is the distance lens-cam
            %dxLP=dx*Zc/(Z+Zc); %mm/px on the lens plane
            %dyLP=dy*Zc/(Z+Zc); %mm/px on the lens plane
            dxLP=0.1434; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');
            dyLP=0.1436; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');

            dx=337.9/1280; %mm/pixel-proyector size
            dy=270.3/1024; %mm/pixel-proyector size
            Tx=d.Get(char(DemodulatorProps.Tx))*dx; %mm on the screen
            Ty=d.Get(char(DemodulatorProps.Ty))*dy; %mm on the screen
            %from phase-rad to deflection-rad delta=Tx/(2*pi*Z)
            %from deflection-rad/px to  deflection-rad/mm we must estimate
            %the pixel size on-the-lens-plane, Z is the distance
            %screen-lens and Zc is the distance lens-cam

            Sx=1e3*Tx/(2*pi*Z*dxLP); %px/m
            Sy=1e3*Ty/(2*pi*Z*dyLP); %px/m

            Pxx=Sx*Pxx; Pxy=Sy*Pxy; %in D
            Pyx=Sx*Pyx; Pyy=Sy*Pyy; %in D

            %input gradient quality  Q=0 is perfect
            Q=UtilFunFPA.GradientConsistency(angle(zx),angle(zy));
            figure; imagesc(Q.*Mdpm, [0 0.1]); title('deflection quality map');


            %la dpm debe ser una matriz simetrica por lo tanto es una
            %matriz normal (ver wikipedia) A*conj(A)=conj(A)*A de aqui
            %de \AQ11\Programs\Matlab\DPMProperties\DPMProperties.m
            %the eigenvalue of DPM*DPM'-DPM'*DPM must be zero
            Qdpm=(Pxy - Pyx).^2;

            figure; imagesc(Qdpm); title('Qdpm');

            figure; imagesc(angle(zx).*Mdpm); title('delta_x');
            figure; imagesc(angle(zy).*Mdpm); title('delta_y');
            figure; imagesc(Pxx.*Mdpm); title('Pxx (D)');
            figure; imagesc(Pyy.*Mdpm); title('Pyy (D)');
            figure; imagesc(Pxy.*Mdpm); title('Pxy (D)');
            figure; imagesc(Pyx.*Mdpm); title('Pyx (D)');


            %de la patente "A method and apparatus for testing and mapping
            %optical elements" comentada en Papers_06
            t1=Pxx-Pyy; %rad/px
            t2=Pxy+Pyx; %rad/px
            %AQNOTA no se de donde sale este signo negativo, repasar signo
            %de la deflexion medida y signos de las derivadas
            tr=-(Pxx+Pyy); %rad/px

            C=sqrt(t1.^2+t2.^2); %rad/px
            S=0.5*(tr-C); %rad/px
            Seq=0.5*tr; %rad/px
            A=0.5*atan2d(t1,t2); %in deg


            figure; imagesc(Seq.*Mdpm); title('Seq (D)'); colorbar
            figure; imagesc(C.*Mdpm); title('C (D)'); colorbar


            [~,Y]=meshgrid(1:NC, 1:NR);
            R0=round(sum(sum(Mdpm.*Y))/sum(Mdpm(:)));
            x=1:NC;
            figure; plot(x,C(R0, :).*Mdpm(R0, :)./Mdpm(R0, :)); grid; title('Cyl center row');
            figure; plot(x,Seq(R0, :).*Mdpm(R0, :)./Mdpm(R0, :)); grid; title('Seq center row');


            if strcmp(LMMFile,'LensMapperMeasurement_05-May-2020_NULL.mat')
                f=C(Mdpm);
                x=linspace(-0.15,0.15, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title('Cyl hist for NULL');


                f=Seq(Mdpm);
                x=linspace(-0.15,0.15, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title('Seq hist for NULL');

            end

        end


        % ======================================================================
        %> @brief testMejoraCaluloDPMUsingLMMClass_APR20_GeomCal test for checking the LensMapperMeasurement class
        %> @details here we test the method implemented in testMejoraCaluloDPM_APR20 but using the LensMapperMeasurement class
        %> Here we are using the geometrical calibraction calculated with
        %> run(testFPA_UtilFunFPAClassVer,'testCameraCalibrationCVTbx_5MAY20');
        %> and run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
        %> also here we test the effect of the distortion in the power
        %> calculation
        %> @see testMejoraCaluloDPM_APR20 onenote->Mejoras calculo DPM APR20 for experimental
        %> @details the measurement was obtained usin the
        %> TransDeflAppInterface class of the repo https://bitbucket.org/iot_development_es/perseus/src/master/src/Deflectometer/FFVAppInt/
        %> @author AQ 14APR20
        %>
        % ======================================================================
        function testMejoraCaluloDPMUsingLMMClass_APR20_GeomCal(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testMejoraCaluloDPMUsingLMMClass_APR20_GeomCal')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());


            %load camera calibration params generated with run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            fname='params_Calibracion_5MAY20.json';
            if exist(fname, 'file')
                params_struct=loadjson(fname);
                %for loading we need to cast two values to logical
                params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion);
                params_struct.EstimateSkew=logical(params_struct.EstimateSkew);
                params=cameraParameters(params_struct);
            else
                %defalt valurs no distortion K=eye(3)
                warning(sprintf('calibration file %s not found', fname));
                params=cameraParameters;
            end

            %optionally undistort images
            UNDISTORT=true;
            %UNDISTORT=false;

            %load measurents
            dropboxFolder=fixturesRoot();
            %set of new measuremnts as measured onenote->Mejoras calculo DPM APR20 for experimental
            %basicallly AGC off
            %baseFolder='PerseusMedidas\ExperimentosPerseus\Deflectometria\Medidas_5MAY20\';
            %imageSource='default'; % other option is ''watec_DFGPro_winvideo_Y800_768x576';
            %LMMFile='LensMapperMeasurement_05-May-2020_comfort_A2_F0.mat';
            %LMMFile='LensMapperMeasurement_05-May-2020_n5.mat';
            %LMMFile='LensMapperMeasurement_08-Jun-2020-n5-oblicua.mat';
            %LMMFile='LensMapperMeasurement_05-May-2020-p5';
            %LMMFile='LensMapperMeasurement_08-Jun-2020-p5-oblicua.mat';
            %LMMFile='LensMapperMeasurement_05-May-2020-p2';
            %LMMFile='LensMapperMeasurement_05-May-2020-n2';
            %LMMFile='LensMapperMeasurement_05-May-2020_NULL.mat';
            %LMMFile='LensMapperMeasurement_05-May-2020_PAL_AQ';
            %LMMFile='LensMapperMeasurement_05-May-2020_SwissCoat_40L88030R_A2_Fn5.mat';
            %LMMFile='LensMapperMeasurement_16-Jul-2020-monofocal_n10D.mat'; highPowerLens=true; %-10D
            %LMMFile='LensMapperMeasurement_26-Aug-2020-monofocal_p10D.mat'; highPowerLens=true;  %+10D

            %This is to check for the ROI calculation for lenses mounted on
            %the new holder for volumetric printing of 01OCT20
            baseFolder='Calibracion_1OCT20';
            %imageSource='default'; % other option is ''watec_DFGPro_winvideo_Y800_768x576';
            LMMFile='LensMapperMeasurement_01-Oct-2020-n2';
            %LMMFile='LensMapperMeasurement_01-Oct-2020-p2';
            %LMMFile='LensMapperMeasurement_01-Oct-2020-n5';

            %This is to check for the ROI calculation for lenses mounted on
            %the new holder for volumetric printing of 01OCT20
            %baseFolder='PerseusMedidas\ExperimentosPerseus\Deflectometria\Medidas_Volumetrica\';
            %imageSource='default'; % other option is ''watec_DFGPro_winvideo_Y800_768x576';
            %LMMFile='S3v205_01';
            %LMMFile='S3v204_01';


            d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.NIgrams), 8);
            d.Set(char(DemodulatorProps.Tx), 16); %pixels
            d.Set(char(DemodulatorProps.Ty), 16); %pixels

            %load the LMM from dropbox
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));

            %optionally undistort images
            if UNDISTORT
                LMM=testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages(LMM, params);
            end

            %calculate the phasors
            %the first half are the X igrams and the second the Y igrams
            NP=0.5*length(LMM.gr);

            %demodulate ref X
            FPList=LMM.gr(1:NP); %X direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zrx=zr{1};

            %demodulate ref Y
            FPList=LMM.gr(NP+1:end); %Y direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zry=zr{1};

            %demodulate signal X
            FPList=LMM.g(1:NP); %X direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcx=zc{1};

            %demodulate signal Y
            FPList=LMM.g(NP+1:end); %Y direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcy=zc{1};

            %Calculate defection phasors zx=b*exp(i*2pi*Z*delta_x/p_x) and zy=b*exp(i*2pi*Z*delta_y/p_y) phasors,
            %outside the ROI b=1 and delta_x=0
            zx=zcx./zrx;
            zy=zcy./zry;

            %calculate average b (bx and by should be equal)
            %b is in [0 1] + noise
            b=0.5*(abs(zx)+abs(zy));
            %umbralize B with safe threslhold
            Mb=b>0.5;


            figure; imagesc(b, [0 1]); title('average modulation');
            figure; imagesc(Mb, [0 1]); title('ROI from average modulation');

            %feed the LMM before calculate lens power as we do in the
            %AppInterface
            %feed the LMM
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.zrx=zrx;
            LMM.zry=zry;
            %here we assume we have a mask calculated in automatic mode in LMM.calculateROIFromPhasor
            %LMM.M=M;

            %calculate ROI from phasor
            LMM.calculateROIFromPhasor();

            figure; imagesc(LMM.M, [0 1]); title('segmented P0 in ROI');


            %scale from phase-rad/px to deflection-rad/mm
            %Z y Z medidos "a mano salen unos Z=150 y Zc=140 approx
            Z=152; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            Zc=146; %mm distance camera-lens

            %monitor resolution from the monitor data in px-camera
            %dx=0.2913; %mm/px-camera lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            %dy=0.2941; %mm/px-camera lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');

            %lens plane resolution in px-camera
            %if every thing is OK (not taking into account the displacement
            %due to the supporting glass
            %the pixel size on-the-lens-plane, Z is the distance
            %screen-lens and Zc is the distance lens-cam
            %dxLP=dx*Zc/(Z+Zc); %mm/px on the lens plane
            %dyLP=dy*Zc/(Z+Zc); %mm/px on the lens plane
            dxLP=0.1434; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');
            dyLP=0.1436; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');

            dx=337.9/1280; %mm/pixel-proyector size
            dy=270.3/1024; %mm/pixel-proyector size
            Tx=d.Get(char(DemodulatorProps.Tx))*dx; %mm on the screen
            Ty=d.Get(char(DemodulatorProps.Ty))*dy; %mm on the screen
            %from phase-rad to deflection-rad delta=Tx/(2*pi*Z)
            %from deflection-rad/px to  deflection-rad/mm we must estimate
            %the pixel size on-the-lens-plane, Z is the distance
            %screen-lens and Zc is the distance lens-cam

            Kx=1e3*Tx/(2*pi*Z*dxLP); % px/m from phase-rad/px to deflection-rad/m in m^-1
            Ky=1e3*Ty/(2*pi*Z*dyLP); % px/m from phase-rad/px to deflection-rad/m in m^-1
            K=[Kx, Ky];
            %if we made the calculation with the y direction the
            %calculation should be the same for squere pixels ON the screen
            %usin the same fringe period in both directions
            %K=Tys/(2*pi*Z*dyLP); %px/m

            %No params
            %LMM.CalculateLensPower(M, K);
            %with params,
            %(see doc for CalculateLensPower)
            if exist('highPowerLens', 'var')
                LMM.CalculateLensPower(LMM.M, K, 'highPowerLens', true);
            else
                LMM.CalculateLensPower(LMM.M, K);
            end

            DispMask=double(LMM.M)./double(LMM.M);

            figure; imagesc(angle(LMM.zx).*DispMask); title(['\delta_x,' sprintf('UNDISTORT=%d', UNDISTORT)]);
            figure; imagesc(angle(LMM.zy).*DispMask); title(['\delta_y,' sprintf('UNDISTORT=%d', UNDISTORT)]);
            figure; imagesc(LMM.Q.*DispMask); title(sprintf('Dx Dy Quality map, UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pxx.*DispMask); title(sprintf('Pxx (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pyy.*DispMask); title(sprintf('Pyy (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pxy.*DispMask); title(sprintf('Pxy (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pyx.*DispMask); title(sprintf('Pyx (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Qdpm.*DispMask, [0 1]); title(sprintf('DPM Quality map, UNDISTORT=%d', UNDISTORT));


            figure; imagesc(LMM.Seq.*DispMask); title(sprintf('Seq (D), UNDISTORT=%d', UNDISTORT)); colorbar
            figure; imagesc(LMM.C.*DispMask); title(sprintf('C (D), UNDISTORT=%d', UNDISTORT)); colorbar; colorbar
            figure; imagesc(LMM.S.*DispMask); title(sprintf('S (D), UNDISTORT=%d', UNDISTORT)); colorbar; colorbar

            [NR, NC]=size(LMM.M);
            [~,Y]=meshgrid(1:NC, 1:NR);
            R0=round(sum(sum(LMM.M.*Y))/sum(LMM.M(:)));
            x=1:NC;
            figure; plot(x,LMM.C(R0, :).*LMM.M(R0, :)./LMM.M(R0, :)); grid; title(sprintf('Cyl center row, UNDISTORT=%d', UNDISTORT));
            figure; plot(x,LMM.Seq(R0, :).*LMM.M(R0, :)./LMM.M(R0, :)); grid; title(sprintf('Seq center row, UNDISTORT=%d', UNDISTORT));


            if strcmp(LMMFile,'LensMapperMeasurement_05-May-2020_NULL.mat')
                f=LMM.C(LMM.M);
                stdC=std(f), meanC=mean(f);
                x=linspace(-0.15,0.15, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Cyl hist for NULL (D), UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.3f D, mean: %2.3f D', stdC, meanC));


                f=LMM.Seq(LMM.M);
                stdSeq=std(f); meanSeq=mean(f);
                x=linspace(-0.15,0.15, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Seq hist for NULL, UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.3f D, mean: %2.3f D', stdSeq, meanSeq));
            else
                f=LMM.C(LMM.M);
                minC=-0.1; maxC=max(f)+0.2;
                stdC=std(f), meanC=mean(f);
                x=linspace(minC,maxC, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Cyl hist for NULL (D), UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.2f D, mean: %2.2f D', stdC, meanC));


                f=LMM.Seq(LMM.M);
                minSeq=min(f)-0.2; maxSeq=max(f)+0.2;
                stdSeq=std(f), meanSeq=mean(f);
                x=linspace(minSeq,maxSeq, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Seq hist for NULL, UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.2f D, mean: %2.2f D', stdSeq, meanSeq));
            end

        end




        % ======================================================================
        %> @brief testCaluloDPMUsingLMMClass_15DIC20 test for checking the LensMapperMeasurement class
        %> @details here we test the DPM calculation using the LensMapperMeasurement class
        %> Here we are using the geometrical calibraction calculated with
        %> run(testFPA_UtilFunFPAClassVer,'testCameraCalibrationCVTbx_15DIC20');
        %> and run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_15DIC20');
        %> also here we test the effect of the distortion in the power
        %> calculation
        %> @see onenote->calibracion 15DIC20
        %> @details the measurement was obtained usin the
        %> TransDeflAppInterface class of the repo https://bitbucket.org/iot_development_es/perseus/src/master/src/Deflectometer/FFVAppInt/
        %> @author AQ 15DIC20
        %>
        % ======================================================================

        function testCaluloDPMUsingLMMClass_15DIC20(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testCaluloDPMUsingLMMClass_15DIC20')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());


            %load camera calibration params generated with run(testFPA_UtilFunFPAClassVer, run(testFPA_UtilFunFPAClassVer,'testCameraCalibrationCVTbx_15DIC20');
            fname='params_Calibracion_15DIC20.json';
            if exist(fname, 'file')
                params_struct=loadjson(fname);
                %for loading we need to cast two values to logical
                params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion);
                params_struct.EstimateSkew=logical(params_struct.EstimateSkew);
                params=cameraParameters(params_struct);
            else
                %defalt valurs no distortion K=eye(3)
                warning(sprintf('calibration file %s not found', fname));
                params=cameraParameters;
            end

            %optionally undistort images
            %UNDISTORT=true;
            UNDISTORT=false;

            %load measurents
            dropboxFolder=fixturesRoot();
            %set of new measuremnts as measured onenote->calibracion 15DIC20 for experimental
            %basicallly AGC off
            baseFolder='Calibracion_15DIC20';
            %LMMFile='LensMapperMeasurement_15-Dec-2020-n2';
            %LMMFile='LensMapperMeasurement_15-Dec-2020-p2';
            LMMFile='LensMapperMeasurement_15-Dec-2020-p5';
            %LMMFile='LensMapperMeasurement_15-Dec-2020-null';


            d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.NIgrams), 8);
            d.Set(char(DemodulatorProps.Tx), 16); %pixels
            d.Set(char(DemodulatorProps.Ty), 16); %pixels

            %load the LMM
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));

            %optionally undistort images
            if UNDISTORT
                LMM=testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages(LMM, params);
            end

            %calculate the phasors
            %the first half are the X igrams and the second the Y igrams
            NP=0.5*length(LMM.gr);

            %demodulate ref X
            FPList=LMM.gr(1:NP); %X direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zrx=zr{1};

            %demodulate ref Y
            FPList=LMM.gr(NP+1:end); %Y direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zry=zr{1};

            %demodulate signal X
            FPList=LMM.g(1:NP); %X direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcx=zc{1};

            %demodulate signal Y
            FPList=LMM.g(NP+1:end); %Y direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcy=zc{1};

            %Calculate defection phasors zx=b*exp(i*2pi*Z*delta_x/p_x) and zy=b*exp(i*2pi*Z*delta_y/p_y) phasors,
            %outside the ROI b=1 and delta_x=0
            zx=zcx./zrx;
            zy=zcy./zry;

            %calculate average b (bx and by should be equal)
            %b is in [0 1] + noise
            b=0.5*(abs(zx)+abs(zy));
            %umbralize B with safe threslhold
            Mb=b>0.5;


            figure; imagesc(b, [0 1]); title('average modulation');
            figure; imagesc(Mb, [0 1]); title('ROI from average modulation');

            %feed the LMM before calculate lens power as we do in the
            %AppInterface
            %feed the LMM
            LMM.zx=zx;
            LMM.zy=zy;
            LMM.zrx=zrx;
            LMM.zry=zry;
            %here we assume we have a mask calculated in automatic mode in LMM.calculateROIFromPhasor
            %LMM.M=M;

            %calculate ROI from phasor
            LMM.calculateROIFromPhasor();

            figure; imagesc(LMM.M, [0 1]); title('segmented P0 in ROI');

            Z=2.052945e+02; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_5MAY20');;
            Zc=2.667984e+02; %mm distance camera-lens

            fu=3735.4745; %px u focal length
            fv=3722.0838; %px u focal length

            %valor teorico de acuerdo a la calibracion
            dxLP=Zc/fu; %approx 0.0714 mm/px mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            dyLP=Zc/fv; %approx 0.0717 mm/px mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');

            %estos valores estan calculados mediante una imagen del plano de calibracion con run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_15DIC20');
            %dxLP=7.147865e-02; %mm
            %dyLP=7.160968e-02; %mm


            dx=337.9/1280; %mm/pixel-proyector size
            dy=270.3/1024; %mm/pixel-proyector size

            Tx=16*dx; %mm on the screen
            Ty=16*dy; %mm on the screen

            Kx=Tx/(2*pi*Z*dxLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            Ky=Ty/(2*pi*Z*dyLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            K=1000*[Kx, Ky]; % px/m to obtain power in D

            %No params
            %LMM.CalculateLensPower(M, K);
            %with params,
            %(see doc for CalculateLensPower)

            h = msgbox({'Calculating power...please wait', 'This could be a minute. Patience, grasshopper...'},'Calculating Power','help');
            child = get(h,'Children');
            delete(child(3)); %delete OK button

            if exist('highPowerLens', 'var')
                LMM.CalculateLensPower(LMM.M, K, 'highPowerLens', true);
            else
                LMM.CalculateLensPower(LMM.M, K);
            end

            delete(h)

            DispMask=double(LMM.M)./double(LMM.M);

            figure; imagesc(angle(LMM.zx).*DispMask); title(['\delta_x,' sprintf('UNDISTORT=%d', UNDISTORT)]);
            figure; imagesc(angle(LMM.zy).*DispMask); title(['\delta_y,' sprintf('UNDISTORT=%d', UNDISTORT)]);
            figure; imagesc(LMM.Q.*DispMask); title(sprintf('Dx Dy Quality map, UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pxx.*DispMask); title(sprintf('Pxx (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pyy.*DispMask); title(sprintf('Pyy (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pxy.*DispMask); title(sprintf('Pxy (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Pyx.*DispMask); title(sprintf('Pyx (D), UNDISTORT=%d', UNDISTORT));
            figure; imagesc(LMM.Qdpm.*DispMask, [0 1]); title(sprintf('DPM Quality map, UNDISTORT=%d', UNDISTORT));


            figure; imagesc(LMM.Seq.*DispMask); title(sprintf('Seq (D), UNDISTORT=%d', UNDISTORT)); colorbar
            figure; imagesc(LMM.C.*DispMask); title(sprintf('C (D), UNDISTORT=%d', UNDISTORT)); colorbar; colorbar
            figure; imagesc(LMM.S.*DispMask); title(sprintf('S (D), UNDISTORT=%d', UNDISTORT)); colorbar; colorbar

            [NR, NC]=size(LMM.M);
            [~,Y]=meshgrid(1:NC, 1:NR);
            R0=round(sum(sum(LMM.M.*Y))/sum(LMM.M(:)));
            x=1:NC;
            figure; plot(x,LMM.C(R0, :).*LMM.M(R0, :)./LMM.M(R0, :)); grid; title(sprintf('Cyl center row, UNDISTORT=%d', UNDISTORT));
            figure; plot(x,LMM.Seq(R0, :).*LMM.M(R0, :)./LMM.M(R0, :)); grid; title(sprintf('Seq center row, UNDISTORT=%d', UNDISTORT));


            if strcmp(LMMFile,'LensMapperMeasurement_15-Dec-2020_NULL.mat')
                f=LMM.C(LMM.M);
                stdC=std(f), meanC=mean(f);
                x=linspace(-0.15,0.15, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Cyl hist for NULL (D), UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.3f D, mean: %2.3f D', stdC, meanC));


                f=LMM.Seq(LMM.M);
                stdSeq=std(f); meanSeq=mean(f);
                x=linspace(-0.15,0.15, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Seq hist for NULL, UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.3f D, mean: %2.3f D', stdSeq, meanSeq));
            else
                f=LMM.C(LMM.M);
                minC=-0.1; maxC=max(f)+0.2;
                stdC=std(f), meanC=mean(f);
                x=linspace(minC,maxC, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Cyl hist for NULL (D), UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.2f D, mean: %2.2f D', stdC, meanC));


                f=LMM.Seq(LMM.M);
                minSeq=min(f)-0.2; maxSeq=max(f)+0.2;
                stdSeq=std(f), meanSeq=mean(f);
                x=linspace(minSeq,maxSeq, 100); %histogram sampling in D
                h=hist(f, x);
                figure; plot(x,h); grid; title(sprintf('Seq hist for NULL, UNDISTORT=%d', UNDISTORT));
                xlabel(sprintf('sigma: %2.2f D, mean: %2.2f D', stdSeq, meanSeq));
            end

        end

        % ======================================================================
        %> @brief testDPMPowerRangeCalc test for validating the DPM calculation using LensMapperMeasurement class
        %> @details here we check the Power measurement ranges of the DPM calculation using LensMapperMeasurement in particular the +10D and -10D cases
        %> the measurement was obtained usin the TransDeflAppInterface class of
        %> the repo https://bitbucket.org/iot_development_es/perseus/src/master/src/Deflectometer/FFVAppInt/
        %> @details also in this test we check for non-linearities in the X
        %> patterns and its influence on tne final DPM
        %> @see testMejoraCaluloDPM_APR20 onenote->Mejoras calculo DPM APR20 for experimental
        %> @author AQ 14AUG20
        % ======================================================================
        function testDPMPowerRangeCalc(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testDPMPowerRangeCalc')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());


            %load camera calibration params generated with run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            fname='params_Calibracion_5MAY20.json';
            if exist(fname, 'file')
                params_struct=loadjson(fname);
                %for loading we need to cast two values to logical
                params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion);
                params_struct.EstimateSkew=logical(params_struct.EstimateSkew);
                params=cameraParameters(params_struct);
            else
                %defalt valurs no distortion K=eye(3)
                warning(sprintf('calibration file %s not found', fname));
                params=cameraParameters;
            end


            %load measurents
            dropboxFolder=fixturesRoot();
            %using setup onenote->Mejoras calculo DPM APR20
            baseFolder='Medidas_5MAY20';
            %LMMFile='LensMapperMeasurement_05-May-2020-p5'; highPowerLens=false; %+5D
            %LMMFile='LensMapperMeasurement_05-May-2020_n5.mat'; highPowerLens=false;  %-5D
            %LMMFile='LensMapperMeasurement_05-May-2020-n2.mat'; highPowerLens=false; %-2D
            %LMMFile='LensMapperMeasurement_05-May-2020-p2.mat'; highPowerLens=false; %+2D
            %LMMFile='LensMapperMeasurement_16-Jul-2020-monofocal_n10D.mat'; highPowerLens=true; %-10D
            LMMFile='LensMapperMeasurement_26-Aug-2020-monofocal_p10D.mat'; highPowerLens=true; %+10D
            %LMMFile='LensMapperMeasurement_NULL_T32_27-Aug-2020.mat'; highPowerLens=false;  %este test es un NULL sin lente y T=32 px en vez de 16


            %medida DR 21SEP20 donde se aprecia muy bien un cuerto nivel de
            %armonicos
            %baseFolder='PerseusMedidas\ExperimentosPerseus\Deflectometria\MedidasRevisar';
            %LMMFile='DRLenteMuescas.mat'; highPowerLens=false; %+5D medida DR 21SEP20


            d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.NIgrams), 8);
            d.Set(char(DemodulatorProps.Tx), 16); %pixels
            d.Set(char(DemodulatorProps.Ty), 16); %pixels

            %load the LMM
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));

            %set test options
            UNDISTORT=false;
            DISPLAY_SPEC=true;
            SHOW_DPM=true;

            %optionally undistort images
            if UNDISTORT
                LMM=testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages(LMM, params);
            end


            %calculate the phasors
            %the first half are the X igrams and the second the Y igrams
            NP=0.5*length(LMM.gr);
            [NR, NC]=size(LMM.gr{1});

            %demodulate ref X
            FPList=LMM.gr(1:NP); %X direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zrx=zr{1};

            if DISPLAY_SPEC
                strSet='Ref X';
                for n=1:length(FPList):length(FPList)
                    g=double(FPList{n}); g=g-mean(g(:));
                    G=log(abs(fftshift(fft2(g)))+1);
                    figure; imagesc(G); colormap hot; title(sprintf('set: %s, number: %d', strSet, n))
                    figure; imagesc(g); colormap gray; title(sprintf('set: %s, number: %d', strSet, n))
                end

                [px,py, Mp]=UtilFunFPA.phaseGradientDirect(zrx, ones(size(zrx)), 1, 1, 1);
                figure; imagesc(px.*Mp); colormap hot; title(sprintf('Dx set: %s', strSet))
                figure; imagesc(py.*Mp); colormap hot; title(sprintf('Dy set: %s', strSet))
            end

            %demodulate ref Y
            FPList=LMM.gr(NP+1:end); %Y direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zry=zr{1};

            if DISPLAY_SPEC
                strSet='Ref Y';
                for n=1:length(FPList):length(FPList)
                    g=double(FPList{n}); g=g-mean(g(:));
                    G=log(abs(fftshift(fft2(g)))+1);
                    figure; imagesc(G); colormap hot; title(sprintf('set: %s, number: %d', strSet, n))
                    figure; imagesc(g); colormap gray; title(sprintf('set: %s, number: %d', strSet, n))
                end

                [px,py, Mp]=UtilFunFPA.phaseGradientDirect(zry, ones(size(zry)), 1, 1, 1);
                figure; imagesc(px.*Mp); colormap hot; title(sprintf('Dx set: %s', strSet))
                figure; imagesc(py.*Mp); colormap hot; title(sprintf('Dy set: %s', strSet))
            end

            %demodulate signal X
            FPList=LMM.g(1:NP); %X direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcx=zc{1};

            if DISPLAY_SPEC
                strSet='Ref+Signal X';
                for n=1:length(FPList):length(FPList)
                    g=double(FPList{n}); g=g-mean(g(:));
                    G=log(abs(fftshift(fft2(g)))+1);
                    figure; imagesc(G); colormap hot; title(sprintf('set: %s, number: %d', strSet, n))
                    figure; imagesc(g); colormap gray; title(sprintf('set: %s, number: %d', strSet, n))
                end


                [px,py, Mp]=UtilFunFPA.phaseGradientDirect(zcx, ones(size(zcx)), 1, 1, 1);
                figure; imagesc(px.*Mp); colormap hot; title(sprintf('Dx set: %s', strSet))
                figure; imagesc(py.*Mp); colormap hot; title(sprintf('Dy set: %s', strSet))

            end

            %demodulate signal Y
            FPList=LMM.g(NP+1:end); %Y direction
            d.Process(FPList);
            zc=d.Get(char(DemodulatorProps.zList));
            zcy=zc{1};

            %Calculate defection phasors zx=b*exp(i*2pi*Z*delta_x/p_x) and zy=b*exp(i*2pi*Z*delta_y/p_y) phasors,
            %outside the ROI b=1 and delta_x=0
            zx=zcx./zrx;
            zy=zcy./zry;




            if SHOW_DPM
                %calculate average b (bx and by should be equal)
                %b is in [0 1] + noise
                b=0.5*(abs(zx)+abs(zy));
                %umbralize B with safe threslhold
                Mb=b>0.2; %over 1


                figure; imagesc(b, [0 1]); title('average modulation');
                figure; imagesc(Mb, [0 1]); title('ROI from average modulation');

                %etiquetamos las zonas segnemtadas en Mb
                L=bwlabel(Mb);
                %escogemos la zona que coincida con un punto de control P0
                %escogemos P0[R,C]=0.5*size
                [NR, NC]=size(Mb); R0=round(0.5*NR); C0=round(0.5*NC);
                %segment P in M, close for cleaning mask
                M=(L==L(R0,C0)); se = strel('disk',10); M = imclose(M,se);

                figure; imagesc(M, [0 1]); title('segmented P0 in ROI');


                %feed the LMM before calculate lens power as we do in the
                %AppInterface
                %feed the LMM
                LMM.zx=zx;
                LMM.zy=zy;
                LMM.zrx=zrx;
                LMM.zry=zry;
                %here we assume we have a mask calculated in automatic mode
                LMM.M=M;


                %NO scale from phase-rad/px to deflection-rad/mm
                Kx=1; % px/m from phase-rad/px to deflection-rad/m in m^-1
                Ky=1; % px/m from phase-rad/px to deflection-rad/m in m^-1
                K=[Kx, Ky];
                %if we made the calculation with the y direction the
                %calculation should be the same for squere pixels ON the screen
                %usin the same fringe period in both directions
                %K=Tys/(2*pi*Z*dyLP); %px/m
                LMM.CalculateLensPower(M, K, 'highPowerLens', highPowerLens);




                SE = strel('disk',5);
                LMM.M=imerode(LMM.M,SE);
                DispMask=double(LMM.M)./double(LMM.M);

                figure; imagesc(angle(LMM.zx).*DispMask); title(['\delta_x,' sprintf('UNDISTORT=%d', UNDISTORT)]);
                figure; imagesc(angle(LMM.zy).*DispMask); title(['\delta_y,' sprintf('UNDISTORT=%d', UNDISTORT)]);
                figure; imagesc(LMM.Q.*DispMask); title(sprintf('Dx Dy Quality map, UNDISTORT=%d', UNDISTORT));
                figure; imagesc(LMM.Pxx.*DispMask); title(sprintf('Pxx (D), UNDISTORT=%d', UNDISTORT));
                figure; imagesc(LMM.Pyy.*DispMask); title(sprintf('Pyy (D), UNDISTORT=%d', UNDISTORT));
                figure; imagesc(LMM.Pxy.*DispMask); title(sprintf('Pxy (D), UNDISTORT=%d', UNDISTORT));
                figure; imagesc(LMM.Pyx.*DispMask); title(sprintf('Pyx (D), UNDISTORT=%d', UNDISTORT));
                figure; imagesc(LMM.Qdpm.*DispMask, [0 1]); title(sprintf('DPM Quality map, UNDISTORT=%d', UNDISTORT));


                figure; imagesc(LMM.Seq.*DispMask); title(sprintf('Seq (D), UNDISTORT=%d', UNDISTORT)); colorbar
                figure; imagesc(LMM.C.*DispMask); title(sprintf('C (D), UNDISTORT=%d', UNDISTORT)); colorbar; colorbar
                figure; imagesc(LMM.S.*DispMask); title(sprintf('S (D), UNDISTORT=%d', UNDISTORT)); colorbar; colorbar

                [~,Y]=meshgrid(1:NC, 1:NR);
                R0=round(sum(sum(LMM.M.*Y))/sum(LMM.M(:)));
                x=1:NC;
                figure; plot(x,LMM.C(R0, :).*LMM.M(R0, :)./LMM.M(R0, :)); grid; title(sprintf('Cyl center row, UNDISTORT=%d', UNDISTORT));
                figure; plot(x,LMM.Seq(R0, :).*LMM.M(R0, :)./LMM.M(R0, :)); grid; title(sprintf('Seq center row, UNDISTORT=%d', UNDISTORT));


                if strcmp(LMMFile,'LensMapperMeasurement_05-May-2020_NULL.mat')
                    f=LMM.C(LMM.M);
                    x=linspace(-0.15,0.15, 100); %histogram sampling in D
                    h=hist(f, x);
                    figure; plot(x,h); grid; title(sprintf('Cyl hist for NULL (D), UNDISTORT=%d', UNDISTORT));


                    f=LMM.Seq(LMM.M);
                    x=linspace(-0.15,0.15, 100); %histogram sampling in D
                    h=hist(f, x);
                    figure; plot(x,h); grid; title(sprintf('Seq hist for NULL, UNDISTORT=%d', UNDISTORT));
                end
            end

        end


        % ======================================================================
        %> @brief testCheckLMapperHarmonics is a test for checking an extra harmonic appearing in the X igrams
        %> @details As of 27/8/2020 there is an extra harmonics that do not correspond tp the w0 harmonics.
        %> For well imaged igrams, namely T=8, 16 o 32 px for example, this extra harmonic only apears in the X igrams and do not appear in the Y igrams
        %> The non-linearities affect specially the Dx gradient of the phase in the X grams and can be observed in the FT of the X igrams
        %> @see testMejoraCaluloDPM_APR20 onenote->Mejoras calculo DPM APR20 for experimental
        %> @author AQ 14AUG20
        % ======================================================================
        function testCheckLMapperHarmonics(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testCheckLMapperHarmonics')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());


            %load measurents
            dropboxFolder=fixturesRoot();
            %using setup onenote->Mejoras calculo DPM APR20
            %resolucion 768x576
            baseFolder='Medidas_5MAY20';
            imageSource='default'; %'watec_DFGPro_winvideo_Y800_768x576';
            LMMFile='LensMapperMeasurement_05-May-2020-p5'; %+5D
            %LMMFile='LensMapperMeasurement_05-May-2020_n5.mat'; %-5D
            %LMMFile='LensMapperMeasurement_16-Jul-2020-monofocal_n10D.mat'; %-10D
            %LMMFile='LensMapperMeasurement_26-Aug-2020-monofocal_p10D.mat'; %+10D
            %LMMFile='LensMapperMeasurement_NULL_T32_27-Aug-2020.mat'; %este test es un NULL sin lente y T=32 px en vez de 16
            %LMMFile='LensMapperMeasurement_NULL_T64_27-Aug-2020.mat'; %este test es un NULL sin lente y T=64 px en vez de 16
            %LMMFile='LensMapperMeasurement_NULL_T128_27-Aug-2020.mat'; %este test es un NULL sin lente y T=128 px en vez de 16
            %LMMFile='LensMapperMeasurement_NULL_T8_27-Aug-2020.mat'; %este test es un NULL sin lente y T=8 px en vez de 16
            %LMMFile='LensMapperMeasurement_05-May-2020_NULL.mat';  %este test es un NULL sin lente y T=16 standard
            %LMMFile='LensMapperMeasurement_NULL_T17_27-Aug-2020.mat'; %este test es un NULL sin lente y T=17 px en vez de 16

            %resolucion 720x576
            %baseFolder='PerseusMedidas\ExperimentosPerseus\Deflectometria\Medidas16SEP2020\720x576';
            %imageSource='watec_DFGPro_winvideo_Y800_720x576';
            %LMMFile='LensMapperMeasurement_16-Sep-2020-n5'; %-5D
            %LMMFile='LensMapperMeasurement_16-Sep-2020-n2'; %-5D


            %resolucion 756x576
            %baseFolder='PerseusMedidas\ExperimentosPerseus\Deflectometria\Medidas16SEP2020\756x576';
            %imageSource='default'; % ''watec_DFGPro_winvideo_Y800_768x576';
            %LMMFile='LensMapperMeasurement_16-Sep-2020-n5'; %-5D
            %LMMFile='LensMapperMeasurement_16-Sep-2020-n2'; %-2D
            %LMMFile='LensMapperMeasurement_16-Sep-2020-p10'; %+10D

            %resolucion 640x480
            %baseFolder='PerseusMedidas\ExperimentosPerseus\Deflectometria\Medidas16SEP2020\640x480';
            %LMMFile='LensMapperMeasurement_23-Sep-2020-n5'; %-5D
            %imageSource='imageSource'; %'watec_DFGPro_winvideo_Y800_640x480';
            %LMMFile='LensMapperMeasurement_16-Sep-2020-n2'; %-2D
            %LMMFile='LensMapperMeasurement_16-Sep-2020-p10'; %+10D



            d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.NIgrams), 8);
            d.Set(char(DemodulatorProps.Tx), 16); %pixels
            d.Set(char(DemodulatorProps.Ty), 16); %pixels

            %load the LMM
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));


            %calculate the phasors
            %the first half are the X igrams and the second the Y igrams
            NP=0.5*length(LMM.gr);
            [NR, NC]=size(LMM.gr{1});
            R0=round(0.5*NR); C0=round(0.5*NC);
            c=1:NC; r=1:NR;

            % *****************************************************************************
            % demodulate ref X or signal X depending on FPList in REF o SIGNAL X direction
            % *****************************************************************************
            %FPList=LMM.gr(1:NP); %REF X direction
            FPList=LMM.g(1:NP); %SIGNAL X direction

            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zrx=zr{1};

            strSet='Ref X VERT plot Row ';
            for n=2:length(FPList):length(FPList)
                g=double(FPList{n}); g=mat2gray(g-mean(g(:)));
                G=log(abs(fftshift(fft2(g)))+1);
                figure; imagesc(G); colormap hot; title(sprintf('set: %s, image number: %d', strSet, n))
                figure; imagesc(g); colormap gray; title(sprintf('set: %s, image number: %d', strSet, n))
            end

            Nmed=2; %1 px
            NS=7; %2*NS+1 px phasor filtering
            LPCycles=3; %number of LP cycles
            [px, py, Mp]=UtilFunFPA.phaseGradientDirect(zrx, ones(size(zrx)), NS, Nmed, LPCycles);

            %AQDEBUG 16SEP2020 filtrado fuerza bruta de la spatial freq 66 para 756x576
            if strcmp(imageSource, 'watec_DFGPro_winvideo_Y800_768x576')
                wx=66; %ff Tx=768/66=11 px
                [px, Mp]=UtilFunFPA.filterHarmonicsX(px, wx, 'M', Mp);
            end


            figure; imagesc(log(abs(fftshift(fft2(px)))+1)); colormap hot; title(sprintf('Dx: %s, ', strSet));
            figure; imagesc(log(abs(fftshift(fft2(py)))+1)); colormap hot; title(sprintf('Dy: %s, ', strSet));


            %trim the mask in the borders
            Delta=20;
            Mp(1:Delta, :)=0; Mp(:, 1:Delta)=0; Mp(NR-Delta:NR, :)=0; Mp(:, NC-Delta:NC)=0;
            Mp=Mp./Mp; %NaN mask

            px=px.*Mp; py=py.*Mp; %NaN mask
            figure; imagesc(px); colormap gray; title(sprintf('Dx set: %s', strSet))
            figure; imagesc(py); colormap gray; title(sprintf('Dy set: %s', strSet))

            figure; plot(c, g(R0, :), c, px(R0, :)); title(sprintf('Igram vs Dx set: %s %d', strSet, R0));
            figure; plot(c, angle(zrx(R0, :))/pi, c, px(R0, :)); title(sprintf('Phase/pi vs Dx set: %s %d', strSet, R0));
            figure; plot(c, angle(zrx(R0, :))/pi, c, py(R0, :)); title(sprintf('Phase/pi vs Dy set: %s %d', strSet, R0));

            % *****************************************************************************
            % demodulate ref Y or signal Y depending on FPList in REF o SIGNAL Y direction
            % *****************************************************************************
            FPList=LMM.gr(NP+1:end); %REF Y direction
            %FPList=LMM.g(NP+1:end); %SIGNAL Y direction
            d.Process(FPList);
            zr=d.Get(char(DemodulatorProps.zList));
            zry=zr{1};

            strSet='Ref Y HORZ plot Col ';
            FPList=LMM.g(NP+1:end); %SIGNAL Y direction
            for n=1:length(FPList):length(FPList)
                g=double(FPList{n}); g=mat2gray(g-mean(g(:)));
                G=log(abs(fftshift(fft2(g)))+1);
                figure; imagesc(G); colormap hot; title(sprintf('set: %s, number: %d', strSet, n))
                figure; imagesc(g); colormap gray; title(sprintf('set: %s, number: %d', strSet, n))
            end

            Nmed=2; %1 px
            NS=7; %2*NS+1 px phasor filtering
            LPCycles=3; %number of LP cycles
            [px,py, Mp]=UtilFunFPA.phaseGradientDirect(zry, ones(size(zry)), NS, Nmed, LPCycles);
            figure; imagesc(log(abs(fftshift(fft2(px)))+1)); colormap hot; title(sprintf('Dx: %s, ', strSet));
            figure; imagesc(log(abs(fftshift(fft2(py)))+1)); colormap hot; title(sprintf('Dy: %s, ', strSet));

            %trim the mask in the borders
            Delta=20;
            Mp(1:Delta, :)=0; Mp(:, 1:Delta)=0; Mp(NR-Delta:NR, :)=0; Mp(:, NC-Delta:NC)=0;
            Mp=Mp./Mp; %NaN mask

            px=px.*Mp; py=py.*Mp; %NaN mask
            figure; imagesc(px); colormap hot; title(sprintf('Dx set: %s', strSet))
            figure; imagesc(py); colormap hot; title(sprintf('Dy set: %s', strSet))

            figure; plot(r, g(:, C0), r, mat2gray(py(:, C0))); title(sprintf('Igram vs Dy set: %s %d', strSet, C0));
            figure; plot(r, angle(zry(:, C0))/pi, r, px(:, C0)); title(sprintf('Phase/pi vs Dx set: %s %d', strSet, C0));
            figure; plot(r, angle(zry(:, C0))/pi, r, py(:, C0)); title(sprintf('Phase/pi vs Dy set: %s %d', strSet, C0));


        end


        % ======================================================================
        %> @brief testCheckIOTMapperHarmonicsDirectImages is a test for
        %> checking an extra harmonic appearing in the direct images obtained
        %> in the IOT-Mapper in the X direction
        %> @details As of 27/8/2020 there is an extra harmonics in the X direction that do not correspond tp the w0 harmonics.
        %> it appears that is a problem associated with the digitizer
        %> resolution
        %> @see testMejoraCaluloDPM_APR20 onenote->Mejoras calculo DPM APR20 for experimental
        %> @see testCheckLMapperHarmonics
        %> @author AQ 14SEP20
        % ======================================================================
        function testCheckIOTMapperHarmonicsDirectImages(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testCheckIOTMapperHarmonicsDirectImages')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());


            %load measurents
            dropboxFolder=fixturesRoot();
            %using setup onenote->Armonicos en DFGPro/Watec
            %AGC authomatic gain control
            %MGC manual gain control
            %PALB_Y800 formato disponible para tisimaq
            %tisimaq controlador TIS para image aquisition tooolbox
            %windeo controlador estandar wdm windows
            baseFolder='MedidasResolucionDFGPro-Watec_11SEP20';

            %gFileName='g_AGC_tisimaq_r2013_64_PALB_Y800_640x480.tif';
            %gFileName='g_AGC_winvideo_Y800_640x480.tif';
            %gFileName='g_MGC_tisimaq_r2013_64_PALB_Y800_640x480.tif';
            %gFileName='g_MGC_winvideo_Y800_640x480.tif';

            %gFileName='g_AGC_tisimaq_r2013_64_PALB_Y800_720x576.tif';
            %gFileName='g_AGC_winvideo_Y800_720x576.tif';
            %gFileName='g_MGC_tisimaq_r2013_64_PALB_Y800_720x576.tif';
            %gFileName='g_MGC_winvideo_Y800_720x576.tif';

            %gFileName='g_AGC_tisimaq_r2013_64_PALB_Y800_768x576.tif';
            %gFileName='g_AGC_winvideo_Y800_768x576.tif';
            %gFileName='g_MGC_tisimaq_r2013_64_PALB_Y800_768x576.tif';
            gFileName='g_MGC_winvideo_Y800_768x576.tif';


            %load the image
            g=imread(fullfile(dropboxFolder, baseFolder, gFileName));


            %calculate the phasors
            [NR, NC]=size(g);
            R0=floor(0.5*NR)+1; C0=floor(0.5*NC)+1; %fftshift center
            c=1:NC; r=1:NR;

            % *****************************************************************************
            % Optinal filter
            % *****************************************************************************
            FILTERX=0;
            if FILTERX
                g=double(g);
                g=conv2(g, ones(3, 15), 'same');
            end

            strSet=gFileName;
            g=double(g); g=mat2gray(g-mean(g(:)));
            G=log(abs(fftshift(fft2(g)))+1);
            disp(strSet)
            figure; imagesc(G); colormap hot; title(sprintf('set: %s', strSet), 'Interpreter', 'none')
            figure; imagesc(g); colormap flag; title(sprintf('set: %s', strSet), 'Interpreter', 'none')
            figure; plot(c, G(R0, :)); title(sprintf('abs(G) : %s row %d', strSet, R0), 'Interpreter', 'none');



            [gx, gy, Mg]=UtilFunFPA.gradientDirect(g, ones(size(g)), 3, 1, 1);
            Gx=log(abs(fftshift(fft2(gx)))+1);
            Gy=log(abs(fftshift(fft2(gy)))+1);
            figure; imagesc(Gx); colormap hot; title(sprintf('Dx: %s, ', strSet), 'Interpreter', 'none');
            figure; imagesc(Gy); colormap hot; title(sprintf('Dy: %s, ', strSet), 'Interpreter', 'none');
            figure; plot(c, Gx(R0, :)); title(sprintf('abs(Gx) : %s row %d', strSet, R0), 'Interpreter', 'none');
            figure; plot(r, Gy(:, C0)); title(sprintf('abs(Gy) : %s col %d', strSet, C0), 'Interpreter', 'none');


            %trim the mask in the borders
            Delta=20;
            Mg(1:Delta, :)=0; Mg(:, 1:Delta)=0; Mg(NR-Delta:NR, :)=0; Mg(:, NC-Delta:NC)=0;
            Mg=Mg./Mg; %NaN mask

            gx=gx.*Mg; gy=gy.*Mg; %NaN mask
            figure; imagesc(gx); colormap hot; title(sprintf('Dx set: %s', strSet), 'Interpreter', 'none')
            figure; imagesc(gy); colormap hot; title(sprintf('Dy set: %s', strSet), 'Interpreter', 'none')

            figure; plot(c, g(R0, :), c, gx(R0, :)); title(sprintf('Igram vs Dx: %s row %d', strSet, R0), 'Interpreter', 'none');
            figure; plot(c, g(R0, :), c, gy(R0, :)); title(sprintf('Igram vs Dy: %s row %d', strSet, R0), 'Interpreter', 'none');

            figure; plot(c, gx(R0, :)); title(sprintf('Dx : %s row %d', strSet, R0), 'Interpreter', 'none');
            figure; plot(c, gy(R0, :)); title(sprintf('Dy : %s row %d', strSet, R0), 'Interpreter', 'none');





        end



        % ======================================================================
        %> @brief testLMM_Calibration_5MAY20 aqui vamos a hacer un test de la calibracion con lentes de
        %> referencia usando la calibracionde MAYO de 2020 using only the LensMapperMeasurement class
        %> @details here we use the camera calibration params generated with testUndistortImagesCVTbx_5MAY20
        %> using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20')
        %> optionally we can undistort the LMM images with the static
        %> function testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages
        %> @see testMejoraCaluloDPM_APR20 onenote->Mejoras calculo DPM APR20 for experimental
        %> @details the measurement was obtained usin the
        %> TransDeflAppInterface class of the repo https://bitbucket.org/iot_development_es/perseus/src/master/src/Deflectometer/FFVAppInt/
        %> @author AQ 14APR20
        % ======================================================================
        function testLMM_Calibration_5MAY20(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testLMM_Calibration_5MAY20')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();
            calFolder='Calibracion_5MAY20';
            calDir=fullfile(dropboxFolder, calFolder);

            %load camera calibration params generated with run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            fname='params_Calibracion_5MAY20.json';
            params_struct=loadjson(fname);
            %for loading we need to cast two values to logical
            params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            params_struct.EstimateSkew=logical(params_struct.EstimateSkew)
            params=cameraParameters(params_struct);


            %get callibrated LMM files with valid nominal power Pnom
            LMMFileList = dir(fullfile(calDir, '*.mat'));
            N=length(LMMFileList);
            LMMList=cell(1,N);
            F=0; %valid LMM counter
            waitMsg='test lenses Calibration in process...';
            h=waitbar(0, waitMsg);
            for n=1:N
                %comprobamos que es un mat con una LMM si no continuamos
                S=load(fullfile(calDir, LMMFileList(n).name));
                if isfield(S, 'LMM')
                    if not(isnan(S.LMM.Pnom))
                        LMM=S.LMM;

                        AQUNDISTORT=true;
                        if AQUNDISTORT
                            LMM=testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages(LMM, params);
                        end

                        LMM.CalculateLensPower(LMM.M, [1 1]); %get power with Kxy=1 mm^-1/rad
                        F=F+1;
                        LMMList{F}=LMM;
                    end
                end
                waitbar(n/N, h);
            end
            close(h);

            %trim the List
            LMMList=LMMList(1:F);

            %first calibrate using the monofocal test lenses test lenses
            %get K1
            verbose=true;
            K1=LMM.Calibrate(LMMList, verbose);


            %compare results from geometrical calibration with calibration
            %using test monofocal lenses
            %get K2

            Z=151.97; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_5MAY20');;
            Zc=146; %mm distance camera-lens

            dxLP=0.1436; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            dyLP=0.1438; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');

            dx=337.9/1280; %mm/pixel-proyector size
            dy=270.3/1024; %mm/pixel-proyector size

            Tx=16*dx; %mm on the screen
            Ty=16*dy; %mm on the screen

            Kx=Tx/(2*pi*Z*dxLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            Ky=Ty/(2*pi*Z*dyLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            K2=[Kx, Ky];


            %recalculating power
            D=5; %size mask in px
            N=length(LMMList);
            Pm1=zeros(1, N);
            Pm2=zeros(1, N);
            Pnd=zeros(1, N);
            waitMsg='Recalculation in process...';
            h=waitbar(0, waitMsg);
            for n=1:N
                %comprobamos que es un mat con una LMM si no continuamos
                LMM=LMMList{n};

                %set central ROI
                M=mat2gray(LMM.M);
                [y,x] = find(M) ;
                xm=round(mean(x));
                ym=round(mean(y));

                c=xm-D:xm+D; %square arrounf xm, ym
                r=ym-D:ym+D;
                PM=(M(r,c)==1); %check if any ellement inside is masked

                Pnd(n)=LMM.Pnom; %nominal power in mm^-1 (DPM=Pnom*eye(2))

                %calculate power with K1 test lens calibration
                LMM.CalculateLensPower(LMM.M, K1); %get power with K1
                P1=LMM.Seq(r,c); %Seq power at the center K1
                Pm1(n)=mean(P1(PM)); %Seq power using K=1

                %calculate power with K2 geometrical calibration
                LMM.CalculateLensPower(LMM.M, K2); %get power with K2
                P2=LMM.Seq(r,c); %Seq power at the center K2
                Pm2(n)=mean(P2(PM)); %Seq power using K=2

                waitbar(n/N, h);
            end
            close(h);

            %1) Calibration with test lenses
            figure;
            xb=1000*Pnd;
            yb=1000*Pm1;
            bar(xb, xb-yb); ylabel('\Delta Seq (D)'); xlabel('Nominal power (D)'); title('Seq error calibration test lenses Nominal-Measured');

            %2) Geometrical calibration
            figure;
            yb=1000*Pm2;
            bar(xb, xb-yb); ylabel('\Delta Seq (D)'); xlabel('Nominal power (D)'); title('Seq error geom calibration Nominal-Measured');

        end


        % ======================================================================
        %> @brief testLMM_Calibracion_1OCT20 aqui vamos a hacer un test de la calibracion con lentes de
        %> referencia usando la calibracionde 1 OCT 20 using only the LensMapperMeasurement class
        %> There is a bug in the compiled version of 30SEP20
        %> @details here we use the camera calibration params generated with testUndistortImagesCVTbx_5MAY20
        %> using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20')
        %> optionally we can undistort the LMM images with the static
        %> function testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages
        %> @see testMejoraCaluloDPM_APR20 onenote->Mejoras calculo DPM APR20 for experimental
        %> @author AQ 1OCT20
        % ======================================================================
        function testLMM_Calibracion_1OCT20(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testLMM_Calibracion_1OCT20')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();
            calFolder='Calibracion_1OCT20';
            calDir=fullfile(dropboxFolder, calFolder);

            %load camera calibration params generated with run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            fname='params_Calibracion_5MAY20.json';
            params_struct=loadjson(fname);
            %for loading we need to cast two values to logical
            params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            params_struct.EstimateSkew=logical(params_struct.EstimateSkew)
            params=cameraParameters(params_struct);


            %get callibrated LMM files with valid nominal power Pnom
            LMMFileList = dir(fullfile(calDir, '*.mat'));
            N=length(LMMFileList);
            LMMList=cell(1,N);
            F=0; %valid LMM counter
            waitMsg='test lenses Calibration in process...';
            h=waitbar(0, waitMsg);
            for n=1:N
                %comprobamos que es un mat con una LMM si no continuamos
                %starting 2JUN20 the LMM is saved as a struct, for this
                %reason we must use LensMapperMeasurement.load
                LMM=LensMapperMeasurement.load(fullfile(calDir, LMMFileList(n).name));

                if not(isnan(LMM.Pnom))

                    AQUNDISTORT=false;
                    if AQUNDISTORT
                        LMM=testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages(LMM, params);
                    end

                    LMM.CalculateLensPower(LMM.M, [1 1]); %get power with Kxy=1 mm^-1/rad
                    F=F+1;
                    LMMList{F}=LMM;
                end
                waitbar(n/N, h);
            end
            close(h);

            %trim the List
            LMMList=LMMList(1:F);

            %first calibrate using the monofocal test lenses test lenses
            %get K1
            verbose=true;
            K1=LensMapperMeasurement.Calibrate(LMMList, verbose);


            %compare results from geometrical calibration with calibration
            %using test monofocal lenses
            %get K2

            Z=151.97; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_5MAY20');;
            Zc=146; %mm distance camera-lens

            dxLP=0.1436; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            dyLP=0.1438; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');

            dx=337.9/1280; %mm/pixel-proyector size
            dy=270.3/1024; %mm/pixel-proyector size

            Tx=16*dx; %mm on the screen
            Ty=16*dy; %mm on the screen

            Kx=Tx/(2*pi*Z*dxLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            Ky=Ty/(2*pi*Z*dyLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            K2=[Kx, Ky];


            %recalculating power
            D=5; %size mask in px
            N=length(LMMList);
            Pm1=zeros(1, N);
            Pm2=zeros(1, N);
            Pnd=zeros(1, N);
            waitMsg='Recalculation in process...';
            h=waitbar(0, waitMsg);
            for n=1:N
                %comprobamos que es un mat con una LMM si no continuamos
                LMM=LMMList{n};

                %set central ROI
                M=mat2gray(LMM.M);
                [y,x] = find(M) ;
                xm=round(mean(x));
                ym=round(mean(y));

                c=xm-D:xm+D; %square arrounf xm, ym
                r=ym-D:ym+D;
                PM=(M(r,c)==1); %check if any ellement inside is masked

                Pnd(n)=LMM.Pnom; %nominal power in mm^-1 (DPM=Pnom*eye(2))

                %calculate power with K1 test lens calibration
                LMM.CalculateLensPower(LMM.M, K1); %get power with K1
                P1=LMM.Seq(r,c); %Seq power at the center K1
                Pm1(n)=mean(P1(PM)); %Seq power using K=1

                %calculate power with K2 geometrical calibration
                LMM.CalculateLensPower(LMM.M, K2); %get power with K2
                P2=LMM.Seq(r,c); %Seq power at the center K2
                Pm2(n)=mean(P2(PM)); %Seq power using K=2

                waitbar(n/N, h);
            end
            close(h);

            %1) Calibration with test lenses
            figure;
            xb=1000*Pnd;
            yb=1000*Pm1;
            bar(xb, xb-yb); ylabel('\Delta Seq (D)'); xlabel('Nominal power (D)'); title('Seq error calibration test lenses Nominal-Measured');

            %2) Geometrical calibration
            figure;
            yb=1000*Pm2;
            bar(xb, xb-yb); ylabel('\Delta Seq (D)'); xlabel('Nominal power (D)'); title('Seq error geom calibration Nominal-Measured');

        end


        % ======================================================================
        %> @brief testLMM_Calibracion_15DIC20 aqui vamos a hacer un test de la calibracion con lentes de
        %> referencia usando la calibracionde 15DIC20 using only the LensMapperMeasurement class
        %> @details here we use the camera calibration params generated with
        %> using run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_15DIC20');
        %> optionally we can undistort the LMM images with the static
        %> function testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages
        %> @see "Calibraci�n 15DIC20" doc en onenote
        %> @author AQ 15DIC20
        % ======================================================================
        function testLMM_Calibracion_15DIC20(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testLMM_Calibracion_15DIC20')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();
            calFolder='Calibracion_15DIC20';
            calDir=fullfile(dropboxFolder, calFolder);

            %load camera calibration params generated with run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_15DIC20');
            fname='params_Calibracion_15DIC20.json';
            params_struct=loadjson(fname);
            %for loading we need to cast two values to logical
            params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            params_struct.EstimateSkew=logical(params_struct.EstimateSkew)
            params=cameraParameters(params_struct);


            %get callibrated LMM files with valid nominal power Pnom
            LMMFileList = dir(fullfile(calDir, '*.mat'));
            N=length(LMMFileList);
            LMMList=cell(1,N);
            F=0; %valid LMM counter
            waitMsg='test lenses Calibration in process...';
            h=waitbar(0, waitMsg);
            for n=1:N
                %comprobamos que es un mat con una LMM si no continuamos
                %starting 2JUN20 the LMM is saved as a struct, for this
                %reason we must use LensMapperMeasurement.load
                LMM=LensMapperMeasurement.load(fullfile(calDir, LMMFileList(n).name));

                if not(isnan(LMM.Pnom))

                    AQUNDISTORT=false;
                    if AQUNDISTORT
                        LMM=testFPA_UtilFunMapperMeasureClassVer.undistortLMMImages(LMM, params);
                    end

                    LMM.CalculateLensPower(LMM.M, [1 1]); %get power with Kxy=1 mm^-1/rad
                    F=F+1;
                    LMMList{F}=LMM;
                end
                waitbar(n/N, h);
            end
            close(h);

            %trim the List
            LMMList=LMMList(1:F);

            %first calibrate using the monofocal test lenses test lenses
            %get K1
            verbose=true;
            K1=LensMapperMeasurement.Calibrate(LMMList, verbose);


            %compare results from geometrical calibration with calibration
            %using test monofocal lenses
            %get K2

            Z=2.052945e+02; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_5MAY20');;
            Zc=2.667984e+02; %mm distance camera-lens

            fu=3735.4745; %px u focal length
            fv=3722.0838; %px u focal length

            %valor teorico de acuerdo a la calibracion
            dxLP=Zc/fu; %approx 0.0714 mm/px mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            dyLP=Zc/fv; %approx 0.0717 mm/px mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');

            %estos valores estan calculados mediante una imagen del plano de calibracion con run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_15DIC20');
            %dxLP=7.147865e-02; %mm
            %dyLP=7.160968e-02; %mm


            dx=337.9/1280; %mm/pixel-proyector size
            dy=270.3/1024; %mm/pixel-proyector size

            Tx=16*dx; %mm on the screen
            Ty=16*dy; %mm on the screen

            Kx=Tx/(2*pi*Z*dxLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            Ky=Ty/(2*pi*Z*dyLP); % px/mm from phase-rad/px to deflection-rad/m in mm^-1
            K2=[Kx, Ky];


            %recalculating power
            D=5; %size mask in px
            N=length(LMMList);
            Pm1=zeros(1, N);
            Pm2=zeros(1, N);
            Pnd=zeros(1, N);
            waitMsg='Recalculation in process...';
            h=waitbar(0, waitMsg);
            for n=1:N
                %comprobamos que es un mat con una LMM si no continuamos
                LMM=LMMList{n};

                %set central ROI
                M=mat2gray(LMM.M);
                [y,x] = find(M) ;
                xm=round(mean(x));
                ym=round(mean(y));

                c=xm-D:xm+D; %square arrounf xm, ym
                r=ym-D:ym+D;
                PM=(M(r,c)==1); %check if any ellement inside is masked

                Pnd(n)=LMM.Pnom; %nominal power in mm^-1 (DPM=Pnom*eye(2))

                %calculate power with K1 test lens calibration
                LMM.CalculateLensPower(LMM.M, K1); %get power with K1
                P1=LMM.Seq(r,c); %Seq power at the center K1
                Pm1(n)=mean(P1(PM)); %Seq power using K=1

                %calculate power with K2 geometrical calibration
                LMM.CalculateLensPower(LMM.M, K2); %get power with K2
                P2=LMM.Seq(r,c); %Seq power at the center K2
                Pm2(n)=mean(P2(PM)); %Seq power using K=2

                waitbar(n/N, h);
            end
            close(h);

            %1) Calibration with test lenses
            figure;
            xb=1000*Pnd;
            yb=1000*Pm1;
            bar(xb, xb-yb); ylabel('\Delta Seq (D)'); xlabel('Nominal power (D)'); title('Seq error calibration test lenses Nominal-Measured');

            %2) Geometrical calibration
            figure;
            yb=1000*Pm2;
            bar(xb, xb-yb); ylabel('\Delta Seq (D)'); xlabel('Nominal power (D)'); title('Seq error geom calibration Nominal-Measured');

        end

        % ======================================================================
        %> @brief testLMM_Calibracion_GeomVsPower_15DIC20 aqui vamos comparas los resultados
        %> de la calibracion segun el modelo thin-lens y los obtenidos de la
        %> correlacion entre potencia en D (def-rad/m) y la potencia en
        %> pha-rad/px (ver doc deflectometry.docx) usando los datos de la calibracion geometrica y la correlacion
        %> entre potencia del fichero de calibracion del 15DIC20. Esto lo
        %> hacemos para validar el modelo geometrico de lente delgada y
        %> hacer la calibracion de aqui en adelante segun el modelo geometrico
        %> @see "Calibraci�n 15DIC20" doc en onenote
        %> @author AQ 1JAN21
        % ======================================================================
        function testLMM_Calibracion_GeomVsPower_15DIC20(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testLMM_Calibracion_GeomVsPower_15DIC20')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();
            calFolder='Calibracion_15DIC20';
            fname='TrasmDeflConfig.json';
            calFile=fullfile(dropboxFolder, calFolder, fname);

            params_struct=loadjson(calFile);


            %get the calibration params Kx, Ky measured from the correlation
            %between D and pha-rad/px
            Kx_Power=params_struct.K(1); %(def-rad/mm)/(pha-rad/px) direccion x
            Ky_Power=params_struct.K(2); %(def-rad/mm)/(pha-rad/px) direccion y


            %calculate Kx and Ky from the geom params of the mapper
            fu=params_struct.cameraParams.IntrinsicMatrix(1,1);
            fv=params_struct.cameraParams.IntrinsicMatrix(2,2);

            %get the camera pixel size at the lens plane Zc
            duZc=params_struct.MapperData.duZc; %mm/px
            dvZc=params_struct.MapperData.dvZc; %mm/px

            %get the fringe period in mm at the screen
            Tx=params_struct.Tx;
            px=Tx*params_struct.MapperData.Screen.pixelSize(1); %mm

            Ty=params_struct.Ty;
            py=Ty*params_struct.MapperData.Screen.pixelSize(2); %mm

            %get the screen-lens distance in mm
            Z=params_struct.MapperData.Z;

            Kx_Geom=px/(2*pi*Z*duZc); %(def-rad/mm)/(pha-rad/px) direccion x
            Ky_Geom=py/(2*pi*Z*dvZc); %(def-rad/mm)/(pha-rad/px) direccion y

            tol=1e-6;
            testCase.assertEqual(Kx_Geom, Kx_Power, 'AbsTol', tol);
            testCase.assertEqual(Ky_Geom, Ky_Power, 'AbsTol', tol);

        end



        % ======================================================================
        %> @brief 'testLMM2AndFromStruct' %verificamos las funciones para pasar a struct y cargar desde
        %> struct
        %> @author AQ 6JUN20
        %>
        % ======================================================================
        function testLMM2AndFromStruct(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testLMM2AndFromStruct')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());


            dropboxFolder=fixturesRoot();
            %load a old version of LMM file where we have a instance of the
            %LMM class
            baseFolder='Medidas_5MAY20';
            LMMFile='LensMapperMeasurement_05-May-2020_PAL_AQ';

            %load the LMM old format where LMM is an istance of LMM class
            LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));
            testCase.assertTrue(isa(LMM, 'LensMapperMeasurement'));

            %transform to a struct
            sLMM = LMM.class2struct();

            %check copy is OK
            for fn = properties(LMM)'    %enumerat fields
                testCase.assertTrue(isfield(sLMM, fn{1}));
                testCase.assertEqual(sLMM.(fn{1}), LMM.(fn{1}));
            end

            %create a LMM instance and copy a struct
            LMM1=LensMapperMeasurement;
            LMM1.struct2class(sLMM);

            %check copy is OK
            for fn = fields(sLMM)'    %enumerat fields
                testCase.assertTrue(isprop(LMM1, fn{1}));
                testCase.assertEqual(LMM1.(fn{1}), sLMM.(fn{1}));
            end
        end


        % ======================================================================
        %> @brief ttest_SetParamsForCalculateLensPower vemos que parametros usaremos 
        %> para medir la DPM en el mapper
        %> de la resolucion 
        %> @author AQ 27JUN23
        %>
        % ======================================================================        
        function test_SetParamsForCalculateLensPower(testCase)
            %run(testFPA_UtilFunMapperMeasureClassVer, 'test_SetParamsForCalculateLensPower')
            %Only the xlsx sample DB and the CalibracionIOTMapper_15JUN23
            %sample dir it references (the only rows this test actually
            %uses) were copied to fixtures - not the whole 49 INFORME-AVI014
            %Mejoras IOTMapper project folder (6.9GB/3101 files)
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            dropboxFolder=fixturesRoot();
            baseFolder='';
            sampleDB=fullfile(dropboxFolder, baseFolder, 'ListaMuestrasINFORME-AVI014.xlsx'); %samples DB
            sampleTb = readtable(sampleDB, 'Sheet','Samples', 'ReadVariableNames',true, 'Format','auto'); %sample table

            %list of sample dirs
            sampleDirList=sampleTb.SampleDir;

            %samples base path
            sampleHomePathList=sampleTb.SampleHomePath;

            %Sample List
            sampleNameList=sampleTb.SampleName;

            %config Names list
            configNameList=sampleTb.ConfigName;


            %get list of index of interest
            %sampleNameIndexList=find(contains(sampleNameList,{'LensMapperMeasurement_15-Jun-2023_Pn5.mat'}));
            %sampleNameIndexList=find(contains(sampleNameList,{'LensMapperMeasurement_15-Jun-2023_P5.mat'}));
            sampleNameIndexList=find(contains(sampleNameList,{'15-Jun-2023_P5.mat', '15-Jun-2023_P5_R_0.4_M_bilinear.mat'}));
            %sampleNameIndexList=find(contains(sampleNameList,{'15-Jun-2023_P5_R_0.5_M_bilinear.mat'}));



            %% Load sample and configfile
            hwait=waitbar(0, 'Procesando directorios');
            % scan samples dir index (sdi) of sampleDirIndexList
            for sni=sampleNameIndexList'
                sampleHomePath=fullfile(dropboxFolder, baseFolder, sampleHomePathList{sni});
                sampleDir=sampleDirList{sni};
                sampleName=sampleNameList{sni};
                configName=configNameList{sni};

                LMMFileName=fullfile(sampleHomePath, sampleDir, sampleName);
                %configFileName=fullfile(sampleHomePath, sampleDir, configName);

                % AQDEBUG cargar fichero para poder tener constantes de
                % conversion de px^-1 a D


                %Init LMM and load config
                LMM=LensMapperMeasurement.load(LMMFileName);
                %configData=loadjson(configFileName);

                %in this case we get the K from the LMM data
                K=LMM.measurementParams.K; %px^-1 to D

                %Power range in D
                PowerRange=[-6, 6];

                %%%%% use default params for 1st calculation
                LMM.calculateROIFromPhasor(); %reset mask
                LMM.CalculateLensPower(LMM.M, K);

                %calculate some statistics
                M=LMM.M ; %get first mask
                R=sqrt(sum(M(:))); % average size
                se = strel('cube',round(0.25*R)); %reduce to central part
                M=imerode(M, se);

                mC1=1000*mean(LMM.C(M));
                mS1=1000*mean(LMM.S(M));
                stdC1=1000*std(LMM.C(M));
                stdS1=1000*std(LMM.S(M));
                %show figures
                strTitle1=sprintf('%s, default NS=%d, LPCycles=%d, NMed=%d', ...
                    sampleName, LMM.measurementParams.Filter.NS, ...
                    LMM.measurementParams.Filter.LPCycles, ...
                    LMM.measurementParams.Filter.Nmed);
                strXLabelS=sprintf('mean: %d, std=%d', mS1, stdS1);
                strXLabelC=sprintf('mean: %d, std=%d', mC1, stdC1);
                figure; imagesc(abs(LMM.M.*LMM.zx), [0 1]);  truesize; colormap gray;  colorbar; title(['|zx|: ' strTitle1], 'Interpreter', 'none')
                figure; imagesc(angle(LMM.M.*LMM.zx));  truesize; colormap gray;  colorbar; title(['Phase(zx): ' strTitle1], 'Interpreter', 'none')

                figure; imagesc(1000.*LMM.M.*LMM.S, PowerRange); truesize; colormap flag; colorbar; title(['S: ' strTitle1], 'Interpreter', 'none'); xlabel(strXLabelS);
                figure; imagesc(1000.*LMM.M.*LMM.C, PowerRange);  truesize; colormap flag;  colorbar; title(['C: ' strTitle1], 'Interpreter', 'none'); xlabel(strXLabelC);


                %%%%%%% change params
                LPCycles=1;
                NS=3;
                Nmed=3;

                LMM.calculateROIFromPhasor(); %reset mask
                % OJO los valores de
                % LMM.measurementParams.Filter no cambian con
                % CalculateLensPower aunque los parametros si que se usan
                % en el calculo
                LMM.CalculateLensPower(LMM.M, K, 'LPCycles', LPCycles, 'Nmed', Nmed, 'NS', NS);


                %calculate some statistics
                M=LMM.M ; %get first mask
                R=sqrt(sum(M(:))); % average size
                se = strel('cube',round(0.25*R)); %reduce to central part
                M=imerode(M, se);

                mC2=1000*mean(LMM.C(M));
                mS2=1000*mean(LMM.S(M));
                stdC2=1000*std(LMM.C(M));
                stdS2=1000*std(LMM.S(M));


                %show figures
                strTitle2=sprintf('%s, new NS=%d, LPCycles=%d, NMed=%d', ...
                    sampleName, NS, LPCycles, Nmed);
                strXLabelS=sprintf('mean: %d, std=%d', mS2, stdS2);
                strXLabelC=sprintf('mean: %d, std=%d', mC2, stdC2);
                figure; imagesc(1000.*LMM.M.*LMM.S, PowerRange); truesize; colormap flag; colorbar; title(['S: ' strTitle2], 'Interpreter', 'none'); xlabel(strXLabelS);
                figure; imagesc(1000.*LMM.M.*LMM.C, PowerRange);  truesize; colormap flag;  colorbar; title(['C: ' strTitle2], 'Interpreter', 'none'); xlabel(strXLabelC);
            end
            close(hwait);
        end
    end

    methods (Static)
        %> @brief this function is a draft for undistorting the LMM images and chek
        %> if the measured power changes from using distorted vs undistorted
        %> images
        %> @param cameraParams  is a cameraParameters object
        %> @author AQ 6JUN20
        function LMM=undistortLMMImages(LMM, cameraParams)
            N=length(LMM.g);
            for n=1:N
                %Undistort the image and get newOrigin in px
                %cdo 'OutputView'=='same' el tama�o de la imagen undistorted es
                %el mismo que I y newOrigin=[0,0] no hay cambio de origen
                [g, newOrigin] = undistortImage(LMM.g{n},cameraParams,'OutputView','same');
                [gr, newOrigin] = undistortImage(LMM.gr{n},cameraParams,'OutputView','same');
                [M, newOrigin] = undistortImage(LMM.M,cameraParams,'OutputView','same');

                LMM.g{n}=g;
                LMM.gr{n}=gr;
                LMM.M=M;
            end
        end

    end
end
