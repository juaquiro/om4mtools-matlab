classdef PathFollowerTypes
    % PathFollowerTypes enumeration of PathFollower kinds, used by
    % PathFollowerFactory.Create (see testFPAPathFollowerCQueue for unit tests)
    enumeration
        CQueue; % CQueue-based path follower (see PathFollowerCQueue)
    end
end