classdef test_Util_Logging < matlab.unittest.TestCase
    % test_Util_Logging tests OM4MClassLib.Util.Logging
    %run(test_Util_Logging)

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
        function testWhoCalledMe(testCase)
            % testWhoCalledMe checks Logging.WhoCalledMe() reports this
            % test method's own name and file as its caller
            %run(test_Util_Logging, 'testWhoCalledMe')
            %NOTE: WhoCalledMe() uses dbstack() to inspect its caller - as a
            %classdef Test method (rather than the original plain script
            %function) the name/file MATLAB reports here may differ; verify
            %this assertion in MATLAB after conversion.
            disp(Logging.WhoCalledMe())

            %ejemplo usando import
            import OM4MClassLib.Util.*;

            [funcName, fileName]=Logging.WhoCalledMe();

            testCase.assertTrue(strcmp(funcName, 'test_Util_Logging.testWhoCalledMe'))
            testCase.assertTrue(strcmp(fileName, 'test_Util_Logging.m'))
        end
    end
end
