%% demoOrientationVortex
% Demo script (not a unit test) showing how to use OrientationVortex
% (src/OrientationVortex.m) to estimate fringe orientation [0, pi]
% directly from a fringe pattern, and comparing it visually against the
% orientation computed numerically from the known phase gradient.
%%

%% clear
clear all
close all
clc


%% build a synthetic circular fringe pattern with known phase p
NR=258;
NC=257;

[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

% fase circular
p=2*pi*10*abs(x+1i*y)/sqrt(NR*NC);

c=cos(p);
[px, py]=gradient(p);

%numerical direction (ground truth, from the known phase gradient)
dirn=atan2(-py, px);

%numerical orientation (direction folded into [0, pi])
orn=mod(dirn, pi);

% orientation estimated from the fringe pattern alone, no phase gradient
orVortex=OrientationVortex(c);

figure; imagesc(orVortex); title('OrientationVortex'); colorbar







