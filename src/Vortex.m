function s=Vortex(c, dir)
% Vortex vortex transform: computes the quadrature term of c corrected
% by the direction phase factor dir, so for a real c=b*cos(phi), s=b*sin(phi)
% (using orientation instead of direction instead gives
% s=b*sin(phi).*sign(sin(dir))). (Same algorithm as UtilFunFPA.Vortex.)
%
% Ref: Larkin, Bone & Oldfield, "Natural demodulation of two-dimensional
% fringe patterns. I. General background of the spiral phase quadrature
% transform," J. Opt. Soc. Am. A 18, 1862-1870 (2001)
try
   
    TH=max(abs(c(:)));
    if mean(real(c(:)))>0.01*TH
        warning('OM4M:SPHT:OutOfRange', ...
            'C must be DC filtered');
    end
    
    sd=SPHT(c);
    s=-1i.*exp(-1i*dir).*sd;
    
    [NR, NC]=size(c);
    if( sum(abs(imag(s(:))/(NR*NC)))>0.1 )
        warning('OM4M:Vortex:OutOfRange', ...
            'high imaginary part');
    end
    
    s=real(s);
            
catch ME
    throw(ME);
end