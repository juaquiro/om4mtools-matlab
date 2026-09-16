classdef DemodulatorFactory
    % DemodulatorFactory static factory that builds a concrete
    % Demodulator subclass from a DemodulatorTypes enum value

    %% public methods
    methods(Static)
        function obj=Create(type)
            % Create returns a new demodulator instance matching type (a
            % DemodulatorTypes enum value); errors if type is unknown/invalid
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            nameofClass='DemodulatorTypes';
            if not(isa(type, nameofClass))
                retErrorMsg=['Type must be of class ' nameofClass];
                error([callFunc '->' retErrorMsg]);
            end
            
            switch(type)
                case DemodulatorTypes.Void
                    obj=DemodulatorVoid();
                case DemodulatorTypes.FT
                    obj=DemodulatorFT();
                case DemodulatorTypes.TimePSA
                    obj=DemodulatorTimePSA();
                case DemodulatorTypes.RetarPSA
                    obj=DemodRetarPolPS();
                case DemodulatorTypes.RetarPSA6Step
                    obj=DemodRetarPolPS6Step();
                case DemodulatorTypes.FTTempAnalysis
                    obj=DemodulatorFTTempAnalysis();
                case DemodulatorTypes.LSPSA
                    obj=DemodulatorLSPSA();
                case DemodulatorTypes.LSEquispacedPSA
                    obj=DemodulatorLSEquispacedPSA();
                case DemodulatorTypes.PSA6MultiplexedXY
                    obj=DemodulatorPSA6MultiplexedXY();
                case DemodulatorTypes.GrayCode
                    obj=DemodulatorGC();
                case DemodulatorTypes.GCPSA
                    obj=DemodulatorGCPSA();
                    
                otherwise
                    retErrorMsg=['type must be of class ' nameofClass];
                    error([callFunc '->' retErrorMsg]);
            end
        end
    end
end

