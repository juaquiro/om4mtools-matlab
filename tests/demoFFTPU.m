%% demoFFTPU
% Demo script (not a unit test) showing how to use FFTPU
% (src/FFTPU.m, FFT-based phase unwrapping) to unwrap a synthetic wrapped
% phase map w inside a region of interest mask M, and checking the
% result visually by re-wrapping u and comparing it against w.
close all

NR=512;
NC=512;
[x,y]=meshgrid(1:NC, 1:NR);
x=x-0.5*NC; y=y-0.5*NR;
M=abs(x+1i*y)<(1110.2*(NR+NC)); % ROI mask (always true here: NR+NC dwarfs the image radius)

% build a smooth unwrapped phase p, then wrap it into w=mod(p, 2*pi)
p=3*peaks(max(NR, NC));
p=imresize(p, [NR, NC]).*M;

w=mod(p, 2*pi);

u=FFTPU(w, M); % u: FFTPU's unwrapped estimate of p from w
figure; imagesc(w); title('wrapped phase w');
figure; imagesc(u); title('unwrapped phase u');
% re-wrap u and compare to w: should look uniform (near zero) if u is a
% correct unwrap of w
figure; imagesc(angle(exp(1i*(u-w)))); title('angle(exp(i*(u-w))) - should be ~0');