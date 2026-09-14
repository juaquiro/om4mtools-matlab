%> @file PathFollowerModes.m
%> @brief PathFollowerModes enum
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16


% ======================================================================
%> @brief enumeration with the diferent PathFollowerModes
%> @details The different modes calculate in a diffrent way the qualityMap
% of a PathFollower
%> @see PathFollowerTypes for avalible path follower types
%> @see PathFollowerFactory for a static factory
%> @see testFPAPathFollowerCQueue for unit tests
%> @see PathFollowerModes for modes of path follower
%> @see look for "Quality Map" in Servin, M., Quiroga, J. A., & Padilla, M. (2014). Fringe Pattern Analysis for Optical Metrology: Theory, Algorithms, and Applications. Wiley vch
% ======================================================================
classdef PathFollowerModes 
    enumeration
        %> the image is the quality mao
        image; 
        
        %> abs(image) is the quualitymap
        abs; 
        
        %> abs(grad(image))
        absgrad; 
        
        %> abs(del2(image))
        absdel2; 
        
        %> distance to the mask, innner points the better
        distance2Mask; 
        
        %> distance to the mask modulated by the image
        dist2MaskImage; 
    end
end

