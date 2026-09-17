function out = DMK33UX183Bin3_2
% DMK33UX183Bin3_2 creates a video input object for the SECOND of several
% DMK 33UX183 cameras connected (device name 'DMK 33UX183 1'), via the
% tisimaq_r2013_64 adaptor, Y800 (1824x1216) [Binning 3x]
%
%   This is the machine generated representation of a video input object.
%   This MATLAB code file, DMK33UX183BIN3.M, was generated from the OBJ2MFILE function.
%   A MAT-file is created if the object's UserData property is not 
%   empty or if any of the callback properties are set to a cell array  
%   or to a function handle. The MAT-file will have the same name as the 
%   code file but with a .MAT extension. To recreate this video input object,
%   type the name of the code file, DMK33UX183Bin3, at the MATLAB command prompt.
%   
%   The code file, DMK33UX183BIN3.M and its associated MAT-file, DMK33UX183BIN3.MAT (if
%   it exists) must be on your MATLAB path.
%   
%   Example: 
%       vidobj = DMK33UX183Bin3;
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
name='DMK 33UX183 1';
vidFormat = 'Y800 (1824x1216) [Binning 3x]';

% check if TIS IMAQ DLL is registered
% deletes any image acquisition objects that exist in memory and unloads all adaptors loaded by the toolbox. As a result, the image acquisition hardware is reset.
S=imaqhwinfo; %look for installed adaptors
if not(any(strcmp(S.InstalledAdaptors,adaptorName))) %if dll is not registered register it
    filename='C:\\Program Files (x86)\\TIS IMAQ for MATLAB R2013b\\x64\\TISImaq_R2013_64.dll';
    if not(exist(filename, 'file'))
        error('imaqcam:dllNotInstaled',...
            'Error.TIS imaq dll adapter: %s, not located',...
            filename);
    end
    
    % AQVERVOSE
    fprintf('TIS IMAQ DLL %s\n', filename);
    
    imaqregister(filename);
    imaqreset; %deletes any image acquisition objects that exist in memory and unloads all adaptors loaded by the toolbox. As a result, the image acquisition hardware is reset.
    % AQVERVOSE
    fprintf('TISImaq_R2013_64.dll registrada\n');    
end

%get camera
objs = imaqhwinfo(adaptorName);

fprintf('Camara %s detectada\n', objs.DeviceInfo.DeviceName);
objs
fprintf('Device Info\n');
objs.DeviceInfo

% Search for existing video input objects.
vidObj=imaqCam.getVidFromName(adaptorName, name, vidFormat);

% Configure vidObj1 properties.
set(vidObj, 'FramesPerTrigger', 1);

% AQVERVOSE
fprintf('Video Object from cam\n');
vidObj
fprintf('Video Object resolution\n');
vidObj.VideoResolution

% AQVERVOSE
fprintf('video inpunt object inicializado\n');

% Configure video source properties.
srcObj = setDMK33UX183SrcProps(vidObj);

% AQVERVOSE
fprintf('Source Object\n');
srcObj

fprintf('video source properties initialized\n');

% END INIT CAMERA
out = vidObj ;