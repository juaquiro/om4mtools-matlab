function or=OrientationVortex(g)
%OrientationVortex computes orientation using the vortex transform
% or=OrientationVortex(g) computes the orientation angle [0, pi] of the
% fringe pattern g
% Ref: Kieran Larkin, "Uniform estimation of orientation using local and 
% nonlocal 2-D energy operators," Opt. Express 13, 8097-8121 (2005) 

%   AQ, 19/8/09
%   Copyright 2009 OM4M
%   $ Revision: 1.0.0.0 $
%   $ Date: 19-08-2009 $

try
   
    TH=max(abs(g(:)));
    if mean(real(g(:)))>0.01*TH
        warning('OM4M:OrientationVortex:OutOfRange', ...
            'input must be DC filtered');
    end
    
    sd=1i*SPHT(g);  %-b*exp(i*dir)*sin(phi)
    %if we do not conjugate orientation is cancelled instead of added
    ssd=1i*SPHT(conj(sd));%b*exp(2*i*dir)*cos(phi)
    
    exp2OrVor=-sd.^2+g.*ssd;

    or=mod(angle(sqrt(exp2OrVor))-pi/2, pi);   
        
catch ME
    throw(ME);
end