%% TestNorlaizationVortex
% This m-file demostrates how to use the vortex transform to perform a 2D
% normalization
%%

%% prepare
clear all
close all

NR=345;
NC=356;

[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

p=2*pi*25*abs(x+1i*y).^2/(NR*NC);
m=2+cos(2*pi*x/NC + pi/4).*sin(2*pi*y/NR);

%% fringe pattern
g=m.*(1+cos(p + 1*rand(size(p)))) + 1*randn(size(p));

%% filter DC
H=fspecial('disk',50);
c=g-imfilter(g, H);

%% normalize
s=abs(SPHT(c));
gn=cos(atan2(s,c));















