classdef testPolyEquivalent< matlab.unittest.TestCase
    
    methods(Test)
        function testSingleOrder(testCase) %#ok<*DEFNU>
            import Zernikes.*;

            expectedCoeffs={1,[0 1; 0 0],[0 0; 1 0], [0 0 0; 0 2 0; 0 0 0],...
                            [-1 0 2; 0 0 0; 2 0 0], [0 0 -1; 0 0 0; 1 0 0]};

            orderList=0:5;
            for order = orderList;

                n = ceil((-3 + sqrt(9+8*order))/2);

                zCoeff=PolyEquivalent(order);
                testCase.assertEqual(size(zCoeff,1),n+1);
                testCase.assertEqual(size(zCoeff,2),n+1);
                testCase.assertEqual(size(zCoeff,3),1);

                for i=1:n+1
                    for j=1:n+1
                        testCase.assertEqual(zCoeff(i,j),expectedCoeffs{order+1}(i,j));
                    end
                end

            end
        end
        
        function testVector(testCase)
            import Zernikes.*;

            expectedCoeffs={1,[0 1; 0 0],[0 0; 1 0], [0 0 0; 0 2 0; 0 0 0],...
                            [-1 0 2; 0 0 0; 2 0 0], [0 0 -1; 0 0 0; 1 0 0]};

            orderList=0:5;

            n = ceil((-3 + sqrt(9+8*max(orderList)))/2);

            zCoeff=PolyEquivalent(orderList);
            testCase.assertEqual(size(zCoeff,1),n+1);
            testCase.assertEqual(size(zCoeff,2),n+1);
            testCase.assertEqual(size(zCoeff,3),length(orderList));

            for index=1:orderList(end)
                n = ceil((-3 + sqrt(9+8*orderList(index)))/2);
                for i=1:n+1
                    for j=1:n+1
                        testCase.assertEqual(zCoeff(i,j,index),expectedCoeffs{index}(i,j));
                    end
                end
            end

        end
        
    end

end


