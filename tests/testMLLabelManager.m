classdef testMLLabelManager < matlab.unittest.TestCase
    % testMLLabelManager tests labelManager (gety/getlabel/ind2vec/vec2ind)
    %before running the tests
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            setupPath();
        end
    end
    
    %clear after the test
    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m), not MATLAB's factory path
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end
    
    methods (Test)
        %% Checking gety method
        
        function testML_labelManager_gety01(testCase)
            % testML_labelManager_gety01 checks gety with label as a
            % cell array of strings

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            label={'aa' 'dd'};
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            A=labelManager();
            y=A.gety(label,strList);
            testCase.assertEqual(y,[1;4]);
        end
        
        
        function testML_labelManager_gety02(testCase)
            % testML_labelManager_gety02 checks gety with a single-string label

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            label={'cc'};
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            B=labelManager();
            y=B.gety(label,strList);
            testCase.assertEqual(y,3);
        end
        
        
        function testML_labelManager_gety03(testCase)
            % testML_labelManager_gety03 checks gety errors when label
            % or strList is not a string/cell array of strings

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            label=[1 2];
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            C1=labelManager();
            testCase.assertError(@() C1.gety(label,strList),'labelManager:wrongInputLabelFormat');
            
            label='aa';
            strList=1:10;
            C2=labelManager();
            testCase.assertError(@() C2.gety(label,strList),'labelManager:wrongInputStrListFormat');
        end
        
        
        function testML_labelManager_gety04(testCase)
            % testML_labelManager_gety04 checks gety errors when label
            % is not present in strList

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            label='z';
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            D=labelManager();
            testCase.assertError(@() D.gety(label,strList),'labelManager:wrongLabelValue');
        end
        
        %% Checking getlabel method
        
        function testML_labelManager_getlabel01(testCase)
            % testML_labelManager_getlabel01 checks getlabel returns the
            % expected string labels for a vector of numeric indices

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            numList=[2 3];
            A=labelManager();
            label=A.getlabel(numList,strList);
            testCase.assertEqual(label,{'bb' 'cc'})
            
        end
        
        
        function testML_labelManager_getlabel02(testCase)
            % testML_labelManager_getlabel02 checks getlabel errors when
            % numList contains a zero or a non-integer element

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % numList contain at at least one zero element
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            numList=[0 1 2 0];
            A=labelManager();
            testCase.assertError(@() A.getlabel(numList,strList),'labelManager:getlabel:wrongInput');
            
            % numList contain at least one non-integer element
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            numList=[2 3.1];
            B=labelManager();
            testCase.assertError(@() B.getlabel(numList,strList),'labelManager:getlabel:wrongInput');
            
        end
        
        
        function testML_labelManager_getlabel03(testCase)
            % testML_labelManager_getlabel03 checks getlabel errors when
            % numList is outside [1, number of distinct labels]
            % (including negative values)

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            numList=5;
            A=labelManager();
            testCase.assertError(@() A.getlabel(numList,strList),'labelManager:getlabel:wrongLabel');
            
            numList=-1;
            B=labelManager();
            testCase.assertError(@() B.getlabel(numList,strList),'labelManager:getlabel:wrongInput');
        end
        
        
        %% Checking that static method ind2vec
        
        function testML_labelManager_ind2vec01(testCase)
            % testML_labelManager_ind2vec01 checks ind2vec's one-hot
            % encoding against a manually built reference matrix

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Manually encoding for testing: 1 -> [0 0 0 1]; 2 -> [0 0 1 0],
            % 3 -> [0 1 0 0] and 4 -> [1 0 0 0]
            ind=[1 2 3 2 1 3 3 2 2 1 4 1];
            resultTest=[0 0 0 1; 0 0 1 0; 0 1 0 0; 0 0 1 0; 0 0 0 1; 0 1 0 0; 0 1 0 0;...
                0 0 1 0; 0 0 1 0; 0 0 0 1; 1 0 0 0; 0 0 0 1];
            % Performing the conversion
            A=labelManager();
            vec=A.ind2vec(ind);
            testCase.assertEqual(vec,resultTest)
        end
        
        
        function testML_labelManager_ind2vec02(testCase)
            % testML_labelManager_ind2vec02 checks ind2vec errors on a
            % non-vector input, and on zero/non-integer/negative elements

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % ind isn't a vector
            ind=eye(2);
            A=labelManager();
            testCase.assertError(@() A.ind2vec(ind),'labelManager:ind2vec:wrongInputFormat')
            
            % ind contains at least one zero, negative or non-integer element
            ind1=[0;2];
            ind2=[2;1.1];
            ind3=[-5,3];
            A=labelManager();
            testCase.assertError(@() A.ind2vec(ind1),'labelManager:ind2vec:wrongInputValue')
            testCase.assertError(@() A.ind2vec(ind2),'labelManager:ind2vec:wrongInputValue')
            testCase.assertError(@() A.ind2vec(ind3),'labelManager:ind2vec:wrongInputValue')
            
        end
        
        
        %% Checking that static method vec2ind
        
        function testML_labelManager_vec2ind01(testCase)
            % testML_labelManager_vec2ind01 checks vec2ind decodes a
            % one-hot matrix back to the expected index vector

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Manually encoding for testing: 1 -> [0 0 0 1]; 2 -> [0 0 1 0],
            % 3 -> [0 1 0 0] and 4 -> [1 0 0 0]
            resultTest=[1 2 3 2 1 3 3 2 2 1 4 1]';
            vec=[0 0 0 1; 0 0 1 0; 0 1 0 0; 0 0 1 0; 0 0 0 1; 0 1 0 0; 0 1 0 0;...
                0 0 1 0; 0 0 1 0; 0 0 0 1; 1 0 0 0; 0 0 0 1];
            A=labelManager();
            ind=A.vec2ind(vec);
            testCase.assertEqual(ind,resultTest)
        end
        
        
        function testML_labelManager_vec2ind02(testCase)
            % testML_labelManager_vec2ind02 checks vec2ind errors when
            % vec has more or fewer than one 1 per row, or is not numeric

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % vec must be a matrix composed just by zeros and ones, and there can only
            % be a 1 in each row, no more, no less
            vec1=[1 1 0 1; 0 0 1 0; 0 1 0 0; 0 0 1 0; 1 0 0 1; 0 1 0 0; 0 1 0 0;...
                0 1 1 0; 0 0 1 0; 0 0 0 1; 1 0 0 0; 0 0 0 1];
            vec2=[0 2 0 1; 0 0 1 0; 0 1 0 0; 0 0 1 0; 0 0 0 1; 0 1 0 0; 0 1 0 0;...
                0 0 1 0; 5 0 1 0; 0 0 0 1; 1 0 0 0; 0 0 0 1];
            vec3={[1 0 0],[0 0 1]};
            A=labelManager();
            testCase.assertError(@() A.vec2ind(vec1),'labelManager:vec2ind:wrongInputValue')
            testCase.assertError(@() A.vec2ind(vec2),'labelManager:vec2ind:wrongInputValue')
            testCase.assertError(@() A.vec2ind(vec3),'labelManager:vec2ind:wrongInputFormat')
        end
    end    
end

