classdef EnumAQ1 < int32
    % EnumAQ1 is a fixture enumeration (used by testCellEnumList) with
    % contiguous 1..n integer values, as CellEnumList requires, so
    % return values can be checked symbolically against the enumeration
    
    enumeration
        A(1)
        B(2)
        C(3)
        n(4)
    end
    
end

