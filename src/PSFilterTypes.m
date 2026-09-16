classdef PSFilterTypes
    % PSFilterTypes enumeration of phase-shifting filter kinds, used by
    % DemodulatorTimePSA (see FPA book appendix A for full description)
    enumeration
        A0502; % A-5-2 5-step hariharan PSA (w0 = pi/2)
        PS4; % clasical four step (w0=pi/2)
    end
end

