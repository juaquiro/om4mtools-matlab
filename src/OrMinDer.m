function [orn, ornMod]=OrMinDer(FP, varargin)
%OrMinDer Orientation by minmum diference fit
% [orn, ornMod]=OrMinDer(FP, N) computes the orientation using a window
% size N.Default values are N=5 px
% References
% [1] Yang, Xia; Yu, Qifeng, and Fu, Sihua. An algorithm for estimating both fringe orientation and fringe density. Optics Communications. 2007 Jun 15; 274(2):286-292

%   AQ, 28/8/09
%   Copyright 2009 OM4M
%   $ Revision: 1.0.0.0 $
%   $ Date: 28-08-2009 $
try
    % get input parameters
    % only want 1 optional inputs at most
    numvarargs = length(varargin);
    if numvarargs > 1
        error('OM4M:OrMinDer:TooManyInputs', ...
            'requires at most 1 optional inputs: N');
    end
    
    % set defaults for optional inputs
    % N = 5 px
    optargs = {5};
    
    % now put these defaults into the valuesToUse cell array,
    % and overwrite the ones specified in varargin.
    optargs(1:numvarargs) = varargin;
    
    % Place optional args in memorable variable names
    [N] = optargs{:};
    
    [NR, NC]=size(FP);
    
    MinusOneC=[2:NC NC];
    PlusOneC=[1 1:NC-1];
    
    MinusOneR=[2:NR NR];
    PlusOneR=[1 1:NR-1];
    
    d0=sqrt(2)*abs(FP(MinusOneR,:)-FP(PlusOneR,:));
    d45=abs(FP(MinusOneR,PlusOneC)-FP(PlusOneR,MinusOneC));
    d90=sqrt(2)*abs(FP(:,MinusOneC)-FP(:,PlusOneC));
    d135=abs(FP(MinusOneR,MinusOneC)-FP(PlusOneR,PlusOneC));
    
    D0=conv2(d0, ones(N,N)/N^2, 'same');
    D45=conv2(d45, ones(N,N)/N^2, 'same');
    D90=conv2(d90, ones(N,N)/N^2, 'same');
    D135=conv2(d135, ones(N,N)/N^2, 'same');
    
    b=0.5*(D0-D90);
    c=-0.5*(D45-D135);%hay que tener en cuenta que la "y" esta downwards
    Or=0.5*atan2(c,b);
    
    %el metodo da la orientacion a lo largo de la franja por eso hau que
    %sumar (o restar) pi/2
    orn = mod(Or+pi/2,pi);
    ornMod=mat2gray(abs(c+1i*b));
    
catch ME
    throw(ME);
end