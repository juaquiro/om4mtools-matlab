classdef testMLClassifierLR < matlab.unittest.TestCase
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
            
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
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
                retMsg=['ClassifierLR->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end
            
            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);
            
            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
        end
        
        
%         function testTrainDigits(testCase)
%             %example form ex3.m of the ML course
%             %mtest testML_ClassifierLR:testTrainDigits
%             
%             import OM4MClassLib.Util.*;
%             
%             fprintf('\n%s: ',Logging.WhoCalledMe());
%             
%             c=ClassifierFactory.Create(ClassifierTypes.LogR);
%             
%             load('ex3data1.mat'); % training data stored in arrays X, y
%             
%             lambda = 1e-1;
%             c.Set(char(ClassifierProps.lambda), lambda);
%             c.Set(char(ClassifierProps.normalize), false);
%             c.Train(X,y);
%             stErr = c.ErrorFunction(X, y);
%             
%             tol=2e-1;
%             testCase.assertTrue(abs(5-stErr.J)<tol);
%             
%             %en este ejemplo todas las clases estan "divinas"
%             testCase.assertTrue(all(stErr.F1s>.9));
%             testCase.assertTrue(all(stErr.R>.9));
%             testCase.assertTrue(all(stErr.P>.9));
%             
%             % prediction and probability
%             [pred,prb]=c.Predict(X);
%             predicted_class=pred;
%             probability=prb;
%             n=size(y);
%             
%             testCase.assertEqual(size(predicted_class),n);
%             testCase.assertEqual(size(probability),n);
%             
%             % Training Set Accuracy
%             t_accuracy=UtilFunML.Accuracy(y,predicted_class);
%             testCase.assertTrue(abs(t_accuracy-94.9)<=1e-1); % Training Set Accuracy: 95.06
%             
%             
%             %check using incorrect number of features
%             try
%                 n=size(X,2);
%                 X=X(:, n-1);
%                 [z1, p1]=c.Predict(X);
%             catch ME
%                 retMsg='ClassifierLR->feature number mismatch between Train and Predict: Classifier.Predict';
%                 testCase.assertEqual(ME.message, retMsg)
%             end
%             
%         end
        
        
        function testLearningCurve(testCase)
            %example form ex3.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            load('ex3data1.mat'); % training data stored in arrays X, y
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos
            X=X(1:70:end, :); y=y(1:70:end); %diezmamos datos
            
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
            
            lambda = 1;
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
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load('ex2data2.txt');
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
            
            
            lambda = 3;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize), true);
            [error_train5, error_val5] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train5.J], 1:N, [error_val5.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train5.F1s];
                val_F1s=[error_val5.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
                
                train_P=[error_train5.P];
                val_P=[error_val5.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n)]);
                
                
                train_R=[error_train5.R];
                val_R=[error_val5.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n)]);
                
            end
            
        end
        
        
        function testLearningCurveDecimatingSamples(testCase)
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load('ex2data2.txt');
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
            
            
            lambda = 30;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize), true);
            [error_train5, error_val5] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval); %default value decimetion =5
            [error_train2, error_val2] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval, 2); %decimation = 2 samples
            
            %Decimation 5 samples
            figure; plot(1:N, [error_train5.J], 1:N, [error_val5.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            strTitle=' Decimation 5 samples';
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train5.F1s];
                val_F1s=[error_val5.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n) strTitle]);
                
                train_P=[error_train5.P];
                val_P=[error_val5.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n) strTitle]);
                
                
                train_R=[error_train5.R];
                val_R=[error_val5.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n) strTitle]);
                
            end
            
            %decimation 2 samples
            figure; plot(1:N, [error_train2.J], 1:N, [error_val2.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            strTitle=' Decimation 2 samples';
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train2.F1s];
                val_F1s=[error_val2.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n) strTitle]);
                
                train_P=[error_train2.P];
                val_P=[error_val2.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n) strTitle]);
                
                
                train_R=[error_train2.R];
                val_R=[error_val2.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n) strTitle]);
                
            end
            
            
            
        end
        
        
        function testValidationCurve2(testCase)
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load('ex2data2.txt');
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
            
            lambda = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3 10]';
            %lambda=linspace(0, 10, 100);
            [error_train5, error_val5] = UtilFunML.validationCurve(c, lambda, Xt, yt, Xval, yval);
            figure; plot(lambda, [error_train5.J], lambda, [error_val5.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Error');
            
        end
        

        function testTrainChips(testCase)
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load('ex2data2.txt');
            X = data(:, [1, 2]); y = data(:, 3);
            X = mapFeature(X(:,1), X(:,2));
            y=y+1; %transform label (0,1) to (1,2)
            
            lambda = 1;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Train(X,y);
            stErr = c.ErrorFunction(X, y);
            
            tol=1e-1;
            testCase.assertTrue((stErr.J-(100-83.0508)) <= tol);
            testCase.assertTrue(all(stErr.F1s>.8));
            
            %first class has high precission lower recall, second class lower precision
            %high recall
            testCase.assertTrue(all(abs([stErr.P(1) stErr.R(1)]-[0.9000  0.75])<=tol));
            testCase.assertTrue(all(abs([stErr.P(2) stErr.R(2)]-[0.7794  0.9138])<=tol));
            
        end
        
        
        function testTrainingex2data2PostProb(testCase)
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load('ex2data2.txt');
            X = data(:, [1, 2]); y = data(:, 3);
            Xmf = mapFeature(X(:,1), X(:,2));
            y=y+1;
            
            k1=(y==1);
            k2=(y==2);
            figure; plot(X(k1, 1), X(k1, 2), 'g+', X(k2, 1), X(k2, 2), 'ro');
            
            lambda = 0.01;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Train(Xmf,y);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            X=[X1(:), X2(:)];
            Xmf = mapFeature(X(:,1), X(:,2));
            
            [z,p]=c.Predict(Xmf);
            figure; pcolor(X1, X2, reshape(p, N2,N1));
            figure; pcolor(X1, X2, reshape(z, N2,N1));
            
        end
        
        
        function testLearningCurveLensesIOT(testCase)
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            import Util.* OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr, EnumFeatureNames.TrThetaRot};
            LensType=EnumLens.Progressive;
            Eye=EnumEye.R;
            
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
            
            
            lambda = 0.1;
            c.Set(char(ClassifierProps.lambda), lambda);
            c.Set(char(ClassifierProps.normalize), true);
            [error_train5, error_val5] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train5.J], 1:N, [error_val5.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train5.F1s];
                val_F1s=[error_val5.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
                
                train_P=[error_train5.P];
                val_P=[error_val5.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n)]);
                
                
                train_R=[error_train5.R];
                val_R=[error_val5.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n)]);
                
            end
        end
        
        
        function testLearningCurveLensesIOTWPolFeats(testCase)
            %example form ex2.m of the ML course
            %mtest testML_ClassifierLR:testLearningCurveLensesIOTWPolFeats
            
            
            import OM4MClassLib.Util.*;
            import Util.* OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr};
            LensType=EnumLens.Progressive;
            Eye=EnumEye.R;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            
            X=TDL.X;
            y=TDL.y;
            
            p=(y==1); %anomalous
            y=y(not(p))-1; %exclude anomalous
            X=X(not(p), :);
            
            
            
            
            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier
            
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);
            
            
            lambda = 1;
            c.Set(char(ClassifierProps.lambda), lambda);
            p=4;
            c.Set(char(ClassifierProps.p), p);
            
            c.Set(char(ClassifierProps.normalize), true);
            [error_train5, error_val5] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train5.J], 1:N, [error_val5.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train5.F1s];
                val_F1s=[error_val5.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
                
                train_P=[error_train5.P];
                val_P=[error_val5.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n)]);
                
                
                train_R=[error_train5.R];
                val_R=[error_val5.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n)]);
                
            end
        end
        
        
        function testValidationCurveIOTLenses(testCase)
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            import Util.* OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr, EnumFeatureNames.TrThetaRot};
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
            
            lambda = [0 1e-6 3e-6 1e-5 3e-5 1e-4 3e-4 0.001 0.003 0.01 0.03 0.1 0.3 1 3 10]';
            %lambda=linspace(0, 10, 100);
            [error_train5, error_val5] = UtilFunML.validationCurve(c, lambda, Xt, yt, Xval, yval);
            figure; plot(lambda, [error_train5.J], lambda, [error_val5.J], '.-');
            legend('Train', 'Cross Validation'); xlabel('lambda'); ylabel('Error');
            
        end
        
        
        function testLearningCurve2WithPolFeat(testCase)
            %example form ex2.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            data = load('ex2data2.txt');
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
            
            
            lambda = 3;
            c.Set(char(ClassifierProps.lambda), lambda);
            p=7;
            c.Set(char(ClassifierProps.p), p);
            
            c.Set(char(ClassifierProps.normalize), true);
            [error_train5, error_val5] = UtilFunML.learningCurve(c, Xt, yt, Xval, yval);
            figure; plot(1:N, [error_train5.J], 1:N, [error_val5.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
            
            k=length(unique(yt)); %number of classes
            for n=1:k
                train_F1s=[error_train5.F1s];
                val_F1s=[error_val5.F1s];
                
                figure; plot(1:N, train_F1s(n, :), '.-', 1:N, val_F1s(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('F1s');
                title(['class: ' num2str(n)]);
                
                train_P=[error_train5.P];
                val_P=[error_val5.P];
                figure; plot(1:N, train_P(n, :), '.-', 1:N, val_P(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Precission');
                title(['class: ' num2str(n)]);
                
                
                train_R=[error_train5.R];
                val_R=[error_val5.R];
                figure; plot(1:N, train_R(n, :), '.-', 1:N, val_R(n,:), '.-');
                legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Recall');
                title(['class: ' num2str(n)]);
                
            end
        end
        
        
        % Create and train a ClassifierLR, then save it to a .mat file, load this
        % file and obtain and make a prediction
        function testSaveAndLoad(testCase)
            %example form ex3.m of the ML course
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            c=ClassifierFactory.Create(ClassifierTypes.LogR);
            
            load('ex3data1.mat'); % training data stored in arrays X, y
            
            lambda = 1e-1;
            c.Set(char(ClassifierProps.lambda), lambda);
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
            c.save(c,'ClassifierLR_test')
            clear c;
            
            % Loading the saved data from the previous training. It doesn�t matter the
            % type of the created classifier, it can load any other type of classifiers
            c=Classifier.load('classifierLR_test');
            
            testCase.assertTrue(isa(c, 'Classifier'));
            
            [pred2,prb2]=c.Predict(X); % Predicition and probability after loading classifier c
            testCase.assertEqual(pred,pred2);
            testCase.assertEqual(prb,prb2);
            
            delete('ClassifierLR_test.mat') % Delete the .mat file created for the test
        end
    end
    
end

