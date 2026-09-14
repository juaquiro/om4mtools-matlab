function [out,f] = svmdecisionIOTQC(Xnew,svm_struct)
%SVMDECISION Evaluates the SVM decision function

%   Copyright 2004-2012 The MathWorks, Inc.


sv = svm_struct.SupportVectors;
alphaHat = svm_struct.Alpha;
bias = svm_struct.Bias;
kfun = svm_struct.KernelFunction;
kfunargs = svm_struct.KernelFunctionArgs;

f = -1.0*((feval(kfun,sv,Xnew,kfunargs{:})'*alphaHat(:)) + bias);
% points on the boundary are assigned to class 1
out = sign(f);
out(out==0) = 1;
