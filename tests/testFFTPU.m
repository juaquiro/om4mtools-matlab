%function testFFTPU()
close all

NR=512;
NC=512;
[x,y]=meshgrid(1:NC, 1:NR);
x=x-0.5*NC; y=y-0.5*NR;
M=abs(x+1i*y)<(1110.2*(NR+NC));



p=3*peaks(max(NR, NC));
p=imresize(p, [NR, NC]).*M;

w=mod(p, 2*pi);

u=FFTPU(w, M);
figure; imagesc(w);
figure; imagesc(u);
figure; imagesc(angle(exp(1i*(u-w))));



%end