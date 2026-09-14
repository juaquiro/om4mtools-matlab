function vid = DFK24UJ003
%DFK24UJ003POLI Code for creating a video input object.
%   
%   This is the machine generated representation of a video input object.
%   This MATLAB code file, DFK24UJ003POLI.M, was generated from the OBJ2MFILE function.
%   A MAT-file is created if the object's UserData property is not 
%   empty or if any of the callback properties are set to a cell array  
%   or to a function handle. The MAT-file will have the same name as the 
%   code file but with a .MAT extension. To recreate this video input object,
%   type the name of the code file, DFK24UJ003Poli, at the MATLAB command prompt.
%   
%   The code file, DFK24UJ003POLI.M and its associated MAT-file, DFK24UJ003POLI.MAT (if
%   it exists) must be on your MATLAB path.
%   
%   Example: 
%       vidobj = DFK24UJ003Poli;
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
name='DFK 24UJ003';
vidFormat = 'RGB32_3872x2764';
tag = '';

vid=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% Configure vidObj1 properties.
set(vid, 'FramesPerTrigger', 1);

% Configure vidObj1's video source properties.
src = get(vid, 'Source');
set(src(1), 'Exposure', -4);
set(src(1), 'ExposureMode', 'manual');
set(src(1), 'Gain', 130);
set(src(1), 'GainMode', 'manual');
