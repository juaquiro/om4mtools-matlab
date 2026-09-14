classdef testSVM_Toolbox < matlab.unittest.TestCase
    %run(testSVM_Toolbox)
    %test the SVG clasiffier of the stats toolbox
    %
    % The correspondence between the model in the ML course and the SVMstruct
    % in the SVM toiolbox
    % idx = SVMstruct.SupportVectorIndices;
    % model.X= X(idx,:);
    % model.y= y(idx);
    % model.kernelFunction = SVMstruct.KernelFunction;
    % model.b= SVMstruct.Bias;
    % model.alphas= SVMstruct.Alpha;
    % model.w = ((SVMstruct.Alpha.*model.y)'*model.X)';
    %visualizeBoundary(X, y, SVMstruct);
    %
    %NOTE: svmtrain/svmclassify were removed from MATLAB around R2016b -
    %every test here will error on undefined function in R2024b. This is
    %the same known/tracked gap as ClassifierSVM (see DECISIONS.md /
    %TODO.md Fase 4: svmtrain -> fitcsvm modernization), not something new.

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
        function testLinearKernelSet1(testCase)
            %run(testSVM_Toolbox, 'testLinearKernelSet1')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %check toolbox version
            checkSVM_Toolbox();

            % Load from ex6data2:
            % You will have X, y in your environment
            load('ex6data1.mat');

            % Plot training data
            figure; plotData(X, y);

            %the smaller is C the bigger is the regularization and the more support
            %vectors. The bigger is C less generalization and less suport vectors

            % linear kernel C=1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            KF='linear';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C);
            title(['kernel fun: ' KF '; C:' num2str(C)]);
            %si queremos el svmclassify tb puede llevar un 'showplot',true para mostrar
            %la lcasificacion de las nuevas muestras
            p=svmclassify(SVMstruct,X);

            acc=UtilFunML.Accuracy(y,p);
            tol=1e-4;
            acc_ac=98.0392;
            testCase.assertTrue(abs(acc-acc_ac)<=tol);

            [F1s, P, R]=UtilFunML.Fscore(y,p);
            testCase.assertTrue(abs(F1s(1)-0.9756)<=tol);
            testCase.assertTrue(abs(P(1)-1)<=tol);
            testCase.assertTrue(abs(R(1)-0.9524)<=tol);

            % linear kernel C=1e-2
            figure;
            C=1e-2; %this is the regularization parameter, called 'boxconstraint'
            KF='linear';
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C); %#ok<NASGU>
            title(['kernel fun: ' KF '; C:' num2str(C)]);

            % linear kernel C=1e2
            figure;
            C=1e2; %this is the regularization parameter, called 'boxconstraint'
            KF='linear';
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C); %#ok<NASGU>
            title(['kernel fun: ' KF '; C:' num2str(C) ]);
        end


        function testRBFKernelSet1(testCase)
            %run(testSVM_Toolbox, 'testRBFKernelSet1')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %check toolbox version
            checkSVM_Toolbox();

            % Load from ex6data2:
            % You will have X, y in your environment
            load('ex6data1.mat');

            % Plot training data
            figure; plotData(X, y);

            %sigma controls the spatial variation of the hypersurface, less sigma,
            %bigger spatial variation

            % rbf kernel sigma=1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            sigma=10;
            KF='rbf';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma);
            title(['kernel fun: ' KF '; C:' num2str(C) '; sigma:' num2str(sigma)]);
            %si queremos el svmclassify tb puede llevar un 'showplot',true para mostrar
            %la lcasificacion de las nuevas muestras
            p=svmclassify(SVMstruct,X);

            acc=UtilFunML.Accuracy(y,p);
            tol=1e-4;
            acc_ac=98.0392;
            testCase.assertTrue(abs(acc-acc_ac)<=tol);

            [F1s, P, R]=UtilFunML.Fscore(y,p);
            testCase.assertTrue(abs(F1s(1)-0.9756)<=tol);
            testCase.assertTrue(abs(P(1)-1)<=tol);
            testCase.assertTrue(abs(R(1)-0.9524)<=tol);

            % rbf kernel sigma=1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            sigma=1;
            KF='rbf';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma); %#ok<NASGU>
            title(['kernel fun: ' KF '; C:' num2str(C) '; sigma:' num2str(sigma)]);

            % rbf kernel sigma=1e-1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            sigma=1e-1;
            KF='rbf';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma); %#ok<NASGU>
            title(['kernel fun: ' KF '; C:' num2str(C) '; sigma:' num2str(sigma)]);
        end


        function testRBFKernelSet2(testCase)
            %run(testSVM_Toolbox, 'testRBFKernelSet2')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %check toolbox version
            checkSVM_Toolbox();

            % Load from ex6data2:
            % You will have X, y in your environment
            load('ex6data2.mat');

            % Plot training data
            figure; plotData(X, y);

            %sigma controls the spatial variation of the hypersurface, less sigma,
            %bigger spatial variation

            % rbf kernel sigma=1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            sigma=10;
            KF='rbf';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma);
            title(['kernel fun: ' KF '; C:' num2str(C) '; sigma:' num2str(sigma)]);
            p=svmclassify(SVMstruct,X); %#ok<NASGU>

            % acc=UtilFunML.Accuracy(y,p);
            % tol=1e-4;
            % acc_ac=98.0392;
            % assertTrue(abs(acc-acc_ac)<=tol);
            %
            % [F1s, P, R]=UtilFunML.Fscore(y,p);
            % assertTrue(abs(F1s(1)-0.9756)<=tol);
            % assertTrue(abs(P(1)-1)<=tol);
            % assertTrue(abs(R(1)-0.9524)<=tol);

            % rbf kernel sigma=1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            sigma=1;
            KF='rbf';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma); %#ok<NASGU>
            title(['kernel fun: ' KF '; C:' num2str(C) '; sigma:' num2str(sigma)]);

            % rbf kernel sigma=1e-1
            C=1; %this is the regularization parameter, called 'boxconstraint'
            sigma=3e-1;
            KF='rbf';
            figure;
            SVMstruct = svmtrain(X,y,'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma); %#ok<NASGU>
            title(['kernel fun: ' KF '; C:' num2str(C) '; sigma:' num2str(sigma)]);
        end

        function testMulticlass(testCase)
            %run(testSVM_Toolbox, 'testMulticlass')
            %svm train no hace clasificacion multiple hay que hacerlo one-vs-all
            %para calcular la funcion de decision para cada muestra usamos la funcion
            %privada de la toolboox svmdecision renombrada svmdecisionIOTQC
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %check toolbox version
            checkSVM_Toolbox();

            l=[1,2,3];
            DC=0.3;
            X1=DC+0.3*randn(100, 2); y1=l(1)*ones(100, 1);
            X2=-DC+0.3*randn(100, 2); y2=l(2)*ones(100, 1);
            X3=0.0+0.3*randn(100, 2); y3=l(3)*ones(100, 1);

            X=[X1; X2; X3]; y=[y1; y2; y3];

            % clasificamos clase 1 vs all
            C=1;
            KF='rbf';
            %KF='linear';
            % KF='mlp';
            % KF='quadratic';
            sigma=0.1;

            %este lo vamos ancesitar para poder estimar la posterior probability a
            %partir de la salida del SVM
            clr=ClassifierFactory.Create(ClassifierTypes.SVM);
            clr.Set(char(ClassifierProps.lambda), 0.1);
            f=zeros(length(y), length(l));
            zlr=f;
            % clasificamos clase 1 vs all
            % entrenamos SVM para cada clase
            for k=1:length(l)
                figure;
                SVMstruct = svmtrain(X,y==l(k),'Kernel_Function',KF, 'showplot',true, 'boxconstraint', C, 'rbf_sigma', sigma, 'polyorder', 1);
                title(['one-vs-all class: ' num2str(l(k))]);
                for c = 1:size(X, 2)
                    Xnorm(:,c) = SVMstruct.ScaleData.scaleFactor(c)*(X(:,c) +  SVMstruct.ScaleData.shift(c)); %#ok<AGROW>
                end

                [out_class, f(:, k)]=svmdecisionIOTQC(Xnorm,SVMstruct);

                % al contrario que la LR
                % ver (http://stackoverflow.com/questions/11214704/understanding-the-probabilistic-interpretation-of-logistic-regression)
                % las SVM la salida del SVM no se puede interpretar como una probabilidad a posteriori. Para conseguir esto ajutamos la salida
                % del SVM a un modelo LR para ver la probabilidad a posteriori como se
                % indica en
                % John C. Platt Probabilstic Outputs for Suport Vector Machines and comparisons to regularized likelihood methods

                Xlr=f(:, k);
                ylr=0.5*(out_class+1);
                ylr=ylr+1;
                clr.Train(Xlr,ylr);
                [zlr(:, k), ~]=clr.Predict(Xlr);

                %aqui pintamos como se ajusta la salida del SVM con el mejor modelo LR
                [~, I]=sort(Xlr);
                figure; plot(Xlr(I), zlr(I,k), 'r.', Xlr(I), ylr(I), 'g.'); figure(gcf)
                title(['class: ' num2str(l(k))]);
                xlabel('SVM f value');
                legend({'LR posterior prob', 'SVM classification'});
                title(['class: ' num2str(l(k))]);
            end

            %aqui hacemos un one-vs-all
            [~,p]=max(f,[], 2);

            %aqui ajustamos un LR a la salida del SVM
            % clear Xlr, ylr;
            Xlr=f;
            ylr=p;
            clr.Train(Xlr,ylr);
            %LR posterior probability
            [~,zp]=clr.Predict(Xlr);

            acc=UtilFunML.Accuracy(y,p);

            figure; plot(p); ylabel('clase'); xlabel('sample'); title('SVM classification');
            %modulamos por la accuracy para que salga un numero con mejor sentido
            %fisico
            figure; plot(zp.*acc/100); title('posterior probability');
            ylabel('weighted posterior prob'); xlabel('sample');

            %aqui pintamos la (one-vs-all) probabilidad a posteriori en funcion de la muestra para
            %cada muestra y para cada clase
            for k=1:length(l)
                Xlr=f(:, k);
                ylr=(p==k);

                [~, I]=sort(Xlr);
                figure; plot(Xlr(I), zp(I), 'r.', Xlr(I), ylr(I), 'g.'); figure(gcf)
                xlabel('SVM f value');
                legend({'posterior prob', 'SVM classification'});
                title(['class: ' num2str(l(k))]);
            end
        end
    end
end

function checkSVM_Toolbox()
tb='stats'; %toolbox
v=ver(tb);
if(isempty(v))
    error('Statistics toolbox not installed');
end

tbv='8.2'; %minmum version
if verLessThan(tb, tbv)
    error(['stats toolbox is less than: ' tbv]);
end
end
