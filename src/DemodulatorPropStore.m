%> @file DemodulatorPropStore.m
%> @brief typed key/value store backing Demodulator's props member
%> @details NA
%> @copyright 2026 IOT
%> @author AQ


% ======================================================================
%> @brief this class implements the Demodulator abstract interface's storage
%> @details replaces the generic OM4MClassLib.DataStructs.PropsEnumList this
%> class used to delegate to. Keys are DemodulatorProps enum members (as
%> char); every Set() is typechecked against that member's ValidationFcn
%> @see DemodulatorProps
% ======================================================================
classdef DemodulatorPropStore < handle

    %% props
    %private
    properties (Access = private)
        %> containers.Map backing store, one entry per DemodulatorProps member
        mapObj;
    end

    %% public methods
    methods
        function this = DemodulatorPropStore()
            allNames = arrayfun(@char, enumeration('DemodulatorProps'), 'UniformOutput', false);
            this.mapObj = containers.Map(allNames, cell(size(allNames)));
        end

        % ======================================================================
        %> @brief Get() returns a struct with all props and their values
        %> Get(prop) with prop a char value of DemodulatorProps returns the
        %> corresponding value. Get(cell_array_of_prop) returns a cell array
        %> with the corresponding values
        % ======================================================================
        function ret = Get(this, props)
            switch nargin
                case 1
                    keys = this.mapObj.keys;
                    vals = this.mapObj.values;
                    ret = cell2struct(vals', keys);
                case 2
                    if iscell(props)
                        ret = values(this.mapObj, props);
                    elseif ischar(props)
                        ret = this.mapObj(props);
                    else
                        error('DemodulatorPropStore:Get:InvalidInput', 'props must be a cell array of char prop names or a char prop name');
                    end
                otherwise
                    error('DemodulatorPropStore:Get:InvalidUsage', 'usage: Get(), Get(propName) or Get(cellOfPropNames)');
            end
        end

        % ======================================================================
        %> @brief Set(prop, propval) typechecks propval against DemodulatorProps.(prop)
        %> and stores it. Set(cell_of_props, cell_of_propvals) does the same for
        %> several props at once
        % ======================================================================
        function this = Set(this, props, propvals)
            if iscell(props)
                for n = 1:length(props)
                    this.SetOne(props{n}, propvals{n});
                end
            elseif ischar(props)
                this.SetOne(props, propvals);
            else
                error('DemodulatorPropStore:Set:InvalidInput', 'props must be a cell array of char prop names or a char prop name');
            end
        end
    end

    %% private methods
    methods (Access = private)
        function SetOne(this, propName, propval)
            DemodulatorProps.FromName(propName).CheckValue(propval);
            this.mapObj(propName) = propval;
        end
    end

end
