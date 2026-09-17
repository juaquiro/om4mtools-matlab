classdef imaqCamProps
    % imaqCamProps enumerates the allowed props for imaqCam's IProps
    % interface (this.props, get/set via Get/Set)
    enumeration
            detectCornerParams; %this is a struct with relevant corner detection params            
            drawObject; %drawing object (it is vision.ShapeInserter) for drawing shapes in a frame see the detect corners callback     
            maxExpVal; %maximum exposure time in seconds for HDR capture
            hdrCalFile; %hdr rasdiometric calibratioon file, see Capture()      
            geomCalFile; %distortion and camera calibration, intrinsic and extrinsic param
    end 
    
end
    

