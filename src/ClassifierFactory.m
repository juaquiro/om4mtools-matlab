classdef ClassifierFactory
    % ClassifierFactory static factory that builds a concrete Classifier
    % subclass from a ClassifierTypes enum value

    %% public methods
    methods(Static)
        % Create returns a new classifier instance matching type (a
        % ClassifierTypes enum value); errors if type is unknown/invalid
        function obj=Create(type)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                nameofClass='ClassifierTypes';
                if not(isa(type, nameofClass))
                    retErrorMsg=['Type must be of class ' nameofClass];
                    error([callFunc '->' retErrorMsg]);
                end
                
                switch(type)
                    case ClassifierTypes.LogR
                        obj=ClassifierLR();
                    case ClassifierTypes.NN
                        obj=ClassifierNN();
                    case ClassifierTypes.LinReg
                        obj=ClassifierLinReg();
                    case ClassifierTypes.Zernikes
                        obj=ClassifierZernikes();
                    case ClassifierTypes.Chebyshev
                        obj=ClassifierChebyshev();
                    case ClassifierTypes.NN1
                        obj=ClassifierNN1();          
                    case ClassifierTypes.SVM
                        obj=ClassifierSVM();
                    case ClassifierTypes.KmeansCluster
                        obj=ClassifierKmeansCluster();
                    otherwise
                        retErrorMsg=['type must be of class ' nameofClass];
                        error([callFunc '->' retErrorMsg]);
                end
                
            catch ME
                rethrow(ME);
            end
        end
    end
    
end

