classdef testFPADemodulator < matlab.unittest.TestCase
    %run(testFPADemodulator)
    
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
        function testAllDemodulatorsConstructors(testCase)
            %run(testFPADemodulator, 'testAllDemodulatorsConstructors')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            
            %dt types and dn are names for demodulators
            [dt, dn]=enumeration('DemodulatorTypes');
            for n=1:length(dn)
                d=DemodulatorFactory.Create(dt(n));
                
                testCase.assertTrue(isa(d, 'Demodulator'));
                
                %check that you can make a get all props
                [~, pn]=enumeration('DemodulatorProps');
                for m=1:length(pn)
                    p=d.Get(pn{m});
                end
                
                %check default values for public props
                if isa(d, 'DemodulatorGCPSA')
                    biasFP=[];
                else
                    biasFP=127.5;
                end
                testCase.assertEqual(biasFP, d.biasFP);
                
                if isa(d, 'DemodulatorGCPSA')
                    modFP=[];
                else
                    modFP=127.5;
                end

                if dt(n)==DemodulatorTypes.PSA6MultiplexedXY
                    testCase.assertEqual(0.5*modFP, d.modFP);
                else
                    testCase.assertEqual(modFP, d.modFP);
                end
                    
                if isa(d, 'DemodulatorGC')
                    shape=1;  % default value shape
                else
                    shape=0;
                end

                testCase.assertEqual(shape, d.shape);
            
                %default value for onlyModFlag
                onlyModFlag=false;
                testCase.assertEqual(onlyModFlag, d.onlyModFlag);  
                
                %empty mask
                M=d.Get(char(DemodulatorProps.M));
                testCase.assertTrue(isempty(M));
                
            end
        end
        
        
        
        
        function testDemodulatorVoid(testCase)
            %run(testFPADemodulator, 'testDemodulatorVoid')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            d=DemodulatorFactory.Create(DemodulatorTypes.Void);
            
            testCase.assertTrue(isa(d, 'Demodulator'));
            testCase.assertClass(d, 'DemodulatorVoid');
            
        end
        
        
        
        function testDemodulatorVoidProcess(testCase)
            %run(testFPADemodulator, 'testDemodulatorVoidProcess')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            NR=19;
            NC=200;
            g=ones(NR, NC);
            [x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
            phi=atan2(-y,x);
            b=abs(x+1i*y);
            
            d=DemodulatorFactory.Create(DemodulatorTypes.Void);
            M=b<0.2*NR;
            d.Set(char(DemodulatorProps.M), M);
            
            FPList={g};
            d.Process(FPList);
            
            zList=d.Get(char(DemodulatorProps.zList));
            z=zList{1};
            M1=d.Get(char(DemodulatorProps.M));
            
            absTol=1e-13;
            testCase.assertEqual(abs(z), b, 'AbsTol', absTol);
            testCase.assertEqual(angle(z), phi, 'AbsTol', absTol);
            testCase.assertEqual(M1, M, 'AbsTol', absTol);
        end
        
    
        
    end
    
end
