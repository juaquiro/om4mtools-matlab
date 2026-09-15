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
        %> C++ dll interface
        CDLL;
    end
end

