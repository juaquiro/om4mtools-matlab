%> @file DisplayFactory.m
%> @brief Factory of image projectors
%> @copyright 2019 IOT
%> @author SS 15/01/19

% ======================================================================
%> @brief static factory for the displays projectors
% ======================================================================
classdef DisplayFactory   
    %% public methods
    methods(Static)
        function obj=Create(type,varargin)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            nameofClass='DisplayTypes';
            if not(isa(type, nameofClass))
                retErrorMsg=['Type must be of class ' nameofClass];
                error([callFunc '->' retErrorMsg]);
            end
            
            switch(type)
                case DisplayTypes.JavaDisp
                    obj=DisplayProjector();
                case DisplayTypes.Matlab
                    %mirar que varargin sea como maximo 1 parametro
                    numvarargs = length(varargin);
                    if numvarargs == 1
                        obj=DisplayProjectorMatlab(varargin{1});
                    elseif numvarargs == 0
                        obj=DisplayProjectorMatlab();
                    else
                        error('Incorrect number of parameters');
                    end 
                case DisplayTypes.CDLL
                    %mirar que varargin sea como maximo 1 parametro
                    numvarargs = length(varargin);
                    if numvarargs == 1
                        obj=DisplayProjectorC(varargin{1});
                    elseif numvarargs == 0
                        obj=DisplayProjectorC();
                    else
                        error('Incorrect number of parameters');
                    end    
                otherwise
                    retErrorMsg=['type must be of class ' nameofClass];
                    error([callFunc '->' retErrorMsg]);
            end
        end
    end
end

