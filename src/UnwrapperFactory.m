classdef UnwrapperFactory
    %UnwrapperFactory static factory
    
    %% public methods
    methods(Static)
        function obj=Create(type)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            nameofClass='UnwrapperTypes';
            if not(isa(type, nameofClass))
                retErrorMsg=['Type must be of class ' nameofClass];
                error([callFunc '->' retErrorMsg]);
            end
            
            switch(type)
                case UnwrapperTypes.Void
                    obj=UnwrapperVoid();
                case UnwrapperTypes.FlynMd
                    obj=UnwrapperFlynMd();
                otherwise
                    retErrorMsg=['type must be of class ' nameofClass];
                    error([callFunc '->' retErrorMsg]);
            end
        end
    end
end

