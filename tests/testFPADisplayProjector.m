classdef testFPADisplayProjector < matlab.unittest.TestCase
    %run(testFPADisplayProjector)
    
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
    
    
    methods (Test)
        function testConstructorObjeto(testCase)
            %run(testFPADisplayProjector, 'testConstructorObjeto')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dp=DisplayProjector();            
        end
        
        function testConstructor(testCase)
            %run(testFPADisplayProjector, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.JavaDisp;
            dp=DisplayFactory.Create(dpt);
            
            g=zeros(dp.screenSize, 'uint8');
            
            k=500;
            g(k, :, :)=255;
            g(k+2, :, :)=255;
            g(:, k, :)=255;
            g(:, k+2, :)=255;
            
            dp.gList{1}=g;
            dp.Display(1);
            
            pause(3);
            dp.CloseScreen();
            
        end
        
        function testDisplayList(testCase)
            %run(testFPADisplayProjector, 'testDisplayList')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.JavaDisp;
            dp=DisplayFactory.Create(dpt);
            
            screenSize=dp.screenSize;
            g=zeros(screenSize, 'uint8');
            
            NR=screenSize(1);
            NC=screenSize(2);
            NP=screenSize(3);
            
            [x,y]=meshgrid(1:NC, 1:NR);
            Tx=10; %px
            p=2*pi*x/Tx;
            
            delta=pi/2;
            for n=1:9
                g=255*ones(screenSize, 'uint8');
                g(:, :, 1)=uint8(255*0.5*(1+cos(p+(n-1)*delta)));
                g(:, :, 2)=uint8(255*0.5*(1+cos(p+(n-1)*delta)));
                g(:, :, 3)=uint8(255*0.5*(1+cos(p+(n-1)*delta)));
                dp.gList{n}=g;
            end
            
            for n=1:length(dp.gList)
                dp.Display(n);
                pause(1);                
            end
            dp.CloseScreen();
        end
        
        function testRGB(testCase)
            %run(testFPADisplayProjector, 'testRGB')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.JavaDisp;
            dp=DisplayFactory.Create(dpt);
            
            dp.DisplayRGB([1 1 1]);
            pause(1);
            dp.DisplayRGB([1 0 0]);
            pause(1);
            dp.DisplayRGB([0 1 0]);
            pause(1);
            dp.DisplayRGB([0 0 1]);
            pause(1);
            
            dp.CloseScreen();
            
        end

        function testGVconstant(testCase)
        %Test que proyecta niveles de gris con DGV constantes para emplearlos
        %luego en LinLutGv
            %run(testFPADisplayProjectorMatlab, 'testGVconstant')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.JavaDisp;
            %monitor 2
            dp=DisplayFactory.Create(dpt,2); %Segundo parametro es el numero del monitor (por defecto 2)
            g=zeros(dp.screenSize, 'uint8');
            i=0;

            DGV=50; %GV step
            for u=0:DGV:250 %creamos una lista con 50 niveles distintos de gris constantes
            i=i+1;
            g(:, :, :)=u;
            gList{i}=g;
            end
            dp.gList=gList;
            for n=1:length(gList) %proyectamos los 50 niveles 
            dp.Display(n); 
            pause(1);
            end
            dp.CloseScreen();
        end
    end
    
end
