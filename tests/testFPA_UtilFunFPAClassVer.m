classdef testFPA_UtilFunFPAClassVer < matlab.unittest.TestCase
    % testFPA_UtilFunFPAClassVer tests UtilFunFPA's static fringe
    % pattern analysis functions (Gray-code, demodulation, phase
    % gradients, camera calibration, deflectometry, DPM calculation).
    % Converted from the legacy mtest-framework tests (dropped after
    % R2016a) to matlab.unittest - see UtilFunFPA.m.
    %run(testFPA_UtilFunFPAClassVer)

    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
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
        function testBin2Grey(testCase)
            % testBin2Grey checks UtilFunFPA.bin2gray/gray2bin against a
            % precomputed ground-truth table (Dec2Grey_15) for all 4-bit
            % values, both directions, and cross-checks the two directions
            % against each other
            %run(testFPA_UtilFunFPAClassVer, 'testBin2Grey')
            %test of the bin2grey and grey2bin functions
            %load a file previously calculated from \Dropbox
            %(IOT)\AQ_SYNC\AQ11\Programs\Matlab\GreyCodes\Grey2BinDemo.mlx and compare
            %results

            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            Tgt=readtable('Dec2Grey_15', 'delimiter', '\t', 'Format','%d%d%s%s'); %ground truth

            dMax=15;
            nBits=nextpow2(dMax); N=2^nBits;
            d=zeros(N, 1); gd=d;
            b=cell(N,1); gb=b;
            OFFSET=1;

            %first check bin2gray
            for n = 0 : N-1
                d(n+OFFSET)=n; %dec
                b{n+OFFSET} = dec2bin(d(n+OFFSET), nBits); %from dec to binary dec
                gb{n+OFFSET} = UtilFunFPA.bin2gray(b{n+OFFSET}); %from binary dec to binary gray
                gd(n+OFFSET)=bin2dec(gb{n+OFFSET});    %from binary gray to dec gray
            end



            T_B2G=table(d, gd, b, gb);
            %comparamos T y Tgt
            [Td, id]=setdiff(T_B2G,Tgt);

            %check difference is empty
            testCase.assertTrue(isempty(Td));
            testCase.assertTrue(isempty(id));

            %Now check gray2bin, using former results for the grey code list g
            for n = 0 : N-1
                gb{n+OFFSET}=dec2bin(gd(n+OFFSET), nBits); %pass grey code dec to grey code bin
                b{n+OFFSET} = UtilFunFPA.gray2bin(gb{n+OFFSET}); %pass gray bin to dec bin
                d(n+OFFSET)=bin2dec(b{n+OFFSET});    %pass dec bin to dec
            end

            T_G2B=table(d, gd, b, gb);
            %comparamos T y Tgt
            [Td, id]=setdiff(T_G2B,Tgt);

            %check difference is empty
            testCase.assertTrue(isempty(Td));
            testCase.assertTrue(isempty(id));

            %finalmente comparamos T_G2B y T_B2G
            [Td, id]=setdiff(T_G2B,T_B2G);

            %check difference is empty
            testCase.assertTrue(isempty(Td));
            testCase.assertTrue(isempty(id));

        end

        function testGenerateGC(testCase)
            % testGenerateGC checks UtilFunFPA.generateGC's LUTs (against
            % the Dec2Grey_4Bits ground-truth table) and pattern
            % count/sizes, for both X and Y directions
            %run(testFPA_UtilFunFPAClassVer, 'testGenerateGC')
            %load a file previously calculated from \Dropbox
            %(IOT)\AQ_SYNC\AQ11\Programs\Matlab\GreyCodes\GreyCodeAQ and compare
            %results

            %image size
            NR=213; NC=199;

            %establecemos ancho de las las barras en px
            %el ancho de las barras sera el periodo del patron sinosoidal mas fino
            Tx=19; Ty=17;
            Txy=[Tx, Ty];
            TLabel=['X', 'Y'];

            for k=1:2
                T=Txy(k);
                GCDir=k-1;
                [PGC, LUT_GC2D, LUT_D2GC, nBits]=UtilFunFPA.generateGC(T, NR, NC, GCDir);

                %si no se cumple la parte de leer el fichero no se cumple
                %tco
                testCase.assertEqual(nBits, 4);

                %leemos el fichero ground truth a una tabla
                Tgt=readtable('Dec2Grey_4Bits', 'delimiter', '\t', 'Format','%d%d'); %ground truth

                %check for LUT_GC2D
                testCase.assertEqual(LUT_GC2D, double(Tgt.LUT_GC2D));
                testCase.assertEqual(LUT_D2GC, double(Tgt.LUT_D2GC));


                %check for inverse
                NPatterns=nBits+2; %adding W and K
                testCase.assertEqual(length(PGC), NPatterns);

                for n=1:NPatterns
                    testCase.assertEqual(size(PGC{n}), [NR, NC])
                    figure; imshow(PGC{n}); title([TLabel(k) ' ' num2str(n)])
                end
            end


        end

        function testDecodeGC(testCase)
            % testDecodeGC checks UtilFunFPA.decodeGC correctly recovers
            % the fringe order from UtilFunFPA.generateGC's patterns,
            % for both X and Y directions
            %aqui comprobamos que el demodeGC trabaja OK con el generaGC
            %run(testFPA_UtilFunFPAClassVer, 'testDecodeGC')

            %image size
            NR=113; NC=199;

            %establecemos ancho de las las barras en px
            %el ancho de las barras sera el periodo del patron sinosoidal mas fino
            Tx=19; Ty=17;
            Txy=[Tx, Ty];
            TLabel=['X', 'Y'];

            D=cell(1,2);
            %k=1 es X y k=2 es Y
            for k=1:2
                T=Txy(k);
                GCDir=k-1;
                %generamos la lista de GCs
                [PGC, LUT_GC2D, ~, nBits]=UtilFunFPA.generateGC(T, NR, NC, GCDir);

                %la decodificamos
                D{k}=UtilFunFPA.decodeGC(PGC, LUT_GC2D);
                figure; imagesc(D{k});
            end

            %check all rows of Dx are decoded OK
            nx=floor((0:NC-1)/Tx);
            Dx=D{1};
            for r=1:NR
                testCase.assertEqual(nx, Dx(r, :));
            end

            %check all cols of Dy are decoded OK
            ny=floor((0:NR-1)/Ty);
            Dy=D{2};
            for c=1:NC
                testCase.assertEqual(ny', Dy(:, c));
            end

        end

        function testDecodeGC_PSA(testCase)
            % testDecodeGC_PSA checks a Gray-code fringe order combined
            % with an LSPSA-demodulated phase (absolute phase =
            % GC-order*2*pi + wrapped phase) has a near-zero gradient
            % along the constant direction, for every period 3:60 px,
            % in both X and Y
            %run(testFPA_UtilFunFPAClassVer, 'testDecodeGC_PSA')
            %genera un GC + PSA para diferentes periodos y verifica que
            %todos casan

            %image size
            NR=121; NC=199;

            %establecemos ancho de las las barras en px
            %el ancho de las barras sera el periodo del patron sinosoidal mas fino
            for n=3:60
                formatSpec = 'Period: %f px\n';
                fprintf(formatSpec,n)
                Tx=n; Ty=Tx;
                Txy=[Tx, Ty];
                TLabel=['X', 'Y'];

                D=cell(1,2);
                d=cell(1,2);
                %k=1 es X y k=2 es Y
                for k=1:2
                    T=Txy(k);
                    GCDir=k-1;
                    %generamos la lista de GCs
                    [PGC, LUT_GC2D, ~, nBits]=UtilFunFPA.generateGC(T, NR, NC, GCDir);

                    %la decodificamos
                    D{k}=UtilFunFPA.decodeGC(PGC, LUT_GC2D);
                    %figure; imagesc(D{k});
                end

                %X Igrams
                PSDir=0;
                d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
                d.Set(char(DemodulatorProps.Tx), Tx);
                d.Set(char(DemodulatorProps.NIgrams), Tx);
                d.Set(char(DemodulatorProps.PSDir), PSDir);
                gList=d.GenerateFPs([NR, NC]);

                %process X Igrams
                d.Process(gList);
                zList=d.Get(char(DemodulatorProps.zList));
                z=zList{1};
                za=mod(angle(z), 2*pi); %el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
                pa=za+2*pi*D{1}; %fase absoluta
                %figure; imagesc(pa); title('fase X absoluta')
                [Dx, Dy]=gradient(pa);

                testCase.assertLessThan(std(Dx(:)), 1e-6);
                testCase.assertLessThan(abs(mean(Dy(:))), eps);
                %figure; imagesc(Dx); %Dx fase absoluto
                %title('Dx X fase  absoluta'); colorbar;
                %figure; imagesc(Dy); %Dy fase absoluto
                %title('Dy fase X absoluta'); colorbar;

                %AQDEBUG
                %c=1:NC;
                %Nx=D{1};
                %plot(c, angle(z(10, c))/pi, '.-', c, za(10, c)/pi, '.-', c, Nx(10, c), '.-');
                %grid;

                %Y Igrams
                PSDir=1;
                %no hace falta instanciar de nuevo el demodulador
                %d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
                d.Set(char(DemodulatorProps.Ty), Ty);
                d.Set(char(DemodulatorProps.NIgrams), Ty);
                d.Set(char(DemodulatorProps.PSDir), PSDir);
                gList=d.GenerateFPs([NR, NC]);

                %process Y Igrams
                d.Process(gList);
                zList=d.Get(char(DemodulatorProps.zList));
                z=zList{1};
                za=mod(angle(z), 2*pi); %el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
                pa=za+2*pi*D{2}; %fase absoluta
                %figure; imagesc(pa); title('fase Y absoluta')
                [Dx, Dy]=gradient(pa);
                testCase.assertLessThan(std(Dy(:)), 1e-6);
                testCase.assertLessThan(abs(mean(Dx(:))), eps);
                %figure; imagesc(Dx); %Dx fase absoluto
                %title('Dx Y fase  absoluta'); colorbar;
                %figure; imagesc(Dy); %Dy fase absoluto
                %title('Dy fase Y absoluta'); colorbar;
            end



        end

        function testDecodeGC_PSA_ParicularCase1(testCase)
            % testDecodeGC_PSA_ParicularCase1 repeats testDecodeGC_PSA's
            % absolute-phase gradient check for a single period (T=20px)
            % with NIgrams=0.5*T (rather than =T), using
            % DemodulatorLSPSA - a stricter case for DemodulatorGCPSA's
            % own tests
            %run(testFPA_UtilFunFPAClassVer, 'testDecodeGC_PSA_ParicularCase1')
            %genera un GC + PSA para un caso particular y verificar asi los tets de DemodulatorGCPSA
            %aqui se puede ver como los test (muy restrictivos con la
            %pendiente de la fase abosluta) pasan OK si NIgrams=T o 0.5*T y
            %"casi" pasan para 0.25*T
            %usamos como demodulador PSA el LSPSA

            %image size
            NR=190; NC=190;

            %establecemos ancho de las las barras en px
            %el ancho de las barras sera el periodo del patron sinosoidal mas fino
            Tx=20;
            Ty=20;
            Txy=[Tx, Ty];
            TLabel=['X', 'Y'];

            D=cell(1,2);
            d=cell(1,2);
            %k=1 es X y k=2 es Y
            for k=1:2
                T=Txy(k);
                GCDir=k-1;
                %generamos la lista de GCs
                [PGC, LUT_GC2D, ~, nBits]=UtilFunFPA.generateGC(T, NR, NC, GCDir);

                %la decodificamos
                D{k}=UtilFunFPA.decodeGC(PGC, LUT_GC2D);
                %figure; imagesc(D{k});
            end

            %X Igrams
            PSDir=0;
            d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.Tx), Tx);
            d.Set(char(DemodulatorProps.NIgrams), 0.5*Tx); %default is 4
            d.Set(char(DemodulatorProps.PSDir), PSDir);
            gList=d.GenerateFPs([NR, NC]);

            %process X Igrams
            d.Process(gList);
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            za=mod(angle(z), 2*pi); %el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
            pa=za+2*pi*D{1}; %fase absoluta
            figure; imagesc(pa); title('fase X absoluta')
            [Dx, Dy]=gradient(pa);

            testCase.assertLessThan(std(Dx(:)), 1e-6);
            testCase.assertLessThan(abs(mean(Dy(:))), eps);
            %figure; imagesc(Dx); %Dx fase absoluto
            %title('Dx X fase  absoluta'); colorbar;
            %figure; imagesc(Dy); %Dy fase absoluto
            %title('Dy fase X absoluta'); colorbar;


            %Y Igrams
            PSDir=1;
            %no hace falta instanciar de nuevo el demodulador
            %d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.Ty), Ty);
            d.Set(char(DemodulatorProps.NIgrams), 0.5*Ty); %default is 4
            d.Set(char(DemodulatorProps.PSDir), PSDir);
            gList=d.GenerateFPs([NR, NC]);

            %process Y Igrams
            d.Process(gList);
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            za=mod(angle(z), 2*pi); %el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
            pa=za+2*pi*D{2}; %fase absoluta
            figure; imagesc(pa); title('fase Y absoluta')
            [Dx, Dy]=gradient(pa);
            testCase.assertLessThan(std(Dy(:)), 1e-6);
            testCase.assertLessThan(abs(mean(Dx(:))), eps);
            %figure; imagesc(Dx); %Dx fase absoluto
            %title('Dx Y fase  absoluta'); colorbar;
            %figure; imagesc(Dy); %Dy fase absoluto
            %title('Dy fase Y absoluta'); colorbar;

        end

        function testDecodeGC_PSA_ParicularCase2(testCase)
            % testDecodeGC_PSA_ParicularCase2 repeats
            % testDecodeGC_PSA_ParicularCase1 using
            % DemodulatorLSEquispacedPSA instead of DemodulatorLSPSA
            %run(testFPA_UtilFunFPAClassVer, 'testDecodeGC_PSA_ParicularCase2')
            %genera un GC + PSA para un caso particular y verificar asi los tets de DemodulatorGCPSA
            %aqui se puede ver como los test (muy restrictivos con la
            %pendiente de la fase abosluta) pasan OK si NIgrams=T o 0.5*T y
            %"casi" pasan para 0.25*T
            %usamos como demodulador PSA el LSEquispacedPSA

            %image size
            NR=190; NC=190;

            %establecemos ancho de las las barras en px
            %el ancho de las barras sera el periodo del patron sinosoidal mas fino
            Tx=20;
            Ty=20;
            Txy=[Tx, Ty];
            TLabel=['X', 'Y'];

            D=cell(1,2);
            d=cell(1,2);
            %k=1 es X y k=2 es Y
            for k=1:2
                T=Txy(k);
                GCDir=k-1;
                %generamos la lista de GCs
                [PGC, LUT_GC2D, ~, nBits]=UtilFunFPA.generateGC(T, NR, NC, GCDir);

                %la decodificamos
                D{k}=UtilFunFPA.decodeGC(PGC, LUT_GC2D);
                %figure; imagesc(D{k});
            end

            %X Igrams
            PSDir=0;
            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            d.Set(char(DemodulatorProps.Tx), Tx);
            d.Set(char(DemodulatorProps.NIgrams), 0.5*Tx);
            d.Set(char(DemodulatorProps.PSDir), PSDir);
            gList=d.GenerateFPs([NR, NC]);

            %process X Igrams
            d.Process(gList);
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            za=mod(angle(z), 2*pi); %el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
            pa=za+2*pi*D{1}; %fase absoluta
            figure; imagesc(pa); title('fase X absoluta')
            [Dx, Dy]=gradient(pa);

            testCase.assertLessThan(std(Dx(:)), 1e-6);
            testCase.assertLessThan(abs(mean(Dy(:))), eps);
            %figure; imagesc(Dx); %Dx fase absoluto
            %title('Dx X fase  absoluta'); colorbar;
            %figure; imagesc(Dy); %Dy fase absoluto
            %title('Dy fase X absoluta'); colorbar;


            %Y Igrams
            PSDir=1;
            %no hace falta instanciar de nuevo el demodulador
            %d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
            d.Set(char(DemodulatorProps.Ty), Ty);
            d.Set(char(DemodulatorProps.NIgrams), 0.5*Ty);
            d.Set(char(DemodulatorProps.PSDir), PSDir);
            gList=d.GenerateFPs([NR, NC]);

            %process Y Igrams
            d.Process(gList);
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            za=mod(angle(z), 2*pi); %el orden absoluto espera una codificsacion [0, 2*pi] en vez de [-pi, pi]
            pa=za+2*pi*D{2}; %fase absoluta
            figure; imagesc(pa); title('fase Y absoluta')
            [Dx, Dy]=gradient(pa);
            testCase.assertLessThan(std(Dy(:)), 1e-6);
            testCase.assertLessThan(abs(mean(Dx(:))), eps);
            %figure; imagesc(Dx); %Dx fase absoluto
            %title('Dx Y fase  absoluta'); colorbar;
            %figure; imagesc(Dy); %Dy fase absoluto
            %title('Dy fase Y absoluta'); colorbar;

        end




        function testLinLUTGV(testCase)
            % testLinLUTGV visually checks UtilFunFPA.LinLUTGV's
            % linearization LUT (T(u), H(T(u))) on a real monitor-camera
            % radiometric response fixture (RadCal.mat), both on the
            % full sampled response and on it trimmed at both ends
            %run(testFPA_UtilFunFPAClassVer, 'testLinLUTGV')
            S=load('RadCal.mat');
            %sampled response
            us=S.BrilloMonitor;
            vs=S.BrilloCamara;

            uvs=[flipud(us'), flipud(vs')];

            S=UtilFunFPA.LinLUTGV(uvs);
            % OJO! Tu son GV [0,255] pero en double
            Tu=S.Tu;
            Hu=S.Hu;

            NGV=256;
            ONEOFFSET=1;
            u=0:NGV-1;
            figure; plot(us, vs,'+', u, Hu); legend({'Hs', 'H'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Tu); legend({'T(u)'}); xlabel('u'); ylabel('T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Hu(ONEOFFSET+Tu)); legend({'H(T(u))'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);

            %trim the response to check for boundary conditions
            us=us(3:end-4);
            vs=vs(3:end-4);

            uvs=[flipud(us'), flipud(vs')];

            S=UtilFunFPA.LinLUTGV(uvs);
            % OJO! Tu son GV [0,255] pero en double
            Tu=S.Tu;
            Hu=S.Hu;
            figure; plot(us, vs,'+', u, Hu); title('Trimmed') ;legend({'Hs', 'H'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Tu); legend({'T(u)'}); title('Trimmed'); xlabel('u'); ylabel('T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Hu(ONEOFFSET+Tu)); title('Trimmed'); legend({'H(T(u))'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);

        end


        function testLinLUTGVWithFringePattern(testCase)
            % testLinLUTGVWithFringePattern loads an experimental
            % radiometric response and linearizes it, generates a
            % synthetic fringe pattern spanning the linear response's
            % [u0,u1] GV range, passes it through the (nonlinear) system
            % response, transforms it back via T(u), and checks the
            % linearized round-trip recovers the same [v0,v1] output
            % range as the raw response would - for both single-channel
            % and RGB igrams. In this test "intensity" refers to
            % continuous values and "GV" to discrete values
            % run(testFPA_UtilFunFPAClassVer, 'testLinLUTGVWithFringePattern')
            %load smapled Radiometric response
            S=load('RadCal.mat');
            
            % sampled continuous intensity (double)
            us=S.BrilloMonitor;
            vs=S.BrilloCamara;

            uvs=[flipud(us'), flipud(vs')];

            %calculate transformation Tu that lienalized response
            %Hu(Tu)=Linear reponse
            S=UtilFunFPA.LinLUTGV(uvs);
            
            % OJO! Tu son GV [0,255] pero en double
            Tu=S.Tu; %linear transformation to linearize input GV into lineadized GV
            Hu=S.Hu; %sistem respose output intensity=H(input GV v)


            NGV=256;
            ONEOFFSET=1; %MATLAB index run 1... but GV run 0...
            u=0:NGV-1; %inpuit GV
            figure; plot(us, vs,'+', u, Hu); legend({'system response Hs', 'measured response H'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]); grid on;
            figure; plot(u, Tu); legend({'T(u)'}); xlabel('u'); ylabel('GV transformation T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);  grid on;
            figure; plot(u, Hu(ONEOFFSET+Tu)); legend({'linearized response H(T(u))'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);  grid on;

            % generate igram
            NR=500; % n Rows
            NC=501; %n Cols
            minGV=S.u0; 
            maxGV=S.u1;
            [x,~]=meshgrid(1:NC, 1:NR); 
            p=2*pi*x*3/NC;
            m=0.5*(maxGV-minGV); %igram modulation
            b=0.5*(maxGV+minGV); %igram bcgk
            
            %igram in GV [0, 255] single channel
            g=uint8(b+m*cos(p)); 
            %igram in GV [0, 255] RGB 
            f=cat(3, circshift(g, [0 5]), circshift(g, [0 10]), g);


            % assert max min
            testCase.verifyEqual(min(g(:)), uint8(S.u0), 'Abstol', 0);
            testCase.verifyEqual(max(g(:)), uint8(S.u1), 'Abstol', 0);


            testCase.verifyEqual(min(f(:)), uint8(S.u0), 'Abstol', 0);
            testCase.verifyEqual(max(f(:)), uint8(S.u1), 'Abstol', 0);



            % igram alfter passing though the system, 
            gH=Hu(g+ONEOFFSET); %single channel GV
            fH=Hu(f+ONEOFFSET); %RGB GV

            % assert max min
            testCase.verifyEqual(min(gH(:)), S.v0, 'Abstol', 0);
            testCase.verifyEqual(max(gH(:)), S.v1, 'Abstol', 0);
            
            testCase.verifyEqual(min(fH(:)), S.v0, 'Abstol', 0);
            testCase.verifyEqual(max(fH(:)), S.v1, 'Abstol', 0);


            % transformed igram, this is the image that must be sent to the
            % display
            % OJO! Tu son GV [0,255] pero en double
            gT=Tu(g+ONEOFFSET); %single channel GV
            fT=Tu(f+ONEOFFSET); %RGB GV            

            % assert max min
            testCase.verifyEqual(min(gT(:)), S.u0, 'Abstol', 0);
            testCase.verifyEqual(max(gT(:)), S.u1, 'Abstol', 0);

            testCase.verifyEqual(min(fT(:)), S.u0, 'Abstol', 0);
            testCase.verifyEqual(max(fT(:)), S.u1, 'Abstol', 0);


            % linearized igram, afther passing though the system the igram
            % should look OK
            gL=Hu(gT+ONEOFFSET); %single channel GV
            fL=Hu(fT+ONEOFFSET); %RGB GV

            % assert max min
            testCase.verifyEqual(min(gL(:)), S.v0, 'Abstol', 0);
            testCase.verifyEqual(max(gL(:)), S.v1, 'Abstol', 0);

            testCase.verifyEqual(min(fL(:)), S.v0, 'Abstol', 0);
            testCase.verifyEqual(max(fL(:)), S.v1, 'Abstol', 0);

            %plot results
            r0=round(0.5*NR);
            ch=2; %channel for RGB igram
            %note distortion in gH
            figure; plot(1:NC, g(r0, :), 1:NC, gH(r0, :));
            legend({'input igram g', 'igram after system gH'});
            grid on;

            figure; plot(1:NC, f(r0, :, ch), 1:NC, fH(r0, :, ch));
            legend({'R channel input igram f', 'igram after system fH'});
            grid on;

            %note distortion in gH
            figure; plot(1:NC, g(r0, :), 1:NC, gT(r0, :));
            legend({'input igram g', 'transformed igram gT'});
            grid on;

            figure; plot(1:NC, f(r0, :, ch), 1:NC, fT(r0, :, ch));
            legend({'R channel input igram f', 'transformed igram fT'});
            grid on;


            %note distortion corrected in gL
            figure; plot(1:NC, gH(r0, :), 1:NC, gL(r0, :));
            legend({'igram after system gH', 'linearized igram gL'});            
            grid on;

            figure; plot(1:NC, fH(r0, :, ch), 1:NC, fL(r0, :, ch));
            legend({'R channel igram after system fH', 'linearized igram fL'});
            grid on;


        end


        function testLinLUTGVWithDoubleResponse(testCase)
            % testLinLUTGVWithDoubleResponse repeats testLinLUTGV's
            % checks after affinely rescaling the sampled response
            % (double precision, non-[0,255] range) to check LinLUTGV
            % still handles it correctly
            %run(testFPA_UtilFunFPAClassVer, 'testLinLUTGVWithDoubleResponse')
            S=load('RadCal.mat');
            %sampled response
            us=0.5*S.BrilloMonitor+pi;
            vs=0.75*S.BrilloCamara+exp(1);

            uvs=[flipud(us'), flipud(vs')];

            S=UtilFunFPA.LinLUTGV(uvs);
            % OJO! Tu son GV [0,255] pero en double
            Tu=S.Tu;
            Hu=S.Hu;

            NGV=256;
            ONEOFFSET=1;
            u=0:NGV-1;
            figure; plot(us, vs,'+', u, Hu); legend({'Hs', 'H'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Tu); legend({'T(u)'}); xlabel('u'); ylabel('T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Hu(ONEOFFSET+Tu)); legend({'H(T(u))'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);

            %trim the response to check for boundary conditions
            us=us(3:end-4);
            vs=vs(3:end-4);

            uvs=[flipud(us'), flipud(vs')];

            S=UtilFunFPA.LinLUTGV(uvs);
            % OJO! Tu son GV [0,255] pero en double
            Tu=S.Tu;
            Hu=S.Hu;
            figure; plot(us, vs,'+', u, Hu); title('Trimmed') ;legend({'Hs', 'H'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Tu); legend({'T(u)'}); title('Trimmed'); xlabel('u'); ylabel('T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);
            figure; plot(u, Hu(ONEOFFSET+Tu)); title('Trimmed'); legend({'H(T(u))'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV]);

        end

        % ======================================================================
        %> @brief testGradientConsistency
        %> @details this function checks the gradient consistency funcion
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testGradientConsistency(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testGradientConsistency')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            % setup data
            NF=480;
            NC=640;

            p=80*peaks(NC);
            p=imresize(p, [NF, NC]);

            %contunous or unwrapped diferences
            %these are the forward differences GradientConsistency is expecting
            py=diff(p, 1, 1); py(NF, :)=py(NF-1, :);
            px=diff(p, 1, 2); px(:, NC)=px(:, NC-1);

            Q=UtilFunFPA.GradientConsistency(px,py);
            tol=1e-7;
            testCase.assertEqual(abs(mean(Q(:))), 0, 'AbsTol', tol);
            figure; imagesc(Q);title('continous differences'); colorbar; colormap flag

            %wrapped like the ones comming from deflectoemtry or shearing interferometry
            py=angle(exp(1i*py)); px=angle(exp(1i*px));
            Q=UtilFunFPA.GradientConsistency(px,py);
            testCase.assertEqual(abs(mean(Q(:))), 0, 'AbsTol', tol);
            figure; imagesc(Q); title('wrapped differences'); colorbar; colormap flag
        end

        % ======================================================================
        %> @brief test function phaseGradient
        %> @details this function checks the function phaseGradient
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testPhaseGradientDirect(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testPhaseGradientDirect');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=640;
            NC=480;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.3*NR;


            %ground truth, calculate the sigal and mask it
            p=4*peaks(NC);
            p=imresize(p, [NR, NC]);
            [px, py]=gradient(p);

            %add noise
            pn=p+0.5*randn(size(p));
            %1st dif of gradient
            [pnx, pny]=gradient(pn);

            %trim
            p=p.*M; px=px.*M; py=py.*M; pnx=pnx.*M; pny=pny.*M;

            %buid phasor
            b=mat2gray(10+pn);
            z=M.*b.*exp(1i*pn);

            Nmed=3; %1 px
            NS=7; %2*NS+1 px
            LPCycles=2; %number of LP cycles
            [phix, phiy, Mxy]=UtilFunFPA.phaseGradientDirect(z.*M, M, NS, Nmed, LPCycles);

            tol=1e-0;
            e=px-phix;
            figure; imagesc(e.*Mxy); colorbar; title('px absolute error');
            figure; imagesc(px.*Mxy); colorbar; title('px GT');
            figure; imagesc(phix.*Mxy); colorbar; title('phix from GradientDirect');
            figure; imagesc(pnx.*Mxy); colorbar; title('phix from 1st diff');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);

            e=py-phiy;
            figure; imagesc(e.*Mxy); colorbar; title('py absolute error');
            figure; imagesc(py.*Mxy); colorbar; title('py GT');
            figure; imagesc(phiy.*Mxy); colorbar; title('phiy from GradientDirect');
            figure; imagesc(pny.*Mxy); colorbar; title('phix from 1st diff');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);
        end


        % ======================================================================
        %> @brief test function gradientDirect
        %> @details this function checks the function gradientDirect
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testGradientDirect(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testGradientDirect');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=640;
            NC=480;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.3*NR;


            %ground truth, calculate the sigal and mask it
            p=4*peaks(NC);
            p=imresize(p, [NR, NC]);
            [px, py]=gradient(p);

            %add noise
            pn=p+0.5*randn(size(p));
            %1st dif of gradient
            [pnx, pny]=gradient(pn);

            %trim
            p=p.*M; px=px.*M; py=py.*M; pnx=pnx.*M; pny=pny.*M;


            Nmed=3; %1 px
            NS=7; %2*NS+1 px
            LPCycles=2; %number of LP cycles
            [phix, phiy, Mxy]=UtilFunFPA.gradientDirect(p.*M, M, NS, Nmed, LPCycles);

            tol=1e-0;
            e=px-phix;
            figure; imagesc(e.*Mxy); colorbar; title('px absolute error');
            figure; imagesc(px.*Mxy); colorbar; title('px GT');
            figure; imagesc(phix.*Mxy); colorbar; title('phix from GradientDirect');
            figure; imagesc(pnx.*Mxy); colorbar; title('phix from 1st diff');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);

            e=py-phiy;
            figure; imagesc(e.*Mxy); colorbar; title('py absolute error');
            figure; imagesc(py.*Mxy); colorbar; title('py GT');
            figure; imagesc(phiy.*Mxy); colorbar; title('phiy from GradientDirect');
            figure; imagesc(pny.*Mxy); colorbar; title('phix from 1st diff');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);
        end



        % ======================================================================
        %> @brief test function phaseGradientPlaneFit
        %> @details this function checks the function phaseGradientPlaneFit
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testPhaseGradientPlaneFit(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testPhaseGradientPlaneFit');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=640;
            NC=480;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.3*NR;


            %ground truth, calculate the sigal and mask it
            p=4*peaks(NC);
            p=imresize(p, [NR, NC]);
            [px, py]=gradient(p);

            %add noise
            pn=p+0.5*randn(size(p));
            %1st dif of gradient
            [pnx, pny]=gradient(pn);

            %trim
            p=p.*M; px=px.*M; py=py.*M; pnx=pnx.*M; pny=pny.*M;

            %buid phasor
            b=mat2gray(10+pn);
            z=M.*b.*exp(1i*pn);

            Nmed=3; %1 px
            NS=7; %2*NS+1 px
            [phix, phiy, Mxy]=UtilFunFPA.phaseGradientPlaneFit(z, M, NS, Nmed);

            tol=1e-0;
            e=px-phix;
            figure; imagesc(e.*Mxy); colorbar; title('px absolute error');
            figure; imagesc(px.*Mxy); colorbar; title('px GT');
            figure; imagesc(phix.*Mxy); colorbar; title('phix from GradientPlaneFit');
            figure; imagesc(pnx.*Mxy); colorbar; title('phix from 1st diff');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);

            e=py-phiy;
            figure; imagesc(e.*Mxy); colorbar; title('py absolute error');
            figure; imagesc(py.*Mxy); colorbar; title('py GT');
            figure; imagesc(phiy.*Mxy); colorbar; title('phiy from GradientPlaneFit');
            figure; imagesc(pny.*Mxy); colorbar; title('phix from 1st diff');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);
        end

        % ======================================================================
        %> @brief test function GradientPlaneFit
        %> @details this function checks the function GradientPlaneFit
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testGradientPlaneFit(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testGradientPlaneFit');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=640;
            NC=480;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<150;


            %ground truth, calculate the sigal and mask it
            p=peaks(NC);
            p=imresize(p, [NR, NC]);
            [px, py]=gradient(p);


            %noisy signal
            pn=p+0.1*randn(size(p));
            [pnx, pny]=gradient(pn);

            %apply the ROI
            p=p.*M; px=px.*M; py=py.*M;
            pn=pn.*M; pnx=pnx.*M; pny=pny.*M;

            Nmed=3; %px median filter size
            NS=1; %px plane fitting neighbouhood 2*NS+1
            %check for the clean signal
            [gx, gy, Mxy]=UtilFunFPA.GradientPlaneFit(p, M, NS, Nmed);

            tol=1e-3;
            e=px-gx;
            figure; imagesc(e.*Mxy); colorbar; title('px absolute error clean signal');
            figure; imagesc(gx.*Mxy); colorbar; title('px from clean signal');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);

            e=py-gy;
            figure; imagesc(e.*Mxy); colorbar; title('py absolute error clean signal');
            figure; imagesc(gy.*Mxy); colorbar; title('py from clean signal');
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
            testCase.assertEqual(0, std(e(Mxy)), 'AbsTol', tol);


            Nmed=10; %1 px
            NS=10; %px
            %check for the noisy signal
            [gx, gy, Mxy]=UtilFunFPA.GradientPlaneFit(pn, M, NS, Nmed);

            e=px-gx;
            figure; imagesc(e.*Mxy); colorbar; title('px absolute error noisy signal');
            figure; imagesc(gx.*Mxy); colorbar; title('px from noisy signal');
            figure; imagesc(pnx.*Mxy); colorbar; title('px from noisy signal using gradient');

            e=py-gy;
            figure; imagesc(e.*Mxy); colorbar; title('py absolute error noisy signal');
            figure; imagesc(gy.*Mxy); colorbar; title('py from noisy signal');
            figure; imagesc(pny.*Mxy); colorbar; title('py from noisy signal using gradient');
        end


        % ======================================================================
        %> @brief testHomographyCalcWithComputerVisionToolbox
        %> @details this function checks the calculation of the homography between a plane and the camera using
        %> the computer vision toolbox funcionality from MATLAB
        %> the example here is taken from the computer vision toolbox from MATLAB
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testHomographyCalcWithComputerVisionToolbox(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testHomographyCalcWithComputerVisionToolbox');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision Toolbox is NOT installed') ;
            end

            %get image
            files{1} = fullfile(matlabroot, 'toolbox', 'vision', 'visiondata', ...
                'calibration', 'slr', 'image3.jpg');

            % Display one of the calibration image, esta imagen tiene 10
            % cuadrados x 7 cuadrados, por lo tanto MATLAB va a seleccionar
            % el lado largo como X, el lado corto como Y , va a ordenar los
            % puntos por X constante partiendo de la esquina superior
            % derecha
            magnification = 25;
            I = imread(files{1});
            figure; imshow(I, 'InitialMagnification', magnification);
            title('Image with calibration pattern');


            % esta imagen tiene 10 cuadrados x 7 cuadrados, por lo tanto MATLAB va a seleccionar
            % el lado largo como X, el lado corto como Y , va a ordenar los
            % puntos por X constante X=1, Y=1,2,3,..X=2, Y=1,2,3.. etc primero partiendo de la esquina superior
            % derecha donde luego la funcion generateCheckerboardPoints()
            % va a colorcar el (0,0)
            % Detect the checkerboard corners in the images.

            %imagePoints es Detects "internal" checkerboard corner coordinates, returned as an M-by-2 matrix for one image
            %la primera columna es la x (col) la segunda es la y (row) un
            %plot(imagePoints(:, 1), imagePoints(:, 2)) coloca los puntos
            %detectados en el sistema de referencia de la imagen

            [imagePoints, boardSize] = detectCheckerboardPoints(files);

            %check boardSize
            testCase.assertEqual([7,10], boardSize);
            testCase.assertEqual([54,2], size(imagePoints));

            figure; imshow(I, 'InitialMagnification', magnification);
            title('Image with calibration pattern + detected corners');
            hold on; plot(imagePoints(:, 1), imagePoints(:, 2), 'r+-'); hold off

            % Generate the world coordinates of the checkerboard corners in the
            % pattern-centric coordinate system, with the upper-left corner at (0,0).
            squareSize = 30; % in millimeters
            worldPoints = generateCheckerboardPoints(boardSize, squareSize);

            %para la funcion de calculo de la homografia necesitamos 2
            %filas por M columnas, la primea fila es la X y la segunda fila
            %es la Y
            xyCP=worldPoints'; %xy control points en mm
            uvCP=imagePoints'; %uv control points en px

            Hpx2mm = UtilFunFPA.homography_solve(uvCP, xyCP); %px2mm
            Hpx2mm=Hpx2mm/Hpx2mm(3,3);

            [NR, NC, ~]=size(I);
            [u, v]=meshgrid(1:NC, 1:NR);

            uv=[u(:)'; v(:)']; %in px
            %transmform px to mm
            xy=UtilFunFPA.homography_transform(uv, Hpx2mm); %mm
            x=reshape(xy(1, :), NR, NC); %mm
            y=reshape(xy(2, :), NR, NC); %mm

            figure; h=pcolor(x, y, double(rgb2gray(I)));
            set(h, 'EdgeColor', 'none');
            hold on; plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-'); hold off
            title('axis in mm');

        end

        % ======================================================================
        %> @brief testCameraCalibrationCVTbx_5MAY20
        %> @details this function makes a geometrical calibration of the
        %> camera of the delfectometer and estimates ditances to the screen with and without suporting glass plate
        %> with the MATLAB Computer Vision Toolbox
        %> @see oneNote-> Mejoras calculo DPM APR20 for details
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testCameraCalibrationCVTbx_5MAY20(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_5MAY20');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.
            dbDir=fixturesRoot();
            %for comparison purpouses I have callibrated with and without
            %glass window, the screen plane appears 1 mm closer with the
            %glass window see oneNote->"Calibraci�n Geom�trica del Mapper 20 MAYO 2020"
            %(SinVidrio variant not available as a fixture - only ConVidrio was copied)
            calibFilesDir='Calibracion_5MAY20\CalibracionGemetricaCam\CalibracionGeometricaConVidrio';
            ExcludeImages=[]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            % Detect calibration pattern.
            [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);

            % Generate world coordinates of the corners of the squares.
            squareSize = 8; %verificado con la lupa
            worldPoints = generateCheckerboardPoints(boardSize, squareSize);

            % Calibrate the camera.
            I = readimage(images, 1);
            imageSize = [size(I, 1), size(I, 2)];
            [params, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
                'ImageSize', imageSize, 'EstimateTangentialDistortion', true);


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            h1=figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);



            figure; showExtrinsics(params, 'CameraCentric');

            figure; showReprojectionErrors(params);

            displayErrors(estimationErrors, params);


            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %intrinnsic params
            K=params.IntrinsicMatrix;
            %Principal point
            p0=params.PrincipalPoint;


            %get index for the test images @ lens plane
            nZc=find(contains(imageFileNames, 'lensPlane'));
            Zc=zeros(1,length(nZc));
            for k=1:length(nZc)

                tc=params.TranslationVectors(nZc(k),:);
                Rc=params.RotationMatrices(:, :, nZc(k));

                %distance to image_Zc.bmp
                Zc(k)=UtilFunFPA.DistancePlaneCam(K', Rc', tc, p0);
            end

            %distance to image_Z+Zc.bmp
            %get index for the test images @ screen plane
            nZt=find(contains(imageFileNames, 'screenPlane'));
            Zt=zeros(1,length(nZt));
            for k=1:length(nZt)
                t=params.TranslationVectors(nZt(k),:);
                R=params.RotationMatrices(:, :, nZt(k));
                Zt(k)=UtilFunFPA.DistancePlaneCam(K', R', t, p0);
            end

            %distance between lens and screen
            Z=mean(Zt)-mean(Zc);

            fprintf('Camera-Lens plane Zc:%d +/-%d, values:%d', mean(Zc), std(Zc)); disp(Zc);disp('\n');
            fprintf('Camera-Screen plane Zc+Z:%d +/-%d, values:%d', mean(Zt), std(Zt)); disp(Zt);disp('\n');
            fprintf('Screen-Lens plane Z:%d +/-%d', Z, sqrt(std(Zt)^2 + std(Zc)^2)); disp('\n');


            %show distortion map
            NR=imageSize(1); NC=imageSize(2);
            [u,v]=meshgrid(1:50:NC, 1:50:NR);
            uv=[u(:), v(:)];
            %uvc=corrected, undistorted
            uvc = undistortPoints(uv,params);
            du=uvc(:, 1)-uv(:, 1); dv=uvc(:, 2)-uv(:, 2);
            fh=figure; quiver(uv(:, 1), uv(:, 2), du, dv);

            uvDistortion=abs(du+1i*dv);
            [NR, NC]=size(u);
            uvDistortion=reshape(uvDistortion, NR, NC);
            figure(fh); hold on;
            contour(u,v,uvDistortion, 'ShowText','on');
            hold off;






            %AQTODO
            %Ahora faltaria calcular dx y dy en el plano de la lente, en el
            %plano de la pantalla verificar relacion proyectiva y pasar
            %esos datos a
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testMejoraCaluloDPM_APR20')
            %mediante las imagenes corregidas de distorsi�n y sin corregir


        end


        % ======================================================================
        %> @brief testUndistortImagesCVTbx_5MAY20
        %> @details this function is an example of undistort images using MATLAB Computer Vision
        %> Toolbox. Here we calculate the homography from the worldpoints
        %> and also using the extrinsics for comparison. Also we calculate
        %> resolution in mm/px at the selected plane image, Zc or Z+Z_c
        %> @see oneNote-> Mejoras calculo DPM APR20 for details
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testUndistortImagesCVTbx_5MAY20(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.

            dbDir=fixturesRoot();
            calibFilesDir='Calibracion_5MAY20\CalibracionGemetricaCam\CalibracionGeometricaConVidrio';
            ExcludeImages=[3]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            [imagePoints,boardSize] = detectCheckerboardPoints(imageFileNames);

            %Generate world coordinates of the corners of the squares. The square size is in millimeters.
            squareSize = 8; %verificaod con la lupa
            worldPoints = generateCheckerboardPoints(boardSize,squareSize);

            %Calibrate the camera.
            %nImage=10; %this is a image at the screen plane Zc+Z
            nImage=15;  %this is a image at the lens plane Zc
            %I = readimage(images,nImage);
            I = imread(imageFileNames{nImage});

            imageSize = [size(I, 1), size(I, 2)];
            params = estimateCameraParameters(imagePoints,worldPoints, ...
                'ImageSize',imageSize);


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            h1=figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);


            %save params to json
            fname='params_Calibracion_5MAY20.json';
            savejson('', params.toStruct,fname);
            %for loading we need to cast two values to logical
            % params_struct=loadjson(fname)
            % params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            % params_struct.EstimateSkew=logical(params_struct.EstimateSkew)


            %get intrincic and extrinsic
            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            K=params.IntrinsicMatrix;
            p0=params.PrincipalPoint;
            t=params.TranslationVectors(nImage,:);
            R=params.RotationMatrices(:, :, nImage);

            %Load an image and detect the checkerboard points. in px
            points = detectCheckerboardPoints(I);

            %Undistort the points in px
            undistortedPoints = undistortPoints(points,params);

            %Undistort the image and get newOrigin in px
            %cdo 'OutputView'=='same' el tama�o de la imagen undistorted es
            %el mismo que I y newOrigin=[0,0] no hay cambio de origen
            %alternatively if we load a params struct we can create a
            %cameraParameters object with the constructor cameraParameters(paramsStruct)
            [J, camIntrinsicsOut] = undistortImage(I,params,'OutputView','same');

            %check for newOrigin: undistortImage's 2nd output changed from a
            %numeric [x,y] origin offset to a returned cameraIntrinsics
            %object (MATLAB API change, still true in R2024b). With
            %OutputView='same' there is no crop/origin shift, verified here
            %by the returned intrinsics' PrincipalPoint staying unchanged.
            testCase.assertEqual(camIntrinsicsOut.PrincipalPoint, params.PrincipalPoint, 'AbsTol', 1e-6);
            newOrigin = [0, 0];

            %Translate undistorted points in px
            undistortedPoints = [undistortedPoints(:,1) - newOrigin(1), ...
                undistortedPoints(:,2) - newOrigin(2)];

            %Display the results
            figure;
            imshow(I);
            hold on;
            plot(points(:,1),points(:,2),'r*-');
            title('Detected Points');
            hold off;

            figure;
            imshow(J);
            hold on;
            plot(undistortedPoints(:,1),undistortedPoints(:,2),'g*-');

            %plot principal point in mm p0 is already "undistorted" like
            %the roto translations
            plot(p0(1),p0(2),'ro');

            title('Undistorted Points');
            hold off;

            %represent undistorted image in metric coordinates
            %a) using toolbox
            %check for metric coordinates of p0 in mm
            P0tbx = pointsToWorld(params,R,t,p0);
            [NR, NC]=size(J);
            [u,v]=meshgrid(1:NC, 1:NR);
            uv=[u(:), v(:)];
            xy = pointsToWorld(params,R,t,uv);
            x=reshape(xy(:, 1), NR, NC); %mm
            y=reshape(xy(:, 2), NR, NC); %mm
            worldPoints=pointsToWorld(params,R,t,undistortedPoints);

            figure; h=pcolor(x, y, double(J)); colormap gray;
            set(h, 'EdgeColor', 'none');
            hold on;
            %plot undistorted corner points
            plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-');
            %plot ppal point
            plot(P0tbx(1),P0tbx(2),'go');
            hold off
            title('axis in mm (toolbox)');


            %b) using homography H=K[r1 r2 t]

            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %check for metric coordinates of p0 in mm
            [d, Hmm2px, P0h]=UtilFunFPA.DistancePlaneCam(K', R', t, p0);

            %check that results from matlab tbx and homography are the same
            tol=1e-10;
            testCase.assertEqual(P0tbx, P0h', 'abstol', tol);

            uv=[u(:)'; v(:)']; %in px
            %transmform px to mm
            xy=UtilFunFPA.homography_transform(uv, inv(Hmm2px)); %mm
            x=reshape(xy(1, :), NR, NC); %mm
            y=reshape(xy(2, :), NR, NC); %mm

            figure; h=pcolor(x, y, double(J));  colormap gray;
            set(h, 'EdgeColor', 'none');
            hold on;
            plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-');
            %plot ppal point
            plot(P0h(1),P0h(2),'go');
            hold off
            title('axis in mm (homography)');

            %calculation of dx and dy at the plane
            %distance from ppal point
            [dxdu, dxdv]=gradient(x); %mm/px in x directtion (the system can be rotated)
            [dydu, dydv]=gradient(y); %mm/px in y directtion (the system can be rotated)
            du=abs(dxdu+1i*dydu);  %mm/px in the u pixel direction
            dv=abs(dxdv+1i*dydv);  %mm/px in the v pixel direction
            figure; imagesc(du);
            figure; imagesc(dv);

            %estimation of the spatual resolution arround p0
            N=20; %we caculate over a NxN window
            [Nbx, Nby]=meshgrid([-N:N]+round(p0(1)), [-N:N]++round(p0(2)));
            dummy=du(Nbx, Nby); dup0=mean(dummy(:)); dup0_std=std(dummy(:));
            dummy=dv(Nbx, Nby); dvp0=mean(dummy(:)); dvp0_std=std(dummy(:));

            fprintf('\n spatial resoluction u du:%d +/-%d \n', dup0, dup0_std);
            fprintf('\n spatial resoluction v dv:%d +/-%d \n', dvp0, dvp0_std);

        end




        % ======================================================================
        %> @brief testCameraCalibrationCVTbx_29JUN20
        %> @details this function makes a geometrical calibration of the
        %> camera of the delfectometer and estimates ditances to the screen with and without suporting glass plate
        %> with the MATLAB Computer Vision Toolbox. This test is the same
        %> than testCameraCalibrationCVTbx_5MAY20 but in this case the test
        %> images where captured using the IOTMGeomCalibGUI.mlapp GUI of
        %> the Preseus Repo (..\src\Deflectometer\FFVAppInt\)
        %> @see oneNote-> Calibraci�n Geom�trica del Mapper 29 JUNIO 2020 for details
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testCameraCalibrationCVTbx_29JUN20(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_29JUN20');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.
            dbDir=fixturesRoot();
            %The calibration has benn done with the 1 mm glass window see oneNote->"Calibraci�n Geom�trica del Mapper 20 MAYO 2020"
            %(Calibracion_29JUN20 variant not available as a fixture - only _2 was copied)
            calibFilesDir='Calibracion_29JUN20_2';
            ExcludeImages=[]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            % Detect calibration pattern.
            [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);

            % Generate world coordinates of the corners of the squares.
            squareSize = 8; %verificado con la lupa
            worldPoints = generateCheckerboardPoints(boardSize, squareSize);

            % Calibrate the camera.
            I = readimage(images, 1);
            imageSize = [size(I, 1), size(I, 2)];
            [params, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
                'ImageSize', imageSize, 'EstimateTangentialDistortion', true);


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            h1=figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);



            figure; showExtrinsics(params, 'CameraCentric');

            figure; showReprojectionErrors(params);

            displayErrors(estimationErrors, params);


            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %intrinnsic params
            K=params.IntrinsicMatrix;
            %Principal point
            p0=params.PrincipalPoint;


            %get index for the test images @ lens plane
            nZc=find(contains(imageFileNames, 'lensPlane'));
            Zc=zeros(1,length(nZc));
            for k=1:length(nZc)

                tc=params.TranslationVectors(nZc(k),:);
                Rc=params.RotationMatrices(:, :, nZc(k));

                %distance to image_Zc.bmp
                Zc(k)=UtilFunFPA.DistancePlaneCam(K', Rc', tc, p0);
            end

            %distance to image_Z+Zc.bmp
            %get index for the test images @ screen plane
            nZt=find(contains(imageFileNames, 'screenPlane'));
            Zt=zeros(1,length(nZt));
            for k=1:length(nZt)
                t=params.TranslationVectors(nZt(k),:);
                R=params.RotationMatrices(:, :, nZt(k));
                Zt(k)=UtilFunFPA.DistancePlaneCam(K', R', t, p0);
            end

            %distance between lens and screen
            Z=mean(Zt)-mean(Zc);

            fprintf('Camera-Lens plane Zc:%d +/-%d, values:%d', mean(Zc), std(Zc)); disp(Zc);disp('\n');
            fprintf('Camera-Screen plane Zc+Z:%d +/-%d, values:%d', mean(Zt), std(Zt)); disp(Zt);disp('\n');
            fprintf('Screen-Lens plane Z:%d +/-%d', Z, sqrt(std(Zt)^2 + std(Zc)^2)); disp('\n');


            %show distortion map
            NR=imageSize(1); NC=imageSize(2);
            [u,v]=meshgrid(1:50:NC, 1:50:NR);
            uv=[u(:), v(:)];
            %uvc=corrected, undistorted
            uvc = undistortPoints(uv,params);
            du=uvc(:, 1)-uv(:, 1); dv=uvc(:, 2)-uv(:, 2);
            fh=figure; quiver(uv(:, 1), uv(:, 2), du, dv);

            uvDistortion=abs(du+1i*dv);
            [NR, NC]=size(u);
            uvDistortion=reshape(uvDistortion, NR, NC);
            figure(fh); hold on;
            contour(u,v,uvDistortion, 'ShowText','on');
            hold off;






            %AQTODO
            %Ahora faltaria calcular dx y dy en el plano de la lente, en el
            %plano de la pantalla verificar relacion proyectiva y pasar
            %esos datos a
            %run(testFPA_UtilFunMapperMeasureClassVer, 'testMejoraCaluloDPM_APR20')
            %mediante las imagenes corregidas de distorsi�n y sin corregir


        end


        % ======================================================================
        %> @brief testUndistortImagesCVTbx_29JUN20
        %> @details this function is an example of undistort images using MATLAB Computer Vision
        %> Toolbox. Here we calculate the homography from the worldpoints
        %> and also using the extrinsics for comparison. Also we calculate
        %> resolution in mm/px at the selected plane image, Zc or Z+Z_c
        %> @see oneNote-> Calibraci�n Geom�trica del Mapper 29 JUNIO 2020 for details
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testUndistortImagesCVTbx_29JUN20(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_29JUN20');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.

            dbDir=fixturesRoot();
            %(Calibracion_29JUN20 variant not available as a fixture - only _2 was copied)
            JSONSufix='_29JUN20_2.json'; calibFilesDir='Calibracion_29JUN20_2';
            ExcludeImages=[]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            [imagePoints,boardSize] = detectCheckerboardPoints(imageFileNames);

            %Generate world coordinates of the corners of the squares. The square size is in millimeters.
            squareSize = 8; %verificaod con la lupa
            worldPoints = generateCheckerboardPoints(boardSize,squareSize);

            %Calibrate the camera.
            %nImage=15; PLANE_STR='SCREEN PLANE Zc+Z'; %this is a image at the screen plane Zc+Z
            nImage=10; PLANE_STR=['LENS PLANE Zc']; %this is a image at the lens plane Zc
            %I = readimage(images,nImage);
            I = imread(imageFileNames{nImage});

            imageSize = [size(I, 1), size(I, 2)];
            params = estimateCameraParameters(imagePoints,worldPoints, ...
                'ImageSize',imageSize);


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            h1=figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);


            %save params to json
            fname=['params_Calibracion' JSONSufix];
            savejson('', params.toStruct,fname);
            %for loading we need to cast two values to logical
            % params_struct=loadjson(fname)
            % params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            % params_struct.EstimateSkew=logical(params_struct.EstimateSkew)


            %get intrincic and extrinsic
            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            K=params.IntrinsicMatrix;
            p0=params.PrincipalPoint;
            t=params.TranslationVectors(nImage,:);
            R=params.RotationMatrices(:, :, nImage);

            %Load an image and detect the checkerboard points. in px
            points = detectCheckerboardPoints(I);

            %Undistort the points in px
            undistortedPoints = undistortPoints(points,params);

            %Undistort the image and get newOrigin in px
            %cdo 'OutputView'=='same' el tama�o de la imagen undistorted es
            %el mismo que I y newOrigin=[0,0] no hay cambio de origen
            %alternatively if we load a params struct we can create a
            %cameraParameters object with the constructor cameraParameters(paramsStruct)
            [J, camIntrinsicsOut] = undistortImage(I,params,'OutputView','same');

            %check for newOrigin: undistortImage's 2nd output changed from a
            %numeric [x,y] origin offset to a returned cameraIntrinsics
            %object (MATLAB API change, still true in R2024b). With
            %OutputView='same' there is no crop/origin shift, verified here
            %by the returned intrinsics' PrincipalPoint staying unchanged.
            testCase.assertEqual(camIntrinsicsOut.PrincipalPoint, params.PrincipalPoint, 'AbsTol', 1e-6);
            newOrigin = [0, 0];

            %Translate undistorted points in px
            undistortedPoints = [undistortedPoints(:,1) - newOrigin(1), ...
                undistortedPoints(:,2) - newOrigin(2)];

            %Display the results
            figure;
            imshow(I);
            hold on;
            plot(points(:,1),points(:,2),'r*-');
            title('Detected Points');
            hold off;

            figure;
            imshow(J);
            hold on;
            plot(undistortedPoints(:,1),undistortedPoints(:,2),'g*-');

            %plot principal point in mm p0 is already "undistorted" like
            %the roto translations
            plot(p0(1),p0(2),'ro');

            title('Undistorted Points');
            hold off;

            %represent undistorted image in metric coordinates
            %a) using toolbox
            %check for metric coordinates of p0 in mm
            P0tbx = pointsToWorld(params,R,t,p0);
            [NR, NC]=size(J);
            [u,v]=meshgrid(1:NC, 1:NR);
            uv=[u(:), v(:)];
            xy = pointsToWorld(params,R,t,uv);
            x=reshape(xy(:, 1), NR, NC); %mm
            y=reshape(xy(:, 2), NR, NC); %mm
            worldPoints=pointsToWorld(params,R,t,undistortedPoints);

            figure; h=pcolor(x, y, double(J)); colormap gray;
            set(h, 'EdgeColor', 'none');
            hold on;
            %plot undistorted corner points
            plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-');
            %plot ppal point
            plot(P0tbx(1),P0tbx(2),'go');
            hold off
            title('axis in mm (toolbox)');


            %b) using homography H=K[r1 r2 t]

            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %check for metric coordinates of p0 in mm
            [d, Hmm2px, P0h]=UtilFunFPA.DistancePlaneCam(K', R', t, p0);

            %check that results from matlab tbx and homography are the same
            tol=1e-10;
            testCase.assertEqual(P0tbx, P0h', 'abstol', tol);

            uv=[u(:)'; v(:)']; %in px
            %transmform px to mm
            xy=UtilFunFPA.homography_transform(uv, inv(Hmm2px)); %mm
            x=reshape(xy(1, :), NR, NC); %mm
            y=reshape(xy(2, :), NR, NC); %mm

            figure; h=pcolor(x, y, double(J));  colormap gray;
            set(h, 'EdgeColor', 'none');
            hold on;
            plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-');
            %plot ppal point
            plot(P0h(1),P0h(2),'go');
            hold off
            title('axis in mm (homography)');

            %calculation of dx and dy at the plane
            %distance from ppal point
            [dxdu, dxdv]=gradient(x); %mm/px in x directtion (the system can be rotated)
            [dydu, dydv]=gradient(y); %mm/px in y directtion (the system can be rotated)
            du=abs(dxdu+1i*dydu);  %mm/px in the u pixel direction
            dv=abs(dxdv+1i*dydv);  %mm/px in the v pixel direction
            figure; imagesc(du);
            figure; imagesc(dv);

            %estimation of the spatual resolution arround p0
            N=20; %we caculate over a NxN window
            [Nbx, Nby]=meshgrid([-N:N]+round(p0(1)), [-N:N]++round(p0(2)));
            dummy=du(Nbx, Nby); dup0=mean(dummy(:)); dup0_std=std(dummy(:));
            dummy=dv(Nbx, Nby); dvp0=mean(dummy(:)); dvp0_std=std(dummy(:));

            [~, str_imageName, ~]=fileparts(imageFileNames{nImage});
            fprintf(['\n' str_imageName ' ' PLANE_STR '\n']);
            fprintf('\n spatial resoluction u du:%d +/-%d \n', dup0, dup0_std);
            fprintf('\n spatial resoluction v dv:%d +/-%d \n', dvp0, dvp0_std);

        end

        % ======================================================================
        %> @brief testUndistortImagesCVTbx_15DIC20
        %> @details this function is an example of undistort images using MATLAB Computer Vision
        %> Toolbox. Here we calculate the homography from the worldpoints
        %> and also using the extrinsics for comparison. Also we calculate
        %> resolution in mm/px at the lens plane, Zc or screen plane Z+Z_c
        %> @see oneNote-> calibracion 15DIC20 for details
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testUndistortImagesCVTbx_15DIC20(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_15DIC20');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.

            dbDir=fixturesRoot();
            calibFilesDir='Calibracion_15DIC20';
            ExcludeImages=[]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            [imagePoints,boardSize] = detectCheckerboardPoints(imageFileNames);

            %Generate world coordinates of the corners of the squares. The square size is in millimeters.
            squareSize = 8; %mm verificado con la lupa
            worldPoints = generateCheckerboardPoints(boardSize,squareSize);

            %Calibrate the camera.
            %nImage=22; %this is a image at the screen plane Zc+Z
            nImage=17;  %this is a image at the lens plane Zc
            %I = readimage(images,nImage);
            I = imread(imageFileNames{nImage});

            imageSize = [size(I, 1), size(I, 2)];
            params = estimateCameraParameters(imagePoints,worldPoints, ...
                'ImageSize',imageSize);


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            h1=figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);


            % save params to json
            % AQDEBUG NO SALVAMOS use run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_5MAY20');
            % fname='params_Calibracion_15DIC20.json';
            % savejson('', params.toStruct,fname);
            % for loading we need to cast two values to logical
            % params_struct=loadjson(fname)
            % params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            % params_struct.EstimateSkew=logical(params_struct.EstimateSkew)


            %get intrincic and extrinsic
            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            K=params.IntrinsicMatrix;
            p0=params.PrincipalPoint;
            t=params.TranslationVectors(nImage,:);
            R=params.RotationMatrices(:, :, nImage);

            %Load an image and detect the checkerboard points. in px
            points = detectCheckerboardPoints(I);

            %Undistort the points in px
            undistortedPoints = undistortPoints(points,params);

            %Undistort the image and get newOrigin in px
            %cdo 'OutputView'=='same' el tama�o de la imagen undistorted es
            %el mismo que I y newOrigin=[0,0] no hay cambio de origen
            %alternatively if we load a params struct we can create a
            %cameraParameters object with the constructor cameraParameters(paramsStruct)
            [J, camIntrinsicsOut] = undistortImage(I,params,'OutputView','same');

            %check for newOrigin: undistortImage's 2nd output changed from a
            %numeric [x,y] origin offset to a returned cameraIntrinsics
            %object (MATLAB API change, still true in R2024b). With
            %OutputView='same' there is no crop/origin shift, verified here
            %by the returned intrinsics' PrincipalPoint staying unchanged.
            testCase.assertEqual(camIntrinsicsOut.PrincipalPoint, params.PrincipalPoint, 'AbsTol', 1e-6);
            newOrigin = [0, 0];

            %Translate undistorted points in px
            undistortedPoints = [undistortedPoints(:,1) - newOrigin(1), ...
                undistortedPoints(:,2) - newOrigin(2)];

            %Display the results
            figure;
            imshow(I);
            hold on;
            plot(points(:,1),points(:,2),'r*-');
            title('Detected Points');
            hold off;

            figure;
            imshow(J);
            hold on;
            plot(undistortedPoints(:,1),undistortedPoints(:,2),'g*-');

            %plot principal point in mm p0 is already "undistorted" like
            %the roto translations
            plot(p0(1),p0(2),'ro');

            title('Undistorted Points');
            hold off;

            %represent undistorted image in metric coordinates
            %a) using toolbox
            %check for metric coordinates of p0 in mm
            P0tbx = pointsToWorld(params,R,t,p0);
            [NR, NC]=size(J);
            [u,v]=meshgrid(1:NC, 1:NR);
            uv=[u(:), v(:)];
            xy = pointsToWorld(params,R,t,uv);
            x=reshape(xy(:, 1), NR, NC); %mm
            y=reshape(xy(:, 2), NR, NC); %mm
            worldPoints=pointsToWorld(params,R,t,undistortedPoints);

            figure; h=pcolor(x, y, double(J)); colormap gray;
            set(h, 'EdgeColor', 'none');
            hold on;
            %plot undistorted corner points
            plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-');
            %plot ppal point
            plot(P0tbx(1),P0tbx(2),'go');
            hold off
            title('axis in mm (toolbox)');


            %b) using homography H=K[r1 r2 t]

            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %check for metric coordinates of p0 in mm
            [d, Hmm2px, P0h]=UtilFunFPA.DistancePlaneCam(K', R', t, p0);

            %check that results from matlab tbx and homography are the same
            tol=1e-10;
            testCase.assertEqual(P0tbx, P0h', 'abstol', tol);

            uv=[u(:)'; v(:)']; %in px
            %transmform px to mm
            xy=UtilFunFPA.homography_transform(uv, inv(Hmm2px)); %mm
            x=reshape(xy(1, :), NR, NC); %mm
            y=reshape(xy(2, :), NR, NC); %mm

            figure; h=pcolor(x, y, double(J));  colormap gray;
            set(h, 'EdgeColor', 'none');
            hold on;
            plot(worldPoints(:, 1), worldPoints(:, 2), 'r+-');
            %plot ppal point
            plot(P0h(1),P0h(2),'go');
            hold off
            title('axis in mm (homography)');

            %calculation of dx and dy at the plane
            %distance from ppal point
            [dxdu, dxdv]=gradient(x); %mm/px in x directtion (the system can be rotated)
            [dydu, dydv]=gradient(y); %mm/px in y directtion (the system can be rotated)
            du=abs(dxdu+1i*dydu);  %mm/px in the u pixel direction
            dv=abs(dxdv+1i*dydv);  %mm/px in the v pixel direction
            figure; imagesc(du);
            figure; imagesc(dv);

            %estimation of the spatual resolution arround p0
            N=20; %we caculate over a NxN window
            [Nbx, Nby]=meshgrid([-N:N]+round(p0(1)), [-N:N]++round(p0(2)));
            dummy=du(Nbx, Nby); dup0=mean(dummy(:)); dup0_std=std(dummy(:));
            dummy=dv(Nbx, Nby); dvp0=mean(dummy(:)); dvp0_std=std(dummy(:));

            fprintf('\n spatial resoluction u du:%d +/-%d \n', dup0, dup0_std);
            fprintf('\n spatial resoluction v dv:%d +/-%d \n', dvp0, dvp0_std);

        end


        % ======================================================================
        %> @brief testCameraCalibrationCVTbx_15DIC20
        %> @details this function makes a geometrical calibration of the
        %> camera of the deflectometer and estimates ditances to the screen with the suporting glass plate
        %> with the MATLAB Computer Vision Toolbox. This test is the same
        %> the test images where captured using the IOTMGeomCalibGUI.mlapp GUI of
        %> the Perseus Repo (..\src\Deflectometer\FFVAppInt\)
        %> @see oneNote->Calibraci�n 15 DIC 20 for details
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testCameraCalibrationCVTbx_15DIC20(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testCameraCalibrationCVTbx_15DIC20');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.
            dbDir=fixturesRoot();
            %The calibration has been done with the 1 mm glass window see oneNote->"Calibraci�n 15 DIC 20"
            calibFilesDir='Calibracion_15DIC20';
            ExcludeImages=[]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            % Detect calibration pattern.
            [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);

            % Generate world coordinates of the corners of the squares.
            squareSize = 8; %mm verificado con la lupa
            worldPoints = generateCheckerboardPoints(boardSize, squareSize);

            % Calibrate the camera.
            I = readimage(images, 1);
            imageSize = [size(I, 1), size(I, 2)];
            [params, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
                'ImageSize', imageSize, 'EstimateTangentialDistortion', true);


            %save params to json
            fname='params_Calibracion_15DIC20.json';
            savejson('', params.toStruct,fname);
            %for loading we need to cast two values to logical
            % params_struct=loadjson(fname)
            % params_struct.EstimateTangentialDistortion=logical(params_struct.EstimateTangentialDistortion)
            % params_struct.EstimateSkew=logical(params_struct.EstimateSkew)


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            h1=figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);



            figure; showExtrinsics(params, 'CameraCentric');

            figure; showReprojectionErrors(params);

            displayErrors(estimationErrors, params);


            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %intrinnsic params
            K=params.IntrinsicMatrix;
            %Principal point
            p0=params.PrincipalPoint;


            %get index for the test images @ lens plane
            nZc=find(contains(imageFileNames, 'lensPlane'));
            Zc=zeros(1,length(nZc));
            for k=1:length(nZc)

                tc=params.TranslationVectors(nZc(k),:);
                Rc=params.RotationMatrices(:, :, nZc(k));

                %distance to image_Zc.bmp
                Zc(k)=UtilFunFPA.DistancePlaneCam(K', Rc', tc, p0);
            end

            %distance to image_Z+Zc.bmp
            %get index for the test images @ screen plane
            nZt=find(contains(imageFileNames, 'screenPlane'));
            Zt=zeros(1,length(nZt));
            for k=1:length(nZt)
                t=params.TranslationVectors(nZt(k),:);
                R=params.RotationMatrices(:, :, nZt(k));
                Zt(k)=UtilFunFPA.DistancePlaneCam(K', R', t, p0);
            end

            %distance between lens and screen
            Z=mean(Zt)-mean(Zc);

            fprintf('Camera-Lens plane Zc:%d +/-%d, values:%d', mean(Zc), std(Zc)); disp(Zc);disp('\n');
            fprintf('Camera-Screen plane Zc+Z:%d +/-%d, values:%d', mean(Zt), std(Zt)); disp(Zt);disp('\n');
            fprintf('Screen-Lens plane Z:%d +/-%d', Z, sqrt(std(Zt)^2 + std(Zc)^2)); disp('\n');


            %show distortion map
            NR=imageSize(1); NC=imageSize(2);
            [u,v]=meshgrid(1:50:NC, 1:50:NR);
            uv=[u(:), v(:)];
            %uvc=corrected, undistorted
            uvc = undistortPoints(uv,params);
            du=uvc(:, 1)-uv(:, 1); dv=uvc(:, 2)-uv(:, 2);
            fh=figure; quiver(uv(:, 1), uv(:, 2), du, dv);

            uvDistortion=abs(du+1i*dv);
            [NR, NC]=size(u);
            uvDistortion=reshape(uvDistortion, NR, NC);
            figure(fh); hold on;
            contour(u,v,uvDistortion, 'ShowText','on');
            hold off;


            %para la camara DMK 33UX183 binning 3x3 el tama�o del pixel es
            Du=3*2.4e-3; %mm/px
            Dv=3*2.4e-3; %mm/px

            %la focal de la lente es
            fu=K(1,1); %en px
            fv=K(2,2); %en px
            f=0.5*(fu*Du+fv*Dv);%mm

            %la resolucion en el plano de la lente es
            dxi=mean(Zc)/fu; %mm/px
            deta=mean(Zc)/fv; %mm/px

            %la resolucion en el plano de la pantalla es
            dx=mean(Zt)/fu; %mm/px
            dy=mean(Zt)/fv; %mm/px

            fprintf('Camera-Lens focal distance f:%d mm\n', f);
            fprintf('resolution at the lens plane dxi:%d, deta: %d (mm/px)\n', dxi, deta);
            fprintf('resolution at the screen plane dx:%d, dy: %d (mm/px)\n', dx, dy);

        end



        % ======================================================================
        %> @brief testfilterHarmonicsX
        %> @details testing of the testfilterHarmonicsX function. in this
        %function we use MATLAB>2019b argument validation sintax
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testfilterHarmonicsX(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testfilterHarmonicsX');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all


            NR=576; NC=756;
            g=peaks(NR); g=imresize(g, [NR, NC]);
            wx=60; %fringes field
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            wxr=wx*(2*pi)/NC; %rad/px
            g=g+2+2*cos(wxr*x);
            figure; imagesc(g); title('original image 1')

            gh=UtilFunFPA.filterHarmonicsX(g, wx);
            figure; imagesc(gh); title('filtered image 1')
            figure; imagesc(g-gh); title('error 1')


            M=abs(x+1i*y)<0.35*NR;
            g=g+2+2*cos(wxr*x);
            g=g.*M;
            figure; imagesc(g); title('original image + Mask default R')
            [gh, Mh]=UtilFunFPA.filterHarmonicsX(g, wx, 'M', M);
            figure; imagesc(gh.*Mh); title('filtered image + Mask default R')
            figure; imagesc(Mh); title('filtered Mask default R')
            figure; imagesc((g-gh).*Mh); title('error + Mask default R')


            [gh, Mh]=UtilFunFPA.filterHarmonicsX(g, wx, 'M', M, 'R', 3);
            figure; imagesc(gh.*Mh); title('filtered image + Mask R=3')
            figure; imagesc(Mh); title('filtered Mask R=3')
            figure; imagesc((g-gh).*Mh); title('error + Mask default R=3')


        end



        % ======================================================================
        %> @brief testIOTMapperGeomCalibrationVsSize
        %> @details this function makes a geometrical calibration of the
        %> IOT Mapper including camera internals and estimates ditances to the screen with the suporting glass plate
        %> with the MATLAB Computer Vision Toolbox. Here we compare the
        %> results obtained using a laserjet printed 7x8 pattern with different quare sizes
        %> 6, 8 and 10 mm, the reason is that 8 mm gives correct results
        %> while 6 and 10 mm are incorrect.
        %> @see oneNote->InspeccionCos/2021/Fabricaci�n Blancos de calibraci�n Visionlab en placas
        %> @param testCase ref to the unit testing framework class
        % ======================================================================
        function testIOTMapperGeomCalibrationVsSize(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testIOTMapperGeomCalibrationVsSize');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            d=ver;
            if not(any(strcmp({d.Name}, 'Computer Vision Toolbox')))
                error('Computer Vision System Toolbox is NOT installed') ;
            end

            % Create a set of calibration images.
            dbDir=fixturesRoot();
            %The calibration has been done with the 1 mm glass window in place
            %(Calibracion_9FEB21_6mm not available as a fixture)
            %(Calibracion_15DIC20 not used here - see calibFilesDir below)
            calibFilesDir='Calibracion_10FEB21_8mm'; squareSize = 8; %mm verificado con la lupa
            %calibFilesDir='PerseusMedidas\ExperimentosPerseus\Deflectometria\Calibracion_01MAR21_8mm'; squareSize = 8; %mm verificado con la lupa
            %calibFilesDir='PerseusMedidas\ExperimentosPerseus\Deflectometria\Calibracion_26FEB21_A_10mm'; squareSize = 10; %mm verificado con la lupa
            %calibFilesDir='PerseusMedidas\ExperimentosPerseus\Deflectometria\Calibracion_26FEB21_B_10mm'; squareSize = 10; %mm verificado con la lupa
            ExcludeImages=[]; %after a first param estimation this images generate bit retroproj error

            images = imageDatastore(fullfile(dbDir, calibFilesDir));
            imageFileNames = images.Files(setdiff(1:length(images.Files), ExcludeImages));

            % Detect calibration pattern.
            [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);

            % Generate world coordinates of the corners of the squares.

            worldPoints = generateCheckerboardPoints(boardSize, squareSize);

            % Calibrate the camera.
            I = readimage(images, 1);
            imageSize = [size(I, 1), size(I, 2)];
            [params, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
                'ImageSize', imageSize, ...
                'EstimateTangentialDistortion', false,...
                'EstimateSkew' , false, ...
                'NumRadialDistortionCoefficients', 2);


            %show reprojection results
            % View reprojection errors
            %h1=figure; showReprojectionErrors(this.cameraParams);   %this is the default
            baseNames=cell(1, length(imageFileNames));
            for n=1:length(imageFileNames)
                [~, baseNames{n}, ~]=fileparts(imageFileNames{n});
            end
            figure; UtilFunFPA.showReprojectionErrorsWithLabels(params,baseNames);

            figure; showReprojectionErrors(params,'ScatterPlot'); axis equal; grid on;



            figure; showExtrinsics(params, 'CameraCentric');

            displayErrors(estimationErrors, params);

            %display detectec corners and retro-projected points
            if false
                for n=1:length(images.Files)
                    I = readimage(images, n);
                    figure; imagesc(I); title(gca, baseNames{n});
                    hold on
                    plot(imagePoints(:, 1, n), imagePoints(:, 2, n), 'o');
                    plot(params.ReprojectedPoints(:,1,n),params.ReprojectedPoints(:,2,n),'r+');
                    hold off
                end
            end




            %OJO MATLAB calcula s[u,v,1]=[X Y Z 1][R|t]K [x,y,z]=[X Y Z]R+t
            %para manejar vectores fila 1xn por lo tanto si queremos
            %manejar vectores columna (como usualmente) hay que trasponer K
            %y R. Es decir a las funciones de la toolbox hay que pasar K y
            %R sin modificar y a las funciones propias hay que pasar K' y
            %R' para obtener los mismos resultados que la toolbox
            %intrinnsic params
            K=params.IntrinsicMatrix;
            %Principal point
            p0=params.PrincipalPoint;
            %p0=0.5*imageSize;  AQDEBUG



            %get index for the test images @ lens plane
            nZc=find(contains(imageFileNames, 'lensPlane'));
            Zc=zeros(1,length(nZc));
            % distance between lens plane and camera
            for k=1:length(nZc)

                tc=params.TranslationVectors(nZc(k),:);
                Rc=params.RotationMatrices(:, :, nZc(k));

                %distance to image_Zc.bmp
                Zc(k)=UtilFunFPA.DistancePlaneCam(K', Rc', tc, p0);
            end

            %distance to image_Z+Zc.bmp, distance between screen plane and
            %camera
            %get index for the test images @ screen plane
            nZt=find(contains(imageFileNames, 'screenPlane'));
            Zt=zeros(1,length(nZt));
            for k=1:length(nZt)
                t=params.TranslationVectors(nZt(k),:);
                R=params.RotationMatrices(:, :, nZt(k));
                Zt(k)=UtilFunFPA.DistancePlaneCam(K', R', t, p0);
            end

            %distance between lens plane and screen plane
            Z=mean(Zt)-mean(Zc);

            fprintf('\n Camera-Lens plane Zc:%d +/-%d, values:%d', mean(Zc), std(Zc)); disp(Zc);disp('');
            fprintf('\n Camera-Screen plane Zc+Z:%d +/-%d, values:%d', mean(Zt), std(Zt)); disp(Zt);disp('');
            fprintf('\n Screen-Lens plane Z:%d +/-%d', Z, sqrt(std(Zt)^2 + std(Zc)^2)); disp('');


            %show distortion map
            NR=imageSize(1); NC=imageSize(2);
            [u,v]=meshgrid(1:50:NC, 1:50:NR);
            uv=[u(:), v(:)];
            %uvc=corrected, undistorted
            uvc = undistortPoints(uv,params);
            du=uvc(:, 1)-uv(:, 1); dv=uvc(:, 2)-uv(:, 2);
            fh=figure; quiver(uv(:, 1), uv(:, 2), du, dv);

            uvDistortion=abs(du+1i*dv);
            [NR, NC]=size(u);
            uvDistortion=reshape(uvDistortion, NR, NC);
            figure(fh); hold on;
            contour(u,v,uvDistortion, 'ShowText','on');
            hold off;


            %para la camara DMK 33UX183 binning 3x3 el tama�o del pixel es
            Du=3*2.4e-3; %mm/px
            Dv=3*2.4e-3; %mm/px

            %la focal de la lente es
            fu=K(1,1); %en px
            fv=K(2,2); %en px
            f=0.5*(fu*Du+fv*Dv);%mm average focal in mm
            fx=fu*Du; %fx focal in mm
            fy=fv*Dv; %fy focal in mm
            fprintf('\n\n Lens focal [%d, %d] px [%d, %d] mm', fu, fv, fx, fy); disp('\n');


            %la resolucion en el plano de la lente es
            dxi=mean(Zc)/fu; %mm/px
            deta=mean(Zc)/fv; %mm/px

            %la resolucion en el plano de la pantalla es
            dx=mean(Zt)/fu; %mm/px
            dy=mean(Zt)/fv; %mm/px

            fprintf('\n resolution at the lens plane dxi:%d, deta: %d (mm/px)', dxi, deta);
            fprintf('\n resolution at the screen plane dx:%d, dy: %d (mm/px)', dx, dy);

        end

        % ======================================================================
        %> @brief testLSDemodEquispacedPeaks
        %> @details test the LSDemodEquispaced function with the peaks
        %>  testing phase using NFPs steps with a size of NRxNC
        %>  Also we validate the normalization factor comparing the returned
        %>  modulation agaisnt the input modulation. Cjeck error maps for
        %>  different NFPs
        %> @see deflectometry.docx
        %> @param testCase ref to the unit testing framework class
        %> @details run(testFPA_UtilFunFPAClassVer, 'testLSDemodEquispacedPeaks');
        function testLSDemodEquispacedPeaks(testCase)
            % Close all existing figures
            close all;

            % Define the dimensions
            NR=480; % Number of rows
            NC=640; % Number of columns
            NFPs=5; % Number of equispaced phase shifts

            % Create a grid of coordinates
            [x,y]=meshgrid(1:NC,1:NR);
            x=x-0.5*NC;
            y=y-0.5*NR;

            % Define a mask based on the grid coordinates
            M=abs(x+1i*y)<0.25*min(NR,NC);

            % Generate equispaced phase shifts
            delta=2*pi*(0:NFPs-1)'/NFPs;

            % Generate an input phase using the "peaks" function
            p=4*peaks(max(NR,NC));
            p=imresize(p,[NR,NC]);

            % Generate an input modulation in GV (gray values)
            m=80+p;

            % Define an input background in GV
            b=120;

            % Create a cell array to store the GV igrams for each phase shift
            gList=cell(1,NFPs);

            % Generate GV igrams for each phase shift
            % Generate modulated gray values for each phase shift using cellfun
            gList = cellfun(@(n) M.*round(b+m.*cos(p+delta(n))), num2cell(1:NFPs), 'UniformOutput', false);

            % Perform LSDemodEquispaced on both modulation and phase
            onlyModFlag=false;
            [z]=UtilFunFPA.LSDemodEquispaced(gList,M,delta,onlyModFlag);

            % Calculate the phase error
            pd=angle(exp(-1i*p(M)).*z(M));
            x=linspace(-pi/10,pi/10,100);

            % Display a histogram of the phase error
            figure;histogram(pd,x);
            title('phase+mod equispaced LS phase error');
            xlabel('rad');

            % Calculate the modulation error in GV
            % modulation is normalized in function of the number of steps
            md=m-abs(z);
            testCase.assertLessThan(std(md(M)), 0.5);
          

            % Display a histogram of the modulation error
            x=linspace(-3,3,100);
            figure;histogram(md,x);
            title('phase+mod equispaced modulation error');
            xlabel('GV');

            % Display the phase map
            figure;imagesc(angle(z));
            title('Equispaced LS phase map');

            % Display the mod map
            figure;imagesc(abs(z));
            title('Equispaced LS mod map');

            % Perform LSDemodEquispaced on only modulation
            onlyModFlag=true;
            [z]=UtilFunFPA.LSDemodEquispaced(gList,M,delta,onlyModFlag);

            % Ensure the result is real
            assert(all(isreal(z)));

            % Calculate the modulation error in GV
            % modulation is normalized in function of the number of steps
            md=m-abs(z);
            testCase.assertLessThan(std(md(M)), 0.5);
            

            % Display a histogram of the modulation error
            x=linspace(-3,3,100);
            figure;histogram(md,x);
            title('only mod equispaced modulation error');
            xlabel('GV');

            % Display the mod map
            figure;imagesc(z);
            title('only mod Equispaced LS mod map');

        end
 
        % ======================================================================
        %> @brief testLSDemodEquispacedVsLSGeneralPeaks
        %> @details aqui miramos la diferencia de tiempo en calcular la moduladion entre el LS general y el LS
        %> equiespaciado
        %> @param testCase ref to the unit testing framework class
        %> @details run(testFPA_UtilFunFPAClassVer, 'testLSDemodEquispacedVsLSGeneralPeaks');        
        function testLSDemodEquispacedVsLSGeneralPeaks(testCase)
            close all;

            % Define the dimensions
            NR=1480; % Number of rows
            NC=1643; % Number of columns
            NFPs=5; % Number of equispaced phase shifts

            % Create a grid of coordinates
            [x,y]=meshgrid(1:NC,1:NR);
            x=x-0.5*NC;
            y=y-0.5*NR;

            % Define a mask based on the grid coordinates
            M=abs(x+1i*y)<0.25*min(NR,NC);

            % Generate equispaced phase shifts
            deltaList=2*pi*(0:NFPs-1)'/NFPs;

            % Generate an input phase using the "peaks" function
            p=4*peaks(max(NR,NC));
            p=imresize(p,[NR,NC]);

            % Generate an input modulation in GV (gray values)
            m=80+p;

            % Define an input background in GV
            b=120;

            % Create a cell array to store the GV igrams for each phase shift
            gList=cell(1,NFPs);

            % Generate GV igrams for each phase shift
            % Generate modulated gray values for each phase shift using cellfun
            gList = cellfun(@(n) M.*round(b+m.*cos(p+deltaList(n))), num2cell(1:NFPs), 'UniformOutput', false);

            onlyModFlag=true;
            disp('EquisPaced LS demodulation Processing time')
            tic;
            for k=1:10
                [z] = UtilFunFPA.LSDemodEquispaced(gList, M, deltaList, onlyModFlag);
            end
            toc

            disp('General LS demodulation Processing time')
            tic
            for k=1:10
                [z] = UtilFunFPA.LSDemod(gList, M, deltaList, onlyModFlag);
            end
            toc


            % check that the modulations are equal between the equispaced
            % and the LS PSA
            [m1] = UtilFunFPA.LSDemodEquispaced(gList, M, deltaList, onlyModFlag);
            [m2] = UtilFunFPA.LSDemod(gList, M, deltaList, onlyModFlag);

            % Calculate the modulation error in GV
            % modulation is normalized in function of the number of steps
            md=m1-m2;
            testCase.assertLessThan(std(md(M)), 0.5);

            
            % Display a histogram of the modulation error
            x=linspace(-3,3,100);
            figure;histogram(md,x);
            title('only mod equispaced modulation error');
            xlabel('GV');

             % Display the mod map
            figure;imagesc(m1);
            title('only mod Equispaced LS mod map');

            % Display the mod map
            figure;imagesc(m2);
            title('only mod LS PSA mod map');
        end
        
        % ======================================================================
        %> @brief testLSDemod
        %> @details test the LSDemod function with the peaks
        %>  testing phase using NFPs steps with a size of NRxNC
        %>  Also we validate the normalization factor comparing the returned
        %>  modulation agaisnt the input modulation. Check error maps for
        %>  different NFPs
        %> @see deflectometry.docx
        %> @param testCase ref to the unit testing framework class
        %> @details run(testFPA_UtilFunFPAClassVer, 'testLSDemodPeaks');
        function testLSDemodPeaks(testCase)                                    
            close all;

            % Define the dimensions
            NR=1480; % Number of rows
            NC=1643; % Number of columns
            NFPs=5; % Number of equispaced phase shifts

            % Create a grid of coordinates
            [x,y]=meshgrid(1:NC,1:NR);
            x=x-0.5*NC;
            y=y-0.5*NR;

            % Define a mask based on the grid coordinates
            M=abs(x+1i*y)<0.25*min(NR,NC);

            %generamos difernetes tipos de saltos
            %deltaList=2*pi*(0:NFPs-1)'/NFPs; %equispaciados lineales crecientes, la salida del PCA sale con orden OK
            deltaList=2*pi*rand(NFPs,1 ); %arbitrarios
            % deltaList=2*pi*rand(NFPs,1 ); deltaList=sort(deltaList); %arbitrarios pero crecientes podemos ordenadar la salida del PCA
            
            % Generate an input phase using the "peaks" function
            p=4*peaks(max(NR,NC));
            p=imresize(p,[NR,NC]);

            % Generate an input modulation in GV (gray values)
            m=80+p;

            % Define an input background in GV
            b=120;

            % Generate GV igrams for each phase shift
            % Generate modulated gray values for each phase shift using cellfun
            gList = cellfun(@(n) M.*round(b+m.*cos(p+deltaList(n))), num2cell(1:NFPs), 'UniformOutput', false);

            % Perform LSDemodEquispaced on both modulation and phase
            onlyModFlag=false;
            [z]=UtilFunFPA.LSDemod(gList,M,deltaList,onlyModFlag);

            % Calculate the phase error
            pd=angle(exp(-1i*p(M)).*z(M));
            x=linspace(-pi/10,pi/10,100);

            % Display a histogram of the phase error
            figure;histogram(pd,x);
            title('phase+mod LS phase error');
            xlabel('rad');

            % Calculate the modulation error in GV
            % modulation is normalized in function of the number of steps
            md=m-abs(z);
            testCase.assertLessThan(std(md(M)), 0.5);
          

            % Display a histogram of the modulation error
            x=linspace(-3,3,100);
            figure;histogram(md,x);
            title('phase+mod LS modulation error');
            xlabel('GV');

            % Display the phase map
            figure;imagesc(angle(z));
            title('LS phase map');

            % Display the mod map
            figure;imagesc(abs(z));
            title('LS mod map');

            % Perform LSDemod only modulation
            onlyModFlag=true;
            [z]=UtilFunFPA.LSDemod(gList,M,deltaList,onlyModFlag);

            % Ensure the result is real
            assert(all(isreal(z)));

            % Calculate the modulation error in GV
            % modulation is normalized in function of the number of steps
            md=m-abs(z);
            testCase.assertLessThan(std(md(M)), 0.5);
            
            
            % Display a histogram of the modulation error
            x=linspace(-3,3,100);
            figure;histogram(md,x);
            title('only mod equispaced modulation error');
            xlabel('GV');
            
            % Display the mod map
            figure;imagesc(z);
            title('only mod LS mod map');
            
        end
        
        % Here we calculate the LS PSA phase for a truncated igrams and
        % check the effect on the phase and its gradients
        % run(testFPA_UtilFunFPAClassVer, 'testLSDemodSaturation');
        function testLSDemodSaturation(testCase)
            close all; % Close all open figures
            
            NR = 480; % Number of rows
            NC = 640; % Number of columns
            NFPs = 6; % Number of different types of jumps
            
            [x, y] = meshgrid(1:NC, 1:NR); % Generate x and y grid
            x = x - 0.5 * NC; % Shift x grid
            y = y - 0.5 * NR; % Shift y grid
            
            M = abs(x + 1i * y) < 0.25 * min(NR, NC); % Create circular mask
            
            delta = 2 * pi * (0:NFPs-1)' / 6; % Generate different types of jumps
            
            p = 2 * pi * 10 * x / NC; % Generate phase gradient p
            [px, py] = gradient(p); % Compute phase gradient derivatives
            
            gList = cell(1, NFPs); % Initialize cell array for image list
            
            th = 0.75; % Threshold for saturation
            
            % Generate images with different jumps and saturation
            for n = 1:NFPs
                g = 1 + cos(p + delta(n)) + 0.1 * randn(size(p)); % Add jump and noise
                gM = g > th; % Threshold the maximum values
                g(gM) = th; % Cap the maximum values
                gList{n} = M .* g; % Apply circular mask
            end
            
            [z] = UtilFunFPA.LSDemod(gList, M, delta); % Perform LSDemod
            
            % Display original image
            figure;
            imagesc(gList{n} .* M ./ M, [0, 2]);
            title('igram');
            
            pd = angle(exp(-1i * p(M)) .* z(M)); % Compute phase error histogram
            x = linspace(-pi, pi, 50);
            figure;
            histogram(pd, x);
            xlabel('phase error histogram');
            
            % Display LS phase map, ground truth phase map, and phase map error
            figure;
            imagesc(M .* angle(z));
            title('LS phase map');
            colormap gray;
            
            figure;
            imagesc(M .* angle(exp(1i * p)));
            title('Ground truth phase map');
            colormap gray;
            
            figure;
            imagesc(M .* angle(exp(1i * p) ./ z));
            title('Phase map error');
            colormap gray;
            colorbar;
            
            r = round(NR * 0.5); % Row for phase comparison
            pz = angle(z); % LS phase map
            figure;
            plot(1:NC, pz(r,:), 1:NC, angle(exp(1i * p(r, :) .* M(r, :))));
            legend('LS', 'ground truth');
            
            [pzx, pzy, Mxy] = UtilFunFPA.phaseGradientDirect(z, M, 1, 1); % Compute phase gradients
            
            % Display phase gradient maps
            figure;
            imagesc(Mxy .* pzx);
            title('Phase map Dx');
            colormap gray;
            
            figure;
            imagesc(Mxy .* pzy);
            title('Phase map Dy');
            colormap gray;
            colorbar;
            
        end
        
        % here we simulate a defelction measurement of a phase object using two
        % fringe directions using a simple massig deflectometric setup. What we measure are the deirvatives of the output
        % wavefront for each fringe direction
        % run(testFPA_UtilFunFPAClassVer, 'testPSA6MultiplexedXY');
        function testPSA6MultiplexedXY(testCase)
            close all
            
            NR=512; NC=511;
            p=4*peaks(max(NR, NC)); p=imresize(p, [NR, NC]); %phase
            
            [x,y]=meshgrid(1:NC, 1:NR); %XY in au
            [px, py]=gradient(p); %gradient
            
            Z=100; %separation grid-lens in px
            T=20; %grid period in px
            K=2*pi*Z/T; %sensitivity
            
            FF1=2*pi/T; %fringes/px
            theta1=0; %orientation in deg grid 1
            w1=FF1*[cosd(theta1), sind(theta1)]; %spatial carrier in Fringes/px grid 1
            p1=px.*cosd(theta1)+py.*sind(theta1); %directional derivative along normal to grid 1
            
            FF2=2*pi/T; %fringes/px grid 2
            theta2=90; %orientation in deg grid 2
            w2=FF2*[cosd(theta2), sind(theta2)]; %spatial carrier in Fringes/px grid 2
            p2=px.*cosd(theta2)+py.*sind(theta2); %directional derivative along normal grid 2
            
            b=252/2; %background poner denominador >=2
            m=255/4; %modulation poner denominador >=4
            
            NSteps=6;
            s1=[0, pi, -pi/2, pi/2, 0, -pi/2]; %phase steps deflection p1
            s2=[0, 0, -pi/2, -pi/2, pi, pi/2];  %phase steps deflection p2
            
            % build up set of multiplexed 6 igrams
            gList=cell(1, NSteps);
            for n=1:NSteps
                gg=b+m*cos(2*pi*Z*p1/T + w1(1)*x + w1(2)*y + s1(n)) + m*cos(2*pi*Z*p2/T + w2(1)*x + w2(2)*y + s2(n)) ;
                gList{n}=gg;
            end
            
            figure; imagesc(gList{n}); title('fisr igram')
            
            
            % PSA6 demod            
            Mask=true(NR, NC);
            deltaList=struct('X', s1, 'Y', s2);
            zList = UtilFunFPA.PSA6MultiplexedXY(gList, Mask, deltaList);
            
            %first, phasor calculation;
            z1=zList{1};
            z2=zList{2};
            
            figure; imagesc(angle(z1)); colormap jet; drawnow; title('\phi_1');
            figure; imagesc(angle(z2)); colormap jet; drawnow; title('\phi_2');
            
            %check modulation values
            e=abs(m-mean(abs(z1(:))));
            testCase.assertLessThan(e, 1e-3);
            
            e=abs(m-mean(abs(z2(:))));
            testCase.assertLessThan(e, 1e-3);          
            
                                   
            %second, modulation only
            onlyModFlag=true;
            zList = UtilFunFPA.PSA6MultiplexedXY(gList, Mask, deltaList,onlyModFlag);
            m1=zList{1};
            m2=zList{2};
            
            figure; imagesc(m1); colormap jet; drawnow; title('m_1');
            figure; imagesc(m2); colormap jet; drawnow; title('m_2');
            
            %check modulation values
            e=abs(m-mean(abs(m1(:))));
            testCase.assertLessThan(e, 1e-3);
            
            e=abs(m-mean(abs(m2(:))));
            testCase.assertLessThan(e, 1e-3);

        end

        % ==================================================================
        % Consolidated from the legacy mtest testFPA_UtilFunFPA.m
        % (2026-09-13) - see DECISIONS.md, Fase 3, for the coverage
        % analysis (only test_GradientConsistency,
        % test_GradientConsistencyWithWrappedDifs and testBin2Grey were
        % already covered above; these ~40 were not).
        % ==================================================================

        function test_LocateSidelobes_ReferenciaRotlex(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_LocateSidelobes_ReferenciaRotlex')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            %% experimental data
            g=double(imread('RefFFVLidDown-17-11-2015.bmp')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-61 2], 'AbsTol', tol)
            testCase.assertEqual(w2, [-2 -46], 'AbsTol', tol)

            g=double(imread('ProgHoya1.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-56 5], 'AbsTol', tol)
            testCase.assertEqual(w2, [-7 -43], 'AbsTol', tol)

            g=double(imread('ProgHoya.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-28 4], 'AbsTol', tol)
            testCase.assertEqual(w2, [-6 -22], 'AbsTol', tol)

            g=double(imread('ProgHoyaRef.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-28 1], 'AbsTol', tol)
            testCase.assertEqual(w2, [-2 -22], 'AbsTol', tol)

            g=double(imread('ProgHoya1Ref.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-56 2], 'AbsTol', tol)
            testCase.assertEqual(w2, [-2 -43], 'AbsTol', tol)

            g=double(imread('YO_D75_SMinus275_C0.bmp')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [ -52   -12], 'AbsTol', tol)
            testCase.assertEqual(w2, [ 16   -39], 'AbsTol', tol)

            g=double(imread('SwissCoat40L88051R.bmp')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            tol=0.9; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-71  9], 'AbsTol', tol)
            testCase.assertEqual(w2, [ -19  -49], 'AbsTol', tol)

            g=double(imread('ProgHoyaRef.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            w1=w{1};
            w2=w{2};
            tol=0.5;
            testCase.assertEqual(w1, [ -28.3529   1.0588], 'AbsTol', tol)
            testCase.assertEqual(w2, [-2.0769   -22.3077], 'AbsTol', tol)
        end

        function test_LocateSidelobes_ComputerExample(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_LocateSidelobes_ComputerExample')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=231;
            NC=340;
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            a=2+cos(2*pi*x/NC);
            b=2+cos(2*pi*y/NR).*cos(2*pi*y/NR);

            wx1=20.5;
            wy1=2;
            p1=2*pi*(wx1*x/NC + wy1*y/NR);
            g1=a+b.*cos(p1);

            wx2=-2;
            wy2=23.5;
            p2=2*pi*(wx2*x/NC + wy2*y/NR);
            g2=a+b.*cos(p2);

            g=g1 + g2;

            w = UtilFunFPA.LocateSidelobes(g);
            tol=1; %FF
            w1=w{1};
            w2=w{2};
            testCase.assertEqual(w1, [-wx1 -wy1], 'AbsTol', tol)
            testCase.assertEqual(w2, [-wx2 -wy2], 'AbsTol', tol)
        end

        function test_FFTDemod_ReferenciaRotlex(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_FFTDemod_ReferenciaRotlex')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            %% experimental data
            g=double(imread('RefFFVLidDown-17-11-2015.bmp')); %low freq

            w = UtilFunFPA.LocateSidelobes(g);
            wx=w{1};
            wy=w{2};

            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zy=z{1};
            zx=z{2};

            phix=mat2gray(angle(zx));
            bx=mat2gray(abs(zx));

            phiy=mat2gray(angle(zy));
            by=mat2gray(abs(zy));

            figure; imshow(phix); title('DeltaX');
            figure; imshow(bx);title('bx');

            figure; imshow(phiy); title('Deltay');
            figure; imshow(by); title('by');
        end

        function test_FFTDemod(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_FFTDemod')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            %%set dims
            NR=481;
            NC=640;
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

            %% simulated data
            px=1.2*peaks(NC); px=imresize(px, [NR, NC]);
            py=1.2*pi*cos(2*pi*0.5*abs(x+1i*y)/NC);

            wx=[76,-18];
            wy=[38, 56];

            %signal
            gx=10+2*cos(2*pi*wx(1)*x/NC+2*pi*wx(2)*y/NR+ px);
            gy=10+2*cos(2*pi*wy(1)*x/NC+2*pi*wy(2)*y/NR+ py);
            g=gx.*gy;

            %ref
            gxr=10+2*cos(2*pi*wx(1)*x/NC+2*pi*wx(2)*y/NR);
            gyr=10+2*cos(2*pi*wy(1)*x/NC+2*pi*wy(2)*y/NR);
            gr=gxr.*gyr;

            %% demodulation
            w = UtilFunFPA.LocateSidelobes(g);
            wx=w{3}; %exp(+i*w0*x) lobe
            wy=w{4}; %exp(+i*w0*y) lobe
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};

            w = UtilFunFPA.LocateSidelobes(gr);
            wx=w{3}; %exp(+i*w0*x + i*phix) lobe
            wy=w{4}; %exp(+i*w0*y + i*phiy) lobe
            R=5; %FF
            z=UtilFunFPA.FFTDemod(gr, {wx, wy}, R);
            zxr=z{1};
            zyr=z{2};

            zx=zxc./zxr;
            zy=zyc./zyr;

            phix=mat2gray(angle(zx));
            bx=mat2gray(abs(zxc));

            phiy=mat2gray(angle(zy));
            by=mat2gray(abs(zyc));

            figure; imshow(phix); title('DeltaX');
            figure; imshow(bx);title('bx');

            figure; imshow(phiy); title('Deltay');
            figure; imshow(by); title('by');

            ex=angle(zx./exp(1i*px));
            ey=angle(zy./exp(1i*py));

            %no bias
            tol=1e-5;
            testCase.assertEqual(0, mean(ex(:)), 'AbsTol', tol);
            testCase.assertEqual(0, mean(ey(:)), 'AbsTol', tol);

            %small error
            tol=1e-1;
            testCase.assertEqual(0, std(ex(:)), 'AbsTol', tol);
            testCase.assertEqual(0, std(ey(:)), 'AbsTol', tol);
        end

        function test_phaseGradientDirect(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_phaseGradientDirect')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=640;
            NC=480;
            p=peaks(NR);
            p=imresize(p, [NR, NC]);
            [px, py]=gradient(p);

            [u,v]=meshgrid(1:NC, 1:NR); u=u-0.5*NC; v=v-0.5*NR;
            M=abs(u+1i*v)<150;

            b=mat2gray(10+p);
            z=M.*b.*exp(1i*p);

            hx=1; %1 mm/px
            hy=1; %mm/px
            [phix, phiy, Mxy]=UtilFunFPA.phaseGradientDirect(z, M, hx, hy);

            tol=1e-5;
            e=px-phix;
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);

            tol=1e-5;
            e=py-phiy;
            testCase.assertEqual(0, mean(e(Mxy)), 'AbsTol', tol);
        end

        function test_FFTDemod_ProgHoya1(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_FFTDemod_ProgHoya1')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            %% experimental data
            g=double(imread('ProgHoya1.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            wx=w{1};
            wy=w{2};
            flatTopFlag=false;
            R=20; %band pass filter fringes field
            z=UtilFunFPA.FFTDemod(g, {wx, wy}, flatTopFlag, R);

            zxc=z{1};
            zyc=z{2};

            gr=double(imread('ProgHoya1Ref.tif')); %low freq
            w = UtilFunFPA.LocateSidelobes(gr);
            wx=w{1};
            wy=w{2};
            flatTopFlag=false;
            z=UtilFunFPA.FFTDemod(gr, {wx, wy}, flatTopFlag);

            zxr=z{1};
            zyr=z{2};

            zx=zxc./zxr;
            zy=zyc./zyr;

            phix=mat2gray(angle(zx));
            bx=mat2gray(abs(zxc));

            phiy=mat2gray(angle(zy));
            by=mat2gray(abs(zyc));

            figure; imshow(phix);
            figure; imshow(bx);

            figure; imshow(phiy);
            figure; imshow(by);
        end

        function test_FFTDemod_BlankStratemeyerBC_20_n_16(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_FFTDemod_BlankStratemeyerBC_20_n_16')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            %% experimental data
            g=double(imread('BlankStratemeyerBC_20_n_16.bmp')); %low freq
            w = UtilFunFPA.LocateSidelobes(g);
            wx=w{1};
            wy=w{2};
            z=UtilFunFPA.FFTDemod(g, {wx, wy});
            zxc=z{1};
            zyc=z{2};

            gr=double(imread('RefFFVLidDown-17-11-2015.bmp')); %low freq
            w = UtilFunFPA.LocateSidelobes(gr);
            wx=w{1};
            wy=w{2};
            z=UtilFunFPA.FFTDemod(gr, {wx, wy});
            zxr=z{1};
            zyr=z{2};

            zx=zxc./zxr;
            zy=zyc./zyr;

            phix=mat2gray(angle(zx));
            bx=mat2gray(abs(zxc));

            phiy=mat2gray(angle(zy));
            by=mat2gray(abs(zyc));

            figure; imshow(phix);
            figure; imshow(bx);

            figure; imshow(phiy);
            figure; imshow(by);
        end

        function test_wRes_Pro(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_wRes_Pro')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NRows=648;
            NCols=485;
            pt=peaks(min(NRows, NCols)); pt=imresize(pt, [NRows, NCols]);

            [x,y]=meshgrid(1:NCols, 1:NRows); x=x-0.5*NCols; y=y-0.5*NRows;

            %alternativa lineal
            pt=y;

            Mp=abs(x+1i*y)<0.3*min(min(NRows, NCols));

            Mp=double(Mp); %these are weigths more than ROI

            lf=cos(30*2*pi*x/NRows); %loffreq signal to be filtered
            p=(pt+lf).*Mp + randn(size(pt));

            pRP=UtilFunFPA.VicleFilter(p, Mp);

            figure; imagesc(Mp.*(pt-pRP));
            figure; imagesc(Mp.*pRP);
        end

        function test_StressDisk(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_StressDisk')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=568;
            NC=576;

            [delta, w2alpha, sx, sy, sxy, s1, s2, M]=UtilFunFPA.StressDisk(NR, NC); %#ok<ASGLU>
            %use this if you want zero direction at the disk center
            w4alpha=angle(exp(1i*2*w2alpha));

            %use this to obtain a stress jump at the center
            %w4alpha=mod(2*w2alpha, 2*pi);

            tol=eps;
            %check the retardation values
            testCase.assertTrue(all(delta(:))>=0);
            testCase.assertEqual(0, min(delta(:)), 'AbsTol', tol);
            testCase.assertEqual(0, max(delta(:)), 'AbsTol', 10*2*pi);

            %check isochromatic fringes
            figure; imagesc(cos(delta)); colormap jet; title('cos(delta)');
            figure; imagesc(s1); colormap jet; title('sigma1');
            figure; imagesc(s2); colormap jet; title('sigma2');

            %check
            D=20;
            sameColor=false;
            %here we don't know stress direction but we can separate s1 from s2
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColor); title('w2alpha S1 and S2');

            %draw only s1 and s2
            stressDirection='s1';
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColor, stressDirection); title('w2alpha S1');

            stressDirection='s2';
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColor, stressDirection); title('w2alpha S2');

            stressDirection='s2';
            showArrowHead='off';
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColor, stressDirection, showArrowHead); title('w2alpha S2');

            %use CDF as image in DraAlpha
            sameColor=true;
            stressDirection='both';
            showArrowHead='on';
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColor, stressDirection, showArrowHead, 1-cos(delta)); title('CDF with stress directions');

            %here we don't know stress direction and also we can not diferenciate s1 from s2
            %see discusion in paper PCA in fotoelasticity
            UtilFunFPA.DrawAlpha(0.25*w4alpha, D, sameColor); title('w4alpha');

            %for the intensities simulation 0.5*w2alpha or 0.25*w4alpha are the same
            step=[0 22.5 45 67.5];
            %use zero noise
            IList1=UtilFunFPA.LBFPattern(delta, 0.5*w2alpha, step, M, 0);
            IList2=UtilFunFPA.LBFPattern(delta, 0.25*w4alpha, step, M, 0);

            for n=1:4
                g1=IList1{n};
                g2=IList2{n};
                testCase.assertEqual(g1(:),g2(:), 'AbsTol', 1e-8);
            end
        end

        function test_CalcIsoclinPS(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_CalcIsoclinPS')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=568;
            NC=576;

            [delta, w2alpha, sx, sy, sxy, s1, s2, M]=UtilFunFPA.StressDisk(NR, NC); %#ok<ASGLU>
            w4alpha=angle(exp(1i*2*w2alpha)); %#ok<NASGU>

            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);
            %set the PSA to a 4 step method see PSFilterTypes
            d.Set(char(DemodulatorProps.PSType),PSFilterTypes.PS4);
            %another option is the 5 step hariraran
            %d.Set(char(DemodulatorProps.PSType),PSFilterTypes.A0502);

            %set the variation range to pi/2 for isoclinics
            d.Set(char(DemodulatorProps.StepsTwoPwiRange), pi/2);

            %set ROI
            d.Set(char(DemodulatorProps.M),M);

            steps=d.GetStepValues();

            nl=0;
            FPList=UtilFunFPA.LBFPattern(delta, 0.5*w2alpha, steps, M, nl);

            d.Process(FPList);
            zList=d.Get(char(DemodulatorProps.zList));
            z4alphaM=zList{1};
            w4alphaM=angle(z4alphaM);
            D=20;
            sameColorFlag=false;
            UtilFunFPA.DrawAlpha(0.25*w4alphaM, D, sameColorFlag); title('w4alpha Measured');
            UtilFunFPA.DrawAlpha(0.25*w4alpha, D, sameColorFlag); title('w4alpha Teoretical');

            %unwrap w4alpha
            QM=abs(z4alphaM); %relacion se�al ruido: la calidad
            t=5; % neighbouhood 2t+1
            mu=1; % regularization
            [w2alphaM, M]=UtilFunFPA.Calc2Alpha(w4alphaM,QM,M,t,mu);

            UtilFunFPA.DrawAlpha(0.5*w2alphaM, D, sameColorFlag); title('w2alpha Measured');
            UtilFunFPA.DrawAlpha(0.5*w2alpha, D, sameColorFlag); title('w2alpha Teoretical');

            err4a=mean(abs(cos(2*w2alphaM(:))-cos(2*w2alpha(:))));

            testCase.assertEqual(0, err4a, 'AbsTol', 0.01)
        end

        function test_CalcRetarFormCircPolPS8(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_CalcRetarFormCircPolPS8')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            NR=568;
            NC=576;

            [delta, w2alpha, sx, sy, sxy, s1, s2, M]=UtilFunFPA.StressDisk(NR, NC); %#ok<ASGLU>

            %this are the angles for the clasical 8 steps
            %P Q1 Q2 A
            steps={[ 90 45  45 -45]
                [ 90 45 -45  45]
                [ 90 45 -45   0]
                [ 90 45  45   0]
                [-45 90  90   0]
                [-45 90  90  90]
                [-45 90   0  45]
                [-45 90  90  45]};

            N=length(steps);
            phi=zeros(1, N);
            psi=zeros(1,N);
            for n=1:N
                PQQA=steps{n};
                phi(n)=pi*PQQA(3)/180;
                psi(n)=pi*PQQA(4)/180;
            end

            gList=UtilFunFPA.CircPol(delta, w2alpha, psi, phi, M);

            I=cell(1,8);
            I{1} = M.*(0.5*(1+cos(w2alpha).*sin(delta)));
            I{2} = M.*(0.5*(1-cos(w2alpha).*sin(delta)));
            I{3} = M.*(0.5*(1-cos(delta)));
            I{4} = M.*(0.5*(1+cos(delta)));

            I{5} = M.*(0.5*(1+sin(w2alpha).*sin(delta)));
            I{6} = M.*(0.5*(1-sin(w2alpha).*sin(delta)));
            I{7} = M.*(0.5*(1-cos(delta)));
            I{8} = M.*(0.5*(1+cos(delta)));

            for n=1:N
                testCase.assertEqual(I{n}, gList{n}, 'AbsTol', 100*eps);
            end

            num=(gList{1}-gList{2}).*cos(w2alpha)+(gList{5}-gList{6}).*sin(w2alpha);
            dem=0.5*((gList{4}-gList{3})+(gList{8}-gList{7}));
            wdelta = M.*atan2(num,dem);
            imagesc(wdelta); colormap jet;

            testCase.assertEqual(wdelta, angle(exp(1i*delta)), 'AbsTol', 100*eps);
        end

        function test_Temp1DFFTDemod(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_Temp1DFFTDemod')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            N=1000; %samples
            w0=pi/16; %in rads/px
            t=0:N-1;

            p=t*w0;

            % backgroung of BF fringes field
            BF=2;
            b=2+cos(2*pi*t*BF/N);

            g=b+cos(p);

            %default use
            z=UtilFunFPA.Temp1DFFTDemod(g, 2*BF);

            figure; plot(t, g);
            figure; plot(t, angle(z), t, angle(exp(1i*p)));

            zd=z./exp(1i*p);
            testCase.assertTrue(std(angle(zd))<0.11);

            %usamos u0 y sigma
            %pasamos w0 a FF
            u0=w0*N/(2*pi);
            sigma=5; %FF
            z=UtilFunFPA.Temp1DFFTDemod(g, 2*BF, u0, sigma);

            figure; plot(t, g);
            figure; plot(t, angle(z), t, angle(exp(1i*p)));

            zd=z./exp(1i*p);
            testCase.assertTrue(std(angle(zd))<0.15);
        end

        function test_DerOpsFreeBoundary1D(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'test_DerOpsFreeBoundary1D')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            N=10;
            [Dx, Dxx, Dxxx]=UtilFunFPA.DerOpsFreeBoundary1D(N);

            [NR, NC]=size(Dx);
            testCase.assertEqual([N-1, N], [NR, NC]);

            [NR, NC]=size(Dxx);
            testCase.assertEqual([N-2, N], [NR, NC]);

            [NR, NC]=size(Dxxx);
            testCase.assertEqual([N-3, N], [NR, NC]);

            A=[ -1     1     0     0     0     0     0     0     0     0
                0    -1     1     0     0     0     0     0     0     0
                0     0    -1     1     0     0     0     0     0     0
                0     0     0    -1     1     0     0     0     0     0
                0     0     0     0    -1     1     0     0     0     0
                0     0     0     0     0    -1     1     0     0     0
                0     0     0     0     0     0    -1     1     0     0
                0     0     0     0     0     0     0    -1     1     0
                0     0     0     0     0     0     0     0    -1     1];

            testCase.assertEqual(A, full(Dx));

            A=[ 1    -2     1     0     0     0     0     0     0     0
                0     1    -2     1     0     0     0     0     0     0
                0     0     1    -2     1     0     0     0     0     0
                0     0     0     1    -2     1     0     0     0     0
                0     0     0     0     1    -2     1     0     0     0
                0     0     0     0     0     1    -2     1     0     0
                0     0     0     0     0     0     1    -2     1     0
                0     0     0     0     0     0     0     1    -2     1];

            testCase.assertEqual(A, full(Dxx));

            A=[ 1    -4     6    -4     1     0     0     0     0     0
                0     1    -4     6    -4     1     0     0     0     0
                0     0     1    -4     6    -4     1     0     0     0
                0     0     0     1    -4     6    -4     1     0     0
                0     0     0     0     1    -4     6    -4     1     0
                0     0     0     0     0     1    -4     6    -4     1
                0     0     0     0     0     0     1    -4     6    -4];

            testCase.assertEqual(A, full(Dxxx));
        end

        function testunwrapRLS1DPeaks(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testunwrapRLS1DPeaks')
            close all;

            N=512;
            f=peaks(N);
            [x,y]=meshgrid(1:N, 1:N); x=x-0.5*N; y=y-0.5*N;
            fm=abs(x+1i*y)>0.1*N;

            %fila y columnas
            c=1:N;
            R=round(0.5*N);

            z=fm(R,:).*exp(1i*f(R, :));

            %primero Dxxx
            lambda=10;
            regMode='Dxxx';
            u=UtilFunFPA.unwrapRLS1D(z, lambda, regMode);
            u_err=angle(exp(1i*u)./transpose(z));

            figure; plot(c, u, c, f(R, :),c, fm(R, :));title(regMode)
            figure; plot(c, u_err);title(regMode)

            %primero thin plate Dxx
            lambda=1;
            regMode='thinplate';
            u=UtilFunFPA.unwrapRLS1D(z, lambda, regMode);
            u_err=angle(exp(1i*u)./transpose(z));

            figure; plot(c, u, c, f(R, :),c, fm(R, :));title(regMode)
            figure; plot(c, u_err);title(regMode)

            %segundo 'membrane' Dx
            lambda=0.001;
            regMode='membrane';
            u=UtilFunFPA.unwrapRLS1D(z, lambda, regMode);
            u_err=angle(exp(1i*u)./transpose(z));

            figure; plot(c, u, c, f(R, :), c, fm(R, :));title(regMode)
            figure; plot(c, u_err);title(regMode)
        end

        function testPCADemodPeaks(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testPCADemodPeaks')
            close all;

            NR=480;
            NC=640;
            NFPs=8;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);

            %generamos difernetes tipos de saltos
            delta=2*pi*(0:NFPs-1)'/NFPs; %lineales crecientes, la salida del PCA sale con orden OK

            p=4*peaks(max(NR, NC)); p=imresize(p, [NR, NC]);

            gList=cell(1, NFPs);
            for n=1:NFPs
                gList{n}=M.*(1+cos(p+delta(n)));
            end

            [z, deltaPCA] = UtilFunFPA.PCADemod(gList, M);

            pd=angle(exp(-1i*p(M)).*z(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error - ')

            pd=angle(exp(1i*p(M)).*z(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error + ')

            figure; imagesc(angle(z)); title('PCA phase map');

            %si sabemos que delta son crecientes con ordenar deltaPCA sale el resultado
            %OK (tb habria que reordenar los indices)
            figure; plot(1:NFPs, delta, 1:NFPs, deltaPCA); legend('delta', 'deltaPCA'); title('phase shifts')

            %plot polar
            figure; polar(sort(deltaPCA), ones(NFPs,1), '*');
            hold on
            polar(delta, ones(NFPs,1), 'o');
            legend('delta', 'deltaPCA'); title('phase shifts')
        end

        function testPCADemodPeaksMonotonicDeltas(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testPCADemodPeaksMonotonicDeltas')
            close all;

            NR=480;
            NC=640;
            NFPs=10;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);

            %generamos difernetes tipos de saltos
            delta=2*pi*rand(NFPs,1 ); delta=sort(delta); %arbitrarios pero crecientes podemos ordenadar la salida del PCA

            p=4*peaks(max(NR, NC)); p=imresize(p, [NR, NC]);

            gList=cell(1, NFPs);
            for n=1:NFPs
                gList{n}=M.*(1+cos(p+delta(n)));
            end

            [z, deltaPCA] = UtilFunFPA.PCADemod(gList, M);

            pd=angle(exp(-1i*p(M)).*z(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error - ')

            pd=angle(exp(1i*p(M)).*z(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error + ')

            figure; imagesc(angle(z)); title('PCA phase map');
            figure; imagesc(angle(exp(1i*p).*M)); title('Ground truth phase map');

            %si sabemos que delta son crecientes con ordenar deltaPCA sale el resultado
            %OK (tb habria que reordenar los indices)
            figure; plot(1:NFPs, delta, 1:NFPs, deltaPCA); legend('delta', 'deltaPCA'); title('phase shifts')

            %plot polar
            figure; polar(sort(deltaPCA), ones(1,NFPs)', '*');
            hold on
            polar(delta, ones(1,NFPs)', 'o');
            legend('delta', 'deltaPCA'); title('phase shifts')
        end

        function testPCADemodSaturation(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testPCADemodSaturation')
            close all;

            NR=480;
            NC=640;
            NFPs=6;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);

            %generamos difernetes tipos de saltos
            delta=2*pi*(0:NFPs-1)'/NFPs; %lineales crecientes, la salida del PCA sale con orden OK

            p=2*pi*10*x/NC;
            [px, py]=gradient(p); %#ok<ASGLU>

            gList=cell(1, NFPs);
            th=1;
            for n=1:NFPs
                g=1+cos(p+delta(n));
                gM=g>th; g(gM)=th; %mochamos los maximos
                gList{n}=M.*g;
            end

            [z, deltaPCA] = UtilFunFPA.PCADemod(gList, M); %#ok<ASGLU>

            figure; imagesc(gList{n}.*M./M, [0,2]); title('igram')

            pd=angle(exp(-1i*(p(M)+pi)).*z(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error - ')

            pd=angle(exp(1i*p(M)).*z(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error + ')

            figure; imagesc(angle(z)); title('PCA phase map'); colormap gray;
            figure; imagesc(M.*angle(exp(1i*p))); title('Actual phase map'); colormap gray;
            figure; imagesc(M.*angle(exp(1i*p-1i*angle(z)))); title('phase map error'); colormap gray; colorbar
            r=round(NR*0.5); pz=angle(z);
            figure; plot(1:NC, pz(r,:), 1:NC, angle(exp(1i*p(r, :).*M(r,:)))); legend('PCA', 'Actual');

            [pzx, pzy, Mxy]=UtilFunFPA.phaseGradientDirect(z, M, 1, 1); %#ok<ASGLU>

            Dpx=(pzx-px)./px; %relative error
            figure; imagesc(100*Dpx.*Mxy./Mxy); title('\Delta(Dx)% PCA phase map'); colorbar;

            x=linspace(-50, 50, 50);
            h=hist(100*Dpx(Mxy), x);
            figure; plot(x,h); title('\Delta(Dx)% ')
        end

        function testAIADemodPeaks(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testAIADemodPeaks')
            close all;

            NR=480;
            NC=640;
            NFPs=20;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);

            %generamos difernetes tipos de saltos
            delta=2*pi*rand(NFPs,1 ); delta=sort(delta); %arbitrarios pero crecientes podemos ordenadar la salida del PCA

            p=4*peaks(max(NR, NC)); p=imresize(p, [NR, NC]);

            gList=cell(1, NFPs);
            for n=1:NFPs
                gList{n}=M.*(1+cos(p+delta(n)));
            end

            [zAIA, deltaAIA] = UtilFunFPA.AIADemod(gList, M);

            pd=angle(exp(-1i*p(M)).*zAIA(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error - ')

            pd=angle(exp(1i*p(M)).*zAIA(M));
            x=linspace(-pi, pi, 100);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error + ')

            figure; imagesc(angle(zAIA)); title('AIA phase map');

            %si sabemos que delta son crecientes con ordenar deltaPCA sale el resultado
            %OK (tb habria que reordenar los indices)
            figure; plot(1:NFPs, delta, 1:NFPs, deltaAIA); legend('delta', 'deltaAIA'); title('phase shifts')

            %plot polar
            figure; polar(sort(delta), ones(NFPs,1), '*');
            hold on
            polar(deltaAIA, ones(NFPs,1), 'o');
            legend('delta', 'deltaAIA'); title('phase shifts')
        end

        function testAIADemodSaturation(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testAIADemodSaturation')
            close all;

            NR=480;
            NC=640;
            NFPs=36;

            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            M=abs(x+1i*y)<0.25*min(NR, NC);

            %generamos difernetes tipos de saltos
            delta=2*pi*(0:NFPs-1)'/NFPs; %lineales crecientes, la salida del PCA sale con orden OK

            p=2*pi*10*x/NC;
            [px, py]=gradient(p); %#ok<ASGLU>

            gList=cell(1, NFPs);
            th=1;
            for n=1:NFPs
                g=1+cos(p+delta(n))+0.1*randn(size(p));
                gM=g>th; g(gM)=th; %mochamos los maximos
                g=gM; %binarizamos
                gList{n}=M.*g;
            end

            [z, deltaAIA] = UtilFunFPA.AIADemod(gList, M, delta); %#ok<ASGLU>

            figure; imagesc(gList{n}.*M./M, [0,2]); title('igram')

            pd=angle(exp(-1i*p(M)).*z(M));
            x=linspace(-pi, pi, 500);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error - ')

            pd=angle(exp(1i*p(M)).*z(M));
            x=linspace(-pi, pi, 500);
            h=hist(pd, x);
            figure; plot(x,h); title('phase error + ')

            figure; imagesc(M.*angle(z)); title('AIA phase map'); colormap gray;
            figure; imagesc(M.*angle(exp(1i*p))); title('Ground truth phase map'); colormap gray;
            figure; imagesc(M.*angle(exp(1i*p-1i*angle(z)))); title('phase map error'); colormap gray; colorbar
            r=round(NR*0.5); pz=angle(z);
            figure; plot(1:NC, pz(r,:), 1:NC, angle(exp(1i*p(r, :).*M(r,:)))); legend('PCA', 'Actual');

            [pzx, pzy, Mxy]=UtilFunFPA.phaseGradientDirect(z, M, 1, 1); %#ok<ASGLU>

            Dpx=(pzx-px)./px; %relative error
            figure; imagesc(100*Dpx.*Mxy./Mxy); title('\Delta(Dx)% AIA phase map'); colorbar;

            x=linspace(-50, 50, 50);
            h=hist(100*Dpx(Mxy), x);
            figure; plot(x,h); title('\Delta(Dx)% ')
        end

        function testNormalizaIgramFFT(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testNormalizaIgramFFT')
            close all;
            gc=double(imread('DeltaDisFluoCDF.tif'));
            roiMask=double(imread('Mask_Puente1_fluorescencia.tif')); %#ok<NASGU>
            [NR, NC, NP]=size(gc); %#ok<ASGLU>

            R=3; %filtramos hasta 3FF
            for n=1:3
                g=double(gc(:, :, n));
                [gn, gmod]=UtilFunFPA.IgramNorm(g, R);
                figure; imagesc(gn); title(['Canal: ' num2str(n)]);
                figure; imagesc(mat2gray(-gmod)); title(['Canal: ' num2str(n)]);
                c=1:NC; r=round(0.5*NR);
                figure; plot(c, gn(r, c)); title(['Canal: ' num2str(n)]);
            end
        end

        function testOrientationFromMinimumDerShadowMoire(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testOrientationFromMinimumDerShadowMoire')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura orientacion from gradiente
            g=double((imread('shadowMoireDefect_01.tif')));
            g=imresize(g, 1.5);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=1:20:NR; C=1:30:NC;

            N=35;
            %numerical orientation Min diff
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N); %#ok<ASGLU>

            ngx=cos(orn);
            ngy=-sin(orn);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), g, [-1.5*min(g(:)) 1.5*max(g(:))]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',3, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',3, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',3, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',3, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);
        end

        function testOrientationFromMinimumDerMiract(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testOrientationFromMinimumDerMiract')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura orientacion from gradiente
            g=double((imread('miract_crop.jpg')));
            g=imresize(g, 1.5);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=1:20:NR; C=1:30:NC;

            N=35;
            %numerical orientation Min diff
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            ngx=cos(orn);
            ngy=-sin(orn);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), g, [-1.5*min(g(:)) 1.5*max(g(:))]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            figure;
            imagesc(ornMod); colormap gray; axis off, axis image;
            title(['C5_' callfun '_orientation Mod']);
        end

        function testOrientationFromMinimumDerSignalTapa(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testOrientationFromMinimumDerSignalTapa')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura orientacion from gradiente
            g=double((imread('Signal_tapa.tif')));

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=1:20:NR; C=1:30:NC;

            N=20;
            %numerical orientation Min diff
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            ngx=cos(orn);
            ngy=-sin(orn);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), g, [-1.5*min(g(:)) 1.5*max(g(:))]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',1, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            figure;
            imagesc(ornMod); colormap gray; axis off, axis image;
            title(['C5_' callfun '_orientation Mod']);
        end

        function testDirectionShadowMoire(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDirectionShadowMoire')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('shadowMoireDefect_01.tif')));
            g=imresize(g, 1.5);

            N=35;
            %numerical orientation Min diff
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            q=ornMod;
            m=ones(size(g));
            t=5;
            mu=1;
            r0=[];
            [dirn]=UtilFunFPA.calcDirection(orn,q,m,t,mu,r0); dirn=dirn+pi;
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);
        end

        function testDirectionMiract(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDirectionMiract')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('miract_crop.jpg')));
            gm=double((imread('miract_cropMask.tif')));

            N=35;
            %numerical orientation Min diff
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            q=ornMod;
            m=mat2gray(gm);
            t=5;
            mu=1;
            r0=[];
            [dirn]=UtilFunFPA.calcDirection(orn,q,m,t,mu,r0); dirn=dirn+pi;
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);
        end

        function testDirectionDeltaDisNa(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDirectionDeltaDisNa')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('Delta7DisNa.tif'))); g=g(:, :, 1); %red channel

            gm=double((imread('Delta7DisNaMask.jpg')));

            N=35;
            %numerical orientation Min diff
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            q=ornMod;
            m=mat2gray(gm);
            t=5;
            mu=1;
            r0=[];
            [dirn]=UtilFunFPA.calcDirection(orn,q,m,t,mu,r0); dirn=dirn+pi;
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);
        end

        function testDemIQTSignalTapaWithDirection(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemIQTSignalTapaWithDirection')
            %in this test we use DemIQT with Direction
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('Signal_tapa.tif'))); g=g(:, :, 1); %red channel
            gm=ones(size(g));

            % default onlyOrFlag=false, R= 2 FF, N = 5 px, Lambda= 1
            onlyOrFlag=false;
            R=2;
            N=20;
            [z, zor, zdir]=UtilFunFPA.DemIQT(g,gm, onlyOrFlag, R, N);

            %orientation Min diff
            orn=angle(zor);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            dirn=angle(zdir);
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %demodulated phase
            pw=angle(z);
            figure;
            imagesc(pw.*mat2gray(gm)); colormap gray; axis off, axis image;
            title(['C5_' callfun 'wrapped phase']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(pw, gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(pu.*mat2gray(gm)); colormap jet; axis off, axis image;
            title(['C5_' callfun 'Unwrapped phase'])
        end

        function testDemIQTSignalTapaWithOrientation(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemIQTSignalTapaWithOrientation')
            %in this test we use DemIQT with Orientarion Only.
            %This is OK only for open fringes
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('Signal_tapa.tif'))); g=g(:, :, 1); %red channel
            %check for diffrent orientations
            g=g';
            gm=ones(size(g));

            % default onlyOrFlag=false, R= 2 FF, N = 5 px, Lambda= 1
            onlyOrFlag=true;
            R=2;
            N=20;
            [z, zor, zdir]=UtilFunFPA.DemIQT(g,gm, onlyOrFlag, R, N);

            %upgrade mask
            gm=gm.*mat2gray(abs(zor))>0.3;

            %orientation Min diff
            orn=angle(zor);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            dirn=angle(zdir);
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %demodulated phase
            pw=angle(z);
            figure;
            imagesc(pw.*mat2gray(gm)); colormap gray; axis off, axis image;
            title(['C5_' callfun 'wrapped phase']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1

            %process
            u.Process(pw, gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(mat2gray(gm).*pu); colormap jet; axis off, axis image;
            title(['C5_' callfun 'Unwrapped phase'])
        end

        function testDemIQTDeltaDisNa(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemIQTDeltaDisNa')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('Delta7DisNa.tif'))); g=g(:, :, 1); %red channel
            gm=double((imread('Delta7DisNaMask.jpg')));

            % R= 2 FF, N = 5 px, Lambda= 1
            [z, zor, zdir]=UtilFunFPA.DemIQT(g,gm);

            %orientation Min diff
            orn=angle(zor);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            dirn=angle(zdir);
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %demodulated phase
            pw=angle(z);
            figure;
            imagesc(pw.*mat2gray(gm)); colormap gray; axis off, axis image;
            title(['C5_' callfun 'wrapped phase']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(pw, gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(mat2gray(gm).*pu); colormap jet; axis off, axis image;
            title(['C5_' callfun 'Unwrapped phase'])
        end

        function testDemIQTMiract(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemIQTMiract')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('miract_crop.jpg')));
            gm=double((imread('miract_cropMask.tif')));

            % R= 2 FF, N = 5 px, Lambda= 1
            [z, zor, zdir]=UtilFunFPA.DemIQT(g,gm);

            %orientation Min diff
            orn=angle(zor);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            dirn=angle(zdir);
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %demodulated phase
            pw=angle(z);
            figure;
            imagesc(pw.*gm); colormap gray; axis off, axis image;
            title(['C5_' callfun 'wrapped phase']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(pw, gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(gm.*pu); colormap jet; axis off, axis image;
            title(['C5_' callfun 'Unwrapped phase']);
        end

        function testDemIQTShadowMoire(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemIQTShadowMoire')
            close all
            iptsetpref('ImshowBorder','tight');
            iptsetpref('ImtoolInitialMagnification','fit');
            callfun=mfilename;

            %% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
            clc;

            g=double((imread('shadowMoireDefect_01.tif')));
            gm=ones(size(g));

            % onlyOrFlag=false, R= 2 FF, N = 5 px, Lambda= 1
            [z, zor, zdir]=UtilFunFPA.DemIQT(g, gm);

            %orientation Min diff
            orn=angle(zor);

            %numerical orientation
            ngx=cos(orn);
            ngy=-sin(orn);

            %direction VFR
            dirn=angle(zdir);
            px=-cos(dirn);
            py=sin(dirn);

            [NR, NC]=size(g);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            R=2:20:NR; C=2:20:NC;

            %direccion vectors sobre mapa de direccion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(dirn, 2*pi), [0 2*pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_angle']);

            %direccion vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0]);
            quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1]);

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_direction_vector']);

            %orientation vectors sobre mapa de orientacion
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mod(orn, pi), [0 pi+0.2]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_angle']);

            %orientation vectors sobre patron de franjas
            figure;
            imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5 1.5]); colormap gray; axis off, axis image;
            hold on;
            %no se pq, si se quieren las flechas blancas 1ro hay que pintarlas de otro color
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[0 0 0])
            quiver(x(R,C),y(R,C), ngx(R,C), ngy(R,C), 'LineWidth',2, 'AutoScaleFactor',0.6, 'Color',[1 1 1])

            set(gcf,'color','w'); %set border to white to hide eps crop errors
            title(['C5_' callfun '_orientation_vector']);

            %demodulated phase
            pw=angle(z);
            figure;
            imagesc(pw); colormap gray; axis off, axis image;
            title(['C5_' callfun 'wrapped phase']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(pw, gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(pu); colormap jet; axis off, axis image;
            title(['C5_' callfun 'Unwrapped phase']);
        end

        function testDemPSAsync5TunOrientedShadowMoire(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemPSAsync5TunOrientedShadowMoire')
            g=double((imread('shadowMoireDefect_01.tif')));
            gm=ones(size(g));

            figure; imagesc(g); colormap(gray); colorbar; title(['fringe pattern ' ]);

            % Demodulacion 5PS sintonizable
            NS=7; %seis niveles para el adpativo
            strDir='horz';
            [zx, Delta] = UtilFunFPA.DemPSAsync5TunOriented(g, NS, strDir);

            figure; imagesc(angle(zx)); colormap(gray); colorbar; title(['Phase ' strDir] );

            figure; imagesc(abs(zx)); colormap(gray); colorbar; title(['Modulacion ' strDir]);

            figure; imagesc(Delta); colorbar; title(['adaptive steps ' strDir]);

            strDir='vert';
            [zy, Delta] = UtilFunFPA.DemPSAsync5TunOriented(g, NS, strDir);

            figure; imagesc(angle(zy)); colormap(gray); colorbar; title(['Phase ' strDir] );

            figure; imagesc(abs(zy)); colormap(gray); colorbar; title(['Modulacion ' strDir]);

            figure; imagesc(Delta); colorbar; title(['adaptive steps ' strDir]);

            %numerical orientation Min diff
            N=5;
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            z1=real(zx+zy)+1i*(imag(zx).*cos(orn) - imag(zy).*sin(orn));

            figure; imagesc(angle(z1)); colormap(gray); colorbar;  title(['Phase XY']);

            %direction VFR
            q=ornMod;
            m=mat2gray(gm);
            t=5;
            mu=1;
            r0=[];
            [dirn]=UtilFunFPA.calcDirection(orn,q,m,t,mu,r0); dirn=dirn+pi;

            z2=real(zx+zy)+1i*(imag(zx).*cos(dirn) - imag(zy).*sin(dirn));

            figure; imagesc(angle(z2)); colormap(gray); colorbar;  title(['Phase XY']);
        end

        function testDemAsync5TunOriented1DSignal(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemAsync5TunOriented1DSignal')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            N=500;
            t=1:N;
            w0=pi/100;
            p=2*pi*w0*t;

            g=10+10*cos(p);

            %row signal
            NLevels=8;
            [z, Delta] = UtilFunFPA.DemPSAsync5TunOriented(g,NLevels); %#ok<ASGLU>

            %error phasor
            zd=exp(1i*p)./z;
            ad=angle(zd);
            phaseErr=std(ad(NLevels:N-NLevels-1));
            tol=1e-1;
            testCase.assertEqual(phaseErr, 0, 'AbsTol', tol);

            %column signal
            try
                [~, ~] = UtilFunFPA.DemPSAsync5TunOriented(g',NLevels);
            catch ME
                testCase.assertEqual(ME.message, 'UtilFunFPA.DemPSAsync5TunOriented->for 1D signals, g must be a row-vector and dirDemod=''horz'' (default value)');
            end
        end

        function testDemAsync5TunShadowMoire(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemAsync5TunShadowMoire')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            g=double((imread('shadowMoireDefect_01.tif')));
            gm=ones(size(g));

            figure; imagesc(g); colormap(gray); colorbar; title(['fringe pattern ' ]);

            % Demodulacion 5PS tuneada espacialmente
            [z, ~, ~, Delta] = UtilFunFPA.DemAsinc5Tun(g, gm);

            figure; imagesc(angle(z)); colormap(gray); colorbar; title(['Phase '] );

            figure; imagesc(abs(z)); colormap(gray); colorbar; title(['Modulacion ' ]);

            figure; imagesc(abs(Delta)); colorbar; title(['decimation levels']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(angle(z), gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(pu.*mat2gray(gm)); colormap jet; axis off, axis image;
            title(['Unwrapped phase']);
        end

        function testDemPSAsync5TunOrientedMiract(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemPSAsync5TunOrientedMiract')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            g=double((imread('miract_crop.jpg')));
            gm=double((imread('miract_cropMask.tif')));

            figure; imagesc(g); colormap(gray); colorbar; title(['fringe pattern ' ]);

            % Demodulacion 5PS sintonizable
            NS=7; %seis niveles para el adpativo
            strDir='horz';
            [zx, Delta] = UtilFunFPA.DemPSAsync5TunOriented(g, NS, strDir);

            figure; imagesc(angle(zx)); colormap(gray); colorbar; title(['Phase ' strDir] );

            figure; imagesc(abs(zx)); colormap(gray); colorbar; title(['Modulacion ' strDir]);

            figure; imagesc(Delta); colorbar; title(['adaptive steps ' strDir]);

            strDir='vert';
            [zy, Delta] = UtilFunFPA.DemPSAsync5TunOriented(g, NS, strDir);

            figure; imagesc(angle(zy)); colormap(gray); colorbar; title(['Phase ' strDir] );

            figure; imagesc(abs(zy)); colormap(gray); colorbar; title(['Modulacion ' strDir]);

            figure; imagesc(Delta); colorbar; title(['adaptive steps ' strDir]);

            %numerical orientation Min diff
            N=35;
            [orn, ornMod]=UtilFunFPA.OrMinDer(g, N);

            z1=real(zx+zy)+1i*(imag(zx).*cos(orn) - imag(zy).*sin(orn));

            figure; imagesc(angle(z1)); colormap(gray); colorbar;  title(['Phase XY Orientacion']);

            %direction VFR
            q=ornMod;
            m=mat2gray(gm);
            t=5;
            mu=1;
            r0=[];
            [dirn]=UtilFunFPA.calcDirection(orn,q,m,t,mu,r0); dirn=dirn+pi;

            z2=real(zx+zy)+1i*(imag(zx).*cos(dirn) - imag(zy).*sin(dirn));

            figure; imagesc(angle(z2)); colormap(gray); colorbar;  title(['Phase XY Direccion']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z2, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(angle(z2), gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(mat2gray(gm).*pu); colormap jet; axis off, axis image;
            title(['Unwrapped phase']);
        end

        function testDemAsync5TunMiract(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemAsync5TunMiract')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            g=double((imread('miract_crop.jpg')));
            gm=double((imread('miract_cropMask.tif')));

            figure; imagesc(g); colormap(gray); colorbar; title(['fringe pattern ' ]);

            % Demodulacion 5PS tuneada espacialmente
            [z, ~, ~, Delta] = UtilFunFPA.DemAsinc5Tun(g, gm);

            figure; imagesc(angle(z)); colormap(gray); colorbar; title(['Phase '] );

            figure; imagesc(abs(z)); colormap(gray); colorbar; title(['Modulacion ' ]);

            figure; imagesc(abs(Delta)); colorbar; title(['decimation levels']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(angle(z), gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(pu.*mat2gray(gm)); colormap jet; axis off, axis image;
            title([' Unwrapped phase']);
        end

        function testDemAsync5TunDisk(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testDemAsync5TunDisk')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            g=double((imread('Delta7DisNa.tif'))); g=g(:, :, 1); %red channel
            gm=double((imread('Delta7DisNaMask.jpg')));

            figure; imagesc(g); colormap(gray); colorbar; title(['fringe pattern ' ]);

            % Demodulacion 5PS tuneada espacialmente
            [z, ~, ~, Delta] = UtilFunFPA.DemAsinc5Tun(g, gm);

            figure; imagesc(angle(z)); colormap(gray); colorbar; title(['Phase '] );

            figure; imagesc(abs(z)); colormap(gray); colorbar; title(['Modulacion ' ]);

            figure; imagesc(abs(Delta)); colorbar; title(['decimation levels']);

            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);

            qualPhasor=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            %process
            u.Process(angle(z), gm, qualPhasor);

            %get results
            pu=u.Get(char(UnwrapperProps.unw));
            figure;
            imagesc(pu.*mat2gray(gm)); colormap jet; axis off, axis image;
            title([' Unwrapped phase']);
        end

        function testHomography_solve(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testHomography_solve')
            % here we show how the function homography solve workd
            % the funcion was downloaded from
            % https://es.mathworks.com/matlabcentral/answers/26141-homography-matrix
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all

            %% Homography calculation for same input and output
            pin=rand(2, 10);
            pout=pin;

            H = UtilFunFPA.homography_solve(pin, pout);

            tol=1e-7;
            testCase.assertEqual(H/H(3,3), eye(3), 'AbsTol', tol);

            fprintf('\nthis Homography must be diagonal:\n');
            disp(H/H(3,3))
            fprintf('\n');

            pout1=UtilFunFPA.homography_transform(pin, H);

            testCase.assertEqual(pout1, pout, 'AbsTol', tol);

            fprintf('\nAll points in PLOT1 must coincide:\n');
            figure; plot(pout(1, :), pout(2,:), '+', pout1(1, :), pout1(2,:), 'o');
            legend({'pout original', 'pout transformados'});
            title('PLOT1')
            figure(gcf)

            %% Homography calculation for random input and output with inverse
            clear pin pout;

            %H=  3.0000   -1.0000    4.0000
            %   -5.0000    4.0000    1.0000
            %   -0.0000    0.0000    1.0000

            pin=rand(2, 10);
            pout(1, :)=3*pin(1, :)-1*pin(2, :)+4;
            pout(2, :)=4*pin(2, :)-5*pin(1, :)+1;

            H = UtilFunFPA.homography_solve(pin, pout);

            pout1=UtilFunFPA.homography_transform(pin, H);

            %H must be Hr
            Hr=[ 3 -1  4
                -5  4  1
                0  0  1];

            testCase.assertEqual(H/H(3,3), Hr, 'AbsTol', tol);

            testCase.assertEqual(pout1, pout, 'AbsTol', tol);

            fprintf('\nAll points in PLOT2 must coincide:\n');
            figure; plot(pout(1, :), pout(2,:), '+', pout1(1, :), pout1(2,:), 'o');
            legend({'pout original', 'pout transformados'});
            title('PLOT2');
            figure(gcf)

            %ahora usamos la homografia inversa
            pin1=UtilFunFPA.homography_transform(pout, inv(H));

            testCase.assertEqual(pin1, pin, 'AbsTol', tol);

            fprintf('\nAll points in PLOT3 must coincide:\n');
            figure; plot(pin(1, :), pin(2,:), '+', pin1(1, :), pin1(2,:), 'o');
            legend({'pin original', 'pin transformados'});
            title('PLOT3');
            figure(gcf)

            %% Non-linear transformation. Homography calculation for random input and output with inverse
            clear pin pout;

            Hr=[ 3.0000   -1.0000    4.0000
                -5.0000    4.0000    1.0000
                -0.0000    0.0000    1.0000];

            pin=rand(2, 10);
            pout(1, :)=3*pin(1, :)-1*pin(2, :)+0.5*pin(1, :).^2+4;
            pout(2, :)=4*pin(2, :)-5*pin(1, :)+0.5*pin(2, :).^2+1;

            H = UtilFunFPA.homography_solve(pin, pout);

            pout1=UtilFunFPA.homography_transform(pin, H);

            fprintf('\nAll points in PLOT4 must ALMOST coincide:\n');
            figure; plot(pout(1, :), pout(2,:), '+', pout1(1, :), pout1(2,:), 'o');
            legend({'pout original', 'pout transformados'});
            title('PLOT4 Non-linear');
            figure(gcf)

            fprintf('\nthis two Homographies are ALMOST equal:\n');

            disp(H/H(3,3))
            fprintf('\n');
            disp(Hr)
            fprintf('\n');

            %using Hinv
            pin1=UtilFunFPA.homography_transform(pout, inv(H));
            fprintf('\nAll points in PLOT5 ALMOST coincide:\n');
            figure; plot(pin(1, :), pin(2,:), '+', pin1(1, :), pin1(2,:), 'o');
            legend({'pin original', 'pin transformados'});
            title('PLOT5 non-linear');
            figure(gcf)
        end

        %% Ported from tests/testTFM_VdH.m (VictorDelHierro TFM 2020-21), 2026-09-14.
        % See DECISIONS.md ("Grupo 2 hardcoded refs" / testTFM_VdH.m integration) and
        % memory hardcoded_refs_group_2. Fixture data copied from the original TFM
        % Dropbox folder ("Respuesta lineal") to
        % fixturesRoot()/Datos_LinearzationGV_TFM_20-21-VdHG. Camera-driven tests
        % moved to the Hardware methods block below.

        function testLimitsGV4LinearResponse(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testLimitsGV4LinearResponse')

            %Este test verifica la respuesta lineal sin necesidad de emplear la
            %cámara, mediante los ficheros previamente generados en
            %testCalculateResponseFromImages (Hardware, ver más abajo).

            dropboxFolder=fixturesRoot();
            baseFolder='Datos_LinearzationGV_TFM_20-21-VdHG';
            filenameList = {'TrasmDeflConfigDGV1.json','TrasmDeflConfigDGV2.json','TrasmDeflConfigDGV5.json','TrasmDeflConfigDGV10.json','TrasmDeflConfigDGV15.json','TrasmDeflConfigDGV25.json','TrasmDeflConfigDGV5D10.json'};
            njson = 2; %cambiar para elegir el json deseado - solo DGV2 y DGV15 son fixtures disponibles
            loadJ = loadjson(fullfile(dropboxFolder, baseFolder, filenameList{njson}));

            fileNameList = {'ImgGV_5_good','ImgGV_5_bad1','ImgGV_5_bad3','ImgGV','ImgGV_bad2','ImgGV_318-Feb-2021','ImgGV_3','ImgGV_1__25-Feb-2021','ImgGV_15__25-Feb-2021','ImgGV_5__25-Feb-2021'};
            fileName = fullfile(dropboxFolder, baseFolder, fileNameList{2}); %solo ImgGV_5_bad1 es fixture disponible
            load(fileName);
            uvs=[us',vs'];
            NGV = 256;
            S=UtilFunFPA.LinLUTGV(uvs, 'D', 2);
            %Variables de UtilFunFPA.LunLUTGV:
            %Hv = S.Hv;
            Tu=S.Tu;
            Hu=S.Hu;
            u0 = S.u0;
            u1 = S.u1;
            v0 =S.v0;
            v1 = S.v1;
            Lu = S.Lu;
            u = 0:NGV-1;
            ONEOFFSET=1;
            fprintf('u0 = %d, u1 = %d, v0 = %d, v1 = %d',u0, u1, v0, v1);
            %Representamos:
            k=(S.u0:S.u1)+ONEOFFSET;

            %Cargamos el json
%             loadJ = loadjson('TrasmDeflConfig2.json');
            GVresp = UtilFunFPA.LinLUTGV(uvs, 'D', 2);
            loadJ.GVresp = GVresp;
            loadJ.GVresp.Tu = Tu;
            loadJ.GVresp.u1 = u1;
            loadJ.GVresp.u0 = u0;
%             %Guardamos los valores de LinLUTGV en TrasmDeflConfig1.json
%             filesave = 'TrasmDeflConfig1.json';
%             filesave1 = 'TrasmDeflConfig1.json'
%             savejson('',loadJ,filesave1);

            figure; plot(us, vs,'+', u, Hu,'-',u(k),Lu(k)); legend({'H(u) medida', 'H(u) interpol','L(u0:u1)'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV]);
            figure; plot(u, Tu, u(k), Tu(k), '+'); legend({'T(u)', 'T(u0:u1)'}); xlabel('u'); ylabel('T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV-1]);
            figure; plot(u, Hu(ONEOFFSET+Tu),u(k), Hu(ONEOFFSET+Tu(k)),'+'); legend({'H(T(u))','H(T(u0:u1)'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV]);

        end

        function testArgumentsLinLUTGV(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testArgumentsLinLUTGV')

            dropboxFolder=fixturesRoot();
            baseFolder='Datos_LinearzationGV_TFM_20-21-VdHG';
            fileNameList = {'ImgGV_5_bad1'};
            fileName = fullfile(dropboxFolder, baseFolder, fileNameList{1});
            load(fileName);

            uvs=[us',vs'];
            D = 2;
            S=UtilFunFPA.LinLUTGV(uvs, 'D', D);
            testCase.assertEqual(S.D, D);
            testCase.verifyError(@()UtilFunFPA.LinLUTGV(uvs, 'D','p'),'MATLAB:validators:mustBeNumeric');
            testCase.verifyError(@()UtilFunFPA.LinLUTGV('f'),'MATLAB:validators:mustBeNumeric');
        end

        function testFigLimitsGV4LinearResponse(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testFigLimitsGV4LinearResponse')
            %Test que emplea los datos ImgGV_5_bad1 para D = 2 para crear graficas de
            %la respuesta lineal para emplearlas en el TFM de VdH. Usa figurasLin
            %(src/figurasLin.m, recuperado del mismo TFM).

            dropboxFolder=fixturesRoot();
            baseFolder='Datos_LinearzationGV_TFM_20-21-VdHG';
            fileNameList = {'ImgGV_5_bad1'};
            fileName = fullfile(dropboxFolder, baseFolder, fileNameList{1});
            load(fileName);
            uvs=[us',vs'];
            NGV = 256;
            S=UtilFunFPA.LinLUTGV(uvs, 'D', 2);
            %Variables de UtilFunFPA.LunLUTGV:
            %Hv = S.Hv;
            Tu=S.Tu;
            Hu=S.Hu;
            u0 = S.u0;
            u1 = S.u1;
            v0 =S.v0;
            v1 = S.v1;
            Lu = S.Lu;
            u = 0:NGV-1;
            ONEOFFSET=1;
            fprintf('u0 = %d, u1 = %d, v0 = %d, v1 = %d',u0, u1, v0, v1);
            %Representamos:
            k=(S.u0:S.u1)+ONEOFFSET;
            figurasLin.figura_Hu_Lu(us, vs,u(k),Lu(k)); %Linearización respuesta monitor - cámara
            figurasLin.figura_Tu(u, Tu, u(k), Tu(k)); %Transformación u' = T(u) = H^-1[L(u)]
            figurasLin.figura_Hufin(u, Hu(ONEOFFSET+Tu),u(k), Hu(ONEOFFSET+Tu(k))); %Respuesta lineal v' = H(u') = L(u)
        end


    end

    methods (Test, TestTags = {'Hardware'})
        % Ported from tests/testTFM_VdH.m (VictorDelHierro TFM 2020-21), 2026-09-14 -
        % all drive a real camera (imaqCam) and/or a real projector display.

        function testImages(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testImages')
            %test para ejecutar todos los test que generan imagenes para el
            %TFM de VdH
            import matlab.unittest.TestSuite;
            suite1 = TestSuite.fromMethod(?testFPA_UtilFunFPAClassVer,'testLimitsGV4LinearResponse');
            suite2 = TestSuite.fromMethod(?testFPA_UtilFunFPAClassVer,'testFigLimitsGV4LinearResponse');
            suite3 = TestSuite.fromMethod(?testFPA_UtilFunFPAClassVer,'testFigFFTLinGV');
            suite4 = TestSuite.fromMethod(?testFPA_UtilFunFPAClassVer,'testCalculatePowerWithCorrectionFromLMMfile');
            largeSuite = [suite1,suite2,suite3,suite4];
            for i = 1:length(largeSuite)
                run(largeSuite(i))
                disp('Press a key for the next Test')  % Press a key here.
                pause;
            end
        end

        function testCalculateResponseFromImages(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testCalculateResponseFromImages')
            %Test que proyecta us niveles de gris constantes, los recoge en la camara  y verifica la respuesta lineal
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            close all
            %Configuraciones de la camara
            fhList={@DMK33UX183Bin3, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            cam=imaqCam(fh);
            ImSize=cam.ImageSize;
            %capture image size
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );
            cam.hImage=hImage;
            cam.StartPreview();

            dpt = DisplayTypes.Matlab;
            %monitor 2
            dp=DisplayFactory.Create(dpt,2); %Segundo parametro es el numero del monitor (por defecto 2)
            g=zeros(dp.screenSize, 'uint8');

            NGV=256; %numero de GVs
            dGV= 15; %pasos de los GVs
            us=0:dGV:NGV-1; %input GV
            NInputGV = length(us);
            gList = cell(1,NInputGV);
            for m=1:NInputGV %creamos una lista con 50 niveles distintos de gris constantes
                g(:, :, :)=us(m);
                gList{m}=g;
            end
            dp.gList=gList;
            %cam.Start(); %Iniciamos la camara
            Ilist=cell(1,NInputGV);
            for m=1:NInputGV %proyectamos los 50 niveles
                dp.Display(m);
                cam.Start();
                %tic
                cam.Capture(); %Capturamos la imagen
                %toc
                cam.Stop();
                Ilist{m}=cam.Data.I;
                %pause(0.2);
            end
            %save('ImgGV.mat', 'Ilist'); %Por si queremos guardar las img
            dp.CloseScreen();

            c = round(0.35*NC:0.65*NC); %columnas de la ROI
            r = round(0.35*NR:0.65*NR); %filas de la ROI
            vs = zeros(size(us)); % GV capture by the camera
            stdv = vs;
            for k = 1:NInputGV
                gv = Ilist{k};
                gvROI = gv(r,c); %Cuadrado de gv de la ROI
                vs(k) = mean2(gvROI); %hallamos el valor medio del nivel de gris v en nuestro rectangulo
                stdv(k)=std2(gvROI);
            end
            %Plot de us frente a vs
            figure;plot(us,vs); xlabel('u'); ylabel('v');legend('H(u)'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV-1]); %Plot de la media de v frente a u

            %Desviacion std respecto de us:
            figure;plot(us, stdv); xlabel('u'); ylabel('\sigma(v)'); title('std'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV-1]); %Plot de std frente a u

            %Calculamos la linearizacion
            uvs=[us',vs'];
            S=UtilFunFPA.LinLUTGV(uvs,'D',2);
            Tu=S.Tu;
            Hu=S.Hu;
            u = 0:NGV-1;
            ONEOFFSET=1;

            %Representamos:
            k=(S.u0:S.u1)+ONEOFFSET;
            figure; plot(us, vs,'+', u, Hu,'-',u(k),S.Lu(k)); legend({'H(u) medida', 'H(u) interpol','L(u0:u1)'}); xlabel('u'); ylabel('v'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV]);
            figure; plot(u, Tu, u(k), Tu(k), '+'); legend({'T(u)', 'T(u0:u1)'}); xlabel('u'); ylabel('T(u)'); xlim(gca,[0 NGV]); ylim(gca,[0 NGV-1]);
            figure; plot(u, Hu(ONEOFFSET+Tu),u(k), Hu(ONEOFFSET+Tu(k)),'+'); legend({'H(T(u))','H(T(u0:u1)'}); xlabel('u'); ylabel('H(T(u))'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV]);

            u0 = S.u0; %GV minimo de la zona lineal
            u1 = S.u1; %GV maximo de la zona lineal
            fprintf('u0 = %d, u1 = %d, v0 = %d, v1 = %d\n',S.u0, S.u1, S.v0, S.v1); %VICTORDEBUG
            fprintf('u0 from function: %d, min T(u): %d\n', u0, min(Tu));
            fprintf('u1 from function: %d, max T(u): %d\n', u1, max(Tu));
            fprintf('v0 from function: %d, min H(u): %f\n', S.v0, min(Hu));
            fprintf('v1 from function: %d, max H(u): %f\n', S.v1, max(Hu));

            %Vamos a verificar la respuesta lineal
            ut=u0:dGV:u1; %GV para testear entre u0 y u1
            um = Tu(ut+ONEOFFSET);
            NInputGV = length(um);
            %Primero montamos las imagenes modificadas por T(u)
            gList = cell(1,NInputGV);
            for k=1:NInputGV %creamos una lista con niveles distintos de gris constantes
                g(:, :, :)=um(k);
                gList{k}=g;
            end

            dp.gList=gList;
            %cam.Start(); %Iniciamos la camara
            Ilist=cell(1,NInputGV);
            %Volvemos a capturar las imagenes
            for k=1:NInputGV %proyectamos los 50 niveles
                dp.Display(k);
                cam.Start();
                %tic
                cam.Capture(); %Capturamos la imagen
                %toc
                cam.Stop();
                Ilist{k}=cam.Data.I;
                %pause(0.2);
            end
            dp.CloseScreen();
            cam.StopPreview();

            vm = zeros(size(um)); % GV capture by the camera
            for k = 1:NInputGV
                gv = Ilist{k};
                gvROI = gv(r,c); %Cuadrado de gv de la ROI
                vm(k) = mean2(gvROI); %hallamos el valor medio del nivel de gris v en nuestro rectangulo
                stdv(k)=std2(gvROI);
            end

            figure;plot(ut,vm); xlabel('ut'); ylabel('vm');legend('ut, vm'); xlim(gca,[0 NGV-1]); ylim(gca,[0 NGV-1]); %Plot de la media de v frente a u
%
%             %Descomentar si quieres actualizar Tu, u0 y u1 de TrasmDeflConfig1.json
%             %Cargamos el json
%             loadJ = loadjson('TrasmDeflConfig2.json');
%             loadJ.GVresp = S;
%             %Guardamos los valores de LinLUTGV en TrasmDeflConfig1.json
%             filesave = 'TrasmDeflConfigDGV'+string(dGV)+'D10.json';
%             filesave = filesave{1};
%             savejson('',loadJ,filesave);
%


            %VICTORDEBUG 18/02/2021 %Guardamos las variables para testLimitsGV4LinearResponse
            %save('D:\User\Victor\Matlab\Linearizacion\ImgGV_'+string(dGV)+'_'+string(date)+'.mat', 'us','vs','um','vm','ut', 'dGV');
        end

        function testFFTLinGV(testCase)
            %run(testFPA_UtilFunFPAClassVer,'testFFTLinGV')

            %Este test proyecta un patron de franjas con
            %FPADemodulatorLSEquispacedPSA, para en primer lugar capturar
            %la imagen con la camara sin realizar ninguna corrección y hacer
            %la FFT2 y FFT, apareciendo varios armónicos.
            %Despues se transformará este patrón con UtilFunFPA.LinLUTGV
            %y así recoger con la cámara una imagen de tipo sinusoidal.
            %Ahora al hacer la FFT2 y la FFT solo deberían
            %aparecer los armónicos +-1. Finalmente calcula el coeficiente
            %entre armónicos para saber con que saltos de GV la correción
            %es mayor. Se pueden emplear varias T(u) almacenadas en los
            %diferentes json, cada una con unos saltos de GV distintos.
            %NOTE: figDemodulator (used below to render figures) could not be
            %located anywhere - see testFigFFTLinGV's comment for detail.

            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            close all
%
            dropboxFolder=fixturesRoot();
            baseFolder='Datos_LinearzationGV_TFM_20-21-VdHG';

            %Configuraciones de la camara
            fhList={@DMK33UX183Bin3, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};
            cam=imaqCam(fh);
            ImSize=cam.ImageSize;
            %capture image size
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );
            cam.hImage=hImage;
            cam.StartPreview();

            dpt = DisplayTypes.Matlab;
            %monitor 2
            dp=DisplayFactory.Create(dpt,2); %Segundo parametro es el numero del monitor (por defecto 2)

            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            d.Set(char(DemodulatorProps.Tx), 20); %set period in px
            d.Set(char(DemodulatorProps.Ty), 20);

            %we are going to calculate only the modulation
            %the demodulation result wull be a real number
            %d.onlyModFlag=true;

            %check all PSFilterTypes

            %change direction to X
            PSdir=0;
            d.Set(char(DemodulatorProps.PSDir), PSdir);

            NIgrams=1;
            %set NIgrams and set the vaule of deltaList as NIgrams equispaced
            %values beween 0 and 2*pi(1-1/NIgrams)
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);

            %Cargamos el json que contiene Tu, u1 y u0. Cada json tiene un DGV distinto:
            filename = {'TrasmDeflConfigDGV1.json','TrasmDeflConfigDGV2.json','TrasmDeflConfigDGV5.json','TrasmDeflConfigDGV10.json','TrasmDeflConfigDGV15.json','TrasmDeflConfigDGV25.json','TrasmDeflConfigDGV5D10.json'};
            njson = 5; %cambiar para elegir el json deseado
            loadJ = loadjson(fullfile(dropboxFolder, baseFolder, filename{njson}));
            Tu = loadJ.GVresp.Tu;
            u1 = loadJ.GVresp.u1;
            u0 = loadJ.GVresp.u0;
            ONEOFFSET = 1;

            %Modificamos la modulación del patrón de franjas y la bias para
            %que se inicien con el valor máximo sea u1 y el minimo u0:
            d.modFP =  (u1-u0)/2;
            d.biasFP = (u1+u0)/2;
            uGVp = d.GenerateFPs(dp.screenSize); %GVs a proyectar sin ser modificados por Tu

            %VdH DEBUG
            %uGVp = d.GenerateFPs([1000 1000]);

            %Aplicamos la transformación Tu para conseguir que los GVs que
            %se recojan en la cámara sean lineales respecto a los enviados
            %con el proyector
            GV{:} = Tu(uGVp{:}+ONEOFFSET);
            GV{:} = cast(GV{:},'uint8'); %Convertimos GV de double a uint8 para proyectar


            %RESULTADO CON EL PATRÓN GENERADO SIN TRANSFORMAR ---> u
            %Escogemos un cuadrado igual al que se analizará posteriormente en la imagen capturada:
            pSize=dp.screenSize; %Resolucion imagen proyectada
            NRp=pSize(1);
            NCp=pSize(2);
            cp = round(0.35*NCp:0.65*NCp);
            rp = round(0.35*NRp:0.65*NCp);
            m = 1;
            GVp = uGVp{m}; %Niveles de gris de toda la imagen proyectada
            GVpROI = GVp(rp,cp); %Niveles de gris recortados del proyector

            %Hallamos su FFT2:
            GCp = fft2(GVpROI);
            figure; imagesc(log(abs(fftshift(GCp))+1)); title('FFT2 del patrón generado sin transformar');


            %%RESULTADO CON EL PATRÓN GENERADO TRANSFORMADO ---> u'=T(u)
            %Escogemos un cuadrado igual al que se analizará posteriormente en la imagen capturada:
            GVp = GV{m}; %Niveles de gris de toda la imagen proyectada
            GVpROI = GVp(rp,cp); %Niveles de gris recortados del proyector

            %Hallamos su FFT2:
            GCp = fft2(GVpROI);
            figure; imagesc(log(abs(fftshift(GCp))+1)); title('FFT2 del patrón generado Transformada');


            %CAPTURA DE u ---> v
            %Mandamos el patron SIN transformar por Tu y lo capturamos
            %generate the FPS and store them in the projector
            dp.gList=uGVp;
            dp.Display(m);
            cam.Start();
            %tic
            cam.Capture(); %Capturamos la imagen
            %toc
            cam.Stop();
            Ilist{m}=cam.Data.I; %Imagen sin transformar
            %pause(3);
            dp.CloseScreen();
            %FIN PROYECTOR---CAMERA
            %Recortamos la imagen capturada para analizar solo la parte
            %central
            NCr = 0.35*NC:0.65*NC;
            NRr = 0.35*NR:0.65*NR;
%             NCr = 0.15*NC:0.85*NC;
%             NRr = 0.15*NR:0.85*NR;

            c = round(NCr); %columnas de la ROI
            r = round(NRr); %filas de la ROI
            gv = Ilist{m};
            gvROI = gv(r,c); %Cuadrado de gv de la ROI
            %Hallamos su FFT2:
            GC = fft2(gvROI);
            FFT2v = log(abs(fftshift(GC))+1);
            %figure; imagesc(FFT2v); title('FFT2 del patron sin corregir capturado');
            figDemodulator.figuraFFT2v(FFT2v);
            %Calculamos la media de cada fila para hallar el perfil y posteriormente su FFT unidimensional
            agvROI = zeros(size(gvROI(1,:,:,:)));
            LenNCr = length(NCr);
            LenNRr = length(NRr);
            for i = 1: LenNCr
                agvROI(i) = sum(gvROI(:,i,:,:))/(LenNRr);
            end
            %Plot del perfil capturado sin corregir el patron:
            perfilv = agvROI;
            %figure; plot(agvROI); title('Perfil del patron sin corregir capturado');axis([0 length(agvROI) min(agvROI)-10 max(agvROI)+10]);
            figDemodulator.figuraPerfilv(perfilv);

            %FFT del perfil sin corregir
            aG = fft(agvROI);
            I = abs(fftshift(aG));
            Ilog = log(I+1);

            %Calculamos el valor de los picos en la escala logarítmica y los ordenamos
            %descendentemente para hallar su posiciones.
            %Sabemos que la difencia entre el primer máximo
            %y su consecutivo será la distancia entre armónicos. Nos
            %quedaremos con aquellos picos que tengan una intensidad de
            %poco mas de la mitad del primer armónico.
            [IPeak, posPeak] = findpeaks(Ilog,'SortStr','descend');
            [pkI, posPeak] = findpeaks(Ilog,'SortStr','descend','MinPeakDistance',(posPeak(1)-posPeak(2)-2),'MinPeakHeight',(IPeak(2)/2.2));

            %Plot de la FFT del perfil sin corregir con sus correspondientes armónicos
            xI = 0:(length(Ilog)-1);
            xI=xI-floor(length(Ilog)/2);
            yI = Ilog;
            posPeak = posPeak-1;
            xpeak = (posPeak-round(length(Ilog)/2));
            ypeak = pkI;
            ejesI = [(-round(length(Ilog)/2)+1) (round(length(Ilog)/2)+1) min(Ilog)-0.2 max(Ilog)+0.5];
            %figure; plot(xI, yI,xpeak, ypeak,'or'); axis(ejesI); title('FFT(v)'); legend('log(FFT(v)','Armónicos'); xlabel('len(FFT(v)');ylabel('log(FFT(v)');
            figDemodulator.figuralogFFTv(xI, yI, xpeak, ypeak);

            %Creamos una ventana de Hamming para eliminar los efectos de
            %los bordes a la hora de calcular la FFT. Tambien se realzan los armónicos que pueden
            %haber quedado ocultos bajo la funcion
            N = length(perfilv);
            x = 0:(N-1);
            x=x-floor(N/2)+1;
            w = 0.5*(1+cos(2*pi*x/N));
            %Aplicamos el filtro al perfil sin corregir
            perfilvf = perfilv.*w;

            %FFT del perfil sin corregir filtrado
            aGf = fft(perfilvf);
            If = abs(fftshift(aGf));
            Iflog = log(If+1);
            %Buscamos los picos del perfil v filtrado
            [IPeakf, posPeakf] = findpeaks(Iflog,'SortStr','descend');
            [pkIflog, posPeakf] = findpeaks(Iflog,'SortStr','descend','MinPeakDistance',(posPeakf(1)-posPeakf(2)-2),'MinPeakHeight',(IPeakf(2)/3));
            difIf = sum(If(posPeakf(2:3)))/(sum(If(posPeakf(4:length(posPeakf)))));
            fprintf('El cociente entre armonicos del perfil v filtrado es: %f\n', difIf);

            %plot de la FFT del perfil sin corregir filtrado con sus correspondientes armonicos
            xIf = 0:(length(Iflog)-1);
            xIf=xIf-floor(length(Iflog)/2);
            ejesIf = [(-round(length(Iflog)/2)+1) (round(length(Iflog)/2)+1) min(Iflog)-0.2 max(Iflog)+0.5];
            posPeakf = posPeakf-1;
            xpeakf = (posPeakf-floor(length(Iflog)/2));
            ypeakf = pkIflog;
            figure; plot(xIf, Iflog, xpeakf, ypeakf,'or'); axis(ejesIf);title('FFT(v) filtrada'); legend('log(FFT(v'')','Armónicos'); xlabel('franjas/campo');ylabel('log(FFT(v'')');
            figDemodulator.figuralogFFTvfilter(xIf, Iflog, xpeakf, ypeakf);

            xIf = 0:(length(Iflog)-1);
            xIf=xIf-floor(length(Iflog)/2);
            xpkf = (posPeakf-floor(length(Iflog)/2));
            ypkf = If(posPeakf+1);
            ejesIff = [(-round(length(Iflog)/2)+1) (round(length(Iflog)/2)+1) min(If)-0.2 max(If)+0.5];
            figure; plot(xIf, If, xpkf, ypkf,'or'); axis(ejesIff);title('FFT(v) filtrada'); legend('FFT(v)','Armónicos'); xlabel('franjas/campo');ylabel('FFT(v)');
            figDemodulator.figuraFFTvfilter(xIf, If, xpkf, ypkf);

            %CAPTURA DE u' = T(u) ---> v'
            %Mandamos el patron transformado por Tu y lo capturamos
            %generate the FPS and store them in the projector
            dp.gList=GV;
            m=1;
            dp.Display(m);
            cam.Start();
            %tic
            cam.Capture(); %Capturamos la imagen
            %toc
            cam.Stop();
            IlistT{m}=cam.Data.I; %imagen transformada
            %pause(3);
            dp.CloseScreen();
            %FIN PROYECTOR---CAMERA
            gvc = IlistT{m};
            gvROIc = gvc(r,c); %Cuadrado de gv de la ROI

            %Hallamos su FFT2:
            GC = fft2(gvROIc);
            FFT2Tu = log(abs(fftshift(GC))+1);
            %figure; imagesc(FFT2GC); title('FFT2 del patron corregido capturado');
            figDemodulator.figuraFFT2Tu(FFT2Tu);
            %Calculamos la media de cada fila para hallar el perfil y posteriormente su FFT unidimensional
            agvROIc = zeros(size(gvROIc(1,:,:,:)));
            for i = 1:LenNCr
                agvROIc(i) = sum(gvROIc(:,i,:,:))/(LenNRr);
            end
            %Plot del perfil de v'
            perfilTu = agvROIc;
            %figure; plot(agvROI); title('Perfil del patron corregido capturado'); axis([0 length(agvROI) min(agvROI)-10 max(agvROI)+10]);
            figDemodulator.figuraPerfilTu(perfilTu);
            %Plot de ambos perfiles, v y v':
            %figure;plot(1:length(perfilv), perfilv, 1:length(perfilTu),perfilTu); legend('perfil v', 'perfil v''');

            %Aplicamos el filtro de Hamming al perfil v':
            perfilTuf = perfilTu.*w;

            %Plot de ambos perfiles filtrados
            xperfilvf = 1:length(perfilvf);
            xperfilTuf = 1:length(perfilTuf);
            figure;plot(xperfilvf, perfilvf, xperfilTuf, perfilTuf); legend('perfil v con filtro', 'perfil v'' con filtro');
            figDemodulator.figuraPerfilesvTufilter(xperfilvf, [perfilvf; perfilTuf]);

            %FFT de v' sin filtro:
            aGC = fft(perfilTu);
            IC =abs(fftshift(aGC));
            IClog = log(abs(fftshift(aGC))+1);
            %FFT del v' filtrado
            aGCf = fft(perfilTuf);
            ICf = abs(fftshift(aGCf));
            ICflog = log(abs(fftshift(aGCf))+1);

            %Calculamos el valor y posicion de los picos del perfil de v' sin filtrar.
            [IPeakC, posPeakC] = findpeaks(IClog,'SortStr','descend');
            [pkIClog, posPeakC] = findpeaks(IClog,'MinPeakDistance',(posPeakC(1)-posPeakC(2)-2),'MinPeakHeight',(IPeakC(2)/2.2));
            [~, pm0C] = max(pkIClog); %Hallamos la posicion del armonico m=0
            %Calculamos el cociente de la suma de la intensidad de los dos primeros armónicos entre la suma del resto de armónicos:
            difIC = IC(posPeakC(pm0C+1))/(sum(IC(posPeakC((pm0C+2):length(posPeakC)))));fprintf('El cociente entre armonicos del perfil v'' sin filtrar es: %f\n', difIC);
            %Dividimos el primer entre el tercer armónico
            c12IC = IC(posPeakC(pm0C+1))/IC(pm0C+2);fprintf('El cociente entre m1/m2 del perfil v'' sin filtrar es: %f\n', c12IC);
            r12IC = IC(posPeakC(pm0C+1))-IC(pm0C+2);fprintf('La resta de m1-m2 del perfil v'' sin filtrar es: %f\n', r12IC);

            %plot de la FFT del perfil de v' con sus correspondientes armónicos
            ejesIC = [(-round(length(IClog)/2)+1) (round(length(IClog)/2)+1) min(IClog)-0.2 max(IClog)+0.5];
            xIC = 0:(length(IClog)-1);
            xIC=xIC-floor(length(IClog)/2);
            yIC = IClog;
            posPeakC = posPeakC-1;
            xpeakC = (posPeakC-floor(length(IClog)/2));
            ypeakC = pkIClog;
            %figure; plot(xIC, IClog, xpeakC, ypeakC,'or'); axis(ejesIC);title('FFT(v'')'); legend('log(FFT(v'')','Armónicos'); xlabel('len(FFT(v'')');ylabel('log(FFT(v'')');
            figDemodulator.figuralogFFTTu(xIC, yIC, xpeakC, ypeakC);

            %Buscamos los picos del perfil v' filtrado
            [IPeakCf, posPeakCf] = findpeaks(ICflog,'SortStr','descend');
            [pkICflog, posPeakCf] = findpeaks(ICflog,'MinPeakDistance',(posPeakCf(1)-posPeakCf(2)-2),'MinPeakHeight',(IPeakCf(2)/3));
            [~, pm0Cf] = max(pkICflog); %Hallamos la posicion del armonico m=0
            %Calculamos el cociente de la suma de la intensidad de los dos primeros armónicos entre la suma del resto de armónicos:
            difIC = ICf(posPeakCf(pm0Cf+1))/(sum(IC(posPeakCf((pm0Cf+2):length(posPeakCf)))));fprintf('El cociente entre armonicos del perfil v'' sin filtrar es: %f\n', difIC);
            %Dividimos el primer entre el tercer armónico
            m1 = ICf(posPeakCf(pm0Cf+1));
            m2 = ICf(posPeakCf(pm0Cf+2));
            fprintf('En el perfil v'' filtrado m1 = %f y m2 = %f/n', m1,m2);
            fprintf('El cociente entre m1/m2 del perfil v'' filtrado es: %f\n', m1/m2);
            fprintf('La resta de m1-m2 del perfil v'' filtrado es: %f\n', m1-m2);

            %Plot del perfil de v' filtrado con sus correspondientes armónicos:
            ejesICf = [(-round(length(ICflog)/2)+1) (round(length(ICflog)/2)+1) min(ICflog)-0.2 max(ICflog)+0.5];
            xICf = 0:(length(ICflog)-1);
            xICf=xICf-floor(length(ICflog)/2);
            xpeakCf = (posPeakCf-floor(length(ICflog)/2)-1);
            ypeakCf = pkICflog;
            xpkCf = (posPeakCf-floor(length(ICflog)/2)-1);
            ypkCf = ICf(posPeakCf);
            ejesICff = [(-round(length(ICflog)/2)+1) (round(length(ICflog)/2)+1) min(ICf)-0.2 max(ICf)+0.5];
            figure; plot(xICf, ICflog, xpeakCf, ypeakCf,'or'); axis(ejesICf);title('log(FFT(v'')) filtrada'); legend('log(FFT(v'')','Armónicos'); xlabel('franjas/campo');ylabel('log(FFT(v'')');
            figure; plot(xICf, ICf, xpkCf, ypkCf,'or'); axis(ejesICff);title('FFT(v'') filtrada'); legend('FFT(v''','Armónicos'); xlabel('franjas/campo');ylabel('FFT(v'')');

            figDemodulator.figuralogFFTTufilter(xICf, ICflog, xpeakCf, ypeakCf);
            figDemodulator.figuraFFTTufilter(xICf, ICf, xpkCf, ypkCf);

            % VdH DEBGUG
%             imageName = 'prueba.png';
%             imwrite( im2gray(gvROI), imageName);
%             I = imread('prueba.png');
%             x = [100 500];
%             y = [200 200];
%             prof = improfile(I,x,y);
%             vs = abs(fft(prof)); %hallamos la FFT
%             figure;
%             plot(vs(6:end));
%             delete(imageName);

            %VdH DEBUG
%             %Por si queremos guardar los datos en un json
%             loadJ = loadjson('datatestFFTlinGV.json');
%             %Datos de v para FFT2v, perfilv, logFFTv, logFFTvfilter, FFTvfilter
%             if njson == 5
%                 loadJ.v.imagenv = gvROI;
%                 loadJ.v.FFT2v = FFT2v;
%                 loadJ.v.perfilv = perfilv;
%                 loadJ.v.logFFTv.xI = xI; loadJ.v.logFFTv.yI = yI; loadJ.v.logFFTv.xpeak = xpeak; loadJ.v.logFFTv.ypeak = ypeak;
%                 loadJ.v.logFFTvfilter.xIf = xIf; loadJ.v.logFFTvfilter.Iflog = Iflog; loadJ.v.logFFTvfilter.xpeakf = xpeakf; loadJ.v.logFFTvfilter.ypeakf = ypeakf;
%                 loadJ.v.FFTvfilter.xIf = xIf; loadJ.v.FFTvfilter.If = If; loadJ.v.FFTvfilter.xpkf = xpkf; loadJ.v.FFTvfilter.ypkf = ypkf;
%                 %Perfiles de v y Tu filtrados:
%                 loadJ.perfilvTu.xperfilvf = xperfilvf; loadJ.perfilvTu.perfilvf = perfilvf; loadJ.perfilvTu.xperfilTuf = xperfilTuf; loadJ.perfilvTu.perfilTuf = perfilTuf;
%
%                 %Datos de v' para FFT2Tu, perfilTu, logFFTTu, logFFTTufilter, logFFTTufilter, FFTTufilter
%                 loadJ.Tu.imagenTu = gvROIc;
%                 loadJ.Tu.FFT2Tu = FFT2Tu;
%                 loadJ.Tu.perfilTu = perfilTu;
%                 loadJ.Tu.logFFTTu.xIC = xIC; loadJ.Tu.logFFTTu.yIC = yIC; loadJ.Tu.logFFTTu.xpeakC = xpeakC; loadJ.Tu.logFFTTu.ypeakC = ypeakC;
%                 loadJ.Tu.logFFTTufilter.xICf = xICf; loadJ.Tu.logFFTTufilter.ICflog = ICflog; loadJ.Tu.logFFTTufilter.xpeakCf = xpeakCf; loadJ.Tu.logFFTTufilter.ypeakCf = ypeakCf;
%                 loadJ.Tu.FFTTufilter.xICf = xICf; loadJ.Tu.FFTTufilter.ICf = ICf; loadJ.Tu.FFTTufilter.xpkCf = xpkCf; loadJ.Tu.FFTTufilter.ypkCf = ypkCf;
%                 %Armonicos
%                 loadJ.Tu.dGV15.m1 = m1; loadJ.Tu.dGV15.m2 = m2;
%             end
%             if njson == 1
%                 loadJ.Tu.dGV1.m1 = m1; loadJ.Tu.dGV1.m2 = m2;
%             end
%             if njson == 2
%                 loadJ.Tu.dGV2.m1 = m1; loadJ.Tu.dGV2.m2 = m2;
%             end
%             if njson == 3
%                 loadJ.Tu.dGV5.m1 = m1; loadJ.Tu.dGV5.m2 = m2;
%             end
%             if njson == 4
%                 loadJ.Tu.dGV10.m1 = m1; loadJ.Tu.dGV10.m2 = m2;
%             end
%             if njson == 6
%                 loadJ.Tu.dGV25.m1 = m1; loadJ.Tu.dGV25.m2 = m2;
%             end
%             %Guardamos los valores de testFFTlinGV en datatestFFTlinGV.json
%             filesave = 'datatestFFTlinGV'+string(date)+'.json';
%             filesave = filesave{1};
%             savejson('',loadJ,filesave);

        end

        function testCalculatePowerWithCorrection(testCase)
            %run(testFPA_UtilFunFPAClassVer, 'testCalculatePowerWithCorrection')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %LMMFile='LMM_18-Mar-2021.mat';
            %LMMFile='LMMTu_18-Mar-2021.mat';
            %LMM=LensMapperMeasurement.load(LMMFile);
            LMM=LensMapperMeasurement;

            %load measurents
            %Cargamos el json que contiene Tu, u1 y u0. Cada json tiene un DGV distinto:
            dropboxFolder=fixturesRoot();
            baseDir=fullfile(dropboxFolder, 'Datos_LinearzationGV_TFM_20-21-VdHG');

            filenameList = {'TrasmDeflConfigDGV1.json','TrasmDeflConfigDGV2.json','TrasmDeflConfigDGV5.json','TrasmDeflConfigDGV10.json','TrasmDeflConfigDGV15.json','TrasmDeflConfigDGV25.json','TrasmDeflConfigDGV5D10.json'};
            njson = 5; %cambiar para elegir el json deseado
            loadJ = loadjson(fullfile(baseDir, filenameList{njson}));
            Tu = loadJ.GVresp.Tu;
            ONEOFFSET = 1;

            %valores por defecto de forma explicita
            Rroi = 0.1; %factor que recorta la máscara a la hora de realizar el ajuste polinomial
            poly = 'poly22'; %Tipo de ajuste polinomial.
            NIgrams = 4;
            Tx =32; %Periodo en x
            Ty =32; %Periodo en y
            %Elegir si queremos transformar el patron o no con T(u):
            CORRECT_GV=false;
            if CORRECT_GV

                u1 = loadJ.GVresp.u1;
                u0 = loadJ.GVresp.u0;
            else
                u0=0;
                u1=255;
            end

            %Configuraciones de la camara
            fhList={@DMK33UX183Bin3, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};
            cam=imaqCam(fh);
            ImSize=cam.ImageSize;
            %capture image size
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );
            cam.hImage=hImage;
            cam.StartPreview();

            %instanciamos proyector
            dpt = DisplayTypes.Matlab;
            %monitor 2
            dp=DisplayFactory.Create(dpt,2); %Segundo parametro es el numero del monitor (por defecto 2)

            d=DemodulatorFactory.Create(DemodulatorTypes.LSEquispacedPSA);
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);
            d.Set(char(DemodulatorProps.Tx), Tx); %pixels
            d.Set(char(DemodulatorProps.Ty), Ty); %pixels

            %Modificamos la modulación del patrón de franjas y la bias para
            %que se inicien con el valor máximo sea u1 y el minimo u0:
            d.modFP =  (u1-u0)/2;
            d.biasFP = (u1+u0)/2;

            %Proyectamos los igrams sin modifcar, entre u0 y u1:

            PSdir=0;
            %generate the FPS
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            uGVpX = d.GenerateFPs(dp.screenSize); %GVs a proyectar sin ser modificados por Tu

            PSdir=1;
            %generate the FPS
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            uGVpY = d.GenerateFPs(dp.screenSize); %GVs a proyectar sin ser modificados por Tu

            uGVp=[uGVpX,  uGVpY];


            if CORRECT_GV
                %generate the FPS
                for n = 1:length(uGVp)
                    uGVp{n}(:,:,1) = uint8(Tu(uGVp{n}(:,:,1)+ONEOFFSET));
                    uGVp{n}(:,:,2) = uint8(Tu(uGVp{n}(:,:,2)+ONEOFFSET));
                    uGVp{n}(:,:,3) = uint8(Tu(uGVp{n}(:,:,3)+ONEOFFSET));
                end
            end

            dp.gList=uGVp;

            %capturamos ref
            gr=cell(1, length(dp.gList));
            % "capture" the FPS
            TIMEPAUSE=0.5;
            for n=1:length(dp.gList)
                dp.Display(n);
                pause(TIMEPAUSE);
                %condition the captured image
                I=dp.gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                cam.Start();
                %tic
                cam.Capture(); %Capturamos la imagen
                %toc
                cam.Stop();

                gr{n}=cam.Data.I;
                %pause(3);
            end

            disp('Place the lens and Press a key !')  % Press a key here.You can see the message 'Paused: Press any key' in        % the lower left corner of MATLAB window.
            pause;

            %capturamos signal
            g=cell(1, length(dp.gList));
            % "capture" the FPS
            for n=1:length(dp.gList)
                dp.Display(n);
                pause(TIMEPAUSE);
                %condition the captured image
                I=dp.gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                cam.Start();
                %tic
                cam.Capture(); %Capturamos la imagen
                %toc
                cam.Stop();

                g{n}=cam.Data.I;
                %pause(3);
            end

            dp.CloseScreen();
            cam.StopPreview();
            tic
            %Init LMM
            LMM.gr=gr;
            LMM.g=g;

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
            Z=205.2945317; %mm distance screen-lens calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx_5MAY20');
            Zc=266.7984068; %mm distance camera-lens

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
            dxLP=0.07147381885; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');
            dyLP=0.0716408363; %mm/px lens plane calculated using run(testFPA_UtilFunFPAClassVer, 'testUndistortImagesCVTbx');

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
            LMM.CalculateLensPower(LMM.M, K, ...
                'Nmed', 1, 'NS', 1, 'LPCycles', 1);

            DispMask=double(LMM.M)./double(LMM.M);

            UNDISTORT=0;
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

            %VdH DEBUG:
            [XX,YY]=meshgrid(1:NC, 1:NR);
            Seq = LMM.Seq;
            %Para hallar el radio del circulo de 1s creado por la máscara,
            %hallamos la posicion del primer y último 1 y dividimos por 2.
            %Antes de nada cambiamos los valores de NaN a 0 para poder
            %encontrar los 1:

            DispMask0 = DispMask;
            DispMask0(isnan(DispMask0)) = 0;
            [Cy1, P1] = find(DispMask0, 1, 'first');
            [Cy2, P2] = find(DispMask0, 1, 'last');
            %El radio será la posicion del primer 1 menos la del último
            %entre 2:
            R =round(P2-P1)/2;
            %Para hallar el centro del circulo en las X, sumamos a la posicion del
            %primer 1 el radio:
            Cx = P1+R;
            %Para hallar el centro del circulo en las Y,tomamos el valor
            %en la y del primer y último 1. Como en ocasiones no son
            %iguales, hallamos la media para tener mayor precisión:
            Cy = round((Cy1+Cy2)/2);

            %Creamos una máscara centrada. El radio se ha recortado en cada
            %archivo de forma que se consiga evitar los problemas que
            %producen los bordes a la hora de ajustar.

            %Rroi = 0.85; %Factor que recorta el radio.
            Mask = zeros(size(XX));
            Mask((XX-Cx).^2+(YY-Cy).^2 <= (R*Rroi)^2) = 1;
            %Rellenamos la nueva Seq dentro del circulo que nos interesa:
            SeqCirc = Seq(find(Mask));
            XX2 = XX(Mask==1);
            YY2 = YY(Mask==1);
            %Ajustamos los datos por un polinomio bidimensional de grado 5
            sf = fit([XX2, YY2], SeqCirc,poly,'Normalize','On');

            N=50;
            xvec = linspace(min(XX2), max(XX2), N);
            yvec = linspace(min(YY2), max(YY2), N);
            [X, Y] = ndgrid(xvec, yvec);
            Z = sf(X, Y);
            sfEq = sf(XX2,YY2);
            %Calculamos los residuos
            res =sfEq-SeqCirc;
            %Pintamos el ajuste con la superficie equivalente:
            figure;surf(X, Y, Z,'facealpha',0.7,'PickableParts','none',...
                'Tag','curvefit.gui.FunctionSurface');
            hold on;
            plot3(XX2, YY2, SeqCirc,'Color',[0.12,0.47,0.71, 0.8],'LineStyle',':'); legend('Fit Seq', 'Seq');title('Fit Seq');
            %Hallamos la media de la potencia de la Seq en el area
            %recortada, para los valores ajustados y sin ajustar
            xlabel(sprintf('fit Seq: mean = %2.3f D, SeqCirc: mean = %2.3f D,std res = %2.3f D', mean(sfEq),mean(SeqCirc),std(res)));

            %Pintamos los valores de los residuos
            figure;plot3(XX2, YY2, res,'Color',[0.12,0.47,0.71, 0.5],'LineStyle',':'); title('Residuos de fit Seq');

            %Plot del histograma de los residuos:
            meanR =mean((res));
            stdRes=std(res);
            x=linspace(-0.02,0.02, 100); %histogram sampling in D
            h=hist(res, x);
            figure; plot(x,h); grid; title(sprintf('Res hist (D)'));
            xlabel(sprintf('sigma: %2.3f D, mean: %2.3f D', stdRes, meanR));

            %Encontramos los bordes de la nueva mascara para luego
            %evaluar el plot en esos puntos
            [~, P10] = find(Mask, 1, 'first');
            [~, P20] = find(Mask, 1, 'last');
            %Evaluamos el ajuste en nuestros puntos
            FitSeq=feval(sf,XX,YY);
            %Plot del perfil del ajuste de la Seq con los valores reales
            figure; plot((P10:P20),FitSeq(R0,P10:P20));legend('Perfil de Fit Seq'); hold on;
            plot((P10:P20),LMM.Seq(R0,P10:P20));legend('Perfil de Fit Seq','Perfil de Seq');title('Perfil de Fit Seq y Seq');

            MEASURE_NULL=true;
            if MEASURE_NULL
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
            tfin=toc

            %VdH DEBUG
            %LMM=LensMapperMeasurement.load(fullfile(dropboxFolder, baseFolder, LMMFile));
            %LMM.save(LMM,'LMM_NULL_32');

        end

    end

end