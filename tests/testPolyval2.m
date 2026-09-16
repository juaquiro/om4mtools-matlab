classdef testPolyval2 < matlab.unittest.TestCase
    %run(testPolyval2)
    %
    % Polyval2 used to be a free-standing function; it now only survives
    % as ProcessMeasure.Polyval2 (same behaviour for a 3-argument call --
    % the 4th "type" argument defaults to 'sq'). See DECISIONS.md, "Fase 3
    % -- primera pasada de estandarizacion y baseline".

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
            import Zernikes.*;

            X=rand();
            Y=rand();

            C=magic(9);

            Z=ProcessMeasure.Polyval2(X,Y,C);

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

            Z=ProcessMeasure.Polyval2(X,Y,C);

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

