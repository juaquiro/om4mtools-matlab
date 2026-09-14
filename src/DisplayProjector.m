%> @file DisplayProjector.m
%> @brief Java wrapper image projector class
%> @copyright 2019 IOT

% ======================================================================
%> @brief this class implements the Java wrapper image projector class
%> @brief this class uses physical display size, if there is scaling this
%> @brief size is different from logical display size. 
%> @brief if logical size is needed use DisplayProjectorMatlab.
%> @brief see DisplayProjectorMatlab.Init()
%> @see DisplayTypes for avalible projector follower types
%> @see DisplayFactory for a static factory
%> @see testFPADisplayProjector for unit tests
% ======================================================================
classdef DisplayProjector <  handle
    %% props    
    %public
    properties  
        %> cell list of images  
        gList; 
        %> number of the screen
        Monitor;
        flipMonitor; %default true
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
        function this=DisplayProjector()   
            %interchange monitor 0->1     
            %AQ 5MAY20 esto es una ñapa para salir del paso con win7 en PC
            %IOT Mapper en espera de actualizar a win10
            this.flipMonitor=true;
            % Props Initialization
            this.Init();
        end                
        
        % ======================================================================
        %> @brief this funcion display a image in the screen
        %> @param n number of the image in gList
        % ======================================================================
        function Display(this, n)
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
        
        % ======================================================================
        %> @brief this funcion project one color in the screen
        %> @param RGB matriz RGB (componentes entre 0 y 1) que identifica el color que se desea proyectar
        % ======================================================================
        function DisplayRGB(this, RGB)
            % Color the screen grey
            X(:,:,1) = uint8(255*RGB(1)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,2) = uint8(255*RGB(2)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,3) = uint8(255*RGB(3)*ones(this.screenSize(1),this.screenSize(2)));
            
            fullscreen(X, this.Monitor);  
        end
        
        % ======================================================================
        %> @brief this funcion pre charge the images before the display in others projectors
        % ======================================================================
        function TextureImages(this)
            
        end
        
        % ======================================================================
        %> @brief this funcion clear the screen
        % ======================================================================
        function CloseScreen(this)
            closescreen;
        end
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)

            
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

