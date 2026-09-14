classdef testDemodulatorPropStore < matlab.unittest.TestCase
    %run(testDemodulatorPropStore)
    %test the class DemodulatorPropStore

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
        function testConstructor(testCase)
            %run(testDemodulatorPropStore, 'testConstructor')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            sm=DemodulatorPropStore();
            testCase.assertTrue(isa(sm, 'handle'));

            props=sm.Get();
            dataTypesCell=enumeration('DemodulatorProps');
            dataTypesNames=arrayfun(@char, dataTypesCell, 'UniformOutput', false);
            propsNames=fieldnames(props);

            %DemodulatorPropStore.Get() must expose exactly the DemodulatorProps
            %members, order not guaranteed (backed by containers.Map, sorted by key)
            testCase.assertEqual(sort(propsNames), sort(dataTypesNames));

            for n=1:length(propsNames)
                testCase.assertTrue(isempty(props.(propsNames{n})));
            end
        end

        function testSingleGetSet(testCase)
            %run(testDemodulatorPropStore, 'testSingleGetSet')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            sm=DemodulatorPropStore();

            Tx=20;
            sm.Set(char(DemodulatorProps.Tx), Tx);
            testCase.assertEqual(Tx, sm.Get(char(DemodulatorProps.Tx)));

            zList={1, ones(3), 'lolo'};
            sm.Set(char(DemodulatorProps.zList), zList);
            testCase.assertEqual(zList, sm.Get(char(DemodulatorProps.zList)));
        end

        function testMultipleGetSet(testCase)
            %run(testDemodulatorPropStore, 'testMultipleGetSet')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            sm=DemodulatorPropStore();

            Tx=20; Ty=40;
            props={char(DemodulatorProps.Tx), char(DemodulatorProps.Ty)};
            propVals={Tx, Ty};

            sm.Set(props, propVals);

            p=sm.Get(props);
            testCase.assertEqual(Tx, p{1});
            testCase.assertEqual(Ty, p{2});
        end

        function testSetRejectsInvalidValue(testCase)
            %run(testDemodulatorPropStore, 'testSetRejectsInvalidValue')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            sm=DemodulatorPropStore();

            testCase.verifyError(@() sm.Set(char(DemodulatorProps.Tx), 'not numeric'), 'MATLAB:validators:mustBeNumeric');
            testCase.verifyError(@() sm.Set(char(DemodulatorProps.NL), 3), 'MATLAB:validators:mustBeMember');

            %rejected Set must not have modified the store
            testCase.assertTrue(isempty(sm.Get(char(DemodulatorProps.Tx))));
        end

        function testSetUnknownPropNameErrors(testCase)
            %run(testDemodulatorPropStore, 'testSetUnknownPropNameErrors')
            import OM4MClassLib.Util.*;
            fprintf('\ntest %s...\n ',Logging.WhoCalledMe());

            sm=DemodulatorPropStore();
            testCase.verifyError(@() sm.Set('NotAProp', 1), 'DemodulatorProps:FromName:UnknownProp');
        end
    end
end
