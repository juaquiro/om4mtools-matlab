function out = mapFeature(X1, X2)
%MAPFEATURE Expand two features into degree-6 polynomial features.
%
% Maps X1, X2 to [1, X1, X2, X1.^2, X1.*X2, X2.^2, X1.^3, ..., X2.^6] --
% the feature expansion regularized logistic/linear regression needs to
% fit a nonlinear decision boundary from two raw features. Own
% reimplementation of the classic ML-course mapFeature.m (not a copy --
% see DECISIONS.md, "Fase 3 -- fixtures de Coursera").
%
% Syntax:
%   out = mapFeature(X1, X2)
%
% Input Arguments:
%   X1 - first feature column (Mx1 double)
%   X2 - second feature column (Mx1 double), same size as X1
%
% Output Arguments:
%   out - [1, X1, X2, X1.^2, X1.*X2, X2.^2, ..., X2.^6] (Mx28 double)
%
% Version: 0.1.0 | Date: 2026-09 | Author: OM4M Group

arguments
    X1 (:,1) double
    X2 (:,1) double
end

degree = 6;
nTerms = 1 + sum((1:degree) + 1);
out = zeros(numel(X1), nTerms);
out(:,1) = 1;

col = 2;
for order = 1:degree
    for term = 0:order
        out(:,col) = (X1.^(order-term)) .* (X2.^term);
        col = col + 1;
    end
end

end
