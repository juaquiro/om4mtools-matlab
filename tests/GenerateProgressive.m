function Lens=GenerateProgressive()
    % GenerateProgressive simulates a progressive addition lens (PAL) and
    % its crossed-grid deflectometric fringe patterns, returning a struct
    % with the simulated curvature/astigmatism maps and fringe patterns.
    % The deflectometric igrams are generated assuming a grid pattern
    % imaged through the PAL lens as described in Massig, J. H. (1999).
    % Measurement of Phase Objects by Simple Means. Applied Optics,
    % 38(19), 4103. http://doi.org/10.1364/AO.38.004103
%display flag
dispFlag=false;

%% Progressive lens simulation
LD=100; %lens diameter mm
NR=640; NC=480;
[x,y]=meshgrid(linspace(1, LD, NC), linspace(1, LD, NR)); x=x-0.5*LD; y=y-0.5*LD;
ex=x(1, :); %mm axis
ey=y(:, 1); %mm axix
dy=ey(2)-ey(1); %mm step
dx=ex(2)-ex(1); %mm step
M=abs(x+1i*y)<50; %mm mask


% progression profile in optical curvature GO=n-1
% Optical Curvature = (n-1) Geometrical curvature
% set GO to n-1 to get optical curvature for a given material 
GO=1; %Geometrical to Optical power constant
design='erf';
switch design
    case 'lin'
        %alpha is the Dp/mm along the progression profile
        alpha=2e-2; %D/mm
        alpha=GO*alpha*10^-3; %mm^-2
        %beta is the power for the origirn
        beta=0;
        beta=GO*beta*10^-3;
        p=(-alpha*y+beta)/GO; %mm^-1 x1000 para pasar a D we get -1D in the upper side and 1D in the lower side
    case 'exp'
        NRP=-20; %mm at the NRP
        alpha=2; %D max power at the NRP
        alpha=GO*alpha*10^-3; %mm^-1
        
        beta=10; %mm HW of the power gaussian
        p=alpha*exp(-(y-NRP).^2/(sqrt(2)*beta)^2);
        p=p/GO;
    case 'erf'
        A=2; %Addition in D
        A=GO*A*1e-3; %Adition in mm^-1
        PF=0; %Power in D at the far zone
        PF=GO*PF*1e-3; %Power in mm^-1 at the far zone
        k=0.3; %mm^-1 stifness
        y50=-13; %mm progression half power location
        p=A./(1+exp(k*(y-y50)))+PF;
        p=p/GO;
end

if dispFlag
    figure; plot(ey, p(:,1)*1000); title('progression profile (D)');
end

%first integral of profile
%ip=-0.5*alpha*y.^2+beta*y; %rad this for the 'lin' case
ip=cumsum(p*dy);
%figure; plot(ey, p(:,1), ey, ip(:,1));

%second integral of profile
%iip=-alpha/6*y.^3+0.5*beta*y.^2; %mm this for the 'lin' case
iip=cumsum(ip*dy);
%figure; plot(ey, p(:,1), ey, ip(:,1), ey, iip(:,1));

% sag,
s=iip+0.5*x.^2.*p; %mm
%z thickness the wavefront W=C-(n-1)z
z0=10; %mm
z=z0-s;
if dispFlag
    figure; imagesc(ex, ey, z.*M); axis xy; title('thickness mm')
end

%deflexion = - GO x gradiente de z
%DPM = - GO x hesiano de z
[zx, zy]=gradient(z, dx, dy); zy=-zy; %rad (hay que invertir dy por el tema MATLAB)
[zxx, zxy]=gradient(zx, dx, dy); zxy=-zxy; %mm^-1 (para ver en D x1000)
[~, zyy]=gradient(zy, dx, dy); zyy=-zyy;  %mm^-1 (para ver en D x1000)

Px=-GO*zx; %rad
Py=-GO*zy; %rad

Pxx=-GO*zxx; %mm^-1 x1000 en D
Pyy=-GO*zyy; %mm^-1 x1000 en D
Pxy=-GO*zxy; %mm^-1 x1000 en D

tr=Pxx+Pyy;
dt=Pxx.*Pyy-Pxy.^2;

C=sqrt(abs(tr.^2-4*dt)); %mm^-1 x1000 en D
S=0.5*(tr-C); %mm^-1 x1000 en D
Seq=0.5*tr; %mm^-1 x1000 en D

if dispFlag
    figure; imagesc(ex, ey, Px.*M); axis xy; title('Px (rad)')
    figure; imagesc(ex, ey, Py.*M); axis xy; title('Py (rad)')
    figure; imagesc(ex, ey, 1e3*S.*M); axis xy; title('S (D)')
    figure; imagesc(ex, ey, 1e3*C.*M); axis xy; title('C (D)')
    figure; imagesc(ex, ey, 1e3*Seq.*M); axis xy; title('Seq (D)')
end


%% deflectometer simulation
%see  Massig, J. H. (1999). Measurement 
%of Phase Objects by Simple Means. Applied Optics, 38(19), 4103.
%http://doi.org/10.1364/AO.38.004103

D=30; %mm distance lens - screen
px=1; %mm X grid period in mm
py=1; %mm Y grid period in mm

%deflectometric phase
phix=2*pi*Px*D/px;
phiy=2*pi*Py*D/py;
cx=2*pi*x/px; %x carrier
FFx=round((max(cx(:))-min(cx(:)))/(2*pi)); %x Fringes Field
cy=2*pi*y/py; %y carrier
FFy=round((max(cy(:))-min(cy(:)))/(2*pi)); %y Fringes Field

wx=[FFx, 0];
wy=[0, FFy];

% fringe pattern
a=2; %DC
b=1; %AC
gx=a+b*cos(phix+cx); %igram
gy=a+b*cos(phiy+cy);
grx=a+b*cos(cx); %ref igram
gry=a+b*cos(cy);


g=gx.*gy; %crosed grid igram
gr=grx .* gry; %crosed grid ref
G=fft2(g); %just for display purpouses

if dispFlag
    figure; imagesc(ex, ey, g.*M); axis xy; title('g (GV)'); colormap gray;
    figure; imagesc(ex, ey, g.*gry.*M); axis xy; title('Moire Py (GV)'); colormap gray;
    figure; imagesc(ex, ey, g.*grx.*M); axis xy; title('Moire Px (GV)'); colormap gray;
    figure; imagesc(abs(log(fftshift(G)))); axis xy; title('Moire Px (GV)'); colormap gray;
end

%% output structure

s=['This map has been generated using ' mfilename ' with a ' design ' design'];

Lens.wx=wx; %x carrier FF
Lens.wy=wy; %y carrier FF
Lens.g=g; %distorted igram
Lens.gr=gr; %ref igram
Lens.Pxx=Pxx; 
Lens.Pxy=Pxy;
Lens.Pyy=Pyy;
Lens.S=S;
Lens.Seq=Seq;
Lens.C=C;
Lens.D=D;
Lens.px=px;
Lens.py=py;
Lens.s=s;
Lens.M=M;
Lens.phix=phix;
Lens.phiy=phiy;
Lens.dx=dx;
Lens.dy=dy;

