classdef testMLClassifierKmeansCluster < matlab.unittest.TestCase
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
            
            c=ClassifierFactory.Create(ClassifierTypes.KmeansCluster);
            
            %this is not a supervised classifier
            testCase.assertFalse(c.isSupervised);
            
            %this is not a regression
            testCase.assertFalse(c.isRegression);
            
            %default supervised classifier
            t=c.Get(char(ClassifierProps.svcType));
            testCase.assertEqual(t, ClassifierTypes.SVM);
            
            %check default value for featureType
            ft=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft, aFeatureTypes.Unknown);
            
            %check seting incorrect value for featureType
            try
                ft=1;
                c.Set(char(ClassifierProps.featureType), ft);
            catch ME
                retMsg=['ClassifierKmeansCluster->featureType must be of type aFeatureTypes: <<' char(ft) '>>, Classifier.Set' ];
                testCase.assertEqual(ME.message, retMsg)
            end
            
            %check setting featureType
            ft=aFeatureTypes.FeatureTest;
            c.Set(char(ClassifierProps.featureType), ft);
            
            ft1=c.Get(char(ClassifierProps.featureType));
            testCase.assertEqual(ft1, ft);
            
        end
       
        
        function testTrain4Gaussians(testCase)
            %unsupervised clustering of 4 gaussians
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            mu1 = [4 5];
            sigma1 = 25*[.3 0; 0 .2];
            mu2 = [-4 -5];
            sigma2 = 25*[.2 0; 0 .1];
            mu3 = [4 -5];
            sigma3 = 25*[.3 0; 0 .2];
            mu4 = [-4 5];
            sigma4 = 25*[.2 0; 0 .1];
            
            
            X = [mvnrnd(mu1,sigma1,200);mvnrnd(mu2,sigma2,100);mvnrnd(mu3,sigma3,200);mvnrnd(mu4,sigma4,100)];
            
            %we start using the default params
            c=ClassifierFactory.Create(ClassifierTypes.KmeansCluster);
            K=4;
            c.Set(char(ClassifierProps.svcType), ClassifierTypes.LogR);
            c.Train(X,K);
            [z, p]=c.Predict(X);
            stErr = c.ErrorFunction(X, z);
            
            %if we compute the error of the prediction is 0 and all Fis, P and R are 1
            %because we are using a unsupervised clustring method
            %for unsupervised learning the clasical learning curve has no much sens
            testCase.assertTrue(stErr.J==0);
            testCase.assertTrue(all(stErr.F1s==1));
            testCase.assertTrue(all(stErr.P==1));
            testCase.assertTrue(all(stErr.R==1));
            
            
            
            N1=30;
            N2=31;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            Xp=[X1(:), X2(:)];
            [z, p]=c.Predict(Xp);
            figure; gscatter(X1(:),X2(:),z);title('class');
            figure; pcolor(X1, X2, reshape(p, N2,N1)); title('Posterior probability');
            
            %change the supervised classifier used to train with the clusters
            c.Set(char(ClassifierProps.svcType), ClassifierTypes.SVM);
            C = .10;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.normalize), true);
            c.Set(char(ClassifierProps.showplot), true);
            
            c.Train(X,K);
            [z, p]=c.Predict(Xp);
            
            figure; gscatter(X1(:),X2(:),z); title('class');
            figure; pcolor(X1, X2, reshape(p, N2,N1)); title('Posterior probability');
            
            
            
            %check using incorrect number of features
            try
                n=size(Xp,2);
                Xp=Xp(:, n-1);
                [z1, p1]=c.Predict(Xp);
            catch ME
                retMsg='ClassifierKmeansCluster->feature number mismatch between Train and Predict: Classifier.Predict';
                testCase.assertEqual(ME.message, retMsg)
            end
            
            
        end
        
        
        function testMeanInterClusterDistance(testCase)
            %unsupervised clustering of 4 gaussians
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            mu1 = [4 5];
            sigma1 = 25*[.3 0; 0 .2];
            mu2 = [-4 -5];
            sigma2 = 25*[.2 0; 0 .1];
            mu3 = [4 -5];
            sigma3 = 25*[.3 0; 0 .2];
            mu4 = [-4 5];
            sigma4 = 25*[.2 0; 0 .1];
            
            
            X = [mvnrnd(mu1,sigma1,200);mvnrnd(mu2,sigma2,100);mvnrnd(mu3,sigma3,200);mvnrnd(mu4,sigma4,100)];
            
            %we start using the default params
            c=ClassifierFactory.Create(ClassifierTypes.KmeansCluster);
            Kmax=20;
            [d, K] = UtilFunML.NICDCurve(c, X, Kmax);
            figure; plot(1:Kmax, d, '.-'); title('inter cluster distance');
            
        end
        
        
        function testTrainex6data2(testCase)
            %ex6data2
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Load from ex6data2:
            % You will have X, y in your environment
            load(fullfile(fixturesRoot(), 'CourseraMLData', 'ex6data1.mat'));
            
            %we start using the default params
            c=ClassifierFactory.Create(ClassifierTypes.KmeansCluster);
            K=2;
            c.Train(X,K);
            
            N1=30;
            N2=31;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            Xp=[X1(:), X2(:)];
            [z,p]=c.Predict(Xp);
            figure; gscatter(X1(:),X2(:),z);title('class');
            figure; pcolor(X1, X2, reshape(p, N2,N1)); title('Posterior probability');
            
            %change the supervised classifier used to train with the clusters
            c.Set(char(ClassifierProps.svcType), ClassifierTypes.SVM);
            C = .10;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.normalize), true);
            c.Set(char(ClassifierProps.showplot), true);
            
            c.Train(X,K);
            
            [z,p]=c.Predict(Xp);
            figure; gscatter(X1(:),X2(:),z); title('class');
            figure; pcolor(X1, X2, reshape(p, N2,N1)); title('Posterior probability');
            
            
            
            
        end
        
        
    end
    
end

