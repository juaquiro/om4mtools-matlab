classdef PropsEnumList < OM4MClassLib.DataStructs.IProps
    % PropsEnumList is a key/value properties list (backed by
    % containers.Map) whose only permitted keys are the members of the
    % enumeration it is constructed with. To use it, inherit from IProps,
    % add a PropsEnumList as a class member, and implement Get/Set by
    % delegating to this object's Get/Set
    
    %% private props
    properties
        mapObj; %containers.Map object
        dataTypes; %enumerated type
    end
    
    %% public methods
    methods
        function this=PropsEnumList(dataTypes)
            % PropsEnumList constructs a props list keyed by every
            % member of the dataTypes enumeration (name of the
            % enumeration class), each initialized to an empty value
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
        function ret=Get(this, props)
            % Get() returns a struct with all props and their values.
            % Get(prop), prop a char value of the enumeration
            % this.dataTypes, returns the corresponding value.
            % Get(cellOfProps) returns a cell array of the corresponding
            % values
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
        
        function this=Set(this, props, propvals)
            % Set(prop, propvals), prop a char value of the enumeration
            % this.dataTypes, stores propvals under prop.
            % Set(cellOfProps, cellOfVals) stores each value under its
            % matching prop by position
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

