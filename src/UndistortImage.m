% UndistortImage undistort the input image I
% Iu=UndistortImage(I,CameraCal) undistort the image I using
% calibration data of calibration file CameraCal

%   AQ, V0 18/2/10 proyecto peces
%   AQ, V1 12/5/11
%   Copyright 2009 OM4M
%   $ Revision: 2.0.0.0 $
%   $ Date: 12/5/11 $
function Iu=UndistortImage(I,CameraCal)
callFunc=OM4MClassLib.Util.Logging.WhoCalledMe();

try
    if(not(isa(I, 'uint8')))
        retErrorMsg='input image must be uint8';
        error(['OM4M:' callFunc], ...
            [callFunc ' generated an error: ' retErrorMsg]);
    end
    
    
    load(CameraCal, 'KK', 'fc', 'kc', 'cc', 'alpha_c'); %camera internal parameters
    Iu=uint8(rect(double(I), eye(3), fc, cc, kc, alpha_c, KK));
catch ME
    throw(ME)
end