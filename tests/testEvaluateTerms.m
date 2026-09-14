classdef testEvaluateTerms < matlab.unittest.TestCase
    
    methods(Test)
        
        function testSinglePoint(testCase) %#ok<*DEFNU>
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