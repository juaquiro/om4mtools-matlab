classdef aFeatureFactory
    %FeatureFactory static factory for classifiers
    
    %% public methods
    methods(Static)
        function obj=Create(type)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                nameofClass='aFeatureTypes';
                if not(isa(type, nameofClass))
                    retErrorMsg=['Type must be of class ' nameofClass];
                    error([callFunc '->' retErrorMsg]);
                end
                
                switch(type)
                    case {aFeatureTypes.FeatureTest,aFeatureTypes.Unknown}
                        obj=FeatureTest();
                    case aFeatureTypes.DPMMeStd
                        obj=FeatureDPMMeStd();
                    case aFeatureTypes.DPMMeStdZonal
                        obj=FeatureDPMMeStdZonal();
                    case aFeatureTypes.DPMMeStdNRA
                        obj=FeatureDPMMeStdNRA;
                    case aFeatureTypes.DPMMeStdDRA
                        obj=FeatureDPMMeStdDRA;
                    case aFeatureTypes.DPMMeStdIA
                        obj=FeatureDPMMeStdIA;
                    case aFeatureTypes.DPMMeStdZonalISO
                        obj=FeatureDPMMeStdZonalISO();
                    case aFeatureTypes.DPMMeStdZonalISOParts
                        obj=FeatureDPMMeStdZonalISOParts();
                    case aFeatureTypes.PatternDetector
                        obj=FeaturePatternDetector();
                    otherwise
                        retErrorMsg=['type must be of class ' nameofClass];
                        error([callFunc '->' retErrorMsg]);
                end
                
            catch ME
                throw(ME);
            end
        end
    end
    
end

