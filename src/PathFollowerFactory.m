classdef PathFollowerFactory
    % PathFollowerFactory static factory for PathFollower objects
    %
    % Description:
    %   See PathFollowerTypes for available types, testFPAPathFollowerCQueue
    %   for unit tests, and PathFollowerModes for path-follower modes.

    %% public methods
    methods(Static)
        function obj=Create(type, nLevels, qualityImage, roiMask, followMode)
            % Create returns a new PathFollower instance matching type (a
            % PathFollowerTypes enum value); errors if type is unknown/invalid
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            nameofClass='PathFollowerTypes';
            if not(isa(type, nameofClass))
                retErrorMsg=['Type must be of class ' nameofClass];
                error([callFunc '->' retErrorMsg]);
            end
            
            switch(type)
                case PathFollowerTypes.CQueue
                    obj=PathFollowerCQueue(nLevels, qualityImage, roiMask, followMode);
                otherwise
                    retErrorMsg=['type must be of class ' nameofClass];
                    error([callFunc '->' retErrorMsg]);
            end
        end
    end
end