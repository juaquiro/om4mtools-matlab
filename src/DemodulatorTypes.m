classdef DemodulatorTypes
    %DemodulatorType enumeration of demodulator types
    %for testing purpouses use same name than class
    
    enumeration
        FT; % Fourier transform
        Void; %dummy only for testing purpouses
        TimePSA; %default temporal PSA check DemodulatorTimePSA->Init for details
        RetarPSA; %8 step PSA method for retardation in polarimetry
        RetarPSA6Step; %6 step PSA method for retardation in polarimetry
        FTTempAnalysis; %FT temporal analysis of 2D sigmals
        LSPSA; %temporal Least Squares of 2D signals
        LSEquispacedPSA; %temporal Least Squares with eqquispaced phase shifts in the range [0, 2*pi*(1-1/N)]
        PSA6MultiplexedXY; %temporal PSA 6 steps  XY multiplexed
        GrayCode; %demodulador de codigos gray code 
        GCPSA; %Absolute phase combining PSA and GC
    end
end

