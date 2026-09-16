%% demoVortex
% Demo script (not a unit test) showing how to use Vortex
% (src/Vortex.m) to recover the quadrature term s of a fringe pattern c,
% given either the true direction or, in the last section, only the
% orientation (direction folded into [0, pi], e.g. from
% demoOrientationVortex) to show the resulting sign ambiguity in s.
%%

%% clear
clear all
close all
clc


%% linear phase case, using the true direction
NR=256;
NC=257;

[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

% fase lineal
p=2*pi*10*(x)/(NC);

c=cos(p);
[px, py]=gradient(p);
dirn=atan2(-py, px);

s=Vortex(c, dirn);

figure; imagesc(s); title('s'); colorbar
figure; imagesc(atan2(s, c));  title('fase');

%% circular phase case, using the true direction
p=2*pi*10*abs(x+1i*y)/sqrt(NR*NC);

c=cos(p);
[px, py]=gradient(p);
dirn=atan2(-py, px);

s=Vortex(c, dirn);

figure; imagesc(s); title('s'); colorbar
figure; imagesc(atan2(s, c));  title('fase');


%% same circular case, but using orientation instead of direction
% orientation only fixes dir up to a sign (mod pi), so s inherits that
% ambiguity - compare 's orn'/'fase orn' below against the previous section
[cx, cy]=gradient(c);
orn=mod(atan2(-cy, cx), pi);

s=Vortex(c, orn);

figure; imagesc(s); title('s orn'); colorbar
figure; imagesc(atan2(s, c));  title('fase orn');