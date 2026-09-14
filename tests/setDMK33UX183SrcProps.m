function srcObj = setDMK33UX183SrcProps(vidObj)
%setDMK33UX183SrcProps set props for src of vidObj
%   This function Configures video source properties for DMK33UX183 vidObj
%   This function is a companion to the DMK33UX183Bin3_XX camera files
arguments
    % vidObj must be 1x1 videoinput
    vidObj (1, 1) {mustBeA(vidObj, 'videoinput')}
end

%get src
srcObj = get(vidObj, 'Source');

%set props
set(srcObj, 'Brightness', 50);
set(srcObj, 'Denoise', 0);
set(srcObj, 'Exposure', 0.1);
set(srcObj, 'ExposureAuto', 'Off');
set(srcObj, 'GainAuto', 'Off');
set(srcObj, 'Gain', 12.21);
end

