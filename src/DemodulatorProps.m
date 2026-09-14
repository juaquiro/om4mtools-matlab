classdef DemodulatorProps
    % DemodulatorProps enumeration of demodulator props
    
    enumeration
        M; % logical array which defines the ROI
        zList; %phasor cell array demodulated from the input cell array of Process()
        NL; %number of Lobes
        Tx; %period in px of the Fringe patterns generated for display
        Ty; %period in px of the Fringe patterns generated for display
        PSType; %for PS demodulators the type of PS filter user, for a detailed description of the properties see apendix A of FPA
        PSDir; %1==X vertial patterns, 2==Y horizontal patterns
        StepsTwoPwiRange; %two pi range in voiltage or angles necessaru for the generation of the phase steps
        z2alpha; %isoclinic phasor for retardation demodulation
        NIgrams; %number of igrams in temporal analysis methods
        TempAnalysisType; %type of tempral analisys method
        TempRange; %maximun range [0 TempRange] in voltage, degrees, load, exposure etc of the temporal variation, this is used togueter with NIgrams to ecide the phase steps
        TempVals; %cell array with the temeporal values voltage, degrees, load, exposure etc at which the Temporal series of images was aquired
        FFCut; %high pass cut to elliminate in FT based tempotal analysis in FF, default is 1 FF
        NFilt; %filter size for phasor and mask filtering, default 5 px
        ROINormTH; %normalized threshold [0 1] for ROI calculation. default 0.15
        deltaList; %phase steps list in rad for the LS phase demodulator             
        w0; %temporal/statial carrier freq      
        AbsolutePhasePSADemType; %PSA type used for absolute GCPSA demodulators
    end
end

