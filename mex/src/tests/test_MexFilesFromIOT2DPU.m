classdef test_MexFilesFromIOT2DPU < matlab.unittest.TestCase
    %run(test_MexFilesFromIOT2DPU)
        
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            testSetPaths;                        
        end
    end
    
    methods(TestMethodTeardown)
        function TearDown(testCase)
                        %restore path as indicated in pathdef.m
            matlabpath(pathdef);
            
        end
    end
    
    
    methods (Test)
        function test_PUFlynMdMex(testCase)
            %run(test_MexFilesFromIOT2DPU, 'test_PUFlynMdMex')
            
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
            qual=bmask; %0-1
            %%unw=zeros(size(p));
            thresh_flag=1; %therhold the quality map
            fatten=1; %fatten by 1px the zero points in quality map
            
            %mex file
            unw=PUFlynMdMex(pw, mask, qual, thresh_flag, fatten);
            
            err_map=p(bmask==1)-unw(bmask==1); err_map=err_map-mean(err_map); 
            
            mean_err=mean(err_map);           
            testCase.assertEqual(mean_err, 0, 'AbsTol', 1e-10);
            
            figure; imagesc(pw.*bmask);
            figure; imagesc(unw.*bmask);
        end                        
    end
end