function vid = DFGPro_tisimaq_r2013_64_PALB_Y800_720x576
%DFGUSB2PRO Code for creating a video input object.
%
%   This is generated using the imaqtool and modified to recover the vid form the name istead of the deviceID
%
%   Example:
%       vidobj = DFGPro_tisimaq_r2013_64_PALB_Y800_720x576;
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
adaptorName = 'tisimaq_r2013_64';
vidFormat = 'PAL_B:Y800 (720x576)';
name='DFG/USB2pro';

vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% saved in the MAT-file to their default value.
set(vid, 'ErrorFcn', @imaqcallback);

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);
set(vid, 'ReturnedColorSpace', 'grayscale');
% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);

% Configure vidObj1's video source properties.
srcObj = get(vid, 'Source');
set(srcObj(1), 'Brightness', -40);
set(srcObj(1), 'Contrast', 174);
set(srcObj(1), 'FrameRate', 25);
set(srcObj(1), 'Hue', 0);
set(srcObj(1), 'Saturation', 127);
set(srcObj(1), 'Sharpness', 0);
set(srcObj(1), 'SignalDetected', 'Enable');

% Configure vid video source properties.
src = get(vid, 'Source');
