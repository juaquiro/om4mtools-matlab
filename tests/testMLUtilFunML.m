classdef testMLUtilFunML < matlab.unittest.TestCase
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
        
        function testML_UtilFunML_sigmoid(testCase)
            
            import OM4MClassLib.Util.*;
            
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            z=0;
            s=UtilFunML.sigmoid(z);
            testCase.assertEqual(0.5, s);
            
            z=-inf;
            s=UtilFunML.sigmoid(z);
            testCase.assertEqual(0, s);
            
            z=inf;
            s=UtilFunML.sigmoid(z);
            testCase.assertEqual(1, s);
            
        end
        
        
        function testML_UtilFunML_CostFunctionLR(testCase)
            %example from ex2_reg of the ML course
            
            import OM4MClassLib.Util.*;
            
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            
            % Add Polynomial Features
            
            % Note that mapFeature also adds a column of ones for us, so the intercept
            % term is handled
            X = mapFeature(X(:,1), X(:,2));
            
            % Initialize fitting parameters
            initial_theta = zeros(size(X, 2)+1, 1);
            
            % Set regularization parameter lambda to 1
            lambda = 1e0;
            % Compute initial cost and gradient for regularized logistic
            % regression
            [c, g] = UtilFunML.CostFunctionLR(initial_theta, X, y, lambda);
            
            ac=0.693147180559945;
            ag=[
                0.008474576271186
                0.018788093220339
                0.000077771186441
                0.050344639536356
                0.011501330787339
                0.037664847359551
                0.018355987221154
                0.007323933911222
                0.008192444683890
                0.023476488865153
                0.039348623439160
                0.002239239066397
                0.012860050337134
                0.003095937202405
                0.039302817110394
                0.019970746726922
                0.004329832324171
                0.003386439019070
                0.005838220778059
                0.004476290665122
                0.031007984901328
                0.031031244228508
                0.001097402384867
                0.006315707966420
                0.000408503006021
                0.007265043164342
                0.001376461747689
                0.038793636344839
                ];
            
            tol=1e-10;
            testCase.assertLessThanOrEqual(c-ac,tol);
            testCase.assertLessThanOrEqual(g-ag,tol);
            
            
        end
        
        
        function testML_UtilFunML_fmincg(testCase)
            %example from ex3_reg of the ML course
            
            import OM4MClassLib.Util.*;
            
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Setup the parameters you will use for this part of the exercise
            input_layer_size  = 400;  % 20x20 Input Images of Digits
            num_labels = 10;          % 10 labels, from 1 to 10
            % (note that we have mapped "0" to label 10)
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex3data1.mat')); % training data stored in arrays X, y
            % Some useful variables
            m = size(X, 1);
            n = size(X, 2);
            lambda = 1e-1;
            
            % You need to return the following variables correctly
            all_theta = zeros(num_labels, n + 1);
            
            
            % Set Initial theta
            initial_theta = zeros(n + 1, 1);
            
            % Set options for fminunc
            options = optimset('GradObj', 'on', 'MaxIter', 50);
            
            fhCost=@UtilFunML.CostFunctionLR;
            
            for c=1:num_labels
                % Run fmincg to obtain the optimal theta
                % This function will return theta and the cost
                %all_theta(c, :) = UtilFunML.fmincg(@(t)(UtilFunML.CostFunctionLR(t, Xbias, (y == c), lambda)), ...
                all_theta(c, :) = UtilFunML.fmincg(@(t)(fhCost(t, X, (y == c), lambda)), ...
                    initial_theta, options);
                
            end
            
            atheta=load(fullfile(fixturesRoot(), 'actual_theta.mat'), 'actual_theta');
            tol=1e-8;
            warning([Logging.WhoCalledMe() ' este test no funciona 1-9-14, esta en estado de DEBUG']);
            %testCase.assertLessThanOrEqual(all_theta(:), atheta.actual_theta(:), 'absolute', tol);
            
        end
        
        
        function testML_UtilFunML_Accuracy(testCase)
            import OM4MClassLib.Util.*;
            
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            n1=5; n2=7; n3=8;
            y=[ones(n1,1); 2*ones(n2, 1); 3*ones(n3, 1)];
            
            p=ones(size(y));
            a=UtilFunML.Accuracy(y,p);
            testCase.assertEqual(100*n1/length(y), a);
            
            
            p=2*ones(size(y));
            a=UtilFunML.Accuracy(y,p);
            testCase.assertEqual(100*n2/length(y), a);
            
            p=3*ones(size(y));
            a=UtilFunML.Accuracy(y,p);
            testCase.assertEqual(100*n3/length(y), a);
            
        end
        
        
        function testML_UtilFunML_CostFunctionLinReg(testCase)
            %ejemplo cojido del ex5 del curso de ML
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            load (fullfile(fixturesRoot(), 'CourseraMLData', 'ex5data1.mat'));
            
            theta = [1 ; 1];
            m = size(X, 1); % Number of training examples
            
            lambda=1;
            J = UtilFunML.CostFunctionLinReg(theta, X, y, lambda);
            tol=1e-5;
            testCase.assertLessThanOrEqual(J-303.993192,tol);
            
            theta = [1 ; 1];
            [~, Jgrad] = UtilFunML.CostFunctionLinReg(theta, X, y, lambda);
            tol=1e-5;
            testCase.assertLessThanOrEqual(Jgrad(1)-(-15.303016),tol);
            testCase.assertLessThanOrEqual(Jgrad(2)-598.250744,tol);
            
        end
        
        
        function testML_UtilFunML_checkTrainSetLabels(testCase)
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            y=[ones(10,1); 2*ones(10,1); 3*ones(10,1)];
            
            UtilFunML.checkTrainSetLabels(y);
            
            try
                y=[ones(10,1); 3*ones(10,1)];
                UtilFunML.checkTrainSetLabels(y);
            catch ME
                t='labels must be consequitive integer numbers 1,2...N-1, N : UtilFunML.checkTrainSetLabels';
                testCase.assertEqual(ME.message, t)
            end
            
            try
                y=[0*ones(10,1); ones(10,1); 2*ones(10,1); 3*ones(10,1)];
                UtilFunML.checkTrainSetLabels(y);
            catch ME
                t='labels must be consequitive integer numbers 1,2...N-1, N : UtilFunML.checkTrainSetLabels';
                testCase.assertEqual(ME.message, t)
            end
            
        end
        
        
        function testML_UtilFunML_Fscore(testCase)
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            y=[ones(100,1); 2*ones(100,1); 3*ones(100,1)];
            p=y;
            %all results are true possitive P=R=1;
            [F1s, P, R]=UtilFunML.Fscore(y,p);
            
            testCase.assertTrue(all(P));
            testCase.assertTrue(all(R));
            testCase.assertTrue(all(F1s));
            
            %not a single true-possitive
            p=[3*ones(100,1); 1*ones(100,1); 2*ones(100,1)];
            [F1s, P, R]=UtilFunML.Fscore(y,p);
            testCase.assertTrue(all(P==0));
            testCase.assertTrue(all(R==0));
            testCase.assertTrue(all(F1s==0));
            
            %class 2 succes
            p=[3*ones(100,1); 2*ones(100,1); 1*ones(100,1)];
            [F1s, P, R]=UtilFunML.Fscore(y,p);
            tol=1e-10;
            testCase.assertLessThanOrEqual(F1s-[0,1,0]',tol);
            testCase.assertLessThanOrEqual(P-[0,1,0]',tol);
            testCase.assertLessThanOrEqual(R-[0,1,0]',tol);
            
            %pure chance
            N=10e3;
            y=[ones(N,1); 2*ones(N,1); 3*ones(N,1)];
            k=randperm(length(y));
            p=y(k);
            [F1s, P, R]=UtilFunML.Fscore(y,p);
            tol=1e-1;
            testCase.assertLessThanOrEqual(F1s-[1/3,1/3,1/3]',tol);
            testCase.assertLessThanOrEqual(P-[1/3,1/3,1/3]',tol);
            testCase.assertLessThanOrEqual(R-[1/3,1/3,1/3]',tol);
            
            
        end
        
        
        function testML_UtilFunML_genErrorStruct(testCase)
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            errStruct=UtilFunML.genErrorStruct(3);
            
            estra(1)=errStruct; estra(1).J=10;  estra(1).F1s=ones(3, 1); estra(1).P=2*ones(3, 1); estra(1).R=pi*ones(3, 1);
            estra(2)=errStruct; estra(2).J=20;  estra(2).F1s=ones(4, 1); estra(2).P=2*ones(4, 1); estra(2).R=2*pi*ones(4, 1);
            estra(3)=errStruct; estra(3).J=30;  estra(3).F1s=ones(5, 1); estra(3).P=2*ones(5, 1); estra(3).R=3*pi*ones(5, 1);
            
            
            %number of classes
            k=7;
            errStruct_o=UtilFunML.checkErrorStruct(estra, k);
            
            tol=0;
            testCase.assertLessThanOrEqual([errStruct_o.J]-[10, 20, 30],tol);
            testCase.assertLessThanOrEqual([errStruct_o.F1s]-[[1 1 1 0 0 0 0]', [1 1 1 1 0 0 0]', [1 1 1 1 1 0 0]'],tol);
            testCase.assertLessThanOrEqual([errStruct_o.P]-[2*[1 1 1 0 0 0 0]', 2*[1 1 1 1 0 0 0]', 2*[1 1 1 1 1 0 0]'],tol);
            testCase.assertLessThanOrEqual([errStruct_o.R]-[pi*[1 1 1 0 0 0 0]', 2*pi*[1 1 1 1 0 0 0]', 3*pi*[1 1 1 1 1 0 0]'],tol);

        end

    end
    
end

