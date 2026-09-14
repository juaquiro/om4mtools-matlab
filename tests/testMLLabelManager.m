classdef testMLLabelManager < matlab.unittest.TestCase
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
        
        % label is a cell array of strings
        function testML_labelManager_gety01(testCase)
            
            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            label={'aa' 'dd'};
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            A=labelManager();
            y=A.gety(label,strList);
            testCase.assertEqual(y,[1;4]);
        end
        
        
        % label is a string
        function testML_labelManager_gety02(testCase)
            
            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            label={'cc'};
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            B=labelManager();
            y=B.gety(label,strList);
            testCase.assertEqual(y,3);
        end
        
        
        % label or strList are aren't strings or cell arrays of strings
        function testML_labelManager_gety03(testCase)
            
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
        
        
        % label is not contained in the given list, checking the exception
        function testML_labelManager_gety04(testCase)
            
            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            label='z';
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            D=labelManager();
            testCase.assertError(@() D.gety(label,strList),'labelManager:wrongLabelValue');
        end
        
        %% Checking getlabel method
        
        % Checking that function getlabel works OK
        function testML_labelManager_getlabel01(testCase)
            
            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            strList={'aa' 'bb' 'cc' 'bb' 'aa' 'cc' 'cc' 'bb' 'bb' 'aa' 'dd' 'aa'};
            numList=[2 3];
            A=labelManager();
            label=A.getlabel(numList,strList);
            testCase.assertEqual(label,{'bb' 'cc'})
            
        end
        
        
        % Checking the cases when numList format is wrong
        function testML_labelManager_getlabel02(testCase)
            
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
        
        
        % Checking the case when at least one of the numbers contained in numList
        % doesn't correspond to the range [1,number of different labels]
        function testML_labelManager_getlabel03(testCase)
            
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
        
        % Checking if it works correctly
        function testML_labelManager_ind2vec01(testCase)
            
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
        
        
        % Checking the exceptions
        function testML_labelManager_ind2vec02(testCase)
            
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
        
        % Checking if it works correctly
        function testML_labelManager_vec2ind01(testCase)
            
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
        
        
        % Checking the exceptions
        function testML_labelManager_vec2ind02(testCase)
            
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

