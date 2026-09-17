classdef EnumAQ2 < int32
    % EnumAQ2 is a fixture enumeration (used by testPropsEnumList) with
    % non-contiguous integer values, since PropsEnumList (unlike
    % CellEnumList) places no restriction on the numerical index
    
    enumeration
        A(-1)
        B(20)
        C(30)
        n(4)
    end
    
end

