classdef testPropsEnumList < matlab.unittest.TestCase
    % testPropsEnumList tests OM4MClassLib.DataStructs.PropsEnumList and
    % the ClassWithProps IProps fixture built on top of it
    %run(testPropsEnumList)

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
        function testPropsEnumListConstructor(testCase)
            % testPropsEnumListConstructor checks a fresh PropsEnumList
            % is an IProps and Get() returns one field per EnumAQ2 member
            %run(testPropsEnumList, 'testPropsEnumListConstructor')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=PropsEnumList('EnumAQ2');
            testCase.assertTrue(isa(sm, 'IProps'));

            props=sm.Get();

            dataTypesCell=enumeration('EnumAQ2');
            propsNames=fieldnames(props);

            for n=1:length(propsNames)
                testCase.assertEqual(propsNames{n}, char(dataTypesCell(n)));
            end
        end

        function testPropsEnumListSingleGetSet(testCase)
            % testPropsEnumListSingleGetSet checks Set/Get for a single
            % EnumAQ2 member at a time, with numeric/matrix/cell values
            %run(testPropsEnumList, 'testPropsEnumListSingleGetSet')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=PropsEnumList('EnumAQ2');

            %check Get no parameters
            props=sm.Get();
            dataTypesCell=enumeration('EnumAQ2');
            propsNames=fieldnames(props);
            for n=1:length(propsNames)
                testCase.assertEqual(propsNames{n}, char(dataTypesCell(n)));
            end

            %check single set-get
            A=10;
            sm.Set(char(EnumAQ2.A), A);
            B=ones(3);
            sm.Set(char(EnumAQ2.B), B);
            C={1, ones(3), 'lolo'};
            sm.Set(char(EnumAQ2.C), C);

            AA=sm.Get(char(EnumAQ2.A));
            BB=sm.Get(char(EnumAQ2.B));
            CC=sm.Get(char(EnumAQ2.C));

            testCase.assertEqual(A, AA);
            testCase.assertEqual(B, BB);
            testCase.assertEqual(C, CC);
        end

        function testPropsEnumListMultipleGetSet(testCase)
            % testPropsEnumListMultipleGetSet checks Set/Get with
            % multiple EnumAQ2 members passed together as cell arrays
            %run(testPropsEnumList, 'testPropsEnumListMultipleGetSet')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            sm=PropsEnumList('EnumAQ2');

            %check Get no parameters
            props=sm.Get();
            dataTypesCell=enumeration('EnumAQ2');
            propsNames=fieldnames(props);
            for n=1:length(propsNames)
                testCase.assertEqual(propsNames{n}, char(dataTypesCell(n)));
            end

            %check multiple set-get
            A=10;
            B=ones(3);
            C={1, ones(3), 'lolo'};
            propVals={A, B, C};
            props={char(EnumAQ2.A), char(EnumAQ2.B), char(EnumAQ2.C)};

            sm.Set(props, propVals);

            p=sm.Get(props);
            AA=p{1};
            BB=p{2};
            CC=p{3};

            testCase.assertEqual(A, AA);
            testCase.assertEqual(B, BB);
            testCase.assertEqual(C, CC);
        end

        function testPropsEnumListClassWithProps(testCase)
            % testPropsEnumListClassWithProps checks ClassWithProps (an
            % IProps built on PropsEnumList/EnumPropsTypes) exposes its
            % P1/P2 default values, Add() uses them correctly, and both
            % single- and multi-value Set/Get work as expected
            %run(testPropsEnumList, 'testPropsEnumListClassWithProps')
            import OM4MClassLib.DataStructs.*;
            import OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());

            cwp=ClassWithProps();

            %check the interfaces
            testCase.assertTrue(isa(cwp, 'IProps'));
            testCase.assertTrue(isa(cwp, 'handle'));

            %check props names
            props=cwp.Get();
            dataTypesCell=enumeration('EnumPropsTypes');
            propsNames=fieldnames(props);
            for n=1:length(propsNames)
                testCase.assertEqual(propsNames{n}, char(dataTypesCell(n)));
            end

            %check props internal use
            a=10; b=20;
            P1=cwp.Get(char(EnumPropsTypes.P1));
            P2=cwp.Get(char(EnumPropsTypes.P2));
            s=cwp.Add(a, b);
            testCase.assertEqual(s, P1*a+P2*b)

            %check props default values single value
            P1=cwp.Get(char(EnumPropsTypes.P1));
            P2=cwp.Get(char(EnumPropsTypes.P2));
            testCase.assertEqual(P1, 1);
            testCase.assertEqual(P2, 2);

            %check props default values multiple values
            p=cwp.Get({char(EnumPropsTypes.P1), char(EnumPropsTypes.P2)});
            P1=p{1};
            P2=p{2};
            testCase.assertEqual(P1, 1);
            testCase.assertEqual(P2, 2);

            %check props values single value
            cwp.Set(char(EnumPropsTypes.P1), 10);
            cwp.Set(char(EnumPropsTypes.P2), 15);
            P1=cwp.Get(char(EnumPropsTypes.P1));
            P2=cwp.Get(char(EnumPropsTypes.P2));
            testCase.assertEqual(P1, 10);
            testCase.assertEqual(P2, 15);

            a=10; b=20;
            s=cwp.Add(a, b);
            testCase.assertEqual(s, P1*a+P2*b)

            %check props values multiple value
            PP1=pi;
            PP2=log(2);
            cwp.Set({char(EnumPropsTypes.P1), char(EnumPropsTypes.P2)}, {PP1, PP2});
            P1=cwp.Get(char(EnumPropsTypes.P1));
            P2=cwp.Get(char(EnumPropsTypes.P2));
            testCase.assertEqual(PP1, P1);
            testCase.assertEqual(PP2, P2);

            a=10; b=20;
            s=cwp.Add(a, b);
            testCase.assertEqual(s, P1*a+P2*b)
        end
    end
end
