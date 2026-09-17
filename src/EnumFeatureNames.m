classdef EnumFeatureNames
    % EnumFeatureNames enumeration of allowed ML feature names (error
    % metrics used as classifier inputs, see e.g. testMLClassifierLR)
    enumeration
        NoRegMeanTSeqErr,
        NoRegStdTSeqErr,
        NoRegMeanTCErr,
        NoRegStdTCErr,
        TrDx,
        TrDy,
        TrThetaRot,
        meanTSeqErr,
        StdTSeqErr,
        meanTCErr,
        StdTCErr,
        meanRSeqErr,
        StdRSeqErr,
        meanRCErr,
        StdRCErr      
    end
    
end