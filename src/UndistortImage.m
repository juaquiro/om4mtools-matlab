function Iu=UndistortImage(I,CameraCal)
% UndistortImage undistorts image I (must be uint8) using the
% calibration data (KK, fc, kc, cc, alpha_c) stored in CameraCal
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