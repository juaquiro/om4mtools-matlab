function vid = DFGUSB2Pro
%DFGUSB2PRO Code for creating a video input object.
%
%   This is generated using the imaqtool and modified to recover the vid form the name istead of the deviceID
%
%   Example:
%       vidobj = DFGUSB2Pro;
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
vidFormat = 'RGB24_768x576';
name='DFG/USB2pro';

vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% saved in the MAT-file to their default value.
set(vid, 'ErrorFcn', @imaqcallback);

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);
set(vid, 'ReturnedColorSpace', 'grayscale');

% Configure vid video source properties.
src = get(vid, 'Source');
%set(src(1), 'AnalogVideoFormat', 'pal_b');
