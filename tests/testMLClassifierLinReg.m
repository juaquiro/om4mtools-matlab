classdef testMLClassifierLinReg < matlab.unittest.TestCase
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
        
        function testConstructor(testCase)
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            
            %this is a supervised classfier
            testCase.assertTrue(c.isSupervised);
            
            
            %this is a regression
            testCase.assertTrue(c.isRegression);
            
            l=c.Get();
            testCase.assertTrue(isfield(l, char(ClassifierProps.lambda)));
            
            l=c.Get(char(ClassifierProps.lambda));
            testCase.assertEqual(l, 1);
            
            c.Set(char(ClassifierProps.lambda), 10);
            l=c.Get(char(ClassifierProps.lambda));
            testCase.assertEqual(l, 10);
            
            p=c.Get(char(ClassifierProps.p));
            testCase.assertEqual(p, 1);
            
            c.Set(char(ClassifierProps.p), 3);
            p=c.Get(char(ClassifierProps.p));
            testCase.assertEqual(p, 3);
            
            %check default value for featureType
            ft=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft, aFeatureTypes.Unknown);
            
            %check seting incorrect value for featureType
            try
                ft=1;
                c.Set(char(ClassifierProps.featureType), ft);
            catch ME
                retMsg=['ClassifierLinReg->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end
            
            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);
            
            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
            
        end
        
        
        function testTrain(testCase)
            % ex1_multitaken from the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            
            % Load Data
            data = csvread(fullfile(fixturesRoot(), 'CourseraMLData', 'ex1data2.txt'));
            X = data(:, 1:2);
            y = data(:, 3);
            m = length(y);
            
            c.Set(char(ClassifierProps.normalize), true); %calculate norma params in training
            c.Set(char(ClassifierProps.lambda), 0);
            c.Train(X,y);
            
            % Estimate the price of a 1650 sq-ft, 3 br house and the probability of the
            % prediction
            Y=[1650 3];
            [pred,prb]=c.Predict(Y);
            price=pred;
            probability=prb;
            
            aprice=293081.464335;
            tol=1e-3;
            testCase.assertTrue(abs(price-aprice)<=tol);
            testCase.assertTrue(probability>0.8);
            
            
            %check using incorrect number of features
            try
                n=size(X,2);
                X=X(:, n-1);
                [z1, p1]=c.Predict(X);
            catch ME
                retMsg='ClassifierLinReg->feature number mismatch between Train and Predict: Classifier.Predict';
                testCase.assertEqual(ME.message, retMsg)
            end
            
        end
        
        
        function testLearningCurve(testCase)
            %ejemplo cojido del ex5_multi del curso de ML
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            
            load (fullfile(fixturesRoot(), 'CourseraMLData', 'ex5data1.mat'));
            
            m = size(X, 1); % Number of training examples
            
            lambda = 3;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize), true);
            mdelta=1; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(c, X, y, Xval, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            p = 8;
            % Map X onto Polynomial Features
            X_poly = polyFeatures(X, p);
            X_poly_test = polyFeatures(Xtest, p);
            X_poly_val = polyFeatures(Xval, p);
            
            lambda = 3;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize), true);
            mdelta=1; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(c, X_poly, y, X_poly_val, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
        end
        
        
        function testValidationCurve(testCase)
            %ejemplo cojido del ex5_multi del curso de ML
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            
            load (fullfile(fixturesRoot(), 'CourseraMLData', 'ex5data1.mat'));
            
            m = size(X, 1); % Number of training examples
            
            p = 8;
            % Map X onto Polynomial Features
            X_poly = polyFeatures(X, p);
            X_poly_test = polyFeatures(Xtest, p);
            X_poly_val = polyFeatures(Xval, p);
            
            lambda = 3;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize), true);
            lambda = [0 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3 10 30]';
            %lambda=linspace(0, 10, 100);
            [error_train, error_val] = UtilFunML.validationCurve(c, lambda, X_poly, y, X_poly_val, yval);
            figure; plot(lambda, [error_train.J], lambda, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Accuracy');
            
        end
        
        
        % Create and train a ClassifierLR, then save it to a .mat file, load this
        % file and obtain and make a prediction
        function testSaveAndLoadClassifier(testCase)
            % ex1_multitaken from the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            
            % Load Data
            data = csvread(fullfile(fixturesRoot(), 'CourseraMLData', 'ex1data2.txt'));
            X = data(:, 1:2);
            y = data(:, 3);
            m = length(y);
            
            c.Set(char(ClassifierProps.normalize), true); %calculate norma params in training
            c.Set(char(ClassifierProps.lambda), 0);
            c.Train(X,y);
            
            % Estimate the price of a 1650 sq-ft, 3 br house and the probability of the
            % prediction
            Y=[1650 3];
            [pred,prb]=c.Predict(Y);
            price=pred;
            probability=prb;
            
            aprice=293081.464335;
            tol=1e-3;
            testCase.assertTrue(abs(price-aprice)<=tol);
            testCase.assertTrue(probability>0.8);
            
            % Save, delete and load the classifier to obtain the same prediction and
            % probability vectors as before
            c.save(c,'classifierLinReg_test')
            clear c ans
            % Creating a new classifier
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            % Loading the saved data from the previous training. It doesn�t matter the
            % type of the created classifier, it can load any other type of classifiers
            c=c.load('classifierLinReg_test');
            
            [pred2,prb2]=c.Predict(Y); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prb,prb2);
            
            delete('classifierLinReg_test.mat') % Delete the created .mat file for the test
        end
        
        %this test check the capability for a quadratic fit for XYZ data and then
        %find the minimum of the quadratic form by means of fminsearch
        function testQuadraticFitAndMin(testCase)
            %mtest testML_ClassifierLinReg:testQuadraticFitAndMin
            
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            c=ClassifierFactory.Create(ClassifierTypes.LinReg);
            lambda = 0.01; c.Set(char(ClassifierProps.lambda), lambda); %regularize
            c.Set(char(ClassifierProps.normalize), true); %normalize data
            p = 2; c.Set(char(ClassifierProps.p), p); %cuadratic form
            
            m=200;%number of samples
            x1=(rand(m,1)-0.5); %different ranges for x1, x2 and x3
            x2=(rand(m,1)-0.5);
            x3=(rand(m,1)-0.5);
            DC=5; %DC signal
            gv=DC+sind((x1+0.3).^2 + x2.^2 + x3.^2) + 0.001*randn(size(x1)); %locally is a quadratic
            
            X=[x1, x2, x3];
            y=gv;
            c.Train(X,y);
            
            %search for min
            f=@(P) c.Predict(P);
            P0=[rand-0.5, rand-0.5, rand-0.5];
            Pmin=fminsearch(f, P0);
            [predGV,prbGV]=c.Predict(Pmin);
            testCase.assertTrue(abs(predGV-DC)<1e-2);
            
            
            
            %check learning curve
            k=randperm(m);
            K=round(m/10);
            Xval=X(m-K+1:end, :);
            yval=y(m-K+1:end, :);
            %lambda=linspace(0, 10, 100);
            [error_train, error_val] = UtilFunML.learningCurve(c, X(1:m-K, :), y(1:m-K, :), Xval, yval);
            figure; plot(1:m-K, [error_train.J], 1:m-K, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
        end
    end
    
end

