classdef testDemodulatorProps < matlab.unittest.TestCase
    %run(testDemodulatorProps)
    %test the class DemodulatorProps

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
        function testCheckValueAcceptsValidValues(testCase)
            %run(testDemodulatorProps, 'testCheckValueAcceptsValidValues')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            %numeric prop
            DemodulatorProps.Tx.CheckValue(20);

            %member-restricted prop
            DemodulatorProps.NL.CheckValue(2);
            DemodulatorProps.NL.CheckValue(4);

            %cell-typed prop
            DemodulatorProps.zList.CheckValue({1, 2, 3});

            %class-typed prop
            DemodulatorProps.PSType.CheckValue(PSFilterTypes.A0502);
            DemodulatorProps.AbsolutePhasePSADemType.CheckValue(DemodulatorTypes.LSPSA);

            %prop with no ValidationFcn accepts anything
            DemodulatorProps.TempAnalysisType.CheckValue('whatever');
        end

        function testCheckValueRejectsInvalidValues(testCase)
            %run(testDemodulatorProps, 'testCheckValueRejectsInvalidValues')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            testCase.verifyError(@() DemodulatorProps.Tx.CheckValue('not numeric'), 'MATLAB:validators:mustBeNumeric');
            testCase.verifyError(@() DemodulatorProps.NL.CheckValue(3), 'MATLAB:validators:mustBeMember');
            testCase.verifyError(@() DemodulatorProps.zList.CheckValue([1 2 3]), 'MATLAB:validators:mustBeA');
            testCase.verifyError(@() DemodulatorProps.PSType.CheckValue('A0502'), 'MATLAB:validators:mustBeA');
        end

        function testUnitMetadata(testCase)
            %run(testDemodulatorProps, 'testUnitMetadata')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            testCase.assertEqual(DemodulatorProps.Tx.Unit, 'px');
            testCase.assertEqual(DemodulatorProps.Ty.Unit, 'px');
            testCase.assertEqual(DemodulatorProps.deltaList.Unit, 'rad');
            testCase.assertEqual(DemodulatorProps.NL.Unit, '');
        end

        function testFromName(testCase)
            %run(testDemodulatorProps, 'testFromName')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            member = DemodulatorProps.FromName('Tx');
            testCase.assertEqual(member, DemodulatorProps.Tx);

            testCase.verifyError(@() DemodulatorProps.FromName('NotAProp'), 'DemodulatorProps:FromName:UnknownProp');
        end

        function testEveryMemberHasAName(testCase)
            %run(testDemodulatorProps, 'testEveryMemberHasAName')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            allMembers = enumeration('DemodulatorProps');
            for n = 1:length(allMembers)
                roundTripped = DemodulatorProps.FromName(char(allMembers(n)));
                testCase.assertEqual(roundTripped, allMembers(n));
            end
        end
    end
end
