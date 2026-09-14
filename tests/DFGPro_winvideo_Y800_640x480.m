function vid = DFGPro_winvideo_Y800_640x480
%DFGUSB2PRO Code for creating a video input object.
%
%   This is generated using the imaqtool and modified to recover the vid form the name istead of the deviceID
%
%   Example:
%       vidobj = DFGPro_winvideo_Y800_720x576;
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
vidFormat = 'Y800_720x576';
name='DFG/USB2pro';

vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% saved in the MAT-file to their default value.
set(vid, 'ErrorFcn', @imaqcallback);

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);
set(vid, 'ReturnedColorSpace', 'grayscale');

% Configure vid video source properties.
src = get(vid, 'Source');
% Configure vidObj1's video source properties.
srcObj = get(vid, 'Source');

%set(srcObj(1),'AnalogVideoFormat', 'secam_l1');
set(srcObj(1), 'Brightness', 1);
set(srcObj(1), 'Contrast', 174);
set(srcObj(1), 'FrameRate', '25.0000');
set(srcObj(1), 'Hue', 0);
set(srcObj(1), 'Saturation', 127);
set(srcObj(1), 'Sharpness', 0);
