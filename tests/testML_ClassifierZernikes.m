classdef testML_ClassifierZernikes < matlab.unittest.TestCase
    % testML_ClassifierZernikes tests ClassifierZernikes, mostly against
    % real lens surface data (Youn200225202.mat)
    %run(testML_ClassifierZernikes)

    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            setupPath();
        end
    end

    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m), not MATLAB's factory path
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end

    methods (Test)
        function testConstructor(testCase)
            % testConstructor checks ClassifierZernikes' flags
            % (supervised, regression), default props (lambda, zOrder,
            % featureType) and featureType validation on Set
            %run(testML_ClassifierZernikes, 'testConstructor')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            %this is a supervised classfier
            testCase.assertTrue(c.isSupervised);

            %this is not a regression
            testCase.assertTrue(c.isRegression);

            %Field lambda exists
            l=c.Get();
            testCase.assertTrue(isfield(l, char(ClassifierProps.lambda)));

            %Default lambda is 0
            l=c.Get(char(ClassifierProps.lambda));
            testCase.assertEqual(l, 0);

            %Check we can change the lambda value
            c.Set(char(ClassifierProps.lambda), 10);
            l=c.Get(char(ClassifierProps.lambda));
            testCase.assertEqual(l, 10);

            %Default p is 150
            ZOrder=c.Get(char(ClassifierProps.zOrder));
            testCase.assertEqual(ZOrder, 209);

            %Check we can change the p value
            c.Set(char(ClassifierProps.zOrder), 3);
            ZOrder=c.Get(char(ClassifierProps.zOrder));
            testCase.assertEqual(ZOrder, 3);

            %check default value for featureType
            ft=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft, aFeatureTypes.Unknown);

            %check seting incorrect value for featureType
            try
                ft=1;
                c.Set(char(ClassifierProps.featureType), ft);
            catch ME
                retMsg=['ClassifierZernikes->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end

            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);

            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
        end

        function testTrain(testCase)
            % testTrain fits ClassifierZernikes to a real lens surface
            % (Youn200225202.mat), checks the predicted sag at the
            % center against the fixture's own center value, and checks
            % the feature-count mismatch error on Predict
            %run(testML_ClassifierZernikes, 'testTrain')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;

            %Train the classifier
            c.Train(X,y);

            % Estimate the sagita of the surface in the center
            Y=[0 0];
            [pred,prb]=c.Predict(Y);
            sag=pred;
            probability=prb; %#ok<NASGU>

            %The point in the center of the measured area is (0,0)
            asag=y(125);
            tol=1e-3;
            testCase.assertTrue(abs(sag-asag)<=tol);

            %check using incorrect number of features
            try
                n=size(X,2);
                X=X(:, n-1);
                [z1, p1]=c.Predict(X); %#ok<ASGLU>
            catch ME
                retMsg='ClassifierZernikes->feature number mismatch between Train and Predict: Classifier.Predict';
                testCase.assertEqual(ME.message, retMsg)
            end
        end

        function testLearningCurve(testCase)
            % testLearningCurve plots UtilFunML.learningCurve's train/CV
            % error vs sample count on the real lens fixture, at two
            % lambda values, using the default (data-driven) Zernike radius
            %run(testML_ClassifierZernikes, 'testLearningCurve')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;
            m = length(y); %Total number of points

            %Randomize order
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            Xval=X(end-19:end,:); X=X(1:end-20,:);
            yval=y(end-19:end); y=y(1:end-20);
            m = length(y); % Number of training examples

            %Set a working lambda
            lambda = 0;
            c.Set(char(ClassifierProps.lambda), lambda);

            %Calculate learning curve
            mdelta=5; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(c, X, y, Xval, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');

            lambda = 1e-6;
            c.Set(char(ClassifierProps.lambda), lambda);
            mdelta=5; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(c, X, y, Xval, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
        end


        function testLearningCurveFixedRadius(testCase)
            % testLearningCurveFixedRadius repeats testLearningCurve
            % with an explicit fixed zernikeRadius (60) instead of the
            % default data-driven one
            %run(testML_ClassifierZernikes, 'testLearningCurveFixedRadius')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;
            m = length(y); %Total number of points

            %Randomize order
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            Xval=X(end-19:end,:); X=X(1:end-20,:);
            yval=y(end-19:end); y=y(1:end-20);
            m = length(y); % Number of training examples

            %Set a working lambda
            lambda = 0;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.zernikeRadius),  60);

            %Calculate learning curve
            mdelta=5; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(c, X, y, Xval, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');

            lambda = 1e-6;
            c.Set(char(ClassifierProps.lambda), lambda);
            mdelta=5; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(c, X, y, Xval, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
        end

        function testValidationCurve(testCase)
            % testValidationCurve plots UtilFunML.validationCurve's
            % train/CV error vs lambda (log-spaced) on the real lens
            % fixture at zOrder=209
            %run(testML_ClassifierZernikes, 'testValidationCurve')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;

            %Randomize order
            m = length(y); %Total number of points
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            Xval=X(end-19:end,:); X=X(1:end-20,:);
            yval=y(end-19:end); y=y(1:end-20);

            zOrder = 209;
            c.Set(char(ClassifierProps.zOrder), zOrder);
            lambda=logspace(-8, -3, 100);
            [error_train, error_val] = UtilFunML.validationCurve(c, lambda, X, y, Xval, yval);
            figure; semilogx(lambda, [error_train.J], lambda, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Accuracy');
        end

        function testZernikeMuCurve(testCase)
            % testZernikeMuCurve plots UtilFunML.ZernikeMuCurve's
            % train/CV error vs the mu curvature-regularization
            % parameter on the real lens fixture at zOrder=209, lambda=1e-6
            %run(testML_ClassifierZernikes, 'testZernikeMuCurve')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;

            %Randomize order
            m = length(y); %Total number of points
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            Xval=X(end-19:end,:); X=X(1:end-20,:);
            yval=y(end-19:end); y=y(1:end-20);

            zOrder = 209;
            c.Set(char(ClassifierProps.zOrder), zOrder);
            lambda=1e-6;
            c.Set(char(ClassifierProps.lambda), lambda);
            mu=logspace(-12, -2, 100);
            [error_train, error_val] = UtilFunML.ZernikeMuCurve(c, mu, X, y, Xval, yval);
            figure; semilogx(mu, [error_train.J], mu, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('mu'); ylabel('Accuracy');
        end

        function testValidationCurveFixedRadius(testCase)
            % testValidationCurveFixedRadius repeats testValidationCurve
            % with an explicit fixed zernikeRadius (60)
            %run(testML_ClassifierZernikes, 'testValidationCurveFixedRadius')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;

            %Randomize order
            m = length(y); %Total number of points
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            Xval=X(end-19:end,:); X=X(1:end-20,:);
            yval=y(end-19:end); y=y(1:end-20);

            zOrder = 209;
            c.Set(char(ClassifierProps.zOrder), zOrder);
            c.Set(char(ClassifierProps.zernikeRadius),  60);
            lambda=logspace(-13, -5, 100);
            [error_train, error_val] = UtilFunML.validationCurve(c, lambda, X, y, Xval, yval);
            figure; semilogx(lambda, [error_train.J], lambda, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Accuracy');
        end

        function testZernikeMuCurveFixedRadius(testCase)
            % testZernikeMuCurveFixedRadius repeats testZernikeMuCurve
            % with an explicit fixed zernikeRadius (60) and lambda=3e-9
            %run(testML_ClassifierZernikes, 'testZernikeMuCurveFixedRadius')
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;

            %Randomize order
            m = length(y); %Total number of points
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            Xval=X(end-19:end,:); X=X(1:end-20,:);
            yval=y(end-19:end); y=y(1:end-20);

            zOrder = 209;
            c.Set(char(ClassifierProps.zOrder), zOrder);
            lambda=3e-9;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.zernikeRadius),  60);
            mu=logspace(-20, -10, 50);
            [error_train, error_val] = UtilFunML.ZernikeMuCurve(c, mu, X, y, Xval, yval);
            figure; semilogx(mu, [error_train.J], mu, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('mu'); ylabel('Accuracy');
        end

        function testSaveAndLoadClassifier(testCase)
            % testSaveAndLoadClassifier trains ClassifierZernikes on the
            % real lens fixture, checks the predicted center sag, then
            % saves/loads the classifier and checks predictions are
            % unchanged
            %run(testML_ClassifierZernikes, 'testSaveAndLoadClassifier')
            % Create and train a ClassifierLR, then save it to a .mat file, load this
            % file and obtain and make a prediction
            % ex1_multitaken from the ML course
            %'Youn200225202.mat' contains measures from a real lens
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);

            % Load Data
            data = load('Youn200225202.mat');
            X=[data.X(:), data.Y(:)];
            y=data.Z;

            c.Set(char(ClassifierProps.lambda), 0);
            c.Train(X,y);

            % Estimate the sagita of the surface in the center
            Y=[0 0];
            [pred,prb]=c.Predict(Y);
            sag=pred;
            probability=prb; %#ok<NASGU>

            %The point in the center of the measured area is (0,0)
            asag=y(125);
            tol=1e-3;
            testCase.assertTrue(abs(sag-asag)<=tol);

            % Save, delete and load the classifier to obtain the same prediction and
            % probability vectors as before
            c.save(c,'classifierZernikes_test')
            clear c ans
            % Creating a new classifier
            c=ClassifierFactory.Create(ClassifierTypes.Zernikes);
            % Loading the saved data from the previous training. It doesn't matter the
            % type of the created classifier, it can load any other type of classifiers
            c=c.load('classifierZernikes_test');

            [pred2,prb2]=c.Predict(Y); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prb,prb2);

            delete('classifierZernikes_test.mat') % Delete the created .mat file for the test
        end
    end
end
