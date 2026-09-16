%% demoSPHTNormalization
% Demo script (not a unit test) showing how to use SPHT (spiral phase
% transform, src/SPHT.m) to normalize a 2D fringe pattern: turn a fringe
% pattern with varying background/modulation into one with constant unit
% amplitude, ready for phase demodulation.
%%

%% prepare: build a synthetic fringe pattern
clear all
close all

NR=345;
NC=356;

% Pixel coordinates centered on the image (needed for a radially-varying
% phase term below)
[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

% p: a radially increasing phase (the "vortex"-like pattern being demoed)
p=2*pi*25*abs(x+1i*y).^2/(NR*NC);
% m: a smooth, non-uniform modulation/background - what we want to remove
m=2+cos(2*pi*x/NC + pi/4).*sin(2*pi*y/NR);

%% fringe pattern: modulate + add noise, as a real acquired image would look
g=m.*(1+cos(p + 1*rand(size(p)))) + 1*randn(size(p));

%% filter DC: remove the slowly-varying background, keep only the fringes
H=fspecial('disk',100);
c=g-imfilter(g, H);
c=c-mean(c(:)); % SPHT expects a DC-filtered (zero-mean) input, see src/SPHT.m

%% normalize: use SPHT to get the quadrature term, then collapse amplitude
% s = |SPHT(c)| is the local fringe amplitude estimate
s=abs(SPHT(c));
% gn: normalized fringe pattern - same phase as c, but unit amplitude,
% because atan2(s,c) depends only on the phase of c, not its magnitude
gn=cos(atan2(s,c));
