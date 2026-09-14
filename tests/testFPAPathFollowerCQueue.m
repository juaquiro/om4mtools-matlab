%> @file testFPAPathFollowerCQueue.m
%> @brief unit tests for PathFollowerCQueue
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16
%> @author AQ 


% ======================================================================
%> @brief unnit tests for FPAPathFollowerCQueue
%> @details NA
%> @see PathFollowerTypes for avalible path follower types
%> @see PathFollowerFactory for a static factory
%> @see testFPAPathFollowerCQueue for unit tests
%> @see PathFollowerModes for modes of path follower
%> @see look for "Quality Map" in Servin, M., Quiroga, J. A., & Padilla, M. (2014). Fringe Pattern Analysis for Optical Metrology: Theory, Algorithms, and Applications. Wiley vch.
% ======================================================================
classdef testFPAPathFollowerCQueue < matlab.unittest.TestCase
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
