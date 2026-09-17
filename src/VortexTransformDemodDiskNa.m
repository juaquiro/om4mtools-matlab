function VortexTransformDemodDiskNa()
% VortexTransformDemodDiskNa demo/figure-generation script: demodulates
% the "DisNa" fringe pattern fixture (Delta7DisNa.tif) via orientation
% (OrMinDer), direction (calcDirection) and the Vortex transform, and
% plots the direction vectors and demodulation results. Not a reusable
% function - requires specific fixture files in the working directory.
close all
%addpath('..\..\..\docs\ExportFig');
set(0,'DefaultTextInterpreter', 'latex');
iptsetpref('ImshowBorder','tight');
iptsetpref('ImtoolInitialMagnification','fit');
callfun=mfilename;


%% Figura direccion y orientacion superpuestas a la imagen CIRCULAR
clc;

g=mat2gray(rgb2gray(imread('Delta7DisNa.tif')));
[NR, NC]=size(g);
[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;
R=2:20:NR; C=2:20:NC;



N=50;
%numerical orientation Min diff
[orn, ornMod]=OrMinDer(g, N);

%numerical orientation
ngx=cos(orn);
ngy=-sin(orn);

%direction VFR
q=ornMod;
W=mat2gray(imread('delta7DisNaMask.jpg'));
t=5;
mu=1;
r0=[];
[dirn]=calcDirection(orn,q,W,t,mu,r0); dirn=dirn+pi;
px=-cos(dirn);
py=sin(dirn);

%Vortex operator
RN=10;
c=IgramNorm(g, RN);
s=Vortex(c, dirn);

%direccion vectors sobre patron de franjas
figure;
imagesc(x(round(0.5*NR), :),y(:, round(0.5*NC)), mat2gray(g), [-0.5, 1.5]); colormap gray; axis off, axis image;
hold on;
quiver(x(R,C),y(R,C), px(R,C), py(R,C), 'r', 'LineWidth',2, 'AutoScaleFactor',0.6)

% set(gcf,'color','w'); %set border to white to hide eps crop errors
% figname=['C5_' callfun '_direction_vector' '.eps'];
% export_fig(figname); 

figure; imagesc(c); title('cosine'); colorbar
figure; imagesc(s); title('sine'); colorbar

StrR='$b)$';
phi=atan2(s, c);
phi=1-W+W.*mat2gray(phi);
figure; imshow(phi);
text(15, 25, StrR, 'parent',gca, 'FontSize',24, 'BackgroundColor',[1 1 1]); 
%por alguna extragna razon el primer text no funciona al exportar a eps
text(15, 25, StrR, 'parent',gca, 'FontSize',24, 'BackgroundColor',[1 1 1]);

set(gcf,'color','w'); %set border to white to hide eps crop errors
figname=['C5_' callfun '_demod__Results' '.eps'];
%export_fig(figname);


StrR='$a)$';
phi=1-W+W.*mat2gray(g);
figure; imshow(phi);
text(15, 25, StrR, 'parent',gca, 'FontSize',24, 'BackgroundColor',[1 1 1]); 
%por alguna extragna razon el primer text no funciona al exportar a eps
text(15, 25, StrR, 'parent',gca, 'FontSize',24, 'BackgroundColor',[1 1 1]);

set(gcf,'color','w'); %set border to white to hide eps crop errors
figname=['C5_' callfun '_igram' '.eps'];
%export_fig(figname);




