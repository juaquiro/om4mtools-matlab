function vid = DFK31BF03Z
% DFK31BF03Z creates a video input object for the DFx 31BF03-Z camera
% (device name has a hyphen, function name does not) via the winvideo
% adaptor, BY8 (1024x768).
%
%   This is the machine generated representation of a video input object.
%   This MATLAB code file, DFK31BF03Z.M, was generated from the OBJ2MFILE function.
%   A MAT-file is created if the object's UserData property is not
%   empty or if any of the callback properties are set to a cell array
%   or to a function handle. The MAT-file will have the same name as the
%   code file but with a .MAT extension. To recreate this video input object,
%   type the name of the code file, DFK31BF03Z, at the MATLAB command prompt.
%
%   The code file, DFK31BF03Z.M and its associated MAT-file, DFK31BF03Z.MAT (if
%   it exists) must be on your MATLAB path.
%
%   Example:
%       vidobj = DFK31BF03Z;
%   
%   See also VIDEOINPUT, IMAQDEVICE/PROPINFO, IMAQHELP, PATH.
%   

% Check if we can check out a license for the Image Acquisition Toolbox.
canCheckoutLicense = license('checkout', 'Image_Acquisition_Toolbox');

% Check if the Image Acquisition Toolbox is installed.
isToolboxInstalled = exist('videoinput', 'file');

if ~(canCheckoutLicense && isToolboxInstalled)
    % Toolbox could not be checked out or toolbox is not installed.
    error(message('imaq:obj2mfile:invalidToolbox'));
end


% Device Properties.
adaptorName = 'winvideo';
name='DFx 31BF03-Z';
deviceID = 1;
vidFormat = 'BY8 _1024x768';
tag = '';

vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);

% Configure vidObj1's video source properties.
src = get(vid, 'Source');
set(src(1), 'IrisMode', 'manual');
set(src(1), 'Zoom', 14);
set(src(1), 'Focus', 228);
set(src(1), 'Saturation', 123);


set(src(1), 'WhiteBalanceMode', 'manual');
set(src(1), 'WhiteBalance', 48);

