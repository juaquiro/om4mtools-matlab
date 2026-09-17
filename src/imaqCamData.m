classdef imaqCamData
    % imaqCamData holds the data captured/computed by imaqCam.Capture
    % (frame or HDR map, luminance, undistorted coordinates, timing).
    % Preferred over a plain struct because it validates fields and
    % always exposes a fixed public property list (no dynamic fields)
     properties (Access=public) %GetAccess=public, SetAccess=public
        hImage; %handle of a image object is used for the preview function and the depicting of the results
        I; %frame or hdrMap
        L; %lumniance map for hdr in always in GV
        E; %irradiance (depending on contaxt it cam be on CCD or in a screen)
        X; %undistorted X coordinate for every pixel
        Y; %undistorted Y coordinate for every pixel
        imList; %cell array of images as the ones used in hdr imaging, in this case I will be the hdr radiance
        timeStamp; %time-date
        VideoResolution;
        exposureTimes; %array with the exposure times for hdr
        toneMap; %hdr tone map
    end
end
