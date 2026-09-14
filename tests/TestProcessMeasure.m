classdef TestProcessMeasure < matlab.unittest.TestCase
    %run(TestProcessMeasure)

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
        function testZernikeFitAndGradient(testCase)
            %run(TestProcessMeasure, 'testZernikeFitAndGradient')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            %% setup data
            NF=480;
            NC=640;

            p=peaks(NC);
            p=imresize(p, [NF, NC]);
            [px,py]=gradient(p);

            [u,v]=meshgrid(1:NC, 1:NF); u=u-0.5*NC; v=v-0.5*NF;
            M=abs(u+1i*v)<200;
            sigma=0.03;
            p=p+sigma*randn(size(p));

            %% make zernike fitting
            cl=ClassifierFactory.Create(ClassifierTypes.Zernikes);
            cl.Set(char(ClassifierProps.zOrder),300);
            cl.Set(char(ClassifierProps.lambda),1e-7);
            cl.Set(char(ClassifierProps.mu),1e-10);

            X=[u(:), v(:)];
            y=p(:);

            cl.Train(X,y);
            % cl.GetTheta(); get the zernikes coeffs
            %CMatrix son los coeficientoes del polinomio cartesiano que ajusta la
            %superficie
            C=cl.GetSurfCoeff();

            %get aproximation
            pp=ProcessMeasure.Polyval2(u,v,C);

            %calculate error
            pe=pp-p;
            pev=pe(M);
            xbins=linspace(-10*sigma, 10*sigma, 100);
            peh=hist(pev, xbins);
            %this should ne a gaussian with 0.03 HW
            figure; plot(xbins, peh); title('hist error of zernike fit');

            %get dx and dy
            Cx=ProcessMeasure.Polyder2(C,1);
            Cy=ProcessMeasure.Polyder2(C,2);
            pxf=ProcessMeasure.Polyval2(u,v,Cx);
            pyf=ProcessMeasure.Polyval2(u,v,Cy);

            %calculate error
            pe=px-pxf;
            pev=pe(M);
            xbins=linspace(-10*sigma, 10*sigma, 100);
            peh=hist(pev, xbins);
            %this should ne a gaussian with 0.03 HW
            figure; plot(xbins, peh); title('hist error of Dx zernike fit');

            pe=py-pyf;
            pev=pe(M);
            xbins=linspace(-10*sigma, 10*sigma, 100);
            peh=hist(pev, xbins);
            %this should ne a gaussian with 0.03 HW
            figure; plot(xbins, peh); title('hist error of Dy zernike fit');

            %get curvatures
            Cxx=ProcessMeasure.Polyder2(Cx,1);
            Cyy=ProcessMeasure.Polyder2(Cy,2);
            Cxy=ProcessMeasure.Polyder2(Cx,2);
            pxxf=ProcessMeasure.Polyval2(u,v,Cxx); %#ok<NASGU>
            pyyf=ProcessMeasure.Polyval2(u,v,Cyy); %#ok<NASGU>
            pxyf=ProcessMeasure.Polyval2(u,v,Cxy); %#ok<NASGU>
        end

        function testLearningCurve(testCase)
            %run(TestProcessMeasure, 'testLearningCurve')
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            %% setup data
            NF=48;
            NC=64;

            p=peaks(NC);
            p=imresize(p, [NF, NC]);
            [u,v]=meshgrid(1:NC, 1:NF); u=u-0.5*NC; v=v-0.5*NF;
            M=abs(u+1i*v)<20;
            sigma=0.03;
            p=p+sigma*randn(size(p));

            %% make zernike fitting
            cl=ClassifierFactory.Create(ClassifierTypes.Zernikes);
            cl.Set(char(ClassifierProps.zOrder),300);
            cl.Set(char(ClassifierProps.lambda),1e-5);
            cl.Set(char(ClassifierProps.mu),0e-7);

            X=[u(:), v(:)];
            y=p(:);

            cl.Train(X,y);
            % cl.GetTheta(); get the zernikes coeffs
            %CMatrix son los coeficientoes del polinomio cartesiano que ajusta la
            %superficie
            C=cl.GetSurfCoeff();

            %get aproximation
            pp=ProcessMeasure.Polyval2(u,v,C);

            %calculate error
            pe=pp-p;
            pev=pe(M);
            xbins=linspace(-10*sigma, 10*sigma, 100);
            peh=hist(pev, xbins);
            figure; plot(xbins, peh);

            %% curva aprendizaje
            m = length(y); %Total number of points
            %Randomize order
            randomIndex=randperm(m);
            X=X(randomIndex,:);
            y=y(randomIndex);
            %Reserve data for cross validation
            NVal=round(m/5);

            Xval=X(end-NVal:end,:); X=X(1:end-NVal,:);
            yval=y(end-NVal:end); y=y(1:end-NVal);
            m = length(y); % Number of training examples after removing the validation set

            %Calculate learning curve
            mdelta=60; %calculates ever mdelta samples
            [error_train, error_val] = UtilFunML.learningCurve(cl, X, y, Xval, yval, mdelta);
            figure; plot(1:m, [error_train.J], 1:m, [error_val.J]);
            legend('Train', 'Cross Validation'); xlabel('m'); ylabel('Error');
        end
    end
end
