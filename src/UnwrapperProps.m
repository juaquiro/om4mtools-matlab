classdef UnwrapperProps
    % UnwrapperProps enumeration of unwrapper props
    
    enumeration
        bmask; %array which defines the ROI [0-1]
        qual; %quality map [0-1]
        phase; %phase map
        unw; %unwrapped phase map
        thresh_flag; %therhold the quality map
        fatten; %in px fatten the poitns with qual==0
    end
end

