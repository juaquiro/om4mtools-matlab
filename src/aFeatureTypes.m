classdef aFeatureTypes
    %FeaturePros
    %Types of props for aFeature
    
    enumeration
        Unknown;
        FeatureTest, %return the mean error and the std in the DPM, transmission mode (AQtest)
        DPMMeStd, %return the mean error and the std in the DPM.
        DPMMeStdZonal, %return the mean error and the std in a specified area of the DPM (whole geometric mask).
        DPMMeStdZonalISO, %return the mean error and the std in a specified area of the DPM (whole geometric mask), and applies the ISO table of tolerances
        DPMMeStdNRA, %return the mean error and the std in the Near Reference Area, and applies the ISO table of tolerances
        DPMMeStdDRA, %return the mean error and the std in the Distance Reference Area, and applies the ISO table of tolerances
        DPMMeStdIA, %return the mean error and the std in the Intermediate Area bewtween the NRA and the DRA, and applies the ISO table of tolerances
        DPMMeStdZonalISOParts, % Perform the calculations independently for the NRA, DRA and IA and concatenate the results
        PatternDetector, % Uses a trained CNN as feature extractor
    end
    
end