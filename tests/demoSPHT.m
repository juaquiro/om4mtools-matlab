%% demoSPHT
% Demo script (not a unit test) showing how to use SPHT (spiral phase
% transform, src/SPHT.m) to recover the quadrature term of a fringe
% pattern. Once corrected by the known direction phase factor
% (-1i*exp(-1i*dir)), the result should be purely real - the two
% sanity-check assert() calls below verify exactly that, for a linear
% and a circular phase pattern.
%%

%% clear
clear all
close all
clc


%% linear phase case
NR=256;
NC=257;

[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

% fase lineal
p=2*pi*10*(x)/(NC);

c=cos(p);
[px, py]=gradient(p);
dir=atan2(-py, px);

sd=SPHT(c);

% correct SPHT's output by the known direction to recover a real signal
s=-1i.*exp(-1i*dir).*sd;

assert(sum(abs(imag(s(:))/(NR*NC)))<1e-6, 'imaginary part must be null')

figure; imagesc(real(s)); title('real(s)'); colorbar
figure; imagesc(imag(s)); title('imag(s)'); colorbar
figure; imagesc(atan2(real(s), c));  title('fase');

%% circular phase case (looser tolerance: direction is singular at the center)
p=2*pi*10*abs(x+1i*y)/sqrt(NR*NC);

c=cos(p);
[px, py]=gradient(p);
dir=atan2(-py, px);

sd=SPHT(c);

s=-1i.*exp(-1i*dir).*sd;

assert(sum(abs(imag(s(:))/(NR*NC)))<0.1, 'imaginary part must be null')

figure; imagesc(real(s)); title('real(s)'); colorbar
figure; imagesc(imag(s)); title('imag(s)'); colorbar
figure; imagesc(atan2(real(s), c));  title('fase');













