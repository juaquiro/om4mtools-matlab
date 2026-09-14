%> @file PathFollowerFactory.m
%> @brief NA
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16


% ======================================================================
%> @brief static factory for PathFollower objetcs
%> @see PathFollowerTypes for avalible path follower types
%> @see testFPAPathFollowerCQueue for unit tests
%> @see PathFollowerModes for modes of path follower
% ======================================================================
classdef PathFollowerFactory
    
    %% public methods
    methods(Static)
        % ======================================================================
        %> @brief static factory Create method
        %> @param type PathFollowerTypes
        %> @param nLevels Quality map number of levels
        %> @param qualityImage Quality image to guide the process
        %> @param roiMask ROU
        %> @param followMode see PathFollowerModes
        %> @return instance of a PathFollower
        % ======================================================================
        function obj=Create(type, nLevels, qualityImage, roiMask, followMode)
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