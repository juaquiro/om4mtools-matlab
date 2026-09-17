classdef testFPAPathFollowerCQueue < matlab.unittest.TestCase
    % testFPAPathFollowerCQueue tests PathFollowerFactory's CQueue-based
    % path follower (PathFollowerTypes.CQueue) across every
    % PathFollowerModes value.
    % See PathFollowerTypes for available path follower types,
    % PathFollowerModes for follower modes, and "Quality Map" in Servin,
    % M., Quiroga, J. A., & Padilla, M. (2014). Fringe Pattern Analysis
    % for Optical Metrology: Theory, Algorithms, and Applications. Wiley
    % vch, for the underlying algorithm.
    %run(testFPAPathFollowerCQueue)
    
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
        function testPathFollowerConstructor(testCase)
            % testPathFollowerConstructor checks the CQueue path follower
            % can be constructed from a quality map and ROI mask
            %run(testFPAPathFollowerCQueue, 'testPathFollowerConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            qualityImage=peaks();
            roiMask=qualityImage>0;
            nLevels=6;
            followMode=PathFollowerModes.distance2Mask;
            
            
            pf=PathFollowerFactory.Create(PathFollowerTypes.CQueue, nLevels, qualityImage, roiMask, followMode);
        end
        
        function testPathFollowerAddGetPixelFlatQuality(testCase)
            % testPathFollowerAddGetPixelFlatQuality checks that, with a
            % flat quality map (1 level), AddPoint/GetNext return pixels
            % in insertion (FIFO) order, for every PathFollowerModes value
            %run(testFPAPathFollowerCQueue, 'testPathFollowerAddGetPixelFlatQuality')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %roi=1, quality=1, nLevels=1, all follow modes
            qualityImage=ones(10, 10);
            roiMask=qualityImage>0;
            nLevels=1;
            %fmt types and fmn are names for PathFollowerModes
            [fmt, fmn]=enumeration('PathFollowerModes');
            for n=1:length(fmn)
                followMode=fmt(n);
                fprintf('\nPathFollower Mode: %s\n', fmn{n})
                
                pf=PathFollowerFactory.Create(PathFollowerTypes.CQueue, nLevels, qualityImage, roiMask, followMode);
                
                datax=[1 2 3 4];
                datay=[4 3 2 1];
                pList=OM4MClassLib.DataStructs.Pixel(datax, datay);
                
                for n=1:length(pList);
                    pf.AddPoint(pList(n));
                end
                
                for n=1:length(pList);
                    P=pf.GetNext();
                    testCase.assertEqual(pList(n),P);
                end
                
            end
            
        end
        
        
        function testPathFollowerAddGetPixelPeaksQuality(testCase)
            % testPathFollowerAddGetPixelPeaksQuality repeats
            % testPathFollowerAddGetPixelFlatQuality with a non-flat
            % peaks()-based quality map (6 levels) and its positive ROI
            %run(testFPAPathFollowerCQueue, 'testPathFollowerAddGetPixelPeaksQuality')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %roi=f(x,y), quality=peaks, nLevels=6, all follow modes
            qualityImage=peaks(100); qualityImage=imresize(qualityImage, [100, 101]);
            roiMask=qualityImage>0;
            nLevels=6;
            %fmt types and fmn are names for PathFollowerModes
            [fmt, fmn]=enumeration('PathFollowerModes');
            for n=1:length(fmn)
                followMode=fmt(n);
                fprintf('\nPathFollower Mode: %s\n', fmn{n})
                
                pf=PathFollowerFactory.Create(PathFollowerTypes.CQueue, nLevels, qualityImage, roiMask, followMode);
                
                datax=[1 2 3 4];
                datay=[4 3 2 1];
                pList=OM4MClassLib.DataStructs.Pixel(datax, datay);
                
                for n=1:length(pList);
                    pf.AddPoint(pList(n));
                end
                
                for n=1:length(pList);
                    P=pf.GetNext();
                    testCase.assertEqual(pList(n),P);
                end
                
            end
            
        end
        
        
        function testPathFollowerFillingUsingPeaksQuality(testCase)
            % testPathFollowerFillingUsingPeaksQuality visually animates
            % the follower draining its whole ROI (peaks()-based quality
            % map, border zeroed) starting from 4 seed pixels, for every
            % PathFollowerModes value
            %run(testFPAPathFollowerCQueue, 'testPathFollowerFillingUsingPeaksQuality')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %roi=f(x,y), quality=peaks, nLevels=6, all follow modes
            qualityImage=peaks(100); qualityImage=imresize(qualityImage, [100, 101]);
            roiMask=qualityImage>0;
            [NR, NC]=size(roiMask);
            %set border to zero, not necessary but OK for the disntance
            %followmode
            roiMask(1, :)=0; roiMask(NR, :)=0; roiMask(:, 1)=0; roiMask(:, NC)=0;
            nLevels=6;
            %fmt types and fmn are names for PathFollowerModes
            [fmt, fmn]=enumeration('PathFollowerModes');
            for n=1:length(fmn)
                followMode=fmt(n);
                fprintf('\nPathFollower Mode: %s\n', fmn{n})
                
                pf=PathFollowerFactory.Create(PathFollowerTypes.CQueue, nLevels, qualityImage, roiMask, followMode);
                
                datax=[2 2 3 4];
                datay=[4 3 2 2];
                pList=OM4MClassLib.DataStructs.Pixel(datax, datay);
                
                for k=1:length(pList);
                    pf.AddPoint(pList(k));
                end
                
                
                VisitedMask=zeros(size(roiMask));
                f=figure;
                P=pf.GetNext();
                m=0;
                M=100;
                while not(isempty(P))
                    VisitedMask(P.y, P.x)=round(m/M);
                    if mod(m, 100)==0
                        figure(f);
                        imagesc(VisitedMask); title(['Follow Mode:' fmn{n}]);
                        drawnow
                    end
                    P=pf.GetNext();
                    m=m+1;
                end
                
            end
            
        end
        
        
        function testFillingUsingPeaksQualityStartMax(testCase)
            % testFillingUsingPeaksQualityStartMax repeats
            % testPathFollowerFillingUsingPeaksQuality but seeds the
            % follower from the ROI's maximum-quality pixel(s) instead
            % of 4 fixed points
            %run(testFPAPathFollowerCQueue, 'testFillingUsingPeaksQualityStartMax')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());
            
            %roi=f(x,y), quality=peaks, nLevels=6, all follow modes
            qualityImage=peaks(100); qualityImage=imresize(qualityImage, [100, 113]);
            roiMask=qualityImage>0;
            [NR, NC]=size(roiMask);
            %set border to zero, not necessary but OK for the disntance
            %followmode
            roiMask(1, :)=0; roiMask(NR, :)=0; roiMask(:, 1)=0; roiMask(:, NC)=0;
            nLevels=6;
            %fmt types and fmn are names for PathFollowerModes
            [fmt, fmn]=enumeration('PathFollowerModes');
            for n=1:length(fmn)
                followMode=fmt(n);
                fprintf('\nPathFollower Mode: %s\n', fmn{n})
                
                pf=PathFollowerFactory.Create(PathFollowerTypes.CQueue, nLevels, qualityImage, roiMask, followMode);
                
                q=pf.qualityMap;
                q(not(roiMask))=-Inf;
                maxValue=max(q(:));
                [datay, datax] = find(q == maxValue);
                pList=OM4MClassLib.DataStructs.Pixel(datax, datay);
                
                for k=1:length(pList);
                    pf.AddPoint(pList(k));
                end
                
                
                VisitedMask=zeros(size(roiMask));
                f=figure;
                P=pf.GetNext();
                m=0;
                M=200;
                while not(isempty(P))
                    VisitedMask(P.y, P.x)=round(m/M);
                    if mod(m, M)==0
                        figure(f);
                        imagesc(VisitedMask); title(['Follow Mode:' fmn{n}]);
                        drawnow
                    end
                    P=pf.GetNext();
                    m=m+1;
                end
                
            end
            
        end
        
    end
    
end
