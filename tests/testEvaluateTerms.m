classdef testEvaluateTerms < matlab.unittest.TestCase
    % testEvaluateTerms tests Zernikes.EvaluateTerms against zernfun
    %run(testEvaluateTerms)

    methods(TestMethodSetup)
        function SetUp(testCase)
            setupPath();
        end
    end

    methods(TestMethodTeardown)
        function TearDown(testCase)
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end

    methods(Test)
        
        function testSinglePoint(testCase) %#ok<*DEFNU>
            % testSinglePoint checks EvaluateTerms at one random (X,Y)
            % point matches zernfun for every order 0:300
            import Zernikes.*;

            X=rand()-0.5;
            Y=rand()-0.5;
            orders=0:300;

            ZTerms=EvaluateTerms(X,Y,orders);

             for index=1:length(orders)
                n = ceil((-3 + sqrt(9+8*orders(index)))/2);
                m = 2*orders(index) - n.*(n + 2);
                [t,r]=cart2pol(X,Y);
                testCase.assertEqual(ZTerms(index),zernfun(n,m,r,t),'RelTol',1e-5);
            end
        end
        
        function testVector(testCase)
            % testVector checks EvaluateTerms on 100 random (X,Y) points
            % matches zernfun for every order 0:100

           import Zernikes.*;

            X=rand(100,1)-0.5;
            Y=rand(100,1)-0.5;
            orders=0:100;

            ZTerms=EvaluateTerms(X,Y,orders);

            for index=1:length(orders)
                n = ceil((-3 + sqrt(9+8*orders(index)))/2);
                m = 2*orders(index) - n.*(n + 2);
                [t,r]=cart2pol(X,Y);
                testCase.assertEqual(ZTerms(:,index),zernfun(n,m,r,t),'RelTol',1e-5);
            end

        end
        
    end
    
end