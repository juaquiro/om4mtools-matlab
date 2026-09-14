classdef testKMeansToolbox < matlab.unittest.TestCase
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
        
        function test1(testCase)
            % aqui se muestra la clasificacion con k-means en un caso facil con 2 y 4
            % clusters
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            %check toolbox version
            checkStats_Toolbox();
            
            % Load from ex6data2:
            % You will have X, y in your environment
            load('ex6data1.mat');
            
            figure; gscatter(X(:,1),X(:,2),y, 'gr','so');
            
            K=2;
            idx2=kmeans(X,K, 'display','iter', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx2, 'gr','so');
            
            K=4;
            idx4=kmeans(X,K, 'display','iter', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx4, 'grbk','sod^');
            
        end
        
        
        function test2(testCase)
            %en este ejemplo se muestra como localizar el numero optimo de clusters
            %mediante la inter cluster distance calculada mediante la funcion
            %silhouette
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            %check toolbox version
            checkStats_Toolbox();
            
            % Load from ex6data2:
            % You will have X, y in your environment
            load('ex6data1.mat');
            
            K=20;
            d=zeros(1, K);
            for k=1:K
                fprintf('ex6data1 =================================================\n');
                fprintf('K=%d \n', k);
                idx=kmeans(X,k, 'display','final', 'replicates',5);
                silh = silhouette(X,idx);
                d(k)=mean(silh);
            end
            figure; plot(1:K, d, '.-'); title('inter cluster distance');
            
            [~,K]=max(d);
            idx=kmeans(X,K, 'display','off', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx); title('optimun k-means clusters');
            
            load('ex7data2.mat');
            
            K=20;
            d=zeros(1, K);
            for k=1:K
                fprintf('ex7data2 =================================================\n');
                fprintf('K=%d \n', k);
                idx=kmeans(X,k, 'display','final', 'replicates',5);
                silh = silhouette(X,idx);
                d(k)=mean(silh);
            end
            
            figure; plot(1:K, d, '.-'); title('inter cluster distance');
            [~,K]=max(d);
            idx=kmeans(X,K, 'display','off', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx); title('optimun k-means clusters');
            
            
            
            mu1 = [3 4];
            sigma1 = 55*[.3 0; 0 .2];
            mu2 = [-4 -4];
            sigma2 = 55*[.2 0; 0 .1];
            mu3 = [5 -6];
            sigma3 = 55*[.3 0; 0 .2];
            mu4 = [-6 7];
            sigma4 = 55*[.2 0; 0 .1];
            
            
            X = [mvnrnd(mu1,sigma1,200);mvnrnd(mu2,sigma2,100);mvnrnd(mu3,sigma3,200);mvnrnd(mu4,sigma4,100)];
            
            K=20;
            d=zeros(1, K);
            for k=1:K
                fprintf('4 gaussians =================================================\n');
                fprintf('K=%d \n', k);
                idx=kmeans(X,k, 'display','final', 'replicates',5);
                silh = silhouette(X,idx);
                d(k)=mean(silh);
            end
            figure; plot(1:K, d, '.-'); title('inter cluster distance');
            
            [~,K]=max(d);
            idx=kmeans(X,K, 'display','off', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx); title('optimun k-means clusters');
            
            
            
            
        end
        
        
        function test3(testCase)
            
            import OM4MClassLib.Util.*;
            
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            %check toolbox version
            checkStats_Toolbox();
            
            %  Load an image of a bird
            A = double(imresize(imread('bird_small.png'), [64,64]));
            %A=double(imread('peppers.png'));
            
            % If imread does not work for you, you can try instead
            %   load ('bird_small.mat');
            
            A = A / 255; % Divide by 255 so that all values are in the range 0 - 1
            
            % Size of the image
            img_size = size(A);
            
            % Reshape the image into an Nx3 matrix where N = number of pixels.
            % Each row will contain the Red, Green and Blue pixel values
            % This gives us our dataset matrix X that we will use K-Means on.
            X = reshape(A, img_size(1) * img_size(2), 3);
            
            K=20;
            d=zeros(1, K);
            for k=1:K
                fprintf('=================================================\n');
                fprintf('K=%d \n', k);
                idx=kmeans(X,k, 'display','final', 'replicates',5);
                silh = silhouette(X,idx);
                d(k)=mean(silh);
            end
            figure; plot(1:K, d, '.-'); title('inter cluster distance');
            
            [~,K]=max(d);
            idx=kmeans(X,K, 'display','off', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx); title('R, G optimun k-means clusters');
            figure; gscatter(X(:,2),X(:,3),idx); title('G, B optimun k-means clusters');
            
        end
        
        
        function test4(testCase)
            %here we combine a unsupervised learning method, kmeans with a supervised
            %clasifier SVM %to predict the class of a sample and its posterior prob
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
            
            K=20;
            d=zeros(1, K);
            for k=1:K
                fprintf('4 gaussians =================================================\n');
                fprintf('K=%d \n', k);
                idx=kmeans(X,k, 'display','final', 'replicates',5);
                silh = silhouette(X,idx);
                d(k)=mean(silh);
            end
            figure; plot(1:K, d, '.-'); title('inter cluster distance');
            
            [~,K]=max(d);
            idx=kmeans(X,K, 'display','off', 'replicates',5);
            figure; gscatter(X(:,1),X(:,2),idx); title('optimun k-means clusters');
            
            c=ClassifierFactory.Create(ClassifierTypes.SVM);
            C = .10;
            sigma=1;
            c.Set(char(ClassifierProps.lambda), C);
            c.Set(char(ClassifierProps.sigma), sigma);
            c.Set(char(ClassifierProps.showplot), true);
            j=enumeration('ClassifierProps');
            cnpFlag=true;
            y=idx;
            c.Set(char(ClassifierProps.normalize), false);
            figure; c.Train(X,y); figure(gcf);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            X=[X1(:), X2(:)];
            [z,p]=c.Predict(X);
            figure; gscatter(X(:,1),X(:,2),p); title('class');
            figure; pcolor(X1, X2, reshape(z, N2,N1)); title('Posterior probability');
            
            
        end
        
        
        function test5(testCase)
            %here we combine a unsupervised learning method (kmeans) with a supervised
            %clasifier (bayes gauss) to predict the class of a sample
            %here use the output of the kmeans to train a bayes-gauss classifier, to
            %compute the posterior probs we fit the bayesgauss decission function with
            %a LogR classifier as in testSVM_Toolbox:testMulticlass
            
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
            
            K=4;
            [idx, ctrs]=kmeans(X,K, 'display','final', 'replicates',5);
            
            C=cell(1,4);
            M=cell(1,4);
            
            for k=1:K
                [C{k}, M{k}]=covmatrix(X(idx==k, :));
            end
            
            
            CA=[];
            MA=[];
            for k=1:K
                CA=cat(3,CA, C{k});
                MA=cat(2,MA, M{k});
            end
            
            figure; gscatter(X(:,1),X(:,2),idx); title('optimun k-means clusters');
            hold on; plot(ctrs(:,1),ctrs(:,2),'kx', 'MarkerSize',12,'LineWidth',2); hold off;
            hold on; plot(MA(1,:),MA(2,:),'ro', 'MarkerSize',12,'LineWidth',2); hold off;
            
            [p, D] = bayesgauss(X, CA, MA);
            figure; gscatter(X(:,1),X(:,2),p); title('bayes gauss classification');
            hold on; plot(MA(1,:),MA(2,:),'ro', 'MarkerSize',12,'LineWidth',2); hold off;
            
            %aqui ajustamos un LR a la salida del SVM
            clr=ClassifierFactory.Create(ClassifierTypes.LogR);
            clr.Set(char(ClassifierProps.lambda), 1);
            Xlr=D;
            ylr=p;
            clr.Train(Xlr,ylr);
            
            N1=100;
            N2=101;
            [X1, X2]=meshgrid(linspace(min(X(:, 1)), max(X(:, 1)), N1), linspace(min(X(:, 2)), max(X(:, 2)), N2));
            
            Xlr=[X1(:), X2(:)];
            [~, Dlr] = bayesgauss(Xlr, CA, MA);
            [zlr,plr]=clr.Predict(Dlr);
            figure; gscatter(Xlr(:,1),Xlr(:,2),plr); title('LR prediction class');
            hold; gscatter(X(:,1),X(:,2),p, 'brgk','xo^+');hold off;
            figure; pcolor(X1, X2, reshape(zlr, N2,N1)); title('LR Posterior probability');
            
        end
        
        
        
    end
    
end

