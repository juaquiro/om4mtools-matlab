classdef testFPAUnwrapper < matlab.unittest.TestCase
    %run(testFPAUnwrapper)
    
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
        function testAllUnwrapperConstructors(testCase)
            %run(testFPAUnwrapper, 'testAllUnwrapperConstructors')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            %dt types and dn are names for demodulators
            [dt, dn]=enumeration('UnwrapperTypes');
            for n=1:length(dn)
                u=UnwrapperFactory.Create(dt(n));
                
                testCase.assertTrue(isa(u, 'Unwrapper'));
                
                %check that you can make a get all props
                [~, pn]=enumeration('UnwrapperProps');
                for m=1:length(pn)
                    p=u.Get(pn{m});
                end
            end
        end
        
        
        function testUnwrapperVoid(testCase)
            %run(testFPAUnwrapper, 'testUnwrapperVoid')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            u=UnwrapperFactory.Create(UnwrapperTypes.Void);
            
            testCase.assertTrue(isa(u, 'Unwrapper'));
            testCase.assertClass(u, 'UnwrapperVoid');
            
        end
        
        
        function testUnwrapperVoidProcess(testCase)
            %run(testFPAUnwrapper, 'testUnwrapperVoidProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NC=302;
            NR=201;
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            
            p=3*peaks(max([NR NC]));
            p=imresize(p, [NR NC]);
            pw=mod(p, 2*pi);
            
            M1=abs(x+1i*(y+0.2*NR))<0.2*NC;
            M2=abs((x+1i*(y-0.2*NR)))<0.2*NC;
            M3=abs((x+1i*(y-0.1*NR)))>0.1*NC;
            bmask=double((M1|M2)&M3);
            pw=pw.*bmask; %0-2*pi
            mask=255*bmask;  %0-255
            qual=p; %non-normalized
            
            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.Void);
            %process
            u.Process(pw, mask, qual);
            
            %get results
            unw=u.Get(char(UnwrapperProps.unw));
            qual_pu=u.Get(char(UnwrapperProps.qual));
            
            %validate
            testCase.assertEqual(pw.*(qual_pu>0), unw);
            testCase.assertEqual(bmask, u.Get(char(UnwrapperProps.bmask)));
            testCase.assertEqual(mat2gray(qual).*bmask, qual_pu);
        end
        
        function testUnwrapperFlynMdProcess(testCase)
            %run(testFPAUnwrapper, 'testUnwrapperFlynMdProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NC=302;
            NR=201;
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            
            p=3*peaks(max([NR NC]));
            p=imresize(p, [NR NC])+0.1*randn(size(x));            
            pw=mod(p, 2*pi);
                       
            M1=abs(x+1i*(y+0.2*NR))<0.2*NC;
            M2=abs((x+1i*(y-0.2*NR)))<0.2*NC;
            M3=abs((x+1i*(y-0.1*NR)))>0.1*NC;
            bmask=double((M1|M2)&M3);
            pw=pw.*bmask; %0-2*pi
            
            z=bmask.*exp(1i*pw);            
            qual=abs(conv2(z, ones(3,3)/9, 'same')); %non-normalized 0-1
            
            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            
            %process
            u.Process(pw, bmask, qual);
            
            %get results
            unw=u.Get(char(UnwrapperProps.unw));
            bmask=u.Get(char(UnwrapperProps.bmask));
            qual=u.Get(char(UnwrapperProps.qual));
                                    
            err_map=angle(exp(1i*(pw-unw))); err_map=err_map(bmask==1);            
            n=linspace(-pi, pi, 300);
            h=hist(err_map(:),n);
            
            figure; imagesc(pw.*bmask); title('wrapped phase'); colorbar;            
            figure; imagesc(unw.*bmask); title('unwrapped phase');  colorbar;
            figure; plot(err_map,'.-'); title('error'); colorbar;
            figure; plot(n/pi,h,'.-'); ylabel('n/pi'); title('error histogram'); colorbar;
            figure; imagesc(bmask); title('binary mask ');  colorbar;             
            figure; imagesc(qual);  title('quality');  colorbar;                   
            
        end
        
        
        function testUnwrapperFlynMdWithDeflecMeas(testCase)
            %run(testFPAUnwrapper, 'testUnwrapperFlynMdWithDeflecMeas')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %**********************************
            %load example and demodulate
            %**********************************
            
            DropboxDir=fixturesRoot();
            AQsrcDir='MontajeHorizontal';
            %LMMFileName='TimePS0506_YOminus2_75_14-Jul-2016.mat';
            LMMFileName='TimePS0506_SwisCoat40L88031L_14-Jul-2016.mat';
            %LMMFileName='TimePS0506_VisionLab565964_15-Jul-2016.mat';
            LMMFile=fullfile(DropboxDir, AQsrcDir, LMMFileName);
            
            testCase.assertTrue(exist(LMMFile, 'file')==2);
            
            S=load(LMMFile);LMM=S.LMM; clear('S');
            
            d=DemodulatorFactory.Create(DemodulatorTypes.TimePSA);       
            d.Set(char(DemodulatorProps.PSType), PSFilterTypes.A0502);
            
            %ref list of 5 PS igrams
            N=0.5*length(LMM.gr);
            grX=LMM.gr(1:N);            
            d.Process(grX);
            zList=d.Get(char(DemodulatorProps.zList));
            zrx=zList{1};
            
            grY=LMM.gr(N+1:2*N);            
            d.Process(grY);
            zList=d.Get(char(DemodulatorProps.zList));
            zry=zList{1};    
                                            
            %list of 5 PS igrams
            gcX=LMM.g(1:N);            
            d.Process(gcX);
            zList=d.Get(char(DemodulatorProps.zList));
            zcx=zList{1};
            
            gcY=LMM.g(N+1:2*N);            
            d.Process(gcY);
            zList=d.Get(char(DemodulatorProps.zList));
            zcy=zList{1};    
            
            %AQNOTA
            %en deflectometria por transmision (experimento tipo Massig) 
            %los sistemas de ref en X de los patrones 
            %(pantalla) y de la captura (CCD) estan cambiados
            %especularmente izda-dcha.
            %En la direccion vertical Y no hay reflexion especular.
            %por eso aplicamos el conjugado a la deflexion en X
            LMM.zx=conj(zcx./zrx);            
            LMM.zy=(zcy./zry);
            
            
            %**********************************
            % unwrapp phase maps
            %**********************************
            
            
            z=conv2(LMM.zx, ones(10,10)/100, 'same');
            bmask=LMM.M;
            pw=angle(z); %0-2*pi
            qual=abs(z); 
                        
            %create PU
            u=UnwrapperFactory.Create(UnwrapperTypes.FlynMd);
            %process
            u.Process(pw, bmask, qual);
            
            %get results
            unw=u.Get(char(UnwrapperProps.unw));
            bmask=u.Get(char(UnwrapperProps.bmask));
            qual=u.Get(char(UnwrapperProps.qual));
                                    
            err_map=angle(exp(1i*(pw-unw))); err_map=err_map(bmask==1);            
            n=linspace(-pi, pi, 300);
            h=hist(err_map(:),n);
            
            figure; imagesc(pw.*bmask); title('wrapped phase'); colorbar;            
            figure; imagesc(unw.*bmask); title('unwrapped phase');  colorbar;
            figure; plot(err_map,'.-'); title('error'); colorbar;
            figure; plot(n/pi,h,'.-'); ylabel('n/pi'); title('error histogram'); colorbar;
            figure; imagesc(bmask); title('binary mask ');  colorbar;             
            figure; imagesc(qual);  title('quality');  colorbar;                   
            
        end
        
    end
    
end
