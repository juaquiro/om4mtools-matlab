classdef DisplayProjectorMatlab <  handle
    % DisplayProjectorMatlab MATLAB-figure-based image projector -
    % requires R2018a or newer
    %
    % Description:
    %   Uses the logical display size, which differs from the physical
    %   size when the OS applies scaling (see Init()); use
    %   DisplayProjector (Java-based) instead if the physical size is
    %   needed. See DisplayTypes for available projector types,
    %   DisplayFactory for a static factory, and
    %   testFPADisplayProjectorMatlab for unit tests.
    %% props
    %public
    properties
        gList; % cell list of images
        Monitor; % number of the screen
        hfig; % projector figure handle
        Imag; % projection image handle
    end

    %get only propos
    properties (SetAccess=private)
        screenSize; % screen resolution
    end


    %% public methods
    methods
        function this=DisplayProjectorMatlab(varargin)
            % DisplayProjectorMatlab constructs a MATLAB-figure-based
            % display projector. varargin{1}, if given, is the target
            % monitor number (must not exceed the number of connected
            % monitors); defaults to monitor 2 if there's more than one,
            % else 1.

            posAll=get(0,'MonitorPositions');
            NMons=size(posAll, 1); %number of screen
            if NMons==1
                this.Monitor=1;
            else
                numvarargs = length(varargin);
                if numvarargs == 1
                    if NMons >= varargin{1,1}
                        this.Monitor = varargin{1,1};
                    else
                        error('Incorrect screen number');
                    end
                elseif numvarargs == 0
                    this.Monitor = 2;
                else
                    error('Incorrect number of parameters');
                end
            end
            
            % Props Initialization
            this.Init();
        end
        
        function Display(this, n)
            % Display shows image n from gList on the projector figure
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            N=length(this.gList);
            if n>N
                retMsg='image index exceeds stored list length';
                error([callFunc, '->' retMsg]);
            end
            
            set(this.hfig, 'Visible', 'on');
            this.Imag.CData = this.gList{n};
            drawnow;
        end
        
        function DisplayRGB(this, RGB)
            % DisplayRGB fills the whole screen with solid color RGB
            % (3-element vector, components in [0, 1])
            X(:,:,1) = uint8(255*RGB(1)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,2) = uint8(255*RGB(2)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,3) = uint8(255*RGB(3)*ones(this.screenSize(1),this.screenSize(2)));
            
            this.Imag.CData = X;
            drawnow;
        end
        
        function TextureImages()
            % TextureImages no-op here (other projectors pre-load
            % images before display; this one doesn't need to)

        end

        function CloseScreen(this)
            % CloseScreen hides the projector figure (doesn't actually
            % close it, since that would also destroy hfig/Imag)
            %AQ 6MAY20 do not close, because hfig and Imag are destroyed
            if ishandle(this.hfig)
                set(this.hfig, 'Visible', 'off');
            end
        end
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init creates the fullscreen projector figure on this.Monitor
            % (using MonitorPositions' logical size, rounded, with a
            % warning if it wasn't already integer - see
            % https://undocumentedmatlab.com/articles/working-with-non-standard-dpi-displays)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();

            if verLessThan('matlab', '9.4')
                error('Version must be R2018a or higher');
            end
            
            %pillamos posicion de los monitores disponibles
            %en monitores UHD con un factor de scala diferente de 1
            %get(0,'MonitorPositions'); devuelve un tamaño logico que no se
            %tiene porque corresponder con el tamaño fisico
            %ver https://undocumentedmatlab.com/articles/working-with-non-standard-dpi-displays
            %ademas puede no ser entero y genera un error cdo se construye
            %la matriz de zeros
            %si este es el caso lo mejor es usar FPA.DisplayProjetor que usa
            %Java y si detecta correctamente los tamaños  
            posAll=round(get(0,'MonitorPositions'));

            if not(any(posAll(:)==round(posAll(:))))
                retMsg='screen size not integer. check monitor scaling. Using rounded size';
                warning([callFunc, '->' retMsg]);
            end
            
            %Pillamos posicion monitor y sus dimensiones
            %             this.Monitor=size(posAll, 1); %usamos el ultimo monitor
            
            %Creamos la figura
            this.hfig = figure;
            set(this.hfig,     'Numbertitle','off',...
                'Toolbar','none',...
                'MenuBar', 'None',...
                'WindowState','fullscreen',...
                'Position',posAll(this.Monitor,:),...
                'Color',[0 0 0],...
                'GraphicsSmoothing','off');
            set(gca,'Position',[0 0 1 1],'xtick',[],'ytick',[],'Visible','off');
            
            NR = posAll(this.Monitor,4);
            NC = posAll(this.Monitor,3);
            
            %Proyeccion en negro
            X = zeros(NR,NC,3,'uint8');
            this.Imag = imshow(X,'InitialMagnification','fit');
            
            %the function fullscreen only uses RGB images
            this.screenSize=[NR, NC, 3];
        end
    end
    
    %% statatic methods
    methods(Static)
    end
    
    
end

