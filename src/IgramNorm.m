function [cn, m]=IgramNorm(c, R)
% IgramNorm normalizes interferogram c=b+m*cos(phi) into cn=cos(phi) and
% an estimated modulation m. R is the radius (in fringes/field) of the
% Gaussian DC filter used to remove the background b from c.
%
% Ref: Quiroga & Servin, "Isotropic n-dimensional fringe pattern
% normalization", Optics Communications, 224, 221-227 (2003)
try
    %filter DC with a gaussian
    [NR, NC]=size(c);
    [u,v]=meshgrid(1:NC, 1:NR);
    
    u0=floor(NC/2)+1; v0=floor(NR/2)+1;           
    u=u-u0; v=v-v0; 
    
    H=1-exp(-(u.^2+v.^2)/(2*R^2)); %Gaussian DC filter with sigma=R
    
    C=fft2(c);
    %H is already fftshifted from design, if fftshift is used instead, for even
    %dimensions there is no problem, however for odd dimensions fftshift(H)
    %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
    %see help for ifftshift
    CH=C.*ifftshift(H);
    
    ch=ifft2(CH);
    
    %compute quafrature
    s=abs(SPHT(ch));
    
    %normalized igram
    cn=cos(atan2(s,ch));
    %modulation
    m=abs(ch+1i*s);        
catch ME
    throw(ME);
end

function sd=SPHT(c)
% SPHT spiral phase transform: computes the quadrature term of c, still
% affected by the direction phase factor, so for a real c=b*cos(phi),
% sd=SPHT(c)=i*exp(i*dir)*b*sin(phi)
%
% Ref: Larkin, Bone & Oldfield, "Natural demodulation of two-dimensional
% fringe patterns. I. General background of the spiral phase quadrature
% transform," J. Opt. Soc. Am. A 18, 1862-1870 (2001)
try
    
    TH=max(abs(c(:)));
    if mean(real(c(:)))>0.01*TH
        warning('OM4M:SPHT:OutOfRange', ...
            'input must be DC filtered');
    end
    
    [NR, NC]=size(c);
    [u,v]=meshgrid(1:NC, 1:NR);
    u0=floor(NC/2)+1;
    v0=floor(NR/2)+1;       
    
    u=u-u0;
    v=v-v0;       
    
    H=(u+1i*v)./abs(u+1i*v);
    H(v0, u0)=0; %crop the nan
    
    C=fft2(c);
    %H is already fftshifted from design, if fftshift is used instead, for even
    %dimensions there is no problem, however for odd dimensions fftshift(H)
    %will place the frequency origin (u0,v0) in (1, NR) instead of (1,1)
    %see help for ifftshift
    CH=C.*ifftshift(H);
    
    %the complex conjugate is due to the changein sign for rows from xy 
    %(cartesian) to ij (pixel) systems that generates a change in the
    %sin(dir) signal in both systems
    sd=conj(ifft2(CH));               
        
catch ME
    throw(ME);
end