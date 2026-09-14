%> @file DisplayProjectorPsych.m
%> @brief Psychtoolbox image projector class
%> @copyright 2019 IOT
%> @author SS 11/06/19

% ======================================================================
%> @brief this class implements the DisplayProjector class with Psychtoolbox
%> @details Esta funcion utiliza la version 3.0.15 de la toolbox y se puede encontrar aqui: Dropbox (IOT)\ExperimentsCosmeticInspection\Documentacion Proyecto\Pschtoolbox Para instalarlo se pueden seguir los pasos de la pagina oficial: http://psychtoolbox.org/download.html
%> @see DisplayTypes for avalible projector follower types
%> @see DisplayFactory for a static factory
%> @see testFPADisplayProjectorPsych for unit tests
% ======================================================================
classdef DisplayProjectorPsych <  handle
    %% props    
    %public
    properties 
        %> cell list of images  
        gList;  
        %> handle of the window 
        window;
        windowRect;
        %> screen frecuency
        waitframes;
        ifi;
        imageTexture;
        vbl
    end
            
    %get only propos
    properties (SetAccess=private)  
        %> screen resolution
        screenSize;
    end
    
    
    %% public methods
    methods
        % ======================================================================
        %> @brief constructor
        % ======================================================================
        function this=DisplayProjectorPsych()            
            % Props Initialization
            this.Init();
        end                
        
        % ======================================================================
        %> @brief this funcion display a image in the screen
        %> @param n number of the image in gList
        % ======================================================================
        function Display(this, n)
            N=length(this.gList);
            if n>N
                retMsg=['image index exceeds stored list length'];
                error([callFunc, '->' retMsg]);
            end
            
            % Draw the image to the screen, unless otherwise specified PTB will draw
            % the texture full size in the center of the screen.
            Screen('DrawTexture', this.window, this.imageTexture(n), [], [], 0);

            % Flip to the screen
            this.vbl = Screen('Flip', this.window, this.vbl + (this.waitframes - 0.5) * this.ifi);
        end
        
        % ======================================================================
        %> @brief this funcion project one color in the screen
        %> @param RGB matriz RGB (componentes entre 0 y 1) que identifica el color que se desea proyectar
        % ======================================================================
        function DisplayRGB(this, RGB)
            Screen('FillRect', this.window, 255*RGB);

            % Flip to the screen
            this.vbl = Screen('Flip', this.window, this.vbl + (this.waitframes - 0.5) * this.ifi);
        end
        
        % ======================================================================
        %> @brief this funcion pre charge the images before the display
        % ======================================================================
        function TextureImages(this)
            % Make the image into a texture
            for i=1:length(this.gList)
                this.imageTexture(i) = Screen('MakeTexture', this.window, this.gList{i});
            end
            Screen('PreloadTextures', this.window);
        end
        
        % ======================================================================
        %> @brief this funcion clear the screen
        % ======================================================================
        function CloseScreen(this)
            sca;
        end
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            try
                PsychtoolboxVersion;
            catch ME
                error('Install Psychtoolbox-3');  
            end
            
            % Here we call some default settings for setting up Psychtoolbox
            PsychDefaultSetup(2);

            % Get the screen numbers
            screens = Screen('Screens');

            % Draw to the external screen if avaliable
            screenNumber = max(screens);

            % Define black and white
            white = WhiteIndex(screenNumber);
            black = BlackIndex(screenNumber);

            % Open an on screen window
            Screen('Preference', 'WindowShieldingLevel', 0);
            [this.window, this.windowRect] = PsychImaging('OpenWindow', screenNumber, black);

            % Get the size of the on screen window
            [screenXpixels, screenYpixels] = Screen('WindowSize', this.window);  
            this.screenSize=[screenYpixels, screenXpixels, 3];
            
            % Enable alpha blending for anti-aliasing
            % For help see: Screen BlendFunction?
            % Also see: Chapter 6 of the OpenGL programming guide
%             Screen('BlendFunction', this.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            % Retreive the maximum priority number
            topPriorityLevel = MaxPriority(this.window);
            Priority(topPriorityLevel);
            
            % Measure the vertical refresh rate of the monitor
            this.ifi = Screen('GetFlipInterval', this.window);

            % Numer of frames to wait when specifying good timing. Note: the use of
            % wait frames is to show a generalisable coding. For example, by using
            % waitframes = 2 one would flip on every other frame. See the PTB
            % documentation for details. In what follows we flip every frame.
            this.waitframes = 1;
            
            Screen('FillRect', this.window, [0 0 0]);
            this.vbl = Screen('Flip', this.window);
        end
    end
    
    %% statatic methods
    methods(Static)
    end
       
            
end

