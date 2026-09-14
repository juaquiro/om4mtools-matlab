classdef ClassWithProps < handle & OM4MClassLib.DataStructs.IProps
    %CLASSWITHPROPS this class implementes the IProps interface
    %this class inherits from handle and implements interface IProps
    
    properties (Access=private)
        props;
    end
    
    %public methods
    methods
        function this=ClassWithProps()
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('EnumPropsTypes');
            this.props.Set(char(EnumPropsTypes.P1), 1);
            this.props.Set(char(EnumPropsTypes.P2), 2);
        end
        
        function c=Add(this, a, b)
            P1=this.props.Get(char(EnumPropsTypes.P1));
            P2=this.props.Get(char(EnumPropsTypes.P2));
            c=P1*a+P2*b;
        end
        
    end
    
    %IProps interface
    %check Get implementation¡¡
    methods               
        % Get interface, note the no parameter
        function ret=Get(this, props)
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end
        
        %Set interface
        function this=Set(this, props, propvals)
            this.props.Set(props, propvals);
        end
    end
    
end

