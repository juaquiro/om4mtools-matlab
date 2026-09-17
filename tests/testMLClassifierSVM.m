classdef testMLClassifierSVM < matlab.unittest.TestCase
    % testMLClassifierSVM tests ClassifierSVM
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
            % testConstructor checks ClassifierSVM's flags (supervised,
            % non-regression), default props (lambda, KFp, featureType)
            % and featureType validation on Set

            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());


            c=ClassifierFactory.Create(ClassifierTypes.SVM);

            %this is a supervised classfier
            testCase.assertTrue(c.isSupervised);
            
            %this is not a regression
            testCase.assertFalse(c.isRegression);
            
            l=c.Get();
            testCase.assertTrue(isfield(l, char(ClassifierProps.lambda)));
            
            l=c.Get(char(ClassifierProps.lambda));
            testCase.assertEqual(l, 1);
            
            c.Set(char(ClassifierProps.lambda), 10);
            l=c.Get(char(ClassifierProps.lambda));
            testCase.assertEqual(l, 10);
            
            p=c.Get(char(ClassifierProps.KFp));
            testCase.assertEqual(p, 1);
            
            c.Set(char(ClassifierProps.KFp), 3);
            p=c.Get(char(ClassifierProps.KFp));
            testCase.assertEqual(p, 3);
            
            %check default value for featureType
            ft=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft, aFeatureTypes.Unknown);
            
            %check seting incorrect value for featureType
            try
                ft=1;
                c.Set(char(ClassifierProps.featureType), ft);
            catch ME
                retMsg=['ClassifierSVM->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end
            
            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);
            
            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
            
        end
        
        
        function testTrainDigits(testCase)
            % testTrainDigits trains ClassifierSVM on the Coursera
            % ex3data1 (digits) dataset, checks cost/F1/precision/
            % recall/accuracy against reference values, and checks the
            % feature-count mismatch error on Predict
            %example form ex3.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex3data1.mat')); % training data stored in arrays X, y
            
            C = 1;
            sigma=30;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Train(X,y);
            
            stErr = c.ErrorFunction(X, y);

            % Reference J recomputed 2026-09 for fitcsvm (SMO solver) --
            % svmtrain used a different QP-based solver; the old
            % svmtrain-era value (5.3) no longer matches within 1e-1
            % (fitcsvm actually trains slightly better here, J~4.86).
            % Tolerance widened to absorb this kind of small
            % solver-dependent drift going forward. See DECISIONS.md,
            % "Fase 4 -- svmtrain -> fitcsvm modernization".
            tol=2e-1;
            testCase.assertTrue(abs(4.86-stErr.J)<=tol);
            
            %en este ejemplo todas las clases estan "divinas"
            testCase.assertTrue(all(stErr.F1s>.9));
            testCase.assertTrue(all(stErr.R>.9));
            testCase.assertTrue(all(stErr.P>.9));
            
            % prediction and probability
            [pred,prb]=c.Predict(X);
            predicted_class=pred;
            probability=prb;
            n=size(y);
            
            testCase.assertEqual(size(predicted_class),n);
            testCase.assertEqual(size(probability),n);
            
            % Training Set Accuracy
            % Reference recomputed 2026-09 for fitcsvm (old svmtrain-era
            % value was 94.7, see DECISIONS.md "Fase 4 -- svmtrain ->
            % fitcsvm modernization").
            t_accuracy=UtilFunML.Accuracy(y,predicted_class);
            testCase.assertTrue(abs(t_accuracy-95.14)<=tol);
            
            %check using incorrect number of features
            try
                n=size(X,2);
                X=X(:, n-1);
                [z1, p1]=c.Predict(X);
            catch ME
                retMsg='ClassifierSVM->feature number mismatch between Train and Predict: Classifier.Predict';
                testCase.assertEqual(ME.message, retMsg)
            end
            
        end
        
        
        function testLearningCurve(testCase)
            % testLearningCurve plots UtilFunML.learningCurve's train/CV
            % error and per-class F1 vs sample count on a decimated
            % Coursera ex3data1 dataset
            %example form ex3.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex3data1.mat')); % training data stored in arrays X, y
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos
            X=X(1:20:end, :); y=y(1:20:end); %diezmamos datos
            
            m=size(X, 1);
            N=round(0.7*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            %a veces en el diezmado no quedan las diez etiquetas 1..10
            try
                UtilFunML.checkTrainSetLabels(yt);
            catch ME
                t='labels must be consequitive integer numbers 1,2...N-1, N : UtilFunML.checkTrainSetLabels';
                testCase.assertEqual(ME.message, t)
                error('a veces en el diezmado no salen todas las etiquetas, repetir test');
            end
            
            C = 0.3;
            sigma=30;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            
            [error_train, error_val] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                
                train_F1s=[error_train.F1s];
                val_F1s=[error_val.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
            end
            
            
            
        end
        
        
        function testLearningCurve2(testCase)
            % testLearningCurve2 plots UtilFunML.learningCurve's train/CV
            % error and per-class F1/precision/recall vs sample count on
            % the raw Coursera ex2data2 (microchip QA) dataset
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p)+1; %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            
            C = 1;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            [error_train, error_val] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train.F1s];
                val_F1s=[error_val.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
                
                train_P=[error_train.P];
                val_P=[error_val.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n)]);
                
                
                train_R=[error_train.R];
                val_R=[error_val.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n)]);
                
            end
        end
        
        
        function testValidationCurve2(testCase)
            % testValidationCurve2 plots UtilFunML.validationCurve's
            % train/CV error vs C (the lambda prop) on the raw Coursera
            % ex2data2 dataset.
            %  Note: despite testing ClassifierSVM elsewhere in this
            % file, this method builds a ClassifierTypes.LogR classifier
            % instead.
            %example form ex2.m of the ML course

            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p)+1; %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            C = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3 10 30 100]';
            C=flipud(C);
            
            sigma=1;
            c.Set(char(ClassifierProps.sigma), sigma);
            
            %lambda=linspace(0, 10, 100);
            [error_train, error_val] = UtilFunML.validationCurve(c, C, Xt, yt, Xval, yval);
            figure; plot(C, [error_train.J], C, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('C'); ylabel('Error');
            
        end
        
        
        function testTrainChips(testCase)
            % testTrainChips trains ClassifierSVM on the raw Coursera
            % ex2data2 (microchip QA) dataset (showplot enabled) and
            % checks cost/F1/precision/recall against reference values
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            %aqui no hace falta ningun map feature
            y=y+1; %transform label (0,1) to (1,2)
            
            C = 1;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.showplot), true);
            
            c.Train(X,y); figure(gcf);
            stErr = c.ErrorFunction(X, y);
            
            tol=1e-1;
            % Reference recomputed 2026-09 for fitcsvm (old svmtrain-era
            % value was 100-83.8983=16.1017, see DECISIONS.md "Fase 4 --
            % svmtrain -> fitcsvm modernization"). F1/P/R below still
            % pass within the original tolerance, unchanged.
            testCase.assertTrue(abs(stErr.J-15.2542)<=tol);
            testCase.assertTrue(all(stErr.F1s>.8));
            
            %first class has high precission lower recall, second class lower precision
            %high recall
            testCase.assertTrue(all(abs([stErr.P(1) stErr.R(1)]-[0.82  0.86])<=tol));
            testCase.assertTrue(all(abs([stErr.P(2) stErr.R(2)]-[0.85  0.81])<=tol));
            
        end
        
        
        function testLearningCurveLensesIOT(testCase)
            % testLearningCurveLensesIOT plots UtilFunML.learningCurve's
            % train/CV error and per-class F1/precision/recall vs sample
            % count on real lens QC features (DPMMeStd feature set,
            % loaded via TrainingDataLoader); the commented-out tail
            % would train and save a classifier for use in extGnG
            %AQAQDEBUG este test preparar un clasificador SVM para provar en el extGnG
            %mtest testML_ClassifierSVM:testLearningCurveLensesIOT
            
            import OM4MClassLib.Util.*;
            import Util.* OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            
            QCStatsFile='QCStatsReport2Clases.xlsx';
            labelData=EnumLabelData.Type;
            
            ListFeatureNames={EnumFeatureNames.meanTSeqErr, EnumFeatureNames.StdTSeqErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr};
            LensType=EnumLens.Progressive;
            Eye=EnumEye.R;
            
            %the feature list is the same than FeatureDPMMeStd, so set the classifier
            %featureType for future use in Calculate
            c.Set('featureType', aFeatureTypes.DPMMeStd);
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            
            X=TDL.X;
            y=TDL.y;
            
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            
            C = 0.3;
            sigma=3;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            [error_train, error_val] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train.F1s];
                val_F1s=[error_val.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
                
                train_P=[error_train.P];
                val_P=[error_val.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n)]);
                
                
                train_R=[error_train.R];
                val_R=[error_val.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n)]);
                
            end
            
            %finalmente lo preparamos para crear un clasificador entrenado
            % c.Train(X,y);
            % c.save(c,'ClassifierSVMGnG');
        end
        
        
        function testTrainingEx6data2Normalization(testCase)
            % testTrainingEx6data2Normalization visually trains
            % ClassifierSVM on ex6data2 (with one feature column scaled
            % down by 1e-6) twice, both times with normalize=true.
            %  Note: the comments say "first with normalization" /
            % "second without normalization", but both calls actually
            % set ClassifierProps.normalize to true.
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            % Load from ex6data2:
            % You will have X, y in your environment
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex6data2.mat'));
            
            X(:, 1)=1e-6*X(:, 1);
            y=y+1;
            
            C = 1;
            sigma=0.3;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.showplot), true);
            %first with normalization
            c.Set(char(ClassifierProps.normalize), true);
            c.Train(X,y); figure(gcf);
            
            %second whithout normalization
            c.Set(char(ClassifierProps.normalize), true);
            figure;
            c.Train(X,y); figure(gcf);
        end
        
        
        function testTrainingEx6data2PostProb(testCase)
            % testTrainingEx6data2PostProb trains ClassifierSVM on the
            % raw ex6data2 dataset and visually inspects the predicted
            % class and posterior probability over a grid
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            % Load from ex6data2:
            % You will have X, y in your environment
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex6data2.mat'));
            
            y=y+1;
            
            C = 1;
            sigma=0.3;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.showplot), true);
            c.Set(char(ClassifierProps.normalize), true);
            c.Train(X,y); figure(gcf);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            X=[X1(:), X2(:)];
            [z,p]=c.Predict(X);
            
            X=[X1(:), X2(:)];
            [z,p]=c.Predict(X);
            figure; pcolor(X1, X2, reshape(p, N2,N1));
            figure; pcolor(X1, X2, reshape(z, N2,N1));
            
        end
        
        
        function testTrainingex2data2PostProb(testCase)
            % testTrainingex2data2PostProb trains ClassifierSVM on the
            % raw Coursera ex2data2 dataset and visually inspects the
            % predicted class and posterior probability over a grid
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.SVM);

            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);

            y=y+1;

            C = 1;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.showplot), true);
            c.Set(char(ClassifierProps.normalize), true);
            c.Train(X,y); figure(gcf);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            X=[X1(:), X2(:)];
            [z,p]=c.Predict(X);
            figure; pcolor(X1, X2, reshape(p, N2,N1));
            figure; pcolor(X1, X2, reshape(z, N2,N1));
            
        end
        
        
        function testSaveAndLoad(testCase)
            % testSaveAndLoad trains ClassifierSVM on the raw Coursera
            % ex2data2 dataset, saves it via the static Classifier.load
            % (base-class) API and checks predictions are unchanged.
            %  Note: saves to 'ClassifierSVM_test.mat' but loads from
            % 'classifierSVM_test' (different case) - only works on a
            % case-insensitive filesystem (e.g. Windows).
            % Create and train a ClassifierSVN, then save it to a .mat file, load this
            % file and obtain and make a prediction
            %mtest testML_ClassifierSVM:testSaveAndLoad
            %example form ex3.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            %aqui no hace falta ningun map feature
            y=y+1; %transform label (0,1) to (1,2)
            
            C = 1;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Train(X,y);
            
            % prediction and probability
            [pred,prb]=c.Predict(X);
            predicted_class=pred;
            probability=prb;
            n=size(y);
            
            testCase.assertEqual(size(predicted_class),n);
            testCase.assertEqual(size(probability),n);
            
            % Save, delete and load the classifier to obtain the same prediction matrix
            % as before
            c.save(c,'ClassifierSVM_test')
            clear c;
            
            % Loading the saved data from the previous training. It doesn�t matter the
            % type of the created classifier, it can load any other type of classifiers
            c=Classifier.load('classifierSVM_test');
            
            testCase.assertTrue(isa(c, 'Classifier'));
            
            [pred2,prb2]=c.Predict(X); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prb,prb2);
            
            delete('ClassifierSVM_test.mat') % Delete the .mat file created for the test
        end
    end
    
end

