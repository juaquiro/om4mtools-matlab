classdef testCellEnumList < matlab.unittest.TestCase
    % testCellEnumList tests OM4MClassLib.DataStructs.CellEnumList
    %run(testCellEnumList)

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
        function testCellEnumListConstructor(testCase)
            % testCellEnumListConstructor checks a fresh CellEnumList
            % can immediately Set/Get a single EnumAQ1 member
            %run(testCellEnumList, 'testCellEnumListConstructor')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=CellEnumList('EnumAQ1');

            %un solo parametro
            y=rand(10, 11);
            sm.Set(EnumAQ1.B, y);
            Y=sm.Get(EnumAQ1.B);

            testCase.assertEqual(Y, y);
        end

        function testCellEnumListGetSetOneParameter(testCase)
            % testCellEnumListGetSetOneParameter checks Set/Get with a
            % single member, both as a bare value and wrapped in 1x1 cells
            %run(testCellEnumList, 'testCellEnumListGetSetOneParameter')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=CellEnumList('EnumAQ1');

            %un solo parametro
            y=rand(10, 11);
            sm.Set(EnumAQ1.B, y);
            Y=sm.Get(EnumAQ1.B);
            testCase.assertEqual(Y, y);

            %un solo parametro tipo cell
            y=rand(10, 11);
            a={y}; %measurements
            b={EnumAQ1.B}; %measurements types
            sm.Set(b, a);
            Y=sm.Get(b);
            testCase.assertEqual(Y{1}, a{1});
        end


        function testCellEnumListGetSet(testCase)
            % testCellEnumListGetSet checks Set/Get with single members
            % and with multiple members passed as matching cell arrays
            %run(testCellEnumList, 'testCellEnumListGetSet')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=CellEnumList('EnumAQ1');

            x=rand(11,23);
            z=rand(2, 6);
            n=1;

            %single EnumAQ1
            sm.Set(EnumAQ1.C, z);
            Z=sm.Get(EnumAQ1.C);
            testCase.assertEqual(Z, z);

            %first enumAQ1
            z=pi;
            sm.Set(EnumAQ1.A, z);
            Z=sm.Get(EnumAQ1.A);
            testCase.assertEqual(Z, z);



            a={x, z, n}; %measurements
            b={EnumAQ1.A, EnumAQ1.C, EnumAQ1.n}; %m,easurements types

            %multiple EnumAQ1
            sm.Set(b, a);
            c=sm.Get(b);

            testCase.assertEqual(c{1}, a{1});
            testCase.assertEqual(c{2}, a{2});
            testCase.assertEqual(c{3}, a{3});
        end

        function testCellEnumListGetAll(testCase)
            % testCellEnumListGetAll checks Get([]) returns every member's
            % value, indexable by each member's numeric value
            %run(testCellEnumList, 'testCellEnumListGetAll')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=CellEnumList('EnumAQ1');

            x=rand(11,23);
            z=rand(2, 6);
            n=1;

            %single EnumAQ1
            sm.Set(EnumAQ1.C, z);
            Z=sm.Get(EnumAQ1.C);
            testCase.assertEqual(Z, z);

            a={x, z, n}; %measurements
            b={EnumAQ1.A, EnumAQ1.C, EnumAQ1.n}; %m,easurements types

            %multiple EnumAQ1
            sm.Set(b, a);
            c=sm.Get([]);

            testCase.assertEqual(c{double(EnumAQ1.A)}, a{1});
            testCase.assertEqual(c{double(EnumAQ1.C)}, a{2});
            testCase.assertEqual(c{double(EnumAQ1.n)}, a{3});
        end
    end
end
