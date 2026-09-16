%% demoCalculateHomographyAndTransform
% Demo script (not a unit test) showing how to use UtilFunFPA.homography_solve
% and UtilFunFPA.homography_transform (src/UtilFunFPA.m) to convert an image
% from pixel coordinates to physical mm coordinates, given 4 known reference
% points.
%
% Requires a human at the keyboard: it calls ginput(4) to manually pick the
% 4 corners on the displayed image, so it cannot be automated as a unit
% test. Formerly testFPA_UtilFunFPAClassVer/testCalculateHomographyAndTransform,
% moved out here (2026-09-16) - it always carried an assumeFail() explaining
% exactly this, see DECISIONS.md.
%%

setupPath();

import OM4MClassLib.Util.*;
fprintf('\n%s: ',Logging.WhoCalledMe());
close all

g=imread('009_120s_PLS_7um_MLC2132.jpg');

% Empezando por la esquina superior dcha
% follow clockwise order and slect 4 points
% in the image with coordinaes in mm given by
%(7.5,7.5)->(7.5,-7.5)->(-7.5,7.5)->(-7.5,7.5)

xy=[ 7.5 7.5 -7.5 -7.5; 7.5 -7.5 -7.5 7.5]; %four corners in mm

f=figure; imshow(g); title('axis in px'); %#ok<NASGU>
uv=ginput(4);
uv=uv';

Hpx2mm = UtilFunFPA.homography_solve(uv, xy); %px2mm
Hpx2mm=Hpx2mm/Hpx2mm(3,3);

[NR, NC, ~]=size(g);

[u, v]=meshgrid(1:NC, 1:NR);

uv=[u(:)'; v(:)']; %in px
%transmform px to mm
xy=UtilFunFPA.homography_transform(uv, Hpx2mm); %mm
x=reshape(xy(1, :), NR, NC); %mm
y=reshape(xy(2, :), NR, NC); %mm

figure; h=pcolor(x, y, double(rgb2gray(g)));
set(h, 'EdgeColor', 'none');
title('axis in mm');
