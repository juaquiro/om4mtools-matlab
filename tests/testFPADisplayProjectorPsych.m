classdef testFPADisplayProjectorPsych < matlab.unittest.TestCase
    %run(testFPADisplayProjectorPsych)
    
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
            
            dp=DisplayProjectorPsych();            
        end
        
        function testConstructor(testCase)
            %run(testFPADisplayProjectorPsych, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.Psych;
            dp=DisplayFactory.Create(dpt);
            
            g=zeros(dp.screenSize, 'uint8');
            
            k=500;
            g(k, :, :)=255;
            g(k+2, :, :)=255;
            g(:, k, :)=255;
            g(:, k+2, :)=255;
            
            dp.gList{1}=g;
            dp.TextureImages();
            dp.Display(1);
            
            pause(3);
            dp.CloseScreen();
            
        end
        
        function testDisplayList(testCase)
            %run(testFPADisplayProjectorPsych, 'testDisplayList')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.Psych;
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
            dp.TextureImages();
            
            for n=1:length(dp.gList)
                dp.Display(n);
                pause(1);                
            end
            dp.CloseScreen();
        end
        
        function testRGB(testCase)
            %run(testFPADisplayProjectorPsych, 'testRGB')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            dpt = DisplayTypes.Psych;
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
