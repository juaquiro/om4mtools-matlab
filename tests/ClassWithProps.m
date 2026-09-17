classdef ClassWithProps < handle & OM4MClassLib.DataStructs.IProps
    % ClassWithProps is a minimal IProps-implementing fixture class,
    % used by testPropsEnumList to exercise Get/Set on a PropsEnumList
    % member (props P1/P2 from EnumPropsTypes)
    
    properties (Access=private)
        props;
    end
    
    %public methods
    methods
        function this=ClassWithProps()
            % ClassWithProps constructs the fixture with P1=1, P2=2
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('EnumPropsTypes');
            this.props.Set(char(EnumPropsTypes.P1), 1);
            this.props.Set(char(EnumPropsTypes.P2), 2);
        end
        
        function c=Add(this, a, b)
            % Add returns P1*a+P2*b, using the current P1/P2 props
            P1=this.props.Get(char(EnumPropsTypes.P1));
            P2=this.props.Get(char(EnumPropsTypes.P2));
            c=P1*a+P2*b;
        end
        
    end
    
    methods
        function ret=Get(this, props)
            % Get delegates to this.props.Get (IProps interface)
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end
        
        function this=Set(this, props, propvals)
            % Set delegates to this.props.Set (IProps interface)
            this.props.Set(props, propvals);
        end
    end
    
end

