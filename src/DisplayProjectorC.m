classdef DisplayProjectorC <  handle
    % DisplayProjectorC C++ (CProjector DLL) wrapper image projector -
    % same interface as DisplayProjector, backed by loadlibrary/calllib
    %
    % Description:
    %   See DisplayTypes for available projector types, DisplayFactory
    %   for a static factory, and testFPADisplayProjectorC for unit tests.
    %% props
    %public
    properties
        Lib; % loaded library (DLL) name
        LibH; % library's .h header file name
        gList; % cell list of images
        Monitor; % number of the screen
    end

    %get only propos
    properties (SetAccess=private)
        screenSize; % screen resolution
    end


    %% public methods
    methods
        function this=DisplayProjectorC(varargin)
            % DisplayProjectorC constructs a C++-backed display
            % projector. varargin{1}, if given, is the target monitor
            % number (must not exceed the number of connected monitors);
            % defaults to monitor 2 if there's more than one, else 1.

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
            % Display shows image n from gList on the target monitor
            calllib(this.Lib,'display', n);
        end

        function DisplayRGB(this, RGB)
            % DisplayRGB fills the whole screen with solid color RGB
            % (3-element vector, components in [0, 1])
            RGB = uint8(255*RGB);
            calllib(this.Lib,'displayRGB', RGB(1), RGB(2), RGB(3));
        end

        function TextureImages(this)
            % TextureImages uploads every image in gList to the DLL
            % (split into R/G/B planes) ahead of display, for faster Display
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
        
        function CloseScreen(this)
            % CloseScreen blanks the screen, releases the C++ projector
            % object and unloads the CProjector library
            this.DisplayRGB([0 0 0]);
            calllib(this.Lib,'dele');
            unloadlibrary CProjector;
        end
    end


    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init (re)loads the CProjector library, initializes it on
            % this.Monitor, reads the resulting screen resolution, and
            % blanks the screen
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

