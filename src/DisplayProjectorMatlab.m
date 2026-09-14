%> @file DisplayProjectorMatlab.m
%> @brief Matlab figures image projector class
%> @copyright 2019 IOT
%> @author SS 15/01/19

% ======================================================================
%> @brief this class implements the DisplayProjector class with Matlab figures
%> @brief this class uses logical display size, if there is scaling this
%> @brief size is different from physical display size. Check Init()
%> @brief if physical syze is needed use DisplayProjector that uses Java primitives 
%> @details Esta clase solo es valida a partir de Matlab2018
%> @see DisplayTypes for available projector follower types
%> @see DisplayFactory for a static factory
%> @see testFPADisplayProjectorMatlab for unit tests
% ======================================================================
classdef DisplayProjectorMatlab <  handle
    %% props
    %public
    properties
        %> cell list of images
        gList;
        %> number of the screen
        Monitor;
        %> Projector figure
        hfig;
        %> Projection image
        Imag;
    end
    
    %get only propos
    properties (SetAccess=private)
        %> screen resolution
        screenSize;
    end
    
    
    %% public methods
    methods
        % ======================================================================
        %> @brief contructor
        %> @param varargin como entrada puede recibir el numero del monitor en el que se quiere proyectar, el valor por defecto si no se pasa argunemto es 2
        % ======================================================================
        function this=DisplayProjectorMatlab(varargin)
            %mirar que varargin sea como maximo 1 parametro y usar por
            %defecto 2
            %verificar numero de proyectores
            
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
        
        % ======================================================================
        %> @brief this funcion display a image in the screen
        %> @param n number of the image in gList
        % ======================================================================
        function Display(this, n)
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
        
        % ======================================================================
        %> @brief this funcion project one color in the screen
        %> @param RGB matriz RGB (componentes entre 0 y 1) que identifica el color que se desea proyectar
        % ======================================================================
        function DisplayRGB(this, RGB)
            % Color the screen grey
            X(:,:,1) = uint8(255*RGB(1)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,2) = uint8(255*RGB(2)*ones(this.screenSize(1),this.screenSize(2)));
            X(:,:,3) = uint8(255*RGB(3)*ones(this.screenSize(1),this.screenSize(2)));
            
            this.Imag.CData = X;
            drawnow;
        end
        
        % ======================================================================
        %> @brief this funcion pre charge the images before the display in others projectors
        % ======================================================================
        function TextureImages()
            
        end
        
        % ======================================================================
        %> @brief this funcion clear the screen
        % ======================================================================
        function CloseScreen(this)
            %AQ 6MAY20 do not close, because hfig and Imag are destroyed
            if ishandle(this.hfig)
                set(this.hfig, 'Visible', 'off');
            end
        end
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
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

