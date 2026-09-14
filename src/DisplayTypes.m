%> @file DisplayTypes.m
%> @brief Types of image projectors
%> @copyright 2019 IOT
%> @author SS 04/19

% ======================================================================
%> @brief this class implements the enumeration of display types
% ======================================================================
classdef DisplayTypes
    enumeration
        %> Java
        JavaDisp;
        %> Matlab figures
        Matlab;
        %> Psychtoolbox-3
        Psych;
        %> C++ dll interface
        CDLL;
    end
end

