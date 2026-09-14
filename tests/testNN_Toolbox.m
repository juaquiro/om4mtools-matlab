classdef testNN_Toolbox < matlab.unittest.TestCase
    %run(testNN_Toolbox)
    %test the NN toolbox

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
        function testNN_Toolbox_CrabCassification(testCase)
            %run(testNN_Toolbox, 'testNN_Toolbox_CrabCassification')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %load crab data, ym is the matrix form of the numerical labels in
            %(clases)x(samples)
            %X is the feature matrix in (fearures)x(samples)
            %The MATLAB NN toolbox usa las mismas matrices que el curso de ML pero
            %traspuestas
            [X,ym] = crab_dataset;

            %single hidden later of 10 neurons
            net = patternnet(10);

            %train the net
            [net,tr] = train(net,X,ym);

            %check the net
            Xt = X(:,tr.testInd);
            ymt = ym(:,tr.testInd);

            pmt=net(Xt);
            pm=net(X);

            %para pasar de labels en matrix form a vector form usamos yv=vec2ind(ym); para pasar de vector form a matrix forms
            %usamos ym=full(ind2vec(yv))
            y=vec2ind(ym);
            p=vec2ind(pm);

            yt=vec2ind(ymt);
            pt=vec2ind(pmt);

            %miramos la accuracy del train set
            acc=UtilFunML.Accuracy(y,p); %#ok<NASGU>
            [F1s, P, R]=UtilFunML.Fscore(y,p); %#ok<NASGU,ASGLU>

            %miramos la accuracy del test set
            acct=UtilFunML.Accuracy(yt,pt); %#ok<NASGU>
            [F1st, Pt, Rt]=UtilFunML.Fscore(yt,pt); %#ok<NASGU,ASGLU>
        end

        function testNN_Toolbox_ChipCassification(testCase)
            %run(testNN_Toolbox, 'testNN_Toolbox_ChipCassification')
            %example form ex2.m of the ML course
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

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

            %single hidden later of 10 neurons
            net = patternnet(10);

            %train the net
            %hay que trasponer Xt y convertir a matrix form las etiquetas vector-form yt
            [net,tr] = train(net,Xt',full(ind2vec(yt'))); %#ok<NASGU>

            % hacemos una prediccion para lo cual hay que trasponer X
            pmt=net(Xt');
            pmval=net(Xval');

            %para pasar de labels en matrix form a vector form usamos yv=vec2ind(ym); para pasar de vector form a matrix forms
            %usamos ym=full(ind2vec(yv))
            %hay que trasponer de vuelta para dejar el formato de ML (samples)x1
            pt=vec2ind(pmt); pt=pt';
            pval=vec2ind(pmval); pval=pval';

            %miramos la accuracy del train set
            acct=UtilFunML.Accuracy(yt,pt); %#ok<NASGU>
            [F1st, Pt, Rt]=UtilFunML.Fscore(yt,pt); %#ok<NASGU,ASGLU>

            %miramos la accuracy del xval set
            accval=UtilFunML.Accuracy(yval,pval); %#ok<NASGU>
            [F1sval, Pval, Rval]=UtilFunML.Fscore(yval,pval); %#ok<NASGU,ASGLU>
        end

        function testNN_Toolbox_DigitsCassification(testCase)
            %run(testNN_Toolbox, 'testNN_Toolbox_DigitsCassification')
            %example form ex3.m of the ML course
            import OM4MClassLib.Util.* Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            load('ex3data1.mat'); % training data stored in arrays X, y

            m=size(X, 1);
            p=randperm(m);
            X=X(p, :); y=y(p); %desordenamos, y cambiamos (0,1) a (1,2) pq lo necesita el classifier

            m=size(X, 1);
            N=round(0.8*m);
            Xt=X(1:N, :); %test set
            yt=y(1:N, :);
            Xval=X(N+1:end, :); %cross validation set
            yval=y(N+1:end, :);

            %2x hidden later of 10 neurons
            net = patternnet([5 5]);

            % para el tem,a de regularizacion ver
            % Neural Network Toolbox\User's Guide\Advanced Topics\Improving Generalization\Regularization
            %mse reg with lambda=0.9
            net.performFcn='msereg';
            lambda=0.5;
            if verLessThan('nnet', '8.0.1')
                net.performParam.ratio=1-lambda;
            else
                net.performParam.regularization=1-lambda;
            end

            %train the net
            %hay que trasponer Xt y convertir a matrix form las etiquetas vector-form yt
            [net,tr] = train(net,Xt',full(ind2vec(yt'))); %#ok<NASGU>

            % hacemos una prediccion para lo cual hay que trasponer X
            pmt=net(Xt');
            pmval=net(Xval');

            %para pasar de labels en matrix form a vector form usamos yv=vec2ind(ym); para pasar de vector form a matrix forms
            %usamos ym=full(ind2vec(yv))
            %hay que trasponer de vuelta para dejar el formato de ML (samples)x1
            pt=vec2ind(pmt); pt=pt';
            pval=vec2ind(pmval); pval=pval';

            %miramos la accuracy del train set
            acct=UtilFunML.Accuracy(yt,pt); %#ok<NASGU>
            [F1st, Pt, Rt]=UtilFunML.Fscore(yt,pt); %#ok<NASGU,ASGLU>

            %miramos la accuracy del xval set
            accval=UtilFunML.Accuracy(yval,pval); %#ok<NASGU>
            [F1sval, Pval, Rval]=UtilFunML.Fscore(yval,pval); %#ok<NASGU,ASGLU>
        end

        function testNN_Toolbox_LensesIOTCassification(testCase)
            %run(testNN_Toolbox, 'testNN_Toolbox_LensesIOTCassification')
            import OM4MClassLib.Util.*;
            import Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

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
            %pasamos a matrix form
            ym=full(ind2vec(y')); ym=ym';

            %2x hidden later of 10 neurons
            net = patternnet([10 10]);

            %train the net
            %hay que trasponer X y las etiquetas vector-form ym
            [net,tr] = train(net,X',ym'); %#ok<NASGU>

            % hacemos una prediccion para lo cual hay que trasponer X
            pm=net(X');

            %para pasar de labels en matrix form a vector form usamos yv=vec2ind(ym); para pasar de vector form a matrix forms
            %usamos ym=full(ind2vec(yv))
            %hay que trasponer de vuelta para dejar el formato de ML (samples)x1
            p=vec2ind(pm); p=p';

            %miramos la accuracy del train set
            acc=UtilFunML.Accuracy(y,p); %#ok<NASGU>
            [F1s, P, R]=UtilFunML.Fscore(y,p); %#ok<NASGU,ASGLU>
        end
    end
end
