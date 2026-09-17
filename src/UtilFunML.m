classdef UtilFunML
    % UtilFunML static utility functions for the Machine Learning
    % library (classifiers, cost functions, curves, NN helpers)

    %% public methods
    methods(Static)
        function g = sigmoid(z)
            % sigmoid computes the sigmoid (logistic) function of z
            g = 1.0 ./ (1.0 + exp(-z));
        end
        
        function [X, fX, i] = fmincg(f, X, options, P1, P2, P3, P4, P5)
            % Minimize a continuous differentialble multivariate function. Starting point
            % is given by "X" (D by 1), and the function named in the string "f", must
            % return a function value and a vector of partial derivatives. The Polack-
            % Ribiere flavour of conjugate gradients is used to compute search directions,
            % and a line search using quadratic and cubic polynomial approximations and the
            % Wolfe-Powell stopping criteria is used together with the slope ratio method
            % for guessing initial step sizes. Additionally a bunch of checks are made to
            % make sure that exploration is taking place and that extrapolation will not
            % be unboundedly large. The "length" gives the length of the run: if it is
            % positive, it gives the maximum number of line searches, if negative its
            % absolute gives the maximum allowed number of function evaluations. You can
            % (optionally) give "length" a second component, which will indicate the
            % reduction in function value to be expected in the first line-search (defaults
            % to 1.0). The function returns when either its length is up, or if no further
            % progress can be made (ie, we are at a minimum, or so close that due to
            % numerical problems, we cannot get any closer). If the function terminates
            % within a few iterations, it could be an indication that the function value
            % and derivatives are not consistent (ie, there may be a bug in the
            % implementation of your "f" function). The function returns the found
            % solution "X", a vector of function values "fX" indicating the progress made
            % and "i" the number of iterations (line searches or function evaluations,
            % depending on the sign of "length") used.
            %
            % Usage: [X, fX, i] = fmincg(f, X, options, P1, P2, P3, P4, P5)
            %
            % See also: checkgrad
            %
            % Copyright (C) 2001 and 2002 by Carl Edward Rasmussen. Date 2002-02-13
            %
            %
            % (C) Copyright 1999, 2000 & 2001, Carl Edward Rasmussen
            %
            % Permission is granted for anyone to copy, use, or modify these
            % programs and accompanying documents for purposes of research or
            % education, provided this copyright notice is retained, and note is
            % made of any changes that have been made.
            %
            % These programs and documents are distributed without any warranty,
            % express or implied.  As the programs were written for research
            % purposes only, they have not been tested to the degree that would be
            % advisable in any important application.  All use of these programs is
            % entirely at the user's own risk.
            %
            % [ml-class] Changes Made:
            % 1) Function name and argument specifications
            % 2) Output display
            %
            
            % Read options
            if exist('options', 'var') && ~isempty(options) && isfield(options, 'MaxIter')
                length = options.MaxIter;
            else
                length = 100;
            end
            
            
            RHO = 0.01;                            % a bunch of constants for line searches
            SIG = 0.5;       % RHO and SIG are the constants in the Wolfe-Powell conditions
            INT = 0.1;    % don't reevaluate within 0.1 of the limit of the current bracket
            EXT = 3.0;                    % extrapolate maximum 3 times the current bracket
            MAX = 20;                         % max 20 function evaluations per line search
            RATIO = 100;                                      % maximum allowed slope ratio
            
            argstr = ['feval(f, X'];                      % compose string used to call function
            for i = 1:(nargin - 3)
                argstr = [argstr, ',P', int2str(i)];
            end
            argstr = [argstr, ')'];
            
            if max(size(length)) == 2, red=length(2); length=length(1); else red=1; end
            S=['Iteration '];
            
            i = 0;                                            % zero the run length counter
            ls_failed = 0;                             % no previous line search has failed
            fX = [];
            [f1 df1] = eval(argstr);                      % get function value and gradient
            i = i + (length<0);                                            % count epochs?!
            s = -df1;                                        % search direction is steepest
            d1 = -s'*s;                                                 % this is the slope
            z1 = red/(1-d1);                                  % initial step is red/(|s|+1)
            
            while i < abs(length)                                      % while not finished
                i = i + (length>0);                                      % count iterations?!
                
                X0 = X; f0 = f1; df0 = df1;                   % make a copy of current values
                X = X + z1*s;                                             % begin line search
                [f2 df2] = eval(argstr);
                i = i + (length<0);                                          % count epochs?!
                d2 = df2'*s;
                f3 = f1; d3 = d1; z3 = -z1;             % initialize point 3 equal to point 1
                if length>0, M = MAX; else M = min(MAX, -length-i); end
                success = 0; limit = -1;                     % initialize quanteties
                while 1
                    while ((f2 > f1+z1*RHO*d1) | (d2 > -SIG*d1)) & (M > 0)
                        limit = z1;                                         % tighten the bracket
                        if f2 > f1
                            z2 = z3 - (0.5*d3*z3*z3)/(d3*z3+f2-f3);                 % quadratic fit
                        else
                            A = 6*(f2-f3)/z3+3*(d2+d3);                                 % cubic fit
                            B = 3*(f3-f2)-z3*(d3+2*d2);
                            z2 = (sqrt(B*B-A*d2*z3*z3)-B)/A;       % numerical error possible - ok!
                        end
                        if isnan(z2) | isinf(z2)
                            z2 = z3/2;                  % if we had a numerical problem then bisect
                        end
                        z2 = max(min(z2, INT*z3),(1-INT)*z3);  % don't accept too close to limits
                        z1 = z1 + z2;                                           % update the step
                        X = X + z2*s;
                        [f2 df2] = eval(argstr);
                        M = M - 1; i = i + (length<0);                           % count epochs?!
                        d2 = df2'*s;
                        z3 = z3-z2;                    % z3 is now relative to the location of z2
                    end
                    if f2 > f1+z1*RHO*d1 | d2 > -SIG*d1
                        break;                                                % this is a failure
                    elseif d2 > SIG*d1
                        success = 1; break;                                             % success
                    elseif M == 0
                        break;                                                          % failure
                    end
                    A = 6*(f2-f3)/z3+3*(d2+d3);                      % make cubic extrapolation
                    B = 3*(f3-f2)-z3*(d3+2*d2);
                    z2 = -d2*z3*z3/(B+sqrt(B*B-A*d2*z3*z3));        % num. error possible - ok!
                    if ~isreal(z2) | isnan(z2) | isinf(z2) | z2 < 0   % num prob or wrong sign?
                        if limit < -0.5                               % if we have no upper limit
                            z2 = z1 * (EXT-1);                 % the extrapolate the maximum amount
                        else
                            z2 = (limit-z1)/2;                                   % otherwise bisect
                        end
                    elseif (limit > -0.5) & (z2+z1 > limit)          % extraplation beyond max?
                        z2 = (limit-z1)/2;                                               % bisect
                    elseif (limit < -0.5) & (z2+z1 > z1*EXT)       % extrapolation beyond limit
                        z2 = z1*(EXT-1.0);                           % set to extrapolation limit
                    elseif z2 < -z3*INT
                        z2 = -z3*INT;
                    elseif (limit > -0.5) & (z2 < (limit-z1)*(1.0-INT))   % too close to limit?
                        z2 = (limit-z1)*(1.0-INT);
                    end
                    f3 = f2; d3 = d2; z3 = -z2;                  % set point 3 equal to point 2
                    z1 = z1 + z2; X = X + z2*s;                      % update current estimates
                    [f2 df2] = eval(argstr);
                    M = M - 1; i = i + (length<0);                             % count epochs?!
                    d2 = df2'*s;
                end                                                      % end of line search
                
                if success                                         % if line search succeeded
                    f1 = f2; fX = [fX' f1]';
                    %AQDEBUG no queremos output
                    %fprintf('%s %4i | Cost: %4.6e\r', S, i, f1);
                    s = (df2'*df2-df1'*df2)/(df1'*df1)*s - df2;      % Polack-Ribiere direction
                    tmp = df1; df1 = df2; df2 = tmp;                         % swap derivatives
                    d2 = df1'*s;
                    if d2 > 0                                      % new slope must be negative
                        s = -df1;                              % otherwise use steepest direction
                        d2 = -s'*s;
                    end
                    z1 = z1 * min(RATIO, d1/(d2-realmin));          % slope ratio but max RATIO
                    d1 = d2;
                    ls_failed = 0;                              % this line search did not fail
                else
                    X = X0; f1 = f0; df1 = df0;  % restore point from before failed line search
                    if ls_failed | i > abs(length)          % line search failed twice in a row
                        break;                             % or we ran out of time, so we give up
                    end
                    tmp = df1; df1 = df2; df2 = tmp;                         % swap derivatives
                    s = -df1;                                                    % try steepest
                    d1 = -s'*s;
                    z1 = 1/(1-d1);
                    ls_failed = 1;                                    % this line search failed
                end
                if exist('OCTAVE_VERSION')
                    fflush(stdout);
                end
            end
            %AQDEBUG no queremos output
            %fprintf('.\n');
            
        end
        
        function [J, JGrad]=CostFunctionLR(theta, X, y, lambda)
            % CostFunctionLR computes the regularized logistic regression
            % cost J and gradient JGrad for parameters theta ((n+1)x1)
            % on data X (mxn) and labels y
            % Initialize some useful values
            n=length(theta); %number of features + 1
            
            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];
            
            
            % You need to return the following variables correctly
            J = 0;
            JGrad = zeros(size(theta));
            
            z=Xbias*theta; %theta'*x
            h=UtilFunML.sigmoid(z);
            
            t=theta(2:end);
            J=(-y'*log(h) - (1-y')*log(1-h))/m + lambda*(t')*t/(2*m);
            
            l=[0; lambda*ones(n-1, 1)];
            JGrad=(Xbias'*(h-y))/m +l.*theta/m ;
        end
        
        function a=Accuracy(y_act, y_pred)
            % Accuracy computes the classification success rate (%)
            % between actual labels y_act and predicted labels y_pred
            a=mean(double(y_pred == y_act)) * 100;

        end


        function [J, JGrad]=CostFunctionLinReg(theta, X, y, lambda)
            % CostFunctionLinReg computes the regularized linear
            % regression cost J and gradient JGrad for parameters theta
            % ((n+1)x1) on data X (mxn) and targets y
            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];
            
            
            t=theta(2:end);
            r=Xbias*theta-y;
            J=r'*r/(2*m) + lambda*(t')*t/(2*m);
            
            n=length(theta);
            l=[0; lambda*ones(n-1, 1)];
            JGrad=Xbias'*(Xbias*theta-y)/m + l.*theta/m ;
            JGrad = JGrad(:);
        end
        
        function [error_train, error_val] = learningCurve(classfier, X, y, Xval, yval, varargin)
            % learningCurve computes the learning curve for classfier
            % (with its current params, e.g. lambda) by training on
            % increasing subsets of X/y (every deltaSamples samples) and
            % evaluating on both the training subset and the
            % cross-validation set Xval/yval. Normalization params are
            % computed once on the initial full-X train, then held fixed
            % for the per-subset trainings.
            % error_train/error_val are arrays of error structs (see
            % genErrorStruct).
            %
            % Optional args: deltaSamples (5) step size between learning
            % curve points.
            try
                import OM4MClassLib.Util.*;
                
                callFunc=Logging.WhoCalledMe();
                
                % get input parameters and set defalt values
                % only want 1 optional inputs at most
                numvarargs = length(varargin);
                if numvarargs > 1
                    retErrorMsg=['requires at most 1 optional inputs: deltaSamples(dm): ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
                
                % set defaults for optional inputs
                % deltaSamples=5; %calculate learning curve every 5 sample
                optargs = {5};
                
                % now put these defaults into the valuesToUse cell array,
                % and overwrite the ones specified in varargin.
                optargs(1:numvarargs) = varargin;
                
                % Place optional args in memorable variable names
                [dm] = optargs{:};
                
                %check input parameters
                if not(isa(classfier, 'Classifier'))
                    retErrorMsg=['c must be a classifier object: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
                
                iniCnpFlag=classfier.Get(char(ClassifierProps.normalize));
                if not(isa(iniCnpFlag, 'logical'))
                    retErrorMsg=[' must be a logical: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
                
                %train set labels must be 1,2...N-1, N
                %becasue the train set is used for training
                if not(classfier.isRegression)
                    UtilFunML.checkTrainSetLabels(y);
                end
                                
                
                %train and set internal normalization params if necessary
                classfier.Train(X, y);
                lambda=classfier.Get(char(ClassifierProps.lambda));
                
                % Number of training examples
                m = size(X, 1);
                k=length(unique(y)); %number of classes
                
                %the classfier have been previuously trained with the
                %cnpFlag=true so normalization parameters are calculated for training set X,y
                % further calls to Train(cnpFlag=false), and CostFunction
                % will use current normalization params for all further trainings
                classfier.Set(char(ClassifierProps.normalize),false);
                h = waitbar(0,'Calculating learning curve...');
                hw=findobj(h,'Type','Patch');
                set(hw,'EdgeColor',[0.2 0.8 0.2],'FaceColor',[0.2 0.8 0.2]) % changes the color to green
                %here there is an aspect that must be taken into account,
                %for problems with many claes it is very probable that the
                %first samples had not all the avalilable clases in y
                %specially for y(1:i) so error_train and training is no reliable for i
                %small specially in one-vs-all strategies
                
                %init error_train and error_val so all values are set to
                %zero
                for i=1:m
                    error_train(i)=UtilFunML.genErrorStruct(k);
                    error_val(i)=UtilFunML.genErrorStruct(k);
                end
                
                for i=1:dm:m
                    u=unique(y(1:i));
                    %if the number of classes of test does not match the
                    %number of classes of train continue
                    if length(u)==k || classfier.isRegression
                        classfier.Set(char(ClassifierProps.lambda), lambda);
                        classfier.Train(X(1:i, :), y(1:i));
                        
                        classfier.Set(char(ClassifierProps.lambda), 0);
                        error_train(i) = classfier.ErrorFunction(X(1:i, :), y(1:i));
                        error_train(i)=UtilFunML.checkErrorStruct(error_train(i), k);
                        
                        error_val(i) = classfier.ErrorFunction(Xval, yval);
                        error_val(i)=UtilFunML.checkErrorStruct(error_val(i), k);
                    else
                        %in this case there is not enough classes and set
                        %the values to NaN
                        error_train(i).J=NaN;
                        error_train(i).F1s=NaN(k,1);
                        error_train(i).P=NaN(k,1);
                        error_train(i).R=NaN(k,1);
                                                
                        error_val(i).J=NaN;
                        error_val(i).F1s=NaN(k,1);
                        error_val(i).P=NaN(k,1);
                        error_val(i).R=NaN(k,1);
                    end
                    
                    
                    waitbar(i/m,h)
                end
                %Restore classifier lambda value
                classfier.Set(char(ClassifierProps.lambda), lambda);
                
                %if last samples are not reached set them to NaN
                if i~=m
                    for n=i+1:m
                        error_train(n).J=NaN;
                        error_train(n).F1s=NaN(k,1);
                        error_train(n).P=NaN(k,1);
                        error_train(n).R=NaN(k,1);
                                               
                        error_val(n).J=NaN;
                        error_val(n).F1s=NaN(k,1);
                        error_val(n).P=NaN(k,1);
                        error_val(n).R=NaN(k,1);                    
                    end
                end                
                
                close(h);
                
                if dm>1
                    %interpolate learning curves
                    %interpolant kernel
                    ik=[1:dm dm-1:-1:1]/dm; %linear replication
                    %ik=ones(1, dm); %pixel replication
                    
                    %vectors
                    Jval=conv([error_val(:).J], ik, 'same');                    
                    F1sval=conv2([error_val(:).F1s],ik, 'same');
                    Pval=conv2([error_val(:).P], ik, 'same');
                    Rval=conv2([error_val(:).R], ik, 'same');
                    
                    Jtrain=conv([error_train(:).J], ik, 'same');                    
                    F1strain=conv2([error_train(:).F1s],ik, 'same');
                    Ptrain=conv2([error_train(:).P], ik, 'same');
                    Rtrain=conv2([error_train(:).R], ik, 'same');                
                    
                    for i=1:m
                        error_val(i).J=Jval(i);
                        error_val(i).F1s=F1sval(:, i);
                        error_val(i).P=Pval(:, i);
                        error_val(i).R=Rval(:, i);
                                                
                        error_train(i).J=Jtrain(i);
                        error_train(i).F1s=F1strain(:, i);
                        error_train(i).P=Ptrain(:, i);
                        error_train(i).R=Rtrain(:, i); 
                    end
                end
            catch ME
                rethrow(ME)
            end
            
        end
        
        function [error_train, error_val] = validationCurve(classfier, lambdav, X, y, Xval, yval)
            % validationCurve computes the validation curve for
            % classfier: trains it once per lambda value in lambdav
            % (on the full X/y), then evaluates train/validation error
            % (error_train/error_val, see checkErrorStruct) on X/y and
            % Xval/yval respectively at each lambda
            try
                import OM4MClassLib.Util.*;
                
                callFunc=Logging.WhoCalledMe();
                if not(isa(classfier, 'Classifier'))
                    retErrorMsg=['c must be a classifier : ' callFunc];
                    error([retErrorMsg]);
                end
                
                if not(classfier.isSupervised())
                    retErrorMsg=['c must be a supervised classifier: ' callFunc];
                    error([retErrorMsg]);
                end
                
                %train set labels must be 1,2...N-1, N
                %becasue the train set is used for training
                if not(classfier.isRegression)
                    UtilFunML.checkTrainSetLabels(y);
                end
                
                
                %make a test train and set internal normalization params
                classfier.Set(char(ClassifierProps.lambda), 0);
                classfier.Train(X, y);
                
                
                k=length(unique(y)); %number of classes
                l=length(lambdav);
                %the classfier have been previuously trained with the
                %cnpFlag=true so normalization parameters are calculated for training set X,y
                % further calls to Train(cnpFlag=false), and CostFunction
                % will use current normalization params for all further trainings
                classfier.Set(char(ClassifierProps.normalize), false);
                h = waitbar(0,'Calculating validation curve...');
                for i=1:l
                    classfier.Set(char(ClassifierProps.lambda), lambdav(i));
                    classfier.Train(X, y);
                    
                    classfier.Set(char(ClassifierProps.lambda), 0);
                    error_train(i) = classfier.ErrorFunction(X, y);
                    error_train(i)=UtilFunML.checkErrorStruct(error_train(i), k);
                    
                    error_val(i) = classfier.ErrorFunction(Xval, yval);
                    error_val(i)=UtilFunML.checkErrorStruct(error_val(i), k);
                    
                    waitbar(i/l,h)
                end
                close(h);
                
            catch ME
                throw(ME)
            end
            
        end
        
        function [error_train, error_val] = ZernikeMuCurve(classfier, muv, X, y, Xval, yval)
            % ZernikeMuCurve computes the curvature-regularization (mu)
            % curve for a ClassifierZernikes classfier: trains it once
            % per mu value in muv (on the full X/y, keeping lambda fixed
            % at its current value), then evaluates train/validation
            % error (error_train/error_val, see checkErrorStruct) on
            % X/y and Xval/yval respectively at each mu
            try
                import OM4MClassLib.Util.*;
                
                callFunc=Logging.WhoCalledMe();
                if not(isa(classfier, 'ClassifierZernikes'))
                    retErrorMsg=['c must be a ClassifierZernikes : ' callFunc];
                    error([retErrorMsg]);
                end
                
                
                %make a test train and set internal normalization params
                classfier.Set(char(ClassifierProps.mu), 0);
                classfier.Train(X, y);
                
                
                k=length(unique(y)); %number of classes
                l=length(muv);
                %the classfier have been previuously trained with the
                %cnpFlag=true so normalization parameters are calculated for training set X,y
                % further calls to Train(cnpFlag=false), and CostFunction
                % will use current normalization params for all further trainings
                classfier.Set(char(ClassifierProps.normalize), false);
                h = waitbar(0,'Calculating mu curve...');
                for i=1:l
                    classfier.Set(char(ClassifierProps.mu), muv(i));
                    classfier.Train(X, y);
                    
                    lambda=classfier.Get(char(ClassifierProps.lambda));
                    
                    classfier.Set(char(ClassifierProps.lambda), 0);
                    error_train(i) = classfier.ErrorFunction(X, y);
                    error_train(i)=UtilFunML.checkErrorStruct(error_train(i), k);
                    
                    error_val(i) = classfier.ErrorFunction(Xval, yval);
                    error_val(i)=UtilFunML.checkErrorStruct(error_val(i), k);
                    
                    classfier.Set(char(ClassifierProps.lambda), lambda);
                    
                    waitbar(i/l,h)
                end
                close(h);
                
            catch ME
                rethrow(ME)
            end
            
        end
        
        function [d, K] = NICDCurve(c, X, Kmax)
            % NICDCurve computes the normalized inter-cluster distance
            % for an unsupervised classifier c trained on X, for cluster
            % counts k=2:Kmax. d is a 1xKmax vector of inter-cluster
            % distances (d(1) is set equal to d(Kmax), since k=1 isn't
            % meaningfully computed); K is the cluster count maximizing d.
            try
                import OM4MClassLib.Util.*;
                
                callFunc=Logging.WhoCalledMe();
                if not(isa(c, 'Classifier'))
                    retErrorMsg=['c must be a classifier: ' callFunc];
                    error([retErrorMsg]);
                end
                
                if c.isSupervised()
                    retErrorMsg=['c must be a unsupervised classifier: ' callFunc];
                    error([retErrorMsg]);
                end
                
                h = waitbar(0,'Calculating validation curve...');
                d=zeros(1, Kmax);
                for k=2:Kmax
                    c.Train(X,k);
                    d(k)=c.Get(char(ClassifierProps.d));
                    waitbar(k/Kmax,h)
                end
                d(1)=d(Kmax);
                close(h);
                [~,K]=max(d);
                
            catch ME
                throw(ME)
            end
            
        end
        
        
        
        function theta = normalEqn(X, y, lambda)
            % LS solution to min_theta[(theta*X'-y)^2 + lambda*theta^2]
            %   the data X includes the bias as well as the parameters
            %   theta, i.e. if n is the number of features X is mxn and
            %   theta is (n+1)x1
            
            % Add bias to the X data matrix
            m = size(X, 1); % Number of samples
            Xbias = [ones(m, 1) X];
            
            theta=UtilFunML.normalEqnWithoutBias(Xbias, y, lambda);

        end
        
        function theta= normalEqnWithoutBias(X, y, lambda)
            n=size(X,2); %n features including bias
            
            b=X'*y;
            l=lambda*eye(n); l(1)=0; %bias is not regularized
            A=X'*X+l;
            theta=A\b;

        end
        
        function checkTrainSetLabels(y)
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            
            p=unique(y);
            L=length(p);
            
            if size(y, 2)~=1
                retErrorMsg=['labels must be a column vector: ' callFunc];
                error([retErrorMsg]);
            end
            
            if min(p)~=1 || max(p) ~=L || any(diff(p)~=1)
                retErrorMsg=['labels must be consequitive integer numbers 1,2...N-1, N : ' callFunc];
                error([retErrorMsg]);
            end
        end
        
        % this function generates the error struct for k classes
        % J is the global accuracy, F1s, P and R have a value for each
        % class
        function errStruct=genErrorStruct(k)
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            
            if k<1
                retErrorMsg=['number of clasess must be >= 1 : ' callFunc];
                error([retErrorMsg]);
            end
            
            if rem(k,1)
                retErrorMsg=['number of clasess must integer : ' callFunc];
                error([retErrorMsg]);
            end
            
            
            %generates error estruct to send error information
            %error, Precission, Recall, F1score
            errStruct=struct('J',0,'F1s',0,'P',0,'R',0);
            
            errStruct.J=0;
            errStruct.F1s=zeros(k,1);
            errStruct.P=zeros(k,1);
            errStruct.R=zeros(k,1);
        end
        
        function errStruct_o=checkErrorStruct(errStruct_i, k)
            %check fields of errStruct_i and check that F1s, P and R are
            %vectors of kx1 with k the number of clases
            try
                import OM4MClassLib.Util.*;
                
                
                callFunc=Logging.WhoCalledMe();
                if not(all(isfield(errStruct_i, {'J', 'F1s', 'P', 'R'})))
                    retErrorMsg=['incorrect errStruct: ' callFunc];
                    error([retErrorMsg]);
                end
                
                
                for j=1:length(errStruct_i)
                    errStruct_o(j)=UtilFunML.genErrorStruct(k);
                    errStruct_o(j).F1s=zeros(k,1);
                    errStruct_o(j).P=zeros(k,1);
                    errStruct_o(j).R=zeros(k,1);
                    
                    errStruct_o(j).J=errStruct_i(j).J;
                    l=length(errStruct_i(j).F1s);
                    errStruct_o(j).F1s(1:l)=errStruct_i(j).F1s;
                    
                    l=length(errStruct_i(j).P);
                    errStruct_o(j).P(1:l)=errStruct_i(j).P;
                    
                    l=length(errStruct_i(j).R);
                    errStruct_o(j).R(1:l)=errStruct_i(j).R;
                end
            catch ME
                throw(ME)
            end
            
        end
        
        function [F1s, P, R]=Fscore(y,p)
            % compute Precisin, Reacll and F1score for each of the classes
            % in the labels y. a one-vs-all strategy is used
            % y are the actual training classes ad p the predicted values
            %if there are n clases F1s, P and R are column vectors with the
            %values for each class
            numClasses=length(unique(y));
            
            F1s=zeros(numClasses, 1);
            P=F1s;
            R=F1s;
            
            for c=1:numClasses
                %actual class
                ac=(y==c);
                %predicted class
                pc=(p==c);
                
                %true possitive
                tp=sum(ac&pc);
                %false possitive
                fp=sum(not(ac)&pc);
                %false negative
                fn=sum(ac&not(pc));
                
                d=tp+fp;
                if d
                    P(c)=tp/d;
                else
                    P(c)=0;
                end
                
                d=tp+fn;
                if d
                    R(c)=tp/d;
                else
                    R(c)=0;
                end
                
                d=P(c)+R(c);
                if d
                    F1s(c)=2*P(c)*R(c)/d;
                else
                    F1s(c)=0;
                end
            end
            
        end
        
        
        % This is the code from the coursera ML course, qhich implements a
        % NN algorithm with one hidden layer
        function [J grad]=nnCostFunction(nn_params,input_layer_size, ...
                hidden_layer_size,num_labels,X,y,lambda)
            
            % Reshape nn_params back into the parameters Theta1 and Theta2, the weight matrices
            % for our 2 layer neural network
            Theta1=reshape(nn_params(1:hidden_layer_size * (input_layer_size + 1)), ...
                hidden_layer_size, (input_layer_size + 1));
            
            Theta2=reshape(nn_params((1 + (hidden_layer_size * (input_layer_size + 1))):end), ...
                num_labels, (hidden_layer_size + 1));
            
            % Setup some useful variables
            m=size(X, 1);
            
            % Part 1: Feedforward the neural network and return the cost in the
            % variable J. After implementing Part 1, you can verify that your
            % cost function computation is correct by verifying the cost
            % computed in ex4.m
            
            % Managing the Y to transform it in a nested identity matrix
            Y=eye(num_labels);
            Y=Y(y,:);
            % Fordward propagation
            a1=[ones(m,1) X];
            z2=Theta1*a1';
            a2=UtilFunML.sigmoid(z2);
            a2=[ones(1,size(a2,2));a2];
            z3=Theta2*a2;
            a3=UtilFunML.sigmoid(z3);
            h=a3;
            % Funci�n de coste
            costPos=-Y.*log(h');
            costNeg=(1-Y).*log(1-h)';
            cost=costPos-costNeg;
            J=(1/m)*sum(cost(:));
            
            % Regularization
            Theta1Filtered=Theta1(:,2:end);
            Theta2Filtered=Theta2(:,2:end);
            sqTheta1Filtered=Theta1Filtered.*Theta1Filtered;
            sqTheta2Filtered=Theta2Filtered.*Theta2Filtered;
            regularization=(lambda/(2*m))*(sum(sqTheta1Filtered(:))+sum(sqTheta2Filtered(:)));
            J=J+regularization;
            
            % Part 2: Implement the backpropagation algorithm to compute the gradients
            % Theta1_grad and Theta2_grad
            
            Delta1=0;
            Delta2=0;
            
            for i=1:m
                % Forward propagation: calculating the activity of each
                % layer
                a1=[1,X(i,:)]';
                z2=Theta1*a1;
                a2=[1;UtilFunML.sigmoid(z2)];
                z3=Theta2*a2;
                a3=UtilFunML.sigmoid(z3);
                % Backpropagation: calculating the node errors
                delta3=a3-Y(i,:)';
                delta2=Theta2Filtered'*delta3.*UtilFunML.sigmoidGradient(z2);
                % Calculating the uppercase deltas
                Delta1=Delta1+delta2*a1';
                Delta2=Delta2+delta3*a2';
            end
            
            % Calculating the gradients
            Theta1_grad=(1/m)*Delta1;
            Theta2_grad=(1/m)*Delta2;
            
            % Part 3: Implement regularization with the cost function and
            % gradients
            
            % Gradient regularization
            Theta1_grad(:,2:end)=Theta1_grad(:,2:end) + ((lambda / m) * Theta1Filtered);
            Theta2_grad(:,2:end)=Theta2_grad(:,2:end) + ((lambda / m) * Theta2Filtered);
            
            % Unrolling the gradients
            grad=[Theta1_grad(:);Theta2_grad(:)];
            
        end
        
        function g=sigmoidGradient(z)
            g=UtilFunML.sigmoid(z).*(1-UtilFunML.sigmoid(z));
        end
        
        function W=randInitializeNNWeights(L_in,L_out)
            % RANDINITIALIZEWEIGHTS(L_in, L_out) randomly initializes the weights
            % of a layer with L_in incoming connections and L_out outgoing connections
            epsilon=sqrt(6/(L_in+L_out));
            W=rand(L_out,1+L_in)*2*epsilon-epsilon;
        end
        
        function checkNNGradients(lambda)
            % CHECKNNGRADIENTS Creates a small neural network to check the
            % backpropagation gradients.
            % CHECKNNGRADIENTS(lambda) Creates a small neural network to check the
            % backpropagation gradients, it will output the analytical gradients
            % produced by your backprop code and the numerical gradients (computed
            % using computeNumericalGradient). These two gradient computations should
            % result in very similar values.
            
            if ~exist('lambda', 'var') || isempty(lambda)
                lambda = 0;
            end
            
            input_layer_size = 3;
            hidden_layer_size = 5;
            num_labels = 3;
            m = 5;
            
            % We generate some 'random' test data
            Theta1 = debugInitializeWeights(hidden_layer_size, input_layer_size);
            Theta2 = debugInitializeWeights(num_labels, hidden_layer_size);
            % Reusing debugInitializeWeights to generate X
            X  = debugInitializeWeights(m, input_layer_size - 1);
            y  = 1 + mod(1:m, num_labels)';
            
            % Unroll parameters
            nn_params = [Theta1(:) ; Theta2(:)];
            
            % Short hand for cost function
            costFunc = @(p) nnCostFunction(p, input_layer_size, hidden_layer_size, ...
                num_labels, X, y, lambda);
            
            [~, grad] = costFunc(nn_params);
            numgrad = computeNumericalGradient(costFunc, nn_params);
            
            % Visually examine the two gradient computations.  The two columns
            % you get should be very similar.
            disp([numgrad grad]);
            fprintf(['The above two columns you get should be very similar.\n' ...
                '(Left-Your Numerical Gradient, Right-Analytical Gradient)\n\n']);
            
            % Evaluate the norm of the difference between two solutions.
            % If you have a correct implementation, and assuming you used EPSILON = 0.0001
            % in computeNumericalGradient.m, then diff below should be less than 1e-9
            diff = norm(numgrad-grad)/norm(numgrad+grad);
            
            fprintf(['If your backpropagation implementation is correct, then \n' ...
                'the relative difference will be small (less than 1e-9). \n' ...
                '\nRelative Difference: %g\n'], diff);
        end
        
        
        
        
    end
end

