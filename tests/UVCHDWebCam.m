function vid = UVCHDWebCam
%UVCHDWEBCAM Code for creating a video input object.
%   
%   This is the machine generated representation of a video input object.
%   This MATLAB code file, UVCHDWEBCAM.M, was generated from the OBJ2MFILE function.
%   A MAT-file is created if the object's UserData property is not 
%   empty or if any of the callback properties are set to a cell array  
%   or to a function handle. The MAT-file will have the same name as the 
%   code file but with a .MAT extension. To recreate this video input object,
%   type the name of the code file, UVCHDWebCam, at the MATLAB command prompt.
%   
%   The code file, UVCHDWEBCAM.M and its associated MAT-file, UVCHDWEBCAM.MAT (if
%   it exists) must be on your MATLAB path.
%   
%   Example: 
%       vidobj = UVCHDWebCam;
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
name='USB2.0 UVC HD Webcam';
vidFormat = 'MJPG_640x480';
vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% Configure vidObj1's video source properties.
srcVid = get(vid, 'Source');

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);
