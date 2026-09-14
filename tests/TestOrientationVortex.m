%% Test OrientationVortex
% Test for the OrientationVortex function
%%

%% clear 
clear all
close all
clc


%% Test

NR=258;
NC=257;

[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

% fase circular
p=2*pi*10*abs(x+1i*y)/sqrt(NR*NC);

c=cos(p);
[px, py]=gradient(p);

%numerical direction
dirn=atan2(-py, px);

%numerical orientation
orn=mod(dirn, pi);

orVortex=OrientationVortex(c);

figure; imagesc(orVortex); title('OrientationVortex'); colorbar







