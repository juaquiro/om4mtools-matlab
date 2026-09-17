classdef testFPADisplayProjectorMatlab < matlab.unittest.TestCase
    % testFPADisplayProjectorMatlab tests DisplayProjectorMatlab /
    % DisplayTypes.Matlab (plain figure-based full-screen projector display)
    %run(testFPADisplayProjectorMatlab)
    
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
            % testConstructorObjeto checks DisplayProjectorMatlab can be
            % constructed for monitor 1, monitor 2, or no monitor argument
            %run(testFPADisplayProjectorMatlab, 'testConstructorObjeto')
            import OM4MClassLib.Util.*;
            fprintf('\ntest AQAQ %s...\n ',Logging.WhoCalledMe());
            
            %monitor 1
            %esto de be funcionar tanto si hay dos monitores o solo uno
            dp=DisplayProjectorMatlab(1);
            dp.CloseScreen();
            
            %monitor 2
            %igualmente esto de be funcionar tanto si hay dos monitores o solo uno
            %ya que a veces desde el config viene un monitor 2
            dp=DisplayProjectorMatlab(2);  
            dp.CloseScreen();
            
            %NO monitor
            dp=DisplayProjectorMatlab();  
            dp.CloseScreen();
            
        end
        
        function testConstructor(testCase)
            % testConstructor visually checks a crosshair pattern
            % displays correctly via the factory (DisplayTypes.Matlab) on
            % monitor 1, monitor 2, and with no monitor argument
            %run(testFPADisplayProjectorMatlab, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %monitor 1
            dpt = DisplayTypes.Matlab;
            dp=DisplayFactory.Create(dpt,1); %Segundo parametro es el numero del monitor (por defecto 2)
            
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
            
            %monitor 2
            dp=DisplayFactory.Create(dpt,2); %Segundo parametro es el numero del monitor (por defecto 2)
            
            g=zeros(dp.screenSize, 'uint8');
            
            k=500;
            g(k, :, :)=255;
            g(k+20, :, :)=255;
            g(:, k, :)=255;
            g(:, k+20, :)=255;
            
            dp.gList{1}=g;
            dp.Display(1);
            
            pause(3);
            dp.CloseScreen();

            %NO monitor
            dpt = DisplayTypes.Matlab;
            dp=DisplayFactory.Create(dpt); %Segundo parametro es el numero del monitor (por defecto 2)
            
            g=zeros(dp.screenSize, 'uint8');
            
            k=500;
            g(k, :, :)=255;
            g(k+50, :, :)=255;
            g(:, k, :)=255;
            g(:, k+50, :)=255;
            
            dp.gList{1}=g;
            dp.Display(1);
            
            pause(3);
            dp.CloseScreen();    
        end
        
        function testDisplayList(testCase)
            % testDisplayList visually checks a 9-frame phase-shifted
            % fringe sequence displays in order via dp.gList/Display
            %run(testFPADisplayProjectorMatlab, 'testDisplayList')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.Matlab;
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
        
        function testGVconstant(testCase)
        % testGVconstant projects 6 constant gray-level frames (0:50:250)
        % on monitor 2, for use as calibration inputs to LinLutGv
            %run(testFPADisplayProjectorMatlab, 'testGVconstant')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.Matlab;
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
        
        function testRGB(testCase)
            % testRGB visually checks DisplayRGB fills the screen with
            % white, then red, green and blue in turn
            %run(testFPADisplayProjectorMatlab, 'testRGB')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.Matlab;
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
    end
    
end
