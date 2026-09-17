classdef DisplayTypes
    % DisplayTypes enumeration of display projector kinds, used by
    % DisplayFactory.Create
    enumeration
        JavaDisp; % Java-based (DisplayProjector)
        Matlab; % MATLAB figure-based (DisplayProjectorMatlab)
        CDLL; % C++ DLL-based (DisplayProjectorC)
    end
end

