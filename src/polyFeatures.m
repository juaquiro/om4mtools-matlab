function Xpoly = polyFeatures(X, p)
%POLYFEATURES Expand a column vector into powers 1..p.
%
% Xpoly(:,k) = X.^k for k = 1:p -- the feature expansion polynomial
% regression needs to fit a degree-p curve from a single raw feature.
% Own reimplementation of the classic ML-course polyFeatures.m (not a
% copy -- see DECISIONS.md, "Fase 3 -- fixtures de Coursera").
%
% Syntax:
%   Xpoly = polyFeatures(X, p)
%
% Input Arguments:
%   X - data column (Mx1 double)
%   p - maximum power (positive integer scalar)
%
% Output Arguments:
%   Xpoly - [X, X.^2, ..., X.^p] (Mxp double)
%
% Version: 0.1.0 | Date: 2026-09 | Author: OM4M Group

arguments
    X (:,1) double
    p (1,1) double {mustBePositive, mustBeInteger}
end

Xpoly = zeros(numel(X), p);
for power = 1:p
    Xpoly(:,power) = X.^power;
end

end
