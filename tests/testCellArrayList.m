classdef testCellArrayList < matlab.unittest.TestCase
    %run(testCellArrayList)
    %
    % Converted from an interactive cell-mode demo script (MathWorks,
    % "Step through and execute this script cell-by-cell") into a real
    % matlab.unittest suite. matlab.unittest.TestSuite.fromFolder was
    % picking the old script up as a "script-based test" (each %% section
    % as a pseudo-test) by accident -- each section ran with a fresh
    % workspace, so state from one section (e.g. myList created in
    % "Create Instance") never reached the next, and every section past
    % the first errored. See DECISIONS.md, "Fase 3 -- primera pasada de
    % estandarizacion y baseline".
    %
    % Coverage mirrors the original walkthrough's scenarios; see
    % CellArrayList.m for the class itself.

    properties
        myList
    end

    methods(TestMethodSetup)
        function SetUp(testCase)
            setupPath();
            testCase.myList = OM4MClassLib.DataStructs.CellArrayList();
        end
    end

    methods(TestMethodTeardown)
        function TearDown(testCase)
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end

    methods(Test)
        function testNewListIsEmpty(testCase)
            testCase.assertTrue(testCase.myList.isempty());
            testCase.assertEqual(testCase.myList.length(), 0);
        end

        function testAddSingleNonCellElement(testCase)
            % A single (non-cell) element is stored as one element, even
            % when it is itself a matrix.
            testCase.myList.add(rand(2));

            testCase.assertFalse(testCase.myList.isempty());
            testCase.assertEqual(testCase.myList.length(), 1);
        end

        function testAddCellVectorAddsMultipleElements(testCase)
            % A row/column cell vector adds one element per cell entry.
            testCase.myList.add({50,55});

            testCase.assertEqual(testCase.myList.length(), 2);
            testCase.assertEqual(testCase.myList.get(1), 50);
            testCase.assertEqual(testCase.myList.get(2), 55);
        end

        function testAddNonVectorCellAsSingleElement(testCase)
            % A 2-D (non-vector) cell array is not a "cell vector", so it
            % is stored whole, as a single element.
            twoByTwoCell = {10,11;12,13};
            testCase.myList.add(twoByTwoCell);

            testCase.assertEqual(testCase.myList.length(), 1);
            testCase.assertEqual(testCase.myList.get(1), twoByTwoCell);
        end

        function testInsertAtLocation(testCase)
            testCase.myList.add(5);          % [5]
            testCase.myList.add(10, 1);      % [10, 5]

            testCase.assertEqual(testCase.myList.length(), 2);
            testCase.assertEqual(testCase.myList.get(1), 10);
            testCase.assertEqual(testCase.myList.get(2), 5);
        end

        function testGetMultipleLocations(testCase)
            testCase.myList.add({150,160,170});  % [150, 160, 170]

            elts = testCase.myList.get([3,1]);
            testCase.assertEqual(elts, {170; 150});
        end

        function testCountOfAndLocationsOf(testCase)
            testCase.myList.add({5,50,5});  % [5, 50, 5]

            testCase.assertEqual(testCase.myList.countOf(5), 2);
            testCase.assertEqual(testCase.myList.locationsOf(5), [1;3]);
            testCase.assertEqual(testCase.myList.countOf(50), 1);
            testCase.assertEqual(testCase.myList.locationsOf(50), 2);
        end

        function testRemove(testCase)
            testCase.myList.add({150,160,170});  % [150, 160, 170]

            removed = testCase.myList.remove([2,3]);

            testCase.assertEqual(removed, {160; 170});
            testCase.assertEqual(testCase.myList.length(), 1);
            testCase.assertEqual(testCase.myList.get(1), 150);
        end

        function testRemoveAllElementsBackToEmpty(testCase)
            testCase.myList.add({150,160,170});

            testCase.myList.remove(1:testCase.myList.length());

            testCase.assertTrue(testCase.myList.isempty());
            testCase.assertEqual(testCase.myList.length(), 0);
        end

        function testDisplayDoesNotError(testCase)
            testCase.myList.add({150,160,170});

            output = evalc('testCase.myList.display()');
            testCase.assertNotEmpty(output);
        end
    end

end
