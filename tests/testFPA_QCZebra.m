classdef testFPA_QCZebra < matlab.unittest.TestCase
    %run(testFPA_QCZebra)
    %test unitarios para demostrar el uso de las clases de FPA y standardHW
    %en la medida de la modulacion y la fase de un patron
    
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
        function testCalculateModulation(testCase)
            %run(testFPA_QCZebra, 'testCalculateModulation')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %primero creamos el objeto imaqCam 
            %o bien pillamos la primera camara disponible
            % c=imaqCam(@imaqCam.getFirstImaqCamAvailable);
            % o bien la pillamos a partir del fichero generado con imaqTool
            
            fh=@GVPCCam;            
            c=imaqCam(fh);
            
            % check the cam is running
            c.StartPreview();
            pause(2);
            c.StopPreview();
            
            % creamos el demodulador, lo creamos de tipo Least Squares 
             d=DemodulatorFactory.Create(DemodulatorTypes.LSPSA);
             
            %solo hay que poner el periodo en px (default 8)
            d.Set(char(DemodulatorProps.Tx), 40); %set vert period in px
            d.Set(char(DemodulatorProps.Ty), 42); %set hor perior in px  
            
            %ponemos el numero de igrams que queremos usar (default 4), el
            %DemodulatorTypes.LSPSA usa siempre NIgrams pasos entre 0 y 2*pi*(1-1/NIgrams)     
            NIgrams=5;
            d.Set(char(DemodulatorProps.NIgrams), NIgrams);
            
            %create also a disp projector, esta clase usa la pantalla
            %secundaria para generar los patrones
            dp=DisplayProjector();
            
            %generate the FPS and store them in the projector
            PSdir=0; %default direction 0 -> X, you can change to Y setting PSdir=1;
            d.Set(char(DemodulatorProps.PSDir), PSdir);
            dp.gList=d.GenerateFPs(dp.screenSize);
            
            %start the imaqCam
            c.Start();

            IList=cell(1,length(dp.gList));
            %light on and capture
            for n=1:length(dp.gList)
                dp.Display(n);
                pause(1);
                
                %AQCAPTURE from cam
                %capture projected patterns
                %c.Capture();
                %I=c.Data.I;
                
                %AQCAPTURE simulated capture
                %for demo get patten from display projector
                I=dp.gList{n};
                [~, ~, NB]=size(I);
                if NB==3
                    I=rgb2gray(I);
                end
                
                %for demo: resize, blur and add noise
                I=imresize(I, [640, 480]);
                I=conv2(I, ones(5)/25, 'same');
                I=I+randn(size(I));

                
                %store captures image in a list
                IList{n}=I;
            end
            %opcionalmente hacer un close screen si se quiere
            dp.CloseScreen();

            %stop the imaqCam
            c.Stop();
            
            %process the igrams
            d.Process(IList);
            
            %get the phasor
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            
            %get the phase
            p=angle(z);
            figure; imagesc(p); colormap gray; title('\phi_x')  
            
            %get the modulation
            m=abs(z);
            figure; imagesc(m); colormap gray; title('modulation')  
            
        end
    end
end