classdef testMLClassifierNN1 < matlab.unittest.TestCase
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
            
            import OM4MClassLib.Util.*
            fprintf('\n%s: ',Logging.WhoCalledMe());
            %
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            
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
            
            hs=c.Get(char(ClassifierProps.hiddenSizes));
            testCase.assertTrue(all(hs==[10 10]));
            
            
            c.Set(char(ClassifierProps.hiddenSizes), [10 20 30]);
            hs=c.Get(char(ClassifierProps.hiddenSizes));
            testCase.assertTrue(all(hs==[10 20 30] ));
            
            %check default value for featureType
            ft=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft, aFeatureTypes.Unknown);
            
            %check seting incorrect value for featureType
            try
                ft=1;
                c.Set(char(ClassifierProps.featureType), ft);
            catch ME
                retMsg=['ClassifierNN1->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end
            
            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);
            
            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
            
        end
        
        
        function testTrain(testCase)
            
            import OM4MClassLib.Util.*
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex4data1.mat'));
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            % In the exercise, lamba=3
            lambda=3;
            c.Set(char(ClassifierProps.lambda),lambda);
            % In the exercise, the number there's 1 hidden layer with 25 neurons
            hiddenSizes=25;
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            
            c.Train(X,y);
            stErr=c.ErrorFunction(X, y);
            
            % Note from the exercise:
            % You should see a reported training accuracy of about 95.3% (this may vary
            % by about 1% due to the random initialization)
            tol=1;
            testCase.assertTrue(abs(5-stErr.J)<=tol);
            % As a prepared exercise, each validation parameter has a value closer to 1
            testCase.assertTrue(all(stErr.F1s>.9));
            testCase.assertTrue(all(stErr.R>.9));
            testCase.assertTrue(all(stErr.P>.9));
            
            % Prediction and probability
            [pred,prb]=c.Predict(X);
            predicted_class=pred;
            probability=prb;
            n=size(y);
            
            testCase.assertEqual(n,size(predicted_class))
            testCase.assertEqual(n,size(probability))
            
            % Training Set Accuracy
            t_accuracy=UtilFunML.Accuracy(y,predicted_class);
            testCase.assertTrue(abs(t_accuracy-95.06)<=tol); % Training Set Accuracy: 95.060000
            
            %check using incorrect number of features
            try
                n=size(X,2);
                X=X(:, n-1);
                [z1, p1]=c.Predict(X);
            catch ME
                retMsg='ClassifierNN1->feature number mismatch between Train and Predict: Classifier.Predict';
                testCase.assertEqual(ME.message, retMsg)
            end
            
        end
        
        % Train the algorithm with the good and wrong cases and re-classify the
        % anomalous cases
        function testTrainIOT(testCase)
            
            import OM4MClassLib.Util.*
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegStdTSeqErr, ...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            p1=(y==1); % Logical indices of the anomalous cases (alphabetical order: Anom=>y=1, Good=>y=2, Wrong=>y=3)
            p2=(y==2); % Logical indices of the good cases
            p3=(y==3); % Logical indices of the wrong cases
            
            Xanom=X(p1,:); % Anomalous cases
            X=[X(p2,:);X(p3,:)]; % Selecting just the good and wrong cases to train
            y=[y(p2);y(p3)];
            y=y-1; % labels must be consequitive integer numbers 1,2...N-1, N
            
            m=size(X, 1);
            p=randperm(m); % Dis-ordering the data
            X=X(p, :); y=y(p);
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            lambda=0;
            c.Set(char(ClassifierProps.lambda),lambda);
            hiddenSizes=36;
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            
            c.Set(char(ClassifierProps.normalize),true);
            c.Train(X,y);
            % Prediction and probability
            [pred,prb]=c.Predict(X);
            predicted_class=pred;
            probability=prb;
            n=size(y);
            
            testCase.assertEqual(n,size(predicted_class))
            testCase.assertEqual(n,size(probability))
        end
        
        
        function testLCurve(testCase)
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex4data1.mat'));
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            % In the exercise, lamba=3
            c.Set(char(ClassifierProps.lambda), 3);
            % In the exercise, the number there's 1 hidden layer with 25 neurons
            c.Set(char(ClassifierProps.hiddenSizes), 25);
            
            m=size(X,1);
            p=randperm(m);
            p=p(1:200);
            X=X(p,:);
            y=y(p);
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            lambda=3; % In the exercise, lamba=3
            c.Set(char(ClassifierProps.lambda),lambda);
            
            [error_train, error_val] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
        end
        
        
        function testLCurveIOT(testCase)
            
            import OM4MClassLib.Util.*
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegStdTSeqErr, ...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            
            m=size(X, 1);
            p=randperm(m);
            p=p(1:100); % subset of the data, to make the test faster
            X=X(p, :); y=y(p);
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            hiddenSizes=4; % (4+3)/2
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            lambda=0;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize),true);
            lb=labelManager();
            labels=lb.getlabel(yt,{'Good','Wrong','Anomalous'});
            [error_train, error_val]=UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train.F1s];
                val_F1s=[error_val.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' labels(n)]);
                
                train_P=[error_train.P];
                val_P=[error_val.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' labels(n)]);
                
                train_R=[error_train.R];
                val_R=[error_val.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' labels(n)]);
                
            end
        end
        
        
        function testValCurveIOT(testCase)
            
            import OM4MClassLib.Util.*
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            
            QCStatsFile='QCStatsReport2Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegStdTSeqErr,...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            
            X=TDL.X;
            y=TDL.y;
            
            m=size(X, 1);
            p=randperm(m);
            p=p(1:100); % subset of the data, to make the test faster
            X=X(p, :); y=y(p); % Disordering the data
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            c.Set(char(ClassifierProps.normalize),true);
            lambda = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3 10]';
            [error_train, error_val] = UtilFunML.validationCurve(c, lambda, Xt, yt, Xval, yval);
            figure; plot(lambda, [error_train.J], lambda, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Error');
            
            % ind=(min([error_val.J])==[error_val.J]);
            % lambda_opt=lambda(ind);
        end
        
        
        function testLCurveIOTPoly(testCase)
            
            import OM4MClassLib.Util.*
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport2Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegStdTSeqErr, ...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            
            m=size(X, 1);
            p=randperm(m);
            p=p(1:100); % subset of the data, to make the test faster
            X=X(p, :); y=y(p);
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); % test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); % cross validation set
            yval=y(N+1:end, :);
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            hiddenSizes=36; % (69+4)/2
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            lambda=0;
            c.Set(char(ClassifierProps.lambda), lambda);
            p=4;
            c.Set(char(ClassifierProps.p), p);
            c.Set(char(ClassifierProps.normalize),true);
            lb=labelManager();
            labels=lb.getlabel(yt,{'Good','Wrong'});
            [error_train, error_val]=UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train.F1s];
                val_F1s=[error_val.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' labels(n)]);
                
                train_P=[error_train.P];
                val_P=[error_val.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' labels(n)]);
                
                train_R=[error_train.R];
                val_R=[error_val.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' labels(n)]);
                
            end
        end
        
        
        function testLCurveIOT_3SetsOf100(testCase)
            
            % Obtainig the data
            import OM4MClassLib.Util.*
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegMeanTCErr, ...
                EnumFeatureNames.NoRegStdTSeqErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            
            % Find Indices of the Anomalous, Good and Wrong Classes, 100 random
            % elements of each class
            anom=find(y==1);
            m1=length(anom); p1=randperm(m1); p1=p1(1:100); anom=anom(p1);
            good=find(y==2);
            m2=length(good); p2=randperm(m2); p2=p2(1:100); good=good(p2);
            wrong=find(y==3);
            m3=length(wrong); p3=randperm(m3); p3=p3(1:100); wrong=wrong(p3);
            
            % Plot Examples
            figure; hold on;
            plot(X(anom, 1), X(anom, 2), 'k+','LineWidth', 2, ...
                'MarkerSize', 7);
            plot(X(good, 1), X(good, 2), 'ro', 'MarkerFaceColor', 'r', ...
                'MarkerSize', 4);
            plot(X(wrong, 1), X(wrong, 2), 'bx', 'LineWidth', 2, ...
                'MarkerSize', 7);
            xlabel(char(ListFeatureNames{1}))
            ylabel(char(ListFeatureNames{2}))
            legend('Anomalous','Good','Wrong')
            axis([0 0.16 0 0.22])
            hold off;
            
            figure; hold on;
            plot(X(anom, 3), X(anom, 4), 'k+','LineWidth', 2, ...
                'MarkerSize', 7);
            plot(X(good, 3), X(good, 4), 'ro', 'MarkerFaceColor', 'r', ...
                'MarkerSize', 4);
            plot(X(wrong, 3), X(wrong, 4), 'bx', 'LineWidth', 2, ...
                'MarkerSize', 7);
            xlabel(char(ListFeatureNames{3}))
            ylabel(char(ListFeatureNames{4}))
            legend('Anomalous','Good','Wrong')
            axis([0 0.11 0 0.11])
            hold off;
            
            % Learning curves for each class, using the 4 features contained in
            % ListFeatureNames and the 3 sets of 100 elements generated before
            X=[X(anom,:);X(good,:);X(wrong,:)];
            y=[y(anom,:);y(good,:);y(wrong,:)];
            m=size(X,1);
            p=randperm(m);
            X=X(p,:); y=y(p,:);
            N=round(0.8*m);
            Xt=X(1:N,:); yt=y(1:N);
            Xval=X(N+1:end,:); yval=y(N+1:end,:);
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            hiddenSizes=4; % (4+3)/2
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            lambda=0;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize),true);
            lb=labelManager();
            labels=lb.getlabel(yt,{'Anomalous','Good','Wrong'});
            [error_train, error_val]=UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train.J], 1:N, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train.F1s];
                val_F1s=[error_val.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' labels(n)]);
                
                train_P=[error_train.P];
                val_P=[error_val.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' labels(n)]);
                
                train_R=[error_train.R];
                val_R=[error_val.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' labels(n)]);
                
            end
        end
        
        % Create and train a ClassifierLR, then save it to a .mat file, load this
        % file and obtain and make a prediction
        function testSaveAndLoad(testCase)
            %mtest testML_ClassifierNN1:testSaveAndLoad
            
            import OM4MClassLib.Util.*
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex4data1.mat'));
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            % In the exercise, lamba=3
            lambda=3;
            c.Set(char(ClassifierProps.lambda),lambda);
            % In the exercise, the number there's 1 hidden layer with 25 neurons
            hiddenSizes=25;
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            
            c.Train(X,y);
            stErr=c.ErrorFunction(X, y);
            
            % Note from the exercise:
            % You should see a reported training accuracy of about 95.3% (this may vary
            % by about 1% due to the random initialization)
            tol=1;
            % The algorithm can be stuck in a local minimum and calculate an error much
            % more higher than expected. This rarely happens, but it's not impossible.
            % If this happens, the user should repeat the test another time. If it
            % fails in the following attemps successively, the test must be checked
            try
                testCase.assertTrue(abs(5-stErr.J)<=tol);
            catch
                error(['The algorithm can be stuck in a local minimum and calculate an error much',...
                    'more higher than expected. This rarely happens, but it ISN�T impossible.',...
                    'If this happens, the user should repeat the test another time. If it',...
                    'fails in the following attemps successively, the test must be checked.']);
            end
            % As a prepared exercise, each validation parameter has a value closer to 1
            testCase.assertTrue(all(stErr.F1s>.9));
            testCase.assertTrue(all(stErr.R>.9));
            testCase.assertTrue(all(stErr.P>.9));
            
            % Prediction and probability
            [pred,prb]=c.Predict(X);
            predicted_class=pred;
            probability=prb;
            n=size(y);
            
            testCase.assertEqual(n,size(predicted_class))
            testCase.assertEqual(n,size(probability))
            
            % Training Set Accuracy
            t_accuracy=UtilFunML.Accuracy(y,predicted_class);
            testCase.assertTrue(abs(t_accuracy-95.06)<=tol); % Training Set Accuracy: 95.060000
            
            % Save, delete and load the classifier to obtain the same prediction matrix
            % as before
            c.save(c,'ClassifierNN1_test')
            clear c
            % Creating a new classifier
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            % Loading the saved data from the previous training. It doesn�t matter the
            % type of the created classifier, it can load any other type of classifiers
            c=c.load('classifierNN1_test');
            
            [pred2,prb2]=c.Predict(X); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prb,prb2);
            
            %delete('ClassifierNN1_test.mat') % Delete the .mat file created for the test
        end
        
        function testTrainingex2data2PostProb(testCase)
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            y=y+1;
            
            k1=(y==1);
            k2=(y==2);
            figure; plot(X(k1, 1), X(k1, 2), 'g+', X(k2, 1), X(k2, 2), 'ro');
            
            lambda=0.001;
            c.Set(char(ClassifierProps.lambda),lambda);
            % In the exercise, the number there's 1 hidden layer with 25 neurons
            hiddenSizes=25;
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            c.Train(X,y);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            X=[X1(:), X2(:)];
            [z,p]=c.Predict(X);
            figure; pcolor(X1, X2, reshape(p, N2,N1));
            figure; pcolor(X1, X2, reshape(z, N2,N1));
            
        end
        
        function testSaveAndLoad_ex2data2(testCase)
            % mtest testML_ClassifierNN1:testSaveAndLoad_ex2data2
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN1);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            y=y+1;
            
            k1=(y==1);
            k2=(y==2);
            figure; plot(X(k1, 1), X(k1, 2), 'g+', X(k2, 1), X(k2, 2), 'ro');
            
            lambda=0.001;
            c.Set(char(ClassifierProps.lambda),lambda);
            % In the exercise, the number there's 1 hidden layer with 25 neurons
            hiddenSizes=25;
            c.Set(char(ClassifierProps.hiddenSizes),hiddenSizes);
            c.Train(X,y);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            X=[X1(:), X2(:)];
            [pred,prob]=c.Predict(X);
            figure; pcolor(X1, X2, reshape(pred, N2,N1));
            figure; pcolor(X1, X2, reshape(prob, N2,N1));
            
            % Save, delete and load the classifier to obtain the same prediction matrix
            % as before
            c.save(c,'ClassifierNN1_test')
            clear c
            % Creating a new classifier
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            % Loading the saved data from the previous training. It doesn�t matter the
            % type of the created classifier, it can load any other type of classifiers
            c=c.load('classifierNN1_test');
            
            [pred2,prb2]=c.Predict(X); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prob,prb2);
            
            delete('ClassifierNN1_test.mat') % Delete the .mat file created for the test
            
        end
    end
    
end

