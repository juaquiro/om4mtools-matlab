classdef Logging
    % Logging is a static helper class for logging utilities
    %% static methods
    methods(Static)
        function [funcName, fileName]=WhoCalledMe()
            % WhoCalledMe returns the name/file of the function that
            % called the current function; useful for prefixing error
            % messages with the caller's name
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

