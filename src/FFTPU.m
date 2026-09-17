function u=FFTPU(w, M)
% FFTPU unwraps wrapped phase w within ROI M using the FFT-based
% least-squares phase unwrapping method (Ghiglia & Romero)
[NR, NC]=size(w);

% prepare indexs for diferentiation
dx1=[1 1:NC-1];
dx2=[2:NC NC];
dy1=[1 1:NR-1];
dy2=[2:NR NR];

Mx1=M(:, dx1);
Mx2=M(:, dx2);

My1=M(dy1, :);
My2=M(dy1, :);

Mxy=M.*Mx1.*My1.*Mx2.*My2;

% Compute first difference in direction x
zx1=exp(1i*w(:,dx1));
zx2=exp(1i*w(:,dx2));
Dx=0.5*angle(zx2./zx1);

% Compute first difference in direction y
zy1=exp(1i*w(dy1,:));
zy2=exp(1i*w(dy2,:));
Dy=-0.5*angle(zy2./zy1);

% prepare the filters Hu and Hv
[u,v]=meshgrid(1:NC, 1:NR);
u0=floor(NC/2)+1;
v0=floor(NR/2)+1;
u=u-u0;
v=v-v0;

Hu=1i*sin(2*pi*u/NC);
Hv=1i*sin(2*pi*v/NR);

% FT the differences
DX=fft2(Dx);
DY=fft2(Dy);


% compute the filtering
a=conj(ifftshift(Hu)).*DX + ifftshift(Hv).*DY;
a=a./(ifftshift(Hu.*conj(Hu)) + ifftshift(Hv.*conj(Hv)));
a(1,1)=0;

% compute the unwrapped phase
u=real(ifft2(a).*Mxy);
end

