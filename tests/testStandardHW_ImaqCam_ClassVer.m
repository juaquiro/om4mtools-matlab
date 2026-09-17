classdef testStandardHW_ImaqCam_ClassVer < matlab.unittest.TestCase
    % testStandardHW_ImaqCam_ClassVer is a Hardware-tagged, manual/visual
    % test suite for imaqCam (real camera required; see run_hardware_tests.m).
    %  Known gap: every test here constructs an imaqCam, whose
    % constructor requires the camGeomCal class (this.gc) - which does
    % not exist anywhere in this repo (see the known-gap note on
    % src/imaqCam.m itself) - so none of these tests can currently
    % construct their camera object, let alone run to completion.
    %run (testStandardHW_ImaqCam_ClassVer)

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

    methods (Test, TestTags = {'Hardware'}) %%Test realizados sobre la cámara DMK33UX183Bin3
        function testSaveGVconstant(testCase)
            % testSaveGVconstant projects 50 constant gray-level frames
            % on monitor 2, captures each with the camera and saves them
            % all to ImgGV.mat
            %run(testStandardHW_ImaqCam_ClassVer, 'testSaveGVconstant')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            close all
            %Configuraciones de la camara
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );
            c.hImage=hImage;
            dpt = DisplayTypes.Matlab;
            %monitor 2
            dp=DisplayFactory.Create(dpt,2); %Segundo parametro es el numero del monitor (por defecto 2)
            g=zeros(dp.screenSize, 'uint8');
            m=0;
            for u=0:5:250 %creamos una lista con 50 niveles distintos de gris constantes
                m=m+1;
                g(:, :, :)=u;
                gList{m}=g;
            end
            dp.gList=gList;
            %c.Start(); %Iniciamos la camara
            m=0;
            for n=1:length(gList) %proyectamos los 50 niveles
                m=m+1;
                dp.Display(n);
                c.Start();
                tic
                c.Capture(); %Capturamos la imagen
                toc
                c.Stop();
                save_v{m}=c.Data.I
                pause(3);
            end
            save('ImgGV.mat', 'save_v');
            dp.CloseScreen();
        end

        function test_getFirstImaqCamAvailable(testCase)
            % test_getFirstImaqCamAvailable visually checks
            % imaqCam.getFirstImaqCamAvailable returns a valid video
            % object and can preview it
            %run(testStandardHW_ImaqCam_ClassVer, 'test_getFirstImaqCamAvailable')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_getFirstImaqCamAvailable
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());


            vid=imaqCam.getFirstImaqCamAvailable;

            assertTrue(isvalid(vid));
            preview(vid);
            pause(5);
            closepreview(vid);
        end

        function test_GenCamData(testCase)
            % test_GenCamData checks imaqCamData constructs, and that
            % adding a field to it makes isCamDataStruct fail (or errors,
            % since imaqCamData is a class, not a struct)
            %run(testStandardHW_ImaqCam_ClassVer, 'test_GenCamData')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_GenCamData
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            CDS=imaqCamData;
            assertTrue(isa(CDS, 'imaqCamData'));

            %add a field, now is not a valid struct
            try
                CDS.k=9;
                assertFalse(imaqCam.isCamDataStruct(CDS));
            catch ME
                assertEqual(ME.message, 'No public field k exists for class imaqCamData.');
            end
        end


        function test_ImaqCamConstructor(testCase)
            % test_ImaqCamConstructor checks imaqCam(fh) constructs and
            % initializes this.Data to an imaqCamData instance
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamConstructor')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamConstructor
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);

            assertTrue(isa(c.Data, 'imaqCamData'));

        end

        function test_ImaqCamStartStopPreview(testCase)
            % test_ImaqCamStartStopPreview visually checks two
            % StartPreview/StopPreview cycles work in a row
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamStartStopPreview')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamStartStopPreview
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);

            c.StartPreview();
            pause(15);
            c.StopPreview();

            c.StartPreview();
            pause(5);
            c.StopPreview();

            close all;
        end

        function test_ImaqCamStartStopPreviewALT(testCase)
            % test_ImaqCamStartStopPreviewALT visually checks Start()
            % followed by two StartPreview/StopPreview cycles works
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamStartStopPreviewALT')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamStartStopPreviewALT
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            %error('AQDEBUG 2/2/2016 work in progress');

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);

            c.Start;
            pause(15);

            c.StartPreview();
            pause(5);
            c.StopPreview();

            c.StartPreview();
            pause(5);
            c.StopPreview();

            close all;
        end





        function test_StartStop(testCase)
            % test_StartStop checks Start/Stop run without error and
            % the camera object can be deleted cleanly afterwards
            %run(testStandardHW_ImaqCam_ClassVer, 'test_StartStop')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_StartStop()
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);

            c.Start;

            pause(1);

            c.Stop;

            delete(c);
            clear c;
        end

        function test_GetSethImage(testCase)
            % test_GetSethImage checks the hImage property returns the
            % same handle instance that was set on it
            %run(testStandardHW_ImaqCam_ClassVer, 'test_GetSethImage')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_GetSethImage
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hImage = image( zeros(NR, NC, NB) );

            c.hImage=hImage;

            hImage1=c.hImage;

            assertEqual(hImage1, hImage);

            delete(hFigure);
            delete(c);
            clear c;
        end

        function test_StartPreviewStopPreviewWithFigure(testCase)
            % test_StartPreviewStopPreviewWithFigure drives preview from
            % a caller-supplied hImage, then captures and visually
            % inspects a single frame
            %run(testStandardHW_ImaqCam_ClassVer, 'test_StartPreviewStopPreviewWithFigure')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_StartPreviewStopPreviewWithFigure
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);


            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );


            c.hImage=hImage;
            c.StartPreview();
            pause(5);
            c.StopPreview();

            c.Start();
            c.Capture();
            c.Stop();

            figure; imshow(c.Data.I); title('image capture')

            formatSpec='\nFrame captured at: %s with video resolution\n';
            fprintf(formatSpec, c.Data.timeStamp);

            delete(c);
            clear c;
        end


        function test_StartPreviewStopPreviewWithFigureFromCamFile(testCase)
            % test_StartPreviewStopPreviewWithFigureFromCamFile repeats
            % test_StartPreviewStopPreviewWithFigure verbatim - kept to
            % maintain parity with the original hardware suite
            %run(testStandardHW_ImaqCam_ClassVer, 'test_StartPreviewStopPreviewWithFigureFromCamFile')
            %mtest testStandardHW_ImaqCam_ClassVer:test_StartPreviewStopPreviewWithFigureFromCamFile
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);


            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );


            c.hImage=hImage;
            c.StartPreview();
            pause(5);
            c.StopPreview();

            c.Start();
            c.Capture();
            c.Stop();

            figure; imshow(c.Data.I); title('image capture')

            formatSpec='\nFrame captured at: %s with video resolution\n';
            fprintf(formatSpec, c.Data.timeStamp);

            delete(c);
            clear c;
        end


        function test_Capture(testCase)
            % test_Capture measures execution time of a single Capture
            % call and visually inspects the captured frame
            %run(testStandardHW_ImaqCam_ClassVer, 'test_Capture')
            %mtest testStandardHW_ImaqCam_ClassVer:test_Capture
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);


            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');
            hImage = image( zeros(NR, NC, NB) );


            c.hImage=hImage;

            c.Start();

            tic
            c.Capture();
            toc

            c.Stop();

            figure; imshow(c.Data.I); title('image capture')

            formatSpec='\nFrame captured at: %s with video resolution\n';
            fprintf(formatSpec, c.Data.timeStamp);

            delete(c);
            clear c;
        end



        function test_SetUpdatePreviewCornerdetection(testCase)
            % test_SetUpdatePreviewCornerdetection visually checks the
            % live preview overlays detected corners via
            % imaqCam.detectCornerPointsCallback (drawObject set to a
            % vision.ShapeInserter)
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreviewCornerdetection')
            %mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreviewCornerdetection
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            c.StartPreview();

            c.Set(char(imaqCamProps.drawObject), vision.ShapeInserter);
            c.SetUpdatePreviewWindowFcnCamera(@imaqCam.detectCornerPointsCallback);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);


            pause(20);
            c.StopPreview();

            delete(c);
            clear c;
        end


        function test_SetUpdatePreview2YCBCR(testCase)
            % test_SetUpdatePreview2YCBCR visually checks the live
            % preview converts frames to YCbCr via imaqCam.toYCBCRCallback
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreview2YCBCR')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreview2YCBCR
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            c.StartPreview();
            c.SetUpdatePreviewWindowFcnCamera(@imaqCam.toYCBCRCallback);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);

            pause(20);
            c.StopPreview();

            delete(c);
            clear c;
        end


        function test_SetUpdatePreviewInsertLensMarks(testCase)
            % test_SetUpdatePreviewInsertLensMarks visually checks the
            % live preview overlays crosshair/lens marks via
            % imaqCam.insertLensMarks, then captures a frame
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreviewInsertLensMarks')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreviewInsertLensMarks
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            %set callback
            lensMarks.imageSizeX=80; %image size in mm
            lensMarks.pos=10; %mm marks position from center
            f=@(obj,event,hImage)imaqCam.insertLensMarks(obj,event,hImage, lensMarks);

            c.StartPreview();
            c.SetUpdatePreviewWindowFcnCamera(f);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);

            pause(10);
            c.StopPreview();

            c.Start();
            c.Capture();
            c.Stop();

            figure; imshow(c.Data.I); title('image capture')

            delete(c);
            clear c;
        end

        function test_SetUpdatePreviewDetectEdge(testCase)
            % test_SetUpdatePreviewDetectEdge visually checks the live
            % preview shows an edge map via imaqCam.detectEdgeCallback
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreviewDetectEdge')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreviewDetectEdge
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            c.StartPreview();
            c.SetUpdatePreviewWindowFcnCamera(@imaqCam.detectEdgeCallback);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);

            pause(20);
            c.StopPreview();

            delete(c);
            clear c;
        end

        function test_SetUpdatePreviewSubtractRef(testCase)
            % test_SetUpdatePreviewSubtractRef captures a reference
            % frame, then visually checks the live preview subtracts it
            % from every subsequent frame via imaqCam.subtractRefImageCallback
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreviewSubtractRef')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreviewSubtractRef
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all

            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            %capture ref
            c.Start();
            c.Capture();
            refImage=c.Data.I;

            %set callback
            f=@(obj,event,hImage)imaqCam.subtractRefImageCallback(obj,event,hImage, refImage);

            c.StartPreview();
            c.SetUpdatePreviewWindowFcnCamera(f);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);

            pause(20);
            c.StopPreview();

            delete(c);
            clear c;
        end



        function test_SetUpdatePreviewDetectEdgeFromRGBCam(testCase)
            % test_SetUpdatePreviewDetectEdgeFromRGBCam repeats
            % test_SetUpdatePreviewDetectEdge, intended for an RGB camera
            % (the dedicated @RGBPCCam init handle is commented out, so
            % it currently uses the same camera as the other tests)
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreviewDetectEdgeFromRGBCam')
            %mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreviewDetectEdgeFromRGBCam
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};
            %c=imaqCam(@RGBPCCam);
            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            c.StartPreview();
            c.SetUpdatePreviewWindowFcnCamera(@imaqCam.detectEdgeCallback);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);

            pause(20);
            c.StopPreview();

            delete(c);
            clear c;
        end


        function test_SetUpdatePreviewDetectEdgeFromGVCam(testCase)
            % test_SetUpdatePreviewDetectEdgeFromGVCam repeats
            % test_SetUpdatePreviewDetectEdge, intended for a grayscale
            % camera (the dedicated @GVPCCam init handle is commented
            % out, so it currently uses the same camera as the other tests)
            %run(testStandardHW_ImaqCam_ClassVer, 'test_SetUpdatePreviewDetectEdgeFromGVCam')
            %mtest testStandardHW_ImaqCam_ClassVer:test_SetUpdatePreviewDetectEdgeFromGVCam
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            close all
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};
            %c=imaqCam(@GVPCCam);
            c=imaqCam(fh);
            ImSize=c.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c.hImage=hImage;

            %por el momento para que funciones hay que inicializar los hImage desde
            %fuera mdiante imshow o image
            %podemos usar SetUpdatePreviewWindowFcnCameraR anstes o depues del preview
            %HWCams.SetUpdatePreviewWindowFcnCameraR(@Passive3DCam.detectCornerPointsCallback);
            %HWCams.SetUpdatePreviewWindowFcnCameraL(@Passive3DCam.showImagePairCallback);

            c.StartPreview();
            c.SetUpdatePreviewWindowFcnCamera(@imaqCam.detectEdgeCallback);

            %c.SetUpdatePreviewWindowFcnCamera(@imaqCam.VoidUpdatePreviewCallback);
            %c.SetUpdatePreviewWindowFcnCamera(@imaqcallback);

            pause(20);
            c.StopPreview();

            delete(c);
            clear c;
        end


        function test_ImaqCamSaveLoad(testCase)
            % test_ImaqCamSaveLoad persists an imaqCam instance to disk
            % and restores it, then visually checks preview with an edge
            % callback still works afterwards
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamSaveLoad')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamSaveLoad
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %create a imaqCamObjet and save it
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            c=imaqCam(fh);

            fileName='AQCam.mat';
            imaqCam.save(c, fileName);
            delete(c);

            %create a new cam objet from file
            c1=imaqCam.load(fileName);

            ImSize=c1.ImageSize;
            NR=ImSize(1);
            NC=ImSize(2);
            NB=ImSize(3);

            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','My Preview Window');

            %handle to RGB image
            hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            c1.hImage=hImage;

            c1.StartPreview();
            c1.SetUpdatePreviewWindowFcnCamera(@imaqCam.detectEdgeCallback);
            pause(5);

            %clean
            c1.StopPreview();
            delete(c1);
            delete(fileName);

        end

        function test_getVidFromName(testCase)
            % test_getVidFromName visually checks
            % imaqCam.getVidFromName returns a previewable video object
            % for a given adaptor/device name/format (does not go
            % through the imaqCam constructor, so unaffected by its
            % camGeomCal gap)
            %run(testStandardHW_ImaqCam_ClassVer, 'test_getVidFromName')
            %mtest testStandardHW_ImaqCam_ClassVer:test_getVidFromName
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %check with imaqtool the adaptor, name and resolition desired
            adaptorName='winvideo';
            name='DFG/USB2pro';
            vidFormat = 'RGB24_768x576';
            vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

            preview(vid);

            pause(3);
            stoppreview(vid);
            delete(vid);

        end

        function test_ImaqCamFrom_getVidFromName(testCase)
            % test_ImaqCamFrom_getVidFromName visually checks an imaqCam
            % built from a zero-argument getVidFromName closure can
            % preview
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamFrom_getVidFromName')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamFrom_getVidFromName
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %check with imaqtool the adaptor, name and resolition desired
            adaptorName='winvideo';
            name='DFG/USB2pro';
            vidFormat = 'RGB24_768x576';
            fh=@()imaqCam.getVidFromName(adaptorName, name, vidFormat); %hadle to a function with no parameters
            c=imaqCam(fh);

            c.StartPreview;

            pause(10);

            c.StopPreview;

        end


        function test_ImaqCamFrom_CamFile(testCase)
            % test_ImaqCamFrom_CamFile visually checks an imaqCam built
            % from an imaqtool-generated camera-init function handle can
            % preview
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamFrom_CamFile')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamFrom_CamFile
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %check with imaqtool the adaptor, name and resolition desired
            fhList={@DMK33UX183Bin3StandardHW,@DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003};
            fh=fhList{1};

            c=imaqCam(fh);
            c.StartPreview;
            pause(10);
            c.StopPreview;
            delete(c)
        end


        function test_ImaqCamFrom_CamName(testCase)
            % test_ImaqCamFrom_CamName visually checks an imaqCam can be
            % built from a camera-init function looked up by name
            % (str2func) for each of two cameras in turn
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCamFrom_CamName')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCamFrom_CamName
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;


            strCam1='DFGUSB2Pro';
            strCam2='DMx41BU02';

            fh={str2func(strCam1), str2func(strCam2)}; %transform string to function handle

            for n=1:length(fh)
                c=imaqCam(fh{n});
                c.StartPreview;
                pause(10);
                c.StopPreview;
                delete(c)
            end

        end

        function test_ImaqCam_setSrcProp(testCase)
            % test_ImaqCam_setSrcProp reads a source property (Contrast),
            % captures, changes the property via setSrcProp, captures
            % again, and visually compares the two frames' difference
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_setSrcProp')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_setSrcProp
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            fhList={@DMK33UX183Bin3StandardHW,@DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003};
            fh=fhList{1};

            %init cam
            c=imaqCam(fh);
            c.Start();
            c.Capture();

            %c.StartPreview();

            %get all props and current vals
            srcInfo=c.getSrcInfo();

            %get propierty
            propName='Contrast';
            propVal=srcInfo.(propName).Value;
            fprintf('\n %s: %f \n', propName, propVal);

            %capture
            c.Start();
            c.Capture();
            c.Stop();
            g1=c.Data.I;

            %change propval
            c.setSrcProp(propName, propVal+2);

            %capture
            c.Start();
            c.Capture();
            c.Stop();
            g2=c.Data.I;

            figure; imagesc(double(g1)-double(g2));

            %checkout val
            srcInfo=c.getSrcInfo();
            propVal=srcInfo.(propName).Value;
            fprintf('\n %s: %f \n', propName, propVal);

            delete(c)


        end


        function test_ImaqCam_CaptureHDRSelfCalibrate(testCase)
            % test_ImaqCam_CaptureHDRSelfCalibrate captures an HDR image
            % twice (first forcing a fresh radiometric self-calibration,
            % then reusing the saved one) and visually compares the
            % resulting radiance/tone maps and their relative error.
            %  Also affected by Capture's HDR-branch known gap (missing
            % weight/makeImageMatrixFromIm/gsolve/hdrFromIm/reinhardGlobal).
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_CaptureHDRSelfCalibrate')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_CaptureHDRSelfCalibrate
            %error('commenta esta linea si quieres hacer una nueva calibracion');
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %fh=@DMx41BU02;
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            %init cam
            c=imaqCam(fh);
            c.StartPreview();

            %get all props and current vals
            srcInfo=c.getSrcInfo();

            %get propierty
            propName='Exposure';
            propVal=srcInfo.(propName).Value;
            fprintf('\n %s: %f \n', propName, propVal);

            %capture
            hdrFlag=true;
            forceCalibration=true;

            %set hdr cal file
            c.Set(char(imaqCamProps.hdrCalFile), 'gMatrixTest.mat');


            %first capture with self calibration
            c.Start();
            c.Capture(hdrFlag, forceCalibration);
            c.Stop();
            g1=c.Data.I;
            t1=c.Data.toneMap;

            figure; imagesc(mat2gray(log(g1))); title('radiance image with self calibration');
            figure; imagesc(mat2gray(t1)); title('tone map with self calibration');

            %checkout val
            srcInfo=c.getSrcInfo();
            propVal=srcInfo.(propName).Value;
            fprintf('\n %s: %f \n', propName, propVal);

            %second capture we use the stored calibration
            hdrFlag=true;
            forceCalibration=false; %deflault value

            %capture using stored calibration
            c.Start();
            c.Capture(hdrFlag, forceCalibration);
            c.Stop();
            g2=c.Data.I;
            t2=c.Data.toneMap;

            figure; imagesc(mat2gray(log(g2))); title('radiance image with self calibration');
            figure; imagesc(mat2gray(t2)); title('tone map with self calibration');

            e=(g1-g2)./g1;
            x=linspace(-1, 1, 1000);
            h=hist(e(:), x);

            figure; plot(x,h); title('relative error distribution in radiance');

            delete(c)
        end



        function test_ImaqCam_CaptureHDRUsingRadCalibration(testCase)
            % test_ImaqCam_CaptureHDRUsingRadCalibration captures an HDR
            % image using a previously saved radiometric calibration
            % file and visually inspects the resulting radiance/tone maps.
            %  Also affected by Capture's HDR-branch known gap (see
            % test_ImaqCam_CaptureHDRSelfCalibrate).
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_CaptureHDRUsingRadCalibration')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_CaptureHDRUsingRadCalibration
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %fh=@DFx41BU02;
            %fh=@DMx41BU02;
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            %c=imaqCam(fh);
            %init cam
            c=imaqCam(fh);
            c.StartPreview();

            %get all props and current vals
            srcInfo=c.getSrcInfo();

            %get propierty
            propName='Exposure';
            propVal=srcInfo.(propName).Value;
            fprintf('\n %s: %f \n', propName, propVal);

            %capture
            hdrFlag=true;
            forceCalibration=false; %def value

            %set hdr cal file
            %c.Set(char(imaqCamProps.hdrCalFile), 'gMatrixDFx41BU02.mat');
            c.Set(char(imaqCamProps.hdrCalFile), 'gMatrixDMx41BU02_15FEB19.mat');


            %capture with using calibration
            c.Start();
            c.Capture(hdrFlag, forceCalibration);
            c.Stop();
            g1=c.Data.I;
            t1=c.Data.toneMap;

            figure; imagesc(mat2gray(log(g1))); title('log radiance image with loaded calibration');
            figure; imagesc(g1(:, :, 3)); title('R channel radiance image with loaded calibration');
            figure; imagesc(t1); title('tone map with loaded calibration');


            delete(c)
        end

        function test_ImaqCam_CaptureUsingGeomCalibration(testCase)
            % test_ImaqCam_CaptureUsingGeomCalibration captures a
            % distorted image, then a geometrically undistorted one
            % using a saved camGeomCal calibration file, and uses its
            % homography to label 4 known mm positions on the image.
            %  Uses c.gc (camGeomCal), which does not exist in this repo
            % (see the class-level known-gap note).
            %aqui mostramos como hacer una captura de imagen, corregir la calibracion
            %geometrica y como usar la homografia para calcular posiciones en px de
            %coordenadas en mm
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_CaptureUsingGeomCalibration')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_CaptureUsingGeomCalibration
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;


            %fh=@DFx41BU02;
            %AQDEBUG
            %fh=@imaqCam.getFirstImaqCamAvailable;
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            %init cam
            c=imaqCam(fh);
            c.StartPreview();

            %for capture()
            hdrFlag=false; %def value
            forceCalibration=false; %def value


            %capture without calibration
            c.Start();

            geoCal=false; %no calibration and fast
            c.Capture(hdrFlag, forceCalibration, geoCal);

            c.Stop();
            g1=c.Data.I;
            figure; imshow(uint8(g1)); title('distorted image');

            %%capture with calibration
            %This is a old Calibration file with no value for the Hpx2mm property of
            %the camGeomCal object of the camera. (the c.gc call bellow)
            %in this case the first extrinsinc params are considered the plane of
            %interest and the homografy is calculated from the Extrinsic and intrinsic
            %values in the loadCal function of the camGeomCal object of the camera that
            %is called when setting the imaqCamProps.geomCalFile property of the camera
            c.Set(char(imaqCamProps.geomCalFile), 'Calib_ResultsDFx41BU02.mat');
            c.Start();

            %setting this flag to true implies that the [Iu, X, Y]=undistortImage(this,
            %I) is called upon capture. If no calibration is present distorion params
            %will be zero and intrinsic params will be by default a unitary camera, but
            %after setting the imaqCamProps.geomCalFile theis will have a value

            geoCal=true; %calibration and slow
            c.Capture(hdrFlag, forceCalibration, geoCal);

            c.Stop();
            g1=c.Data.I;
            x=c.Data.X;
            y=c.Data.Y;
            figure; imshow(uint8(g1)); title('undistorted image');
            figure; h=pcolor(x, y, (rgb2gray(uint8(g1))));
            set(h, 'EdgeColor', 'none');
            title('pcolor image', 'Interpreter', 'none'); xlabel('mm'); ylabel('mm');

            c.StopPreview();

            xyc=[ 0  0  10 10;
                2 10  2  10]; %four corners in cm,

            Hmm2px=c.gc.Hmm2px;
            uvc=camGeomCal.homographyTransform(xyc, Hmm2px);

            text={'XY=(0,2) mm', 'XY=(0,10) mm', 'XY=(10,2) mm', 'XY=(10,10) mm'};
            gtext=insertText(uint8(g1),uvc',text, 'AnchorPoint','LeftBottom');
            figure; imshow(gtext); figure(gcf)

            figure; h=pcolor(x, y, (rgb2gray(uint8(gtext))));
            set(h, 'EdgeColor', 'none');
            title('pcolor image', 'Interpreter', 'none'); xlabel('mm'); ylabel('mm');

            delete(c)

        end


        function test_ImaqCam_CaptureUsingHomography(testCase)
            % test_ImaqCam_CaptureUsingHomography computes a homography
            % from 4 known point correspondences, stores it directly on
            % c.gc, saves it for test_ImaqCam_CaptureUsingStoredHomography,
            % and uses it to label the same 4 points on a captured
            % (zero-distortion) image.
            %  Uses c.gc (camGeomCal), which does not exist in this repo
            % (see the class-level known-gap note).
            %aqui mostramos como hacer una captura de imagen, calcular la homografia
            %con el plano y  como usar la homografia para calcular posiciones en px de
            %coordenadas en mm (usamos como dsitorsion geometrica la por defecto que es
            %kc=[0 0 0 0 0];
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_CaptureUsingHomography')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_CaptureUsingHomography
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;


            %fh=@DFx41BU02;
            %AQDEBUG
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            %init cam
            c=imaqCam(fh);

            %calculate homography (normally using ginput)
            xyc=[ 0  0  10 10;
                0 10  0  10]; %four corners in cm,

            uvc=[ 10*xyc(1, :)+50;
                20*xyc(2, :)+50]; %four corners in px,

            Hpx2mm = camGeomCal.homographySolve(uvc, xyc); %px2mm

            %store homography
            c.gc.Hpx2mm=Hpx2mm;

            %save for later use in another test
            CalFileName=['Calib_Results' '_ImaqCam_CaptureUsingHomography.mat'];
            c.gc.saveCal(CalFileName);

            %capture with homography
            c.Start();

            %for capture()
            hdrFlag=false; %def value
            forceCalibration=false; %def value
            geoCal=true; %with kc=[0 0 0 0 0]; is fast
            c.Capture(hdrFlag, forceCalibration, geoCal);

            c.Stop();
            g1=c.Data.I;
            x=c.Data.X;
            y=c.Data.Y;

            figure; imshow(uint8(g1)); title('undistorted image');

            figure; imshow(uint8(g1)); title('undistorted image');
            figure; h=pcolor(x, y, (rgb2gray(uint8(g1))));
            set(h, 'EdgeColor', 'none');
            title('pcolor image', 'Interpreter', 'none'); xlabel('mm'); ylabel('mm');

            text={'XY=(0,0) mm', 'XY=(0,10) mm', 'XY=(10,0) mm', 'XY=(10,10) mm'};
            gtext=insertText(uint8(g1),uvc',text, 'AnchorPoint','LeftBottom');
            figure; imshow(gtext); figure(gcf)

            figure; h=pcolor(x, y, (rgb2gray(uint8(gtext))));
            set(h, 'EdgeColor', 'none');
            title('pcolor image', 'Interpreter', 'none'); xlabel('mm'); ylabel('mm');

            delete(c)

        end


        function test_ImaqCam_CaptureUsingStoredHomography(testCase)
            % test_ImaqCam_CaptureUsingStoredHomography loads the
            % homography calibration file saved by
            % test_ImaqCam_CaptureUsingHomography and reuses it to label
            % the same 4 known mm positions on a newly captured image.
            %  Uses c.gc (camGeomCal), which does not exist in this repo
            % (see the class-level known-gap note); also depends on
            % test_ImaqCam_CaptureUsingHomography having run first to
            % produce its calibration file.
            %aqui mostramos como hacer una captura de imagen, y mediante la homografia almacenada en el test anterior calcular posiciones en px de
            %coordenadas en mm (usamos como dsitorsion geometrica la por defecto que es
            %kc=[0 0 0 0 0];
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_CaptureUsingStoredHomography')
            %testAAAddReferencesPathStandardHW; mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_CaptureUsingStoredHomography
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;


            %fh=@DFx41BU02;
            %AQDEBUG
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};

            %init cam
            c=imaqCam(fh);

            %load calibration from the former test
            CalFileName=['Calib_Results' '_ImaqCam_CaptureUsingHomography.mat'];
            c.gc.loadCal(CalFileName);
            %another posibility is
            %c.Set(char(imaqCamProps.geomCalFile), CalFileName);

            %capture with homography
            c.Start();

            %for capture()
            hdrFlag=false; %def value
            forceCalibration=false; %def value
            geoCal=true; %with kc=[0 0 0 0 0]; is fast
            c.Capture(hdrFlag, forceCalibration, geoCal);

            c.Stop();
            g1=c.Data.I;
            x=c.Data.X;
            y=c.Data.Y;

            figure; imshow(uint8(g1)); title('undistorted image');

            figure; imshow(uint8(g1)); title('undistorted image');
            figure; h=pcolor(x, y, (rgb2gray(uint8(g1))));
            set(h, 'EdgeColor', 'none');
            title('pcolor image', 'Interpreter', 'none'); xlabel('mm'); ylabel('mm');

            %locate four corners given in mm in te image in px
            xyc=[ 0  0  10 10;
                0 10  0  10]; %four corners in cm,
            uvc=camGeomCal.homographyTransform(xyc, c.gc.Hmm2px);

            text={'XY=(0,0) mm', 'XY=(0,10) mm', 'XY=(10,0) mm', 'XY=(10,10) mm'};
            gtext=insertText(uint8(g1),uvc',text, 'AnchorPoint','LeftBottom');
            figure; imshow(gtext); figure(gcf)

            figure; h=pcolor(x, y, (rgb2gray(uint8(gtext))));
            set(h, 'EdgeColor', 'none');
            title('pcolor image', 'Interpreter', 'none'); xlabel('mm'); ylabel('mm');

            delete(c)

        end



        function test_ImaqCam_CaptureHDRUsingGeomCalibration(testCase)
            % test_ImaqCam_CaptureHDRUsingGeomCalibration captures an
            % HDR image distorted and then geometrically undistorted
            % (via a saved camGeomCal calibration file), visually
            % inspecting the radiance/luminance maps and mm coordinate grids.
            %  Affected both by Capture's HDR-branch known gap and by
            % c.gc (camGeomCal) not existing in this repo (see the
            % class-level known-gap note).
            %run(testStandardHW_ImaqCam_ClassVer, 'test_ImaqCam_CaptureHDRUsingGeomCalibration')
            %mtest testStandardHW_ImaqCam_ClassVer:test_ImaqCam_CaptureHDRUsingGeomCalibration
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            close all;

            %fh=@DMx41BU02;
            fhList={@DMK33UX183Bin3StandardHW, @DFGPro_winvideo_Y800_768x576, @DFGPro_winvideo_Y800_640x480, @DFGPro_tisimaq_r2013_64_PALB_Y800_720x576, @DFGPro_winvideo_Y800_720x576, @DMx41BU02, @DFGUSB2Pro, @DFK31BF03Z, @DFK24UJ003, @imaqCam.getFirstImaqCamAvailable};
            fh=fhList{1};
            %init cam
            c=imaqCam(fh);
            c.StartPreview();

            %for capture()
            hdrFlag=true;
            c.Set(char(imaqCamProps.hdrCalFile), 'gMatrixDMx41BU02_15FEB19.mat');
            forceCalibration=false; %def value
            geoCal=true; %def value

            %capture without calibration
            c.Start();
            geoCal=false; %default
            c.Capture(hdrFlag, forceCalibration, geoCal);
            c.Stop();
            g1=c.Data.I;
            figure; imagesc(log(g1)); title('HDR distorted image');
            g2=c.Data.L;
            figure; imagesc(log(g2)); title('Luminance distorted image');

            %%capture with calibration
            c.Set(char(imaqCamProps.geomCalFile), 'Calib_ResultsDMx41BU02.mat');
            c.Start();

            geoCal=true;
            c.Capture(hdrFlag, forceCalibration, geoCal);
            c.Stop();
            g1=c.Data.I;
            figure; imagesc(log(g1)); title('HDR undistorted image');
            g2=c.Data.L;
            figure; imagesc(log(g2)); title('Luminance undistorted image');

            figure; imagesc(c.Data.X); title('X coordinate');
            figure; imagesc(c.Data.Y); title('Y coordinate');

            %for this image calib GUI choose the Y axis along the columns
            figure; pcolor(c.Data.Y(1:10:end, 1:10:end), c.Data.X(1:10:end, 1:10:end), c.Data.L(1:10:end, 1:10:end))
            xlabel('X mm'); ylabel ('Y mm');





            c.StopPreview();
            delete(c)
        end
    end
end

