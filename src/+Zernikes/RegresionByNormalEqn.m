function [theta] = RegresionByNormalEqn(X, Y, lambda)
    % RegresionByNormalEqn fits theta for feature matrix X and targets Y
    % via the ridge-regularized normal equation (lambda default 0, not
    % applied to the bias term)

    if(nargin<3)
        lambda=0;
    end

     lMatrix=lambda*eye(size(X,2));
     lMatrix(1)=0;
     %lMatrix=diag(lambda*[0:size(X,2)-1]);


     theta=pinv(X'*X+lMatrix)*X'*Y;

    % Algorithms pulled from
    % "http://www.di.ens.fr/~mschmidt/Software/lasso.html"
    %BlockCoordinate
    %IteratedRidge
    %Shooting
    %theta = LassoIteratedRidge(X,Y,lambda,'verbose',0);

end