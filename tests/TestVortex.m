%% Test Vortex
% Test for the Vortex function
%%

%% clear 
clear all
close all
clc


%% Test

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

% fase circular
p=2*pi*10*abs(x+1i*y)/sqrt(NR*NC);

c=cos(p);
[px, py]=gradient(p);
dirn=atan2(-py, px);

s=Vortex(c, dirn);

figure; imagesc(s); title('s'); colorbar
figure; imagesc(atan2(s, c));  title('fase');


% fase circular con orientacion en vez de direccion
[cx, cy]=gradient(c);
orn=mod(atan2(-cy, cx), pi);

s=Vortex(c, orn);

figure; imagesc(s); title('s orn'); colorbar
figure; imagesc(atan2(s, c));  title('fase orn');