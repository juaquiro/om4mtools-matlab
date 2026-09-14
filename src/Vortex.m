function s=Vortex(c, dir)
%Vortex Vortex transform transform
% s=Vortex(c, dir) computes the quadrture term of c still corrected by
% the direction phase factor. Therefore for a real c=b*cos(phi)
% s=Vortex(c)=b*sin(phi). If we use orientation instead of direction we
% will obtain s=b*sin(phi).*sign(sin(dir))
% Ref: Kieran G. Larkin, Donald J. Bone, and Michael A. Oldfield, "Natural
% demodulation of two-dimensional fringe patterns. I. General background of the spiral phase quadrature transform," J. Opt. Soc. Am. A 18, 1862-1870 (2001) 

%   AQ, 19/8/09
%   Copyright 2009 OM4M
%   $ Revision: 1.0.0.0 $
%   $ Date: 19-08-2009 $

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