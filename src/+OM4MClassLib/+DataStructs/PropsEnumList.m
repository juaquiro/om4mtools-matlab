classdef PropsEnumList < OM4MClassLib.DataStructs.IProps
    %PROPSENUMLIST Propierties List
    %   This list is init by a enumeration and oly permited keys are the init enumeration
    %   To use this class inherint from IProps and include a PropsEnumList as a memeber of your class
    %   and implement the Get and Set using the PropsEnumList object
    
    %% private props
    properties
        mapObj; %containers.Map object
        dataTypes; %enumerated type
    end
    
    %% public methods
    methods
        function this=PropsEnumList(dataTypes)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            this.dataTypes=dataTypes;
            
            dataTypesCell=enumeration(this.dataTypes);
            if isempty(dataTypesCell)
                error([callFunc '->' 'dataTypes must be an enumeration'])
            end
            
            keySet=cell(size(dataTypesCell));
            for n=1:length(keySet)
                keySet{n}=char(dataTypesCell(n));
            end
            
            valueSet=cell(size(keySet));
            this.mapObj = containers.Map(keySet,valueSet);
        end
    end
    
    %% IProps methods
    methods
        % Get() returns a structure will all props and their values
        % Get(prop) with prop a value of the enumeration this.dataTypes
        % return the corresponding value
        % Get(Cell_array_of_prop) with prop a char-value of the enumeration this.dataTypes
        % return a cell array with the corresponding values
        function ret=Get(this, props)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                                
                switch nargin
                    case 1 %take into account "this" as a parameter
                        props=this.mapObj.keys;
                        propvals=this.mapObj.values;
                        ret=cell2struct(propvals', props);
                    case 2
                        if iscell(props)
                            ret=values(this.mapObj, props);
                        elseif ischar(props)
                            ret=this.mapObj(props);
                        else
                            error([callFunc '->props must be a cell_of_textprops array or a textprop with a valid value']);
                        end
                    otherwise
                        error([callFunc '->usage: Get(), Get(textprop) o Get(cell_of_textprops)']);
                end
                
                if nargout==0
                    disp(ret);
                end
                
            catch ME
                throw(ME)
            end
        end
        
        % Set(prop, propvals) with prop a value of the enumeration this.dataTypes
        % with the corresponding value
        % Set(Cell_array_of_prop, Cell_array_of_vals) with prop a char-value of the enumeration this.dataTypes
        % set the map with the corresponding values
        function this=Set(this, props, propvals)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                                
                if iscell(props)
                    for n=1:length(props)
                        this.mapObj(props{n})=propvals{n};
                    end
                elseif ischar(props)
                    this.mapObj(props)=propvals;
                else
                    error([callFunc '->props must be a cell_of_textprops array or a textprop with a valid value']);
                end
            catch ME
                throw(ME)
            end
        end
    end
    
end

