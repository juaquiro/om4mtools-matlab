classdef testMLClassifierNN < matlab.unittest.TestCase
    % testMLClassifierNN tests ClassifierNN
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
            % testConstructor checks ClassifierNN's flags (supervised,
            % non-regression), default props (lambda, hiddenSizes,
            % featureType) and featureType validation on Set

            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());


            c=ClassifierFactory.Create(ClassifierTypes.NN);

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
                retMsg=['ClassifierNN->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end
            
            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);
            
            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
            
        end
        
        
%         function testTrainDigits_And_Predict(testCase)
%             %example form ex3.m of the ML course
%             
%             import OM4MClassLib.Util.*;
%             
%             fprintf('\n%s: ',Logging.WhoCalledMe());
%             
%             c=ClassifierFactory.Create(ClassifierTypes.NN);
%             
%             load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex3data1.mat')); % training data stored in arrays X, y
%             
%             lambda = 1e-1;
%             c.Set(char(ClassifierProps.lambda), lambda);
%             
%             hiddenSizes=[25];
%             c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
%             
%             c.Train(X,y);
%             stErr = c.ErrorFunction(X, y);
%             
%             try
%                 testCase.assertTrue(stErr.J<7);
%             catch ME
%                 pattern='%s\n';
%                 formatSpec=repmat(pattern,1,4);
%                 msg=sprintf(formatSpec,'The NN algorithm isn�t so much stable, so the calculated cost may',...
%                     'be sometimes very different from the expected. Try to execute this test again.',...
%                     ['J_calculated=' num2str(stErr.J)],'J_expected<7');
%                 error(msg);
%             end
%             
%             %en este ejemplo todas las clases estan "divinas"
%             try
%                 testCase.assertTrue(all(stErr.F1s>.9));
%                 testCase.assertTrue(all(stErr.R>.88));
%                 testCase.assertTrue(all(stErr.P>.9));
%             catch ME
%                 pattern='%s\n';
%                 formatSpec=repmat(pattern,1,5);
%                 msg=sprintf(formatSpec,'The NN algorithm isn�t so much stable, so the calculated indicators may',...
%                     'be sometimes very different from the expected. Try to execute this test again.',...
%                     ['F1s_calculated=' num2str(stErr.F1s) ', F1s_expected>0.9'],...
%                     ['Recall_calculated=' num2str(stErr.R) ', Recall_expected>0.88'],...
%                     ['Precision_calculated=' num2str(stErr.P) ', Precision_expected>0.90']);
%                 error(msg);
%             end
%             
%             % Making a prediction
%             [prediction,probability]=c.Predict(X);
%             testCase.assertEqual(size(y),size(probability));
%             testCase.assertEqual(size(y),size(prediction));
%             testCase.assertTrue(all(probability>=0) && all(probability<=1));
%             testCase.assertTrue(all(prediction>=1) && all(prediction<=10));
%             
%             %check using incorrect number of features
%             try
%                 n=size(X,2);
%                 X=X(:, n-1);
%                 [z1, p1]=c.Predict(X);
%             catch ME
%                 retMsg='ClassifierNN->feature number mismatch between Train and Predict: Classifier.Predict';
%                 testCase.assertEqual(ME.message, retMsg)
%             end
%             
%         end
        
        
        function testLearningCurve(testCase)
            % testLearningCurve plots UtilFunML.learningCurve's train/CV
            % error and per-class F1 vs sample count on a decimated
            % Coursera ex3data1 (digits) dataset
            %example form ex3.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN);
            
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
            
            lambda = 0.1;
            c.Set(char(ClassifierProps.lambda), lambda);
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
            % the mapFeature-expanded Coursera ex2data2 (microchip QA) dataset
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            X = mapFeature(X(:,1), X(:,2));
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p)+1; %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            
            lambda = 0.5;
            c.Set(char(ClassifierProps.lambda), lambda);
            hiddenSizes=[25];
            c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
            
            c.Set(char(ClassifierProps.normalize), true);
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
            % train/CV error vs lambda on the mapFeature-expanded
            % Coursera ex2data2 dataset
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            X = mapFeature(X(:,1), X(:,2));
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p)+1; %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            lambda = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3]';
            %lambda=linspace(0, 10, 100);
            hiddenSizes=[5 5];
            c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
            
            [error_train, error_val] = UtilFunML.validationCurve(c, lambda, Xt, yt, Xval, yval);
            figure; plot(lambda, [error_train.J], lambda, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Error');
            
        end
        
        
%         function testTrainChips(testCase)
%             %example form ex2.m of the ML course
%             
%             import OM4MClassLib.Util.*;
%             
%             fprintf('\n%s: ',Logging.WhoCalledMe());
%             
%             c=ClassifierFactory.Create(ClassifierTypes.NN);
%             
%             data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
%             X = data(:, [1, 2]); y = data(:, 3);
%             X = mapFeature(X(:,1), X(:,2));
%             y=y+1; %transform label (0,1) to (1,2)
%             
%             
%             hiddenSizes=[5 5];
%             c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
%             
%             lambda = .1;
%             c.Set(char(ClassifierProps.lambda), lambda);
%             
%             for i=1:10
%                 try
%                     c.Train(X,y);
%                     stErr = c.ErrorFunction(X, y);
%                     
%                     tol=2; % The calculated cost may be differ about 1% or 2% due to statistic fluctuations
%                     %             try
%                     %                 testCase.assertTrue(abs(stErr.J-(100-83.0508))<=tol);
%                     %             catch
%                     %                 pattern='%s\n';
%                     %                 formatSpec=repmat(pattern,1,4);
%                     %                 msg=sprintf(formatSpec,'The NN algorithm isn�t so much stable, so the calculated cost may',...
%                     %                     'be sometimes very different from the expected (test tolerance tol=2). Try to execute this test again.',...
%                     %                     ['J_calculated=' num2str(stErr.J)],['J_expected=' num2str(16.9492)]);
%                     %                 error(msg);
%                     %             end
%                     disp(stErr.F1s);
%                     testCase.assertTrue(all(stErr.F1s>.8));
%                     
%                     %first class has high precission lower recall, second class lower precision
%                     %high recall
%                     testCase.assertTrue(all(abs([stErr.P(1) stErr.R(1)] - [0.9000  0.75])<=tol));
%                     testCase.assertTrue(all(abs([stErr.P(2) stErr.R(2)] - [0.7794  0.9138])<=tol));
%                     
%                     break
%                 catch
%                     continue
%                 end
%             end
%         end
        
        
        function testLearningCurveLensesIOT(testCase)
            % testLearningCurveLensesIOT plots UtilFunML.learningCurve's
            % train/CV error and per-class F1/precision/recall vs sample
            % count on real lens QC features loaded via TrainingDataLoader
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            import Util.* OM4MClassLib.Util.*;
            
            import UtilQC.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN);
            
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr};
            LensType=EnumLens.Progressive;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            
            X=TDL.X;
            y=TDL.y;
            
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            X=X(1:5:end, :); y=y(1:5:end); %diezmamos datos
            m=size(X, 1);
            
            
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            lambda = 0.3;
            c.Set(char(ClassifierProps.lambda), lambda);
            hiddenSizes=[15 15];
            c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
            
            c.Set(char(ClassifierProps.normalize), true);
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
        
        
        function testValidationCurveIOTLenses(testCase)
            % testValidationCurveIOTLenses plots UtilFunML.validationCurve's
            % train/CV error vs lambda on real lens QC features loaded
            % via TrainingDataLoader
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            import Util.* OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN);
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr};
            LensType=EnumLens.Progressive;
            Eye=EnumEye.R;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            
            X=TDL.X;
            y=TDL.y;
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            c.Set(char(ClassifierProps.normalize),true);
            hiddenSizes=[5 5];
            c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
            lambda = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3 10]';
            %lambda=linspace(0, 10, 100);
            [error_train, error_val] = UtilFunML.validationCurve(c, lambda, Xt, yt, Xval, yval);
            figure; plot(lambda, [error_train.J], lambda, [error_val.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Error');
            
        end
        
        
        function testTrainSetChange(testCase)
            % testTrainSetChange checks a fresh ClassifierNN can be
            % trained on a differently-sized/shaped dataset than a prior
            % instance (2-feature, 1-class vs 3-class synthetic data)
            %two succesive calls to train must work even in tran set changes
            %dimmensiuons
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            
            l=[1,2,3];
            DC=0.3;
            X1=DC+0.3*randn(100, 2); y1=l(1)*ones(100, 1);
            X2=-DC+0.3*randn(100, 2); y2=l(2)*ones(100, 1);
            X3=0.0+0.3*randn(100, 2); y3=l(3)*ones(100, 1);
            
            X=[X1; X2; X3]; y=[y1; y2; y3];
            
            clr=ClassifierFactory.Create(ClassifierTypes.NN);
            clr.Train(X,y);
            
            %change train set and train again
            %we need to reset the object
            clr=ClassifierFactory.Create(ClassifierTypes.NN);
            X=[X1]; y=[y1];
            
            clr.Train(X,y);
            
        end
        
        
        function testTrainingex2data2PostProb(testCase)
            % testTrainingex2data2PostProb trains ClassifierNN on the raw
            % (unmapped) Coursera ex2data2 dataset and visually inspects
            % the predicted class and posterior probability over a grid
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            c=ClassifierFactory.Create(ClassifierTypes.NN);

            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            y=y+1;

            k1=(y==1);
            k2=(y==2);
            figure; plot(X(k1, 1), X(k1, 2), 'g+', X(k2, 1), X(k2, 2), 'ro');
            
            C = 0.1;
            c.Set(char(ClassifierProps.lambda), C);
            hiddenSizes=[5 5];
            c.Set(char(ClassifierProps.hiddenSizes), hiddenSizes);
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
            % testSaveAndLoad_ex2data2 trains on the raw Coursera
            % ex2data2 dataset, saves the classifier, loads it back (via
            % a differently-typed fresh classifier instance) and checks
            % predictions are unchanged.
            %  Note: saves to 'ClassifierNN_test.mat' but loads from
            % 'classifierNN_test' (different case) - only works on a
            % case-insensitive filesystem (e.g. Windows).
            %mtest testML_ClassifierNN:testSaveAndLoad_ex2data2
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.NN);
            
            data = load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex2data2.txt'));
            X = data(:, [1, 2]); y = data(:, 3);
            y=y+1;
            
            k1=(y==1);
            k2=(y==2);
            figure; plot(X(k1, 1), X(k1, 2), 'g+', X(k2, 1), X(k2, 2), 'ro');
            
            lambda=0.1;
            c.Set(char(ClassifierProps.lambda),lambda);
            % In the exercise, the number there's 1 hidden layer with 25 neurons
            hiddenSizes=[5 5];
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
            c.save(c,'ClassifierNN_test')
            clear c
            % Creating a new classifier
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            % Loading the saved data from the previous training. It doesn�t matter the
            % type of the created classifier, it can load any other type of classifiers
            c=c.load('classifierNN_test');
            
            [pred2,prb2]=c.Predict(X); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prob,prb2);
            
            delete('ClassifierNN_test.mat') % Delete the .mat file created for the test
            
        end
        
    end
    
end

