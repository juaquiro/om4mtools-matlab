classdef IProps < handle
    %IPROPS Interface for objects with props
    % to use this interface add a PropsEnumList as a memeber of your class
    % and implement the Get and Set using the PropsEnumList object
    
    methods (Abstract=true)
        ret=Get(this, varargin);
        Set(this, props, values);
    end
    
end

