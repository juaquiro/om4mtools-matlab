classdef testPoly2 < matlab.unittest.TestCase
    %run(testPoly2)

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
        
        function testEvaluateSinglePoint(testCase)

            X=rand();
            Y=rand();

            C=magic(9);
            C=flipud(tril(C,0));

            Z=Poly2.Evaluate(X,Y,C);

            Zv=0;
            for i=1:size(C,1)
                for j=1:size(C,2)
                    Zv=Zv+C(i,j)*X.^(i-1)*Y.^(j-1);
                end
            end
            testCase.assertEqual(Z,Zv,'AbsTol',1e-6);
        end
        
        function testEvaluateVector(testCase)

            [X, Y]=meshgrid(-5:5);

            C=magic(5);
            C=flipud(tril(C,0));

            Z=Poly2.Evaluate(X,Y,C);
            testCase.assertEqual(size(Z), size(X));

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
        
        function testEvaluateNonSquareMatrix(testCase)
            [X, Y]=meshgrid(-5:5);

            C=magic(5);
            C=flipud(tril(C,0));
            C=C(:,1:end-2);
            
            Z=Poly2.Evaluate(X,Y,C);
            testCase.assertEqual(size(Z), size(X));

            for point=1:length(X);
                Zv=0;
                for i=1:size(C,1)
                    for j=1:size(C,2)
                        Zv=Zv+C(i,j)*X(point).^(i-1)*Y(point).^(j-1);
                    end
                end
                testCase.assertEqual(Z(point),Zv,'AbsTol',1e-6);
            end
            
            C=magic(5);
            C=flipud(tril(C,0));
            C=C(1:end-2,:);
            
            Z=Poly2.Evaluate(X,Y,C);
            testCase.assertEqual(size(Z), size(X));

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
        
        function testDerive(testCase)
            [X, Y]=meshgrid(-5:5);

            C=magic(5);
            C=flipud(tril(C,0));
            CderX=Poly2.Derive(C, 1);
            CderY=Poly2.Derive(C, 2);
            Zx=Poly2.Evaluate(X,Y,CderX);
            Zy=Poly2.Evaluate(X,Y,CderY);
            
            [N,M]=size(X);
            for i=1:N
                for j=1:M
                    testCase.assertEqual(Zx(i,j),derivest(@(x)Poly2.Evaluate(x,Y(i,j),C),X(i,j)),'rel',1e-6);
                    testCase.assertEqual(Zy(i,j),derivest(@(y)Poly2.Evaluate(X(i,j),y,C),Y(i,j)),'rel',1e-6);
                end
            end
            
        end
        
        function testLaplacian(testCase)
            [X, Y]=meshgrid(-5:5);

            C=magic(5);
            C=flipud(tril(C,0));
            CLap=Poly2.Laplacian(C);
            ZLap=Poly2.Evaluate(X,Y,CLap);
            
            [N,M]=size(X);
            for i=1:N
                for j=1:M
                    ZxxEst=derivest(@(x)Poly2.Evaluate(x,Y(i,j),C),X(i,j),'DerivativeOrder',2);
                    ZyyEst=derivest(@(y)Poly2.Evaluate(X(i,j),y,C),Y(i,j),'DerivativeOrder',2);
                    testCase.assertEqual(ZLap(i,j),ZxxEst+ZyyEst,'rel',1e-6);
                end
            end
            
        end
        
    end
    
end
