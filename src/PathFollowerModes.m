classdef PathFollowerModes
    % PathFollowerModes enumeration of ways to compute a PathFollower's
    % quality map from its quality image (see PathFollower.ComputeQualityMap)
    enumeration
        image; % the raw image is the quality map
        abs; % abs(image) is the quality map
        absgrad; % abs(gradient(image))
        absdel2; % abs(del2(image)), the discrete Laplacian
        distance2Mask; % distance to the mask edge, inner points score higher
        dist2MaskImage; % distance to the mask edge, modulated by the image
    end
end

