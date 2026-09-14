%> @file DisplayProjectorC.m
%> @brief C++ wrapper image projector class
%> @copyright 2019 IOT
%> @author SS 09/19

% ======================================================================
%> @brief this class implements the DisplayProjector class with c++ dll
%> @see DisplayTypes for avalible projector follower types
%> @see DisplayFactory for a static factory
%> @see testFPADisplayProjectorC for unit tests
% ======================================================================
classdef DisplayProjectorC <  handle
    %% props    
    %public
    properties  
        %> dll name
        Lib;
        %> c++ .h file
        LibH;
        %> cell list of images  
        gList;
        %> number of the screen
        Monitor;
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
        %> @param varargin como entrada puede recibir el numero del monitor en el que se quiere proyectar
        % ======================================================================
        function this=DisplayProjectorC(varargin)   
            %mirar que varargin sea como maximo 1 parametro y usar por
            %defecto 2
            %verificar numero de proyectores y que el monitor pedido no
            %exceda el numero de monitores
            
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
            calllib(this.Lib,'display', n);
        end
        
        % ======================================================================
        %> @brief this funcion project one color in the screen
        %> @param RGB matriz RGB (componentes entre 0 y 1) que identifica el color que se desea proyectar
        % ======================================================================
        function DisplayRGB(this, RGB)
            % Color the screen grey
            RGB = uint8(255*RGB);
            calllib(this.Lib,'displayRGB', RGB(1), RGB(2), RGB(3));
        end
        
        % ======================================================================
        %> @brief this funcion pre charge the images before the display
        % ======================================================================
        function TextureImages(this)
            calllib(this.Lib,'ImageMemo',length(this.gList));
            for n=1:length(this.gList)
                %Preparar la imagen en sus tres componentes para enviar
                %a la dll
                r = this.gList{n}(:,:,1);
                r = r';
                r = r(:);
                g = this.gList{n}(:,:,2);
                g = g';
                g = g(:);
                b = this.gList{n}(:,:,3);
                b = b';
                b = b(:);
                %Llamar a la dll
                calllib(this.Lib,'LoadGList', n, r, g, b);            
            end
        end
        
        % ======================================================================
        %> @brief this funcion clear the screen
        % ======================================================================
        function CloseScreen(this)
            this.DisplayRGB([0 0 0]);
            calllib(this.Lib,'dele');
            unloadlibrary CProjector;
        end
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            this.Lib='CProjector';
            this.LibH=[this.Lib, '.h']; 
            

            if not(libisloaded(this.Lib))
                loadlibrary(this.Lib, this.LibH)
            else
                unloadlibrary CProjector;
                loadlibrary(this.Lib, this.LibH)
            end
            
            %Inicializamos la dll
            calllib(this.Lib,'init',this.Monitor);
            
            %Recuperamos la resolucion y el numero de la pantalla
            this.screenSize = zeros(1, 3,'uint16');
            [this.screenSize(1),this.screenSize(2),this.screenSize(3)] = calllib(this.Lib,'retResolution',this.screenSize(1),this.screenSize(2),this.screenSize(3));
            this.screenSize = double(this.screenSize);
                        
            %Proyeccion en negro
            calllib(this.Lib,'displayRGB', 0, 0, 0);  
        end
    end
    
    %% statatic methods
    methods(Static)
    end
       
            
end

