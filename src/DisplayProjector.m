classdef DisplayProjector <  handle
    % DisplayProjector Java-wrapper (fullscreen.m) image projector
    %
    % Description:
    %   Uses the physical display size - if the OS applies scaling, this
    %   differs from the logical display size; use DisplayProjectorMatlab
    %   instead if logical size is needed (see its Init()). See
    %   DisplayTypes for available projector types, DisplayFactory for a
    %   static factory, and testFPADisplayProjector for unit tests.
    %% props
    %public
    properties
        gList; % cell list of images
        Monitor; % number of the screen
        flipMonitor; %default true
    end

    %get only propos
    properties (SetAccess=private)
        screenSize; % screen resolution
    end


    %% public methods
    methods
        function this=DisplayProjector()
            % DisplayProjector constructs a Java-wrapper display projector
            %interchange monitor 0->1
            %AQ 5MAY20 esto es una �apa para salir del paso con win7 en PC
            %IOT Mapper en espera de actualizar a win10
            this.flipMonitor=true;
            % Props Initialization
            this.Init();
        end

        function Display(this, n)
            % Display shows image n from gList on the target monitor
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            N=length(this.gList);
            if n>N
                retMsg=['image index exceeds stored list length'];
                error([callFunc, '->' retMsg]);
            end
            
            %closescreen;
            fullscreen(this.gList{n}, this.Monitor);    
        end
        
        function DisplayRGB(this, RGB)
            % DisplayRGB fills the whole screen with solid color RGB
            % (3-element vector, components in [0, 1])
            X(:,:,1) = uint8(255*RGB(1)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,2) = uint8(255*RGB(2)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,3) = uint8(255*RGB(3)*ones(this.screenSize(1),this.screenSize(2)));
            
            fullscreen(X, this.Monitor);  
        end
        
        function TextureImages(this)
            % TextureImages no-op here (other projectors pre-load
            % images before display; this one doesn't need to)

        end

        function CloseScreen(this)
            % CloseScreen closes the fullscreen window
            closescreen;
        end
    end


    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init detects the target monitor (flipping 0<->1 on 2-monitor
            % setups if flipMonitor) and reads its physical resolution
            %pillamos posicion de los monitores disponibles
            posAll=get(0,'MonitorPositions');
            
            %Pillamos posicion monitor y sus dimensiones
            this.Monitor=size(posAll, 1); %chek number of monitors
            if(this.Monitor==2) %if there are two
                if this.flipMonitor %check if we want to flip them
                    this.Monitor=1;
                end
            end
            
            
            ge = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment();
            gds = ge.getScreenDevices();

            NR = gds(this.Monitor).getDisplayMode().getHeight();
            NC = gds(this.Monitor).getDisplayMode().getWidth();
                        
            %the function fullscreen only uses RGB images
            this.screenSize=[NR, NC, 3];    
            
            %AQDEBUG reset current JFrame
            %this.CloseScreen();
        end
    end
    
    %% statatic methods
    methods(Static)
    end
       
            
end

