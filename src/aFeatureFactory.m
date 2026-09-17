classdef aFeatureFactory
    % aFeatureFactory static factory that builds a concrete aFeature
    % subclass from an aFeatureTypes enum value
    %
    % Note: only aFeatureTypes.FeatureTest/Unknown resolve to a class
    % that actually exists in this repo (FeatureTest) - the other 7
    % enum cases (DPMMeStd, DPMMeStdZonal, DPMMeStdNRA, DPMMeStdDRA,
    % DPMMeStdIA, DPMMeStdZonalISO, DPMMeStdZonalISOParts,
    % PatternDetector) dispatch to classes that were never migrated
    % from om4mmatlabutils and don't exist here, so Create() will error
    % with "Unrecognized function or class" for those types (verified
    % 2026-09-17, not fixed - see TODO.md, silent-gap audit not pursued).

    %% public methods
    methods(Static)
        function obj=Create(type)
            % Create returns a new aFeature instance matching type (an
            % aFeatureTypes enum value) - see the class-level note above
            % for which types actually work
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

