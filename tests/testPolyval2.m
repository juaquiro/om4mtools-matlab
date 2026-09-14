classdef testPolyval2< matlab.unittest.TestCase
    
    methods(Test)
        
        function testSinglePoint(testCase) %#ok<*DEFNU>
            import Zernikes.*;

            X=rand();
            Y=rand();

            C=magic(9);

            Z=Polyval2(X,Y,C);

            Zv=0;
            for i=1:size(C,1)
                for j=1:size(C,2)
                    Zv=Zv+C(i,j)*X.^(i-1)*Y.^(j-1);
                end
            end
            testCase.assertEqual(Z,Zv,'AbsTol',1e-6);
        end
        
        function testVector(testCase)

            import Zernikes.*;

            X=0:5;
            Y=0:5;

            C=magic(5);

            Z=Polyval2(X,Y,C);

            for point=1:length(X);
                Zv=0;
                for i=1:size(C,1)
                    for j=1:size(C,2)
                        Zv=Zv+C(i,j)*X(point).^(i-1)*Y(point).^(j-1);
                    end
                end
                testCase.assertEqual(Z(point),Zv,'AbsTol',1e-6);
            end

        end
        
    end
    
end

