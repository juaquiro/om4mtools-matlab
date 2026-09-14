%> @file PathFollowerTypes.m
%> @brief PathFollowerTypes enum
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16

% ======================================================================
%> @brief enumeration of PathFollower types
%> @see testFPAPathFollowerCQueue for unit tests
%> @see CQueue PathFollowerCQueue PathFollowerModes for modes of path follower
% ======================================================================
classdef PathFollowerTypes   
    enumeration
        %> this PathFollower is based in the CQueue class       
        CQueue; 
    end
end