classdef test_Util_Validation < matlab.unittest.TestCase
    %run(test_Util_Validation)
    %test_Util_Validation test the class Validation

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
        function test_all2str(testCase)
            %run(test_Util_Validation, 'test_all2str')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            %numeric
            v=45.4;
            vStr=Validation.all2str(v);
            testCase.assertEqual(vStr, '45.4');

            %char
            v='tolo';
            vStr=Validation.all2str(v);
            testCase.assertEqual(vStr, 'tolo');

            %cell
            v={'tolo', 4.5};
            vStr=Validation.all2str(v);
            testCase.assertEqual(vStr, 'tolo, 4.5');

            %struct
            clear v;
            v.l=4.5;
            v.k='tolo';
            vStr=Validation.all2str(v);
            testCase.assertEqual(vStr, '(structure)');

            %matrix
            clear v;
            v=ones(2);
            vStr=Validation.all2str(v);
            testCase.assertEqual(vStr, ['1  1';'1  1']);
        end

        function test_CheckInputParam(testCase)
            %run(test_Util_Validation, 'test_CheckInputParam')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            vList={'A', 'B', 'C'};
            v='A';
            r=Validation.CheckInputParam(v, vList);
            testCase.assertTrue(r);

            try
                felipe='D';
                r=Validation.CheckInputParam(felipe, vList);
            catch ME
                testCase.assertEqual(ME.message, 'Validation.CheckInputParam->felipe has invalid value: D');
            end

            vList={'A'};
            try
                felipe='D';
                r=Validation.CheckInputParam(felipe, vList);
            catch ME
                testCase.assertEqual(ME.message, 'Validation.CheckInputParam->felipe has invalid value: D');
            end

            %list of different types
            vList={1, ones(2), 'tete'};
            v=ones(2);
            r=Validation.CheckInputParam(v, vList);
            testCase.assertTrue(r);

            try
                paco=ones(3);
                r=Validation.CheckInputParam(paco, vList);
            catch ME
                testCase.assertEqual(ME.message, 'Validation.CheckInputParam->paco has invalid value: 111      111      111');
            end
        end

        function test_mustBeEqualSize(testCase)
            %run(test_Util_Validation, 'test_mustBeEqualSize')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            v1=ones(10, 11);
            v2=rand(10, 11);

            Validation.mustBeEqualSize(v1,v2);

            try
                v2=rand(10, 12);
                Validation.mustBeEqualSize(v1,v2);
            catch ME
                testCase.assertEqual(ME.message, 'Validation.mustBeEqualSize->Size of first input must equal size of second input.');
                testCase.assertEqual(ME.identifier,'Size:notEqual');
            end
        end
    end
end
