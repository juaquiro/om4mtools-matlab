function plotData(X, y)
%PLOTDATA Scatter-plot 2-class data on the current axes.
%
% Plots positive examples (y==1) as black '+' markers and negative
% examples (y==0) as black-outlined, yellow-filled 'o' markers. Own
% reimplementation of the classic ML-course plotData.m, ex2 (binary
% classification) variant (not a copy -- see DECISIONS.md, "Fase 3 --
% fixtures de Coursera"). Unlike the original, this does not open its
% own figure -- callers that want a fresh one call figure() first, as
% every caller in this repo already does.
%
% Syntax:
%   plotData(X, y)
%
% Input Arguments:
%   X - feature matrix, first two columns used (Mx2+ double)
%   y - binary class labels, 0 or 1 (Mx1 double)
%
% Version: 0.1.0 | Date: 2026-09 | Author: OM4M Group

arguments
    X (:,:) double
    y (:,1) double
end

hold on;

positive = y == 1;
plot(X(positive,1), X(positive,2), 'k+', 'LineWidth', 2, 'MarkerSize', 7);

negative = y == 0;
plot(X(negative,1), X(negative,2), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 7);

hold off;

end
