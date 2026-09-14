classdef MockCam < handle
    %% MockCam  -  Software mock‑up of a physical camera
    %  This implementation is intentionally lightweight and only aims to
    %  satisfy the subset of the imaqCam API exercised by the unit tests
    %  in *testStandardHW_MockCam.m*.
    %
    %  Key points enforced by the tests:
    %    * ImageSize must always be 640 x 480, RGB (8‑bit).
    %    * Capture must return a slightly different frame every call.
    %    * Preview must show a "live" image (simple frame with temporal noise).

    properties (Constant)
        %% Fixed video resolution ([rows, cols, channels])
        ImageSize = [480 640 3];
    end

    %% Public state -------------------------------------------------------
    properties
        hImage      % handle to the RGB image used for preview
        Data = struct('I', [], 'timeStamp', datetime.empty); % last captured frame & timestamp
    end

    %% Internal (non‑serialised) state -----------------------------------
    properties (Access = private, Transient)
        previewTimer      % MATLAB timer responsible for the live preview
        userUpdateFcn     % callback installed with SetUpdatePreviewWindowFcnCamera
    end

    properties (Access = private)
        isStopped logical = true;
        frameCounter uint32 = 0;  % monotonically increasing frame index
    end

    %% Constructor / destructor ------------------------------------------
    methods
        function this = MockCam(varargin) %#ok<*INUSD>
            % Constructor deliberately accepts -and ignores- any input so
            % calls such as MockCam(fh) do not error out.
        end

        function delete(this)
            % Make sure no timer is left running.
            try
                this.StopPreview();
            catch
            end
        end
    end

    %% Basic camera control ----------------------------------------------
    methods
        function Start(this)
            this.isStopped = false;
        end

        function Stop(this)
            this.isStopped = true;
        end

        function StartPreview(this)
            % Create figure / image if the user did not supply one
            if isempty(this.hImage) || ~ishandle(this.hImage)
                f = figure('Name','MockCam Preview','NumberTitle','off', ...
                           'Toolbar','none','Menubar','none');
                ax = axes('Parent',f);
                blank = zeros(this.ImageSize,'uint8');
                this.hImage = imshow(blank,'Parent',ax);
            end

            % Lazily create the timer
            if isempty(this.previewTimer) || ~isvalid(this.previewTimer)
                this.previewTimer = timer( ...
                    'ExecutionMode','fixedRate', ...
                    'Period',0.2, ...      % 5 fps
                    'TimerFcn',@(~,~)this.updatePreview() );
            end
            start(this.previewTimer);
        end

        function StopPreview(this)
            if ~isempty(this.previewTimer) && isvalid(this.previewTimer)
                stop(this.previewTimer);
                delete(this.previewTimer);
                this.previewTimer = [];
            end
        end

        function Capture(this, varargin)
            if this.isStopped
                this.Start(); % auto‑start when needed
            end
            frame = this.generateFrame();
            this.Data.I = frame;
            this.Data.timeStamp = datetime('now');

            if ~isempty(this.hImage) && ishandle(this.hImage)
                set(this.hImage,'CData',frame);
            end
        end
    end

    %% Preview helpers ----------------------------------------------------
    methods
        function SetUpdatePreviewWindowFcnCamera(this, fh)
            if nargin < 2 || isempty(fh)
                fh = @MockCam.VoidUpdatePreviewCallback;
            end
            this.userUpdateFcn = fh;
        end
    end

    methods (Access = private)
        function updatePreview(this)
            if isempty(this.hImage) || ~ishandle(this.hImage)
                return
            end
            I = this.generateFrame();
            if isempty(this.userUpdateFcn)
                set(this.hImage,'CData',I);
            else
                try
                    this.userUpdateFcn(this, [], this.hImage);
                catch
                    set(this.hImage,'CData',I);
                end
            end
        end

        function I = generateFrame(this)
            % Generate an 8‑bit RGB frame with slight temporal variations.
            rows = this.ImageSize(1);
            cols = this.ImageSize(2);
            channel_number=3;

            [x, ~]=meshgrid(1:cols, 1:rows);
            fringes_field=cols*rand()/100;
            noise = uint8(randi([0 20], rows, cols));
            g=noise + uint8(128+100*cos(2*pi*fringes_field*x/cols + 2*pi*double(this.frameCounter)/4.0));
            I = repmat(g, 1, 1, 3);  % duplicate into 3 channels

            this.frameCounter = this.frameCounter + 1;
        end
    end

    %% Static utilities / callbacks --------------------------------------
    methods (Static)
        function save(obj, fileName)
            if nargin < 2
                error('Usage: MockCam.save(camObj, ''fileName.mat'')');
            end
            camCopy = obj;
            camCopy.StopPreview();
            camCopy.previewTimer = [];
            camCopy.hImage = [];
            save(fileName, 'camCopy', '-mat');
        end

        function cam = load(fileName)
            s = load(fileName);
            fn = fieldnames(s);
            cam = s.(fn{1});
        end

        % -------- Preview callbacks -------------------------------------
        function VoidUpdatePreviewCallback(obj, ~, hImage) %#ok<INUSD>
            set(hImage,'CData', obj.generateFrame());
        end

        function detectEdgeCallback(obj, ~, hImage)
            I = obj.generateFrame();
            BW = edge(rgb2gray(I), 'Canny');
            overlay = cat(3, uint8(BW)*255, zeros(size(BW), 'uint8'), zeros(size(BW), 'uint8'));
            set(hImage,'CData', max(I, overlay));
        end

        function detectCornerPointsCallback(obj, ~, hImage) %#ok<INUSD>
            % Very crude "corner" overlay: draw green squares in the image corners
            I = obj.generateFrame();
            rows = size(I,1);
            cols = size(I,2);
            sz = 5; % pixels
            I(1:sz, 1:sz, 2) = 255;                          % top‑left
            I(1:sz, cols-sz+1:cols, 2) = 255;                % top‑right
            I(rows-sz+1:rows, 1:sz, 2) = 255;                % bottom‑left
            I(rows-sz+1:rows, cols-sz+1:cols, 2) = 255;      % bottom‑right
            set(hImage,'CData', I);
        end

        function insertLensMarks(obj, ~, hImage, lensMarks)
            I = obj.generateFrame();
            cols = size(I,2);
            centre = round(cols/2);
            pxOffset = round(lensMarks.pos / lensMarks.imageSizeX * cols);
            idx = [centre - pxOffset, centre + pxOffset];
            idx = idx(idx > 0 & idx <= cols);
            I(:, idx, 1) = 255;  % vertical red marks
            set(hImage,'CData', I);
        end
    end
end
