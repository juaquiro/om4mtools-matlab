function vid = DMx41BU02
%DMX41BU02 Code for creating a video input object.
%   
%   This is generated using the imaqtool and modified to recover the vid form the name istead of the
%   
%   Example: 
%       vidobj = DMx41BU02;
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
vidFormat = 'BY8 _1280x960';
name='DFx 41BU02';

vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% saved in the MAT-file to their default value.
set(vid, 'ErrorFcn', @imaqcallback);

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);

% Configure vidObj1's video source properties.
src = get(vid, 'Source');
set(src(1), 'ExposureMode', 'manual');
set(src(1), 'GainMode', 'manual');

