%> @file Logging.m
%> @brief this file contains utilities for logging
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16
%> @see test_Util_Logging.m

% ======================================================================
%> @brief static class helper for logging
% ======================================================================
classdef Logging
    %% static methods
    methods(Static)
        % ======================================================================
        %> @brief this function returns the name of the calling function
        %
        %> WhoCalledMe() returns the name of the current function that calls it. It
        %> is very usefull for logging calling funcion names in error messages
        %> @retval funcName calling function name
        %> @retval fileName calling file name
        % ======================================================================
        function [funcName, fileName]=WhoCalledMe()
            r=dbstack();
            if length(r)>1
                funcName=r(2).name;
                fileName=r(2).file;
            else
                funcName='base workspace';
            end
        end
    end
    
end

