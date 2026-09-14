
% This file is for testing the temporal demodulation of the retardation vs
% exposure response, we are looking for the best procedire of demodulation
% and unwrapping that permits the correct temporal demodulation despite low
% modulation zonez prodiced by a fast a sudden retardation change close to
% the end of the retardation curve delta(H)
% see https://en.wikipedia.org/wiki/Exposure_(photography)
classdef testTempAnalysisRetarExposure < matlab.unittest.TestCase
    %run(testTempAnalysisRetarExposition)
    
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            setupPath();
        end
    end
    
    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m), not MATLAB's factory path
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end
    
    
    methods (Test)
        function testPlotDeltaH4AllCells(testCase)
            %run(testTempAnalysisRetarExposure, 'testPlotDeltaH4AllCells')
            % para esta figura he usado el fichero
            % PerseusMedidas\ExperimentosPerseus\Photoalignment\Cells\Comparaci�n7_20_30_70_110\
            % deltaH-12-Jan-2017.mat
            % que se genero mediente el test
            % OM4MMatlabUtils\ClassLib\TestFPA\testTempAnalysisRetarExposure:testGetFFTRetarExposure4AllCells
            % el contenido esta explicado en README_deltaH
            S=load('deltaH-12-Jan-2017');
            
            figure;hold on;
            for n=1:length(S.deltaH);
                plot(S.deltaH(n).H/S.deltaH(n).d^1.3, S.deltaH(n).udelta/S.deltaH(n).d);
            end
            hold off;
            xlabel('H(s)'); ylabel('delta(H)/t')
            l=legend(S.deltaH.name);
            set(l, 'Position',[0.690476193083894 0.214285721097674 0.187499997392297 0.24920634239439]);
            grid on;
            title('normalized retardation by thickness');
        end
    end

end
