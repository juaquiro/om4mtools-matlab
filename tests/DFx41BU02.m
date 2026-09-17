function vid = DMx41BU02
% DFx41BU02 creates a video input object for the 'DFx 41BU02' camera via
% the winvideo adaptor, BY8 (1280x960).
%  Known bug: this function is named DMx41BU02 internally (same name as
% the unrelated DMx41BU02.m in this folder, for the 'DMx 41BU02'
% device), not DFx41BU02 as this file is named (still invocable as
% DFx41BU02() since MATLAB resolves by file name).
%
%   This is generated using the imaqtool and modified to recover the vid form the name istead of the
%
%   Example:
%       vidobj = DFx41BU02;
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

