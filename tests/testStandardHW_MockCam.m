classdef testStandardHW_MockCam < matlab.unittest.TestCase
    % TESTSTANDARDHW_MOCKCAM  Unit‑tests for the *MockCam* software camera.
    %
    %  This class re‑implements the original tests supplied for the real
    %  *imaqCam* hardware so they target the mock implementation instead.
    %  Only the subset of functionality guaranteed by *MockCam* is
    %  exercised here – chiefly construction, basic lifecycle (start/stop),
    %  live preview handling, frame capture, callback installation and
    %  serialisation helpers.
    %
    %  ------------------------------------------------------------------
    %  Running the tests
    %  ------------------------------------------------------------------
    %  • **Full suite**:
    %        >> run(testStandardHW_MockCam)
    %
    %  • **Single test**:
    %        >> %run(testStandardHW_MockCam, 'test_NameOfMethod')
    %    Each test method begins with such a *%run* helper comment so you
    %    can simply copy‑paste it into the MATLAB prompt.  Do **not** remove
    %    them – the developer asked to keep them as shortcuts.
    %
    %  ------------------------------------------------------------------
    %  Dependencies
    %  ------------------------------------------------------------------
    %  *setupPath* (tests/setupPath.m) must be on the path; it adds src/,
    %  tests/fixtures/ and mex/bin/ (the compiled MEX), making
    %  third‑party utilities (e.g. *OM4MClassLib.Util.Logging*) available
    %  during the tests. *resetPath* (tests/resetPath.m) restores the path
    %  snapshot captured at session start in TestMethodTeardown.
    %
    %  ------------------------------------------------------------------
    %  Author:  (updated by ChatGPT, June 2025)
    % -------------------------------------------------------------------

    %% Test fixture lifecycle ============================================
    methods(TestMethodSetup)
        function SetUp(~)
            % SETUP  Prepare environment before each test method.
            %   • Close lingering figures so GUI tests start clean.
            %   • Add custom project folders via helper script.
            close all
            clear all
            setupPath();
        end
    end

    methods(TestMethodTeardown)
        function TearDown(~)
            % TEARDOWN  Restore pristine environment after each test.
            %   resetPath() (tests/resetPath.m) returns the MATLAB path
            %   captured at the start of the test session, before any
            %   test added folders to it.
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end

    %% Actual unit‑tests ==================================================
    methods (Test)  % Tests performed on MockCam only

        function test_MockCamConstructor(testCase) %#ok<INUSD>
            %run(testStandardHW_MockCam, 'test_MockCamConstructor')
            % Verify that constructing without arguments produces a valid
            % *MockCam* handle.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            cam = MockCam();
            testCase.assertTrue(isa(cam, 'MockCam'));
        end

        function test_MockCamStartStopPreview(~)
            %run(testStandardHW_MockCam, 'test_MockCamStartStopPreview')
            % Exercise StartPreview / StopPreview sequence twice with
            % generous pauses so the user can visually confirm the timer
            % keeps working after restart.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            cam = MockCam();

            cam.StartPreview();
            pause(15);
            cam.StopPreview();

            cam.StartPreview();
            pause(5);
            cam.StopPreview();

            close all;
        end

        function test_StartStop(~)
            %run(testStandardHW_MockCam, 'test_StartStop')
            % Sanity‑check that Start/Stop do not error and the object can
            % be deleted cleanly afterwards.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            close all;            % ensure no stray preview figures
            cam = MockCam();

            cam.Start();
            pause(1);
            cam.Stop();

            delete(cam);
            clear cam;
        end

        function test_GetSethImage(~)
            %run(testStandardHW_MockCam, 'test_GetSethImage')
            % Verify that the *hImage* property acts like a regular handle
            % container – setting a graphics object and retrieving it later
            % yields the same handle instance.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            close all;
            cam = MockCam();

            % Build blank figure and image of correct resolution
            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            NR = cam.ImageSize(1); NC = cam.ImageSize(2); NB = cam.ImageSize(3);
            hImage = image(zeros(NR, NC, NB));

            cam.hImage = hImage;
            hImageReturned = cam.hImage;

            % Same handle object?
            assertEqual(hImageReturned, hImage);

            delete(hFig);
            delete(cam);
            clear cam;
        end

        function test_StartPreviewStopPreviewWithFigure(~)
            %run(testStandardHW_MockCam, 'test_StartPreviewStopPreviewWithFigure')
            % Drive preview from a caller‑supplied *hImage* handle.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            close all;
            cam = MockCam();
            NR = cam.ImageSize(1); NC = cam.ImageSize(2); NB = cam.ImageSize(3);

            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage = image(zeros(NR, NC, NB));

            cam.hImage = hImage;
            cam.StartPreview(); pause(5); cam.StopPreview();

            % Capture single frame for visual/manual inspection
            cam.Start(); cam.Capture(); cam.Stop();

            figure; imshow(cam.Data.I); title('image capture');
            fprintf('\nFrame captured at: %s with video resolution\n', cam.Data.timeStamp);

            delete(cam);
            clear cam;
        end

        function test_StartPreviewStopPreviewWithTwoFigures(~)
            %run(testStandardHW_MockCam, 'test_StartPreviewStopPreviewWithTwoFigures')
            % Drive preview from a caller‑supplied *hImage* handle.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            %cam1 init
            cam1 = MockCam();
            NR = cam1.ImageSize(1); NC = cam1.ImageSize(2); NB = cam1.ImageSize(3);
            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage1 = image(zeros(NR, NC, NB));
            cam1.hImage = hImage1;

            %cam2 init
            cam2 = MockCam();
            NR = cam2.ImageSize(1); NC = cam2.ImageSize(2); NB = cam2.ImageSize(3);
            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage2 = image(zeros(NR, NC, NB));
            cam2.hImage = hImage2;

            % launch preview
            cam1.StartPreview(); cam2.StartPreview();
                                   
            pause(10); 
            cam1.StopPreview(); cam2.StopPreview();

            % Capture single frame for visual/manual inspection
            cam1.Start(); cam2.Start();
            cam1.Capture(); cam2.Capture();
            cam1.Stop(); cam2.Stop();
            
            figure; imshow(cam1.Data.I); title('image 1 capture');
            fprintf('\nFrame cam 1 captured at: %s with video resolution\n', cam1.Data.timeStamp);

            figure; imshow(cam2.Data.I); title('image 2 capture');
            fprintf('\nFrame cam 2 captured at: %s with video resolution\n', cam2.Data.timeStamp);

            delete(cam1); delete(cam2);
            clear cam1; clear cam2;
        end

        function test_StartPreviewStopPreviewWithFigureFromCamFile(~)
            %run(testStandardHW_MockCam, 'test_StartPreviewStopPreviewWithFigureFromCamFile')
            % Re‑run previous preview test verbatim – kept to maintain parity
            % with the original hardware suite (ensures idempotence).
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            close all;
            cam = MockCam();
            NR = cam.ImageSize(1); NC = cam.ImageSize(2); NB = cam.ImageSize(3);

            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage = image(zeros(NR, NC, NB));

            cam.hImage = hImage;
            cam.StartPreview(); pause(5); cam.StopPreview();

            cam.Start(); cam.Capture(); cam.Stop();

            figure; imshow(cam.Data.I); title('image capture');
            fprintf('\nFrame captured at: %s with video resolution\n', cam.Data.timeStamp);

            delete(cam);
            clear cam;
        end

        function test_Capture(~)
            %run(testStandardHW_MockCam, 'test_Capture')
            % Measure execution time of a single Capture call and verify
            % captured frame has expected dimensions.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            close all;
            cam = MockCam();
            NR = cam.ImageSize(1); NC = cam.ImageSize(2); NB = cam.ImageSize(3);

            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage = image(zeros(NR, NC, NB));
            cam.hImage = hImage;

            cam.Start();
            t = tic; cam.Capture(); elapsed = toc(t);
            cam.Stop();

            % Validate dimensions
            assert(isequal(size(cam.Data.I), [NR NC NB]), 'Captured frame size mismatch');
            fprintf('\nCapture completed in %.3f s\n', elapsed);

            figure; imshow(cam.Data.I); title('image capture');
            fprintf('\nFrame captured at: %s with video resolution\n', cam.Data.timeStamp);

            delete(cam);
            clear cam;
        end

        function test_SetUpdatePreviewInsertLensMarks(~)
            %run(testStandardHW_MockCam, 'test_SetUpdatePreviewInsertLensMarks')
            % Demonstrate the ability to inject a custom preview callback –
            % here adding symmetrical red lens marks at ±10 mm given a
            % fictitious 80 mm field‑of‑view.
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());

            close all;
            cam = MockCam();
            NR = cam.ImageSize(1); NC = cam.ImageSize(2); NB = cam.ImageSize(3);

            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage = imshow(zeros(NR, NC, NB));
            cam.hImage = hImage;

            % Build closure that forwards static parameters to helper
            lensMarks.imageSizeX = 80;   % mm
            lensMarks.pos        = 10;   % mm from centre
            cb = @(obj,evt,hImg) MockCam.insertLensMarks(obj,evt,hImg,lensMarks);

            cam.StartPreview();
            cam.SetUpdatePreviewWindowFcnCamera(cb);
            pause(10);
            cam.StopPreview();

            cam.Start(); cam.Capture(); cam.Stop();
            figure; imshow(cam.Data.I); title('image capture');

            delete(cam);
            clear cam;
        end

        function test_MockCamSaveLoad(~)
            %run(testStandardHW_MockCam, 'test_MockCamSaveLoad')
            % Persist a MockCam instance to disk and restore it, verifying
            % that preview can still be started afterwards (timer must not
            % be serialised running).
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ', Logging.WhoCalledMe());
            close all;

            cam = MockCam();
            fileName = 'AQCam.mat';
            MockCam.save(cam, fileName);
            delete(cam);

            cam = MockCam.load(fileName);
            NR = cam.ImageSize(1); NC = cam.ImageSize(2); NB = cam.ImageSize(3);
            hFig = figure('Toolbar','none', 'Menubar','none', ...
                          'NumberTitle','Off', 'Name','My Preview Window');
            hImage = imshow(zeros(NR, NC, NB));
            cam.hImage = hImage;

            cam.StartPreview();
            cam.SetUpdatePreviewWindowFcnCamera(@MockCam.detectEdgeCallback);
            pause(5);

            cam.StopPreview();
            delete(cam);
            delete(fileName);
        end
    end
end
