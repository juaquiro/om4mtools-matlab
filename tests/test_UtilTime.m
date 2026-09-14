classdef test_UtilTime < matlab.unittest.TestCase
    %run(test_UtilTime)
    %test the class UtilTime

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
        function testWaitForNSeconds(testCase)
            %run(test_UtilTime, 'testWaitForNSeconds')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            UtilTime.WaitForNSeconds(10, 'Initializing');
        end
    end
end
