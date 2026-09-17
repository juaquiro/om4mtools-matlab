classdef test_Util_XLSUtils < matlab.unittest.TestCase
    % test_Util_XLSUtils tests OM4MClassLib.Util.XLSUtils, against both
    % legacy .xls (97) and .xlsx (2010) fixtures
    %run(test_Util_XLSUtils)

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
        function testReadFileDefaultSheet97(testCase)
            % testReadFileDefaultSheet97 checks ReadFile's sample count,
            % field count/names and sample values on testFile.xls's
            % default (first) sheet
            %run(test_Util_XLSUtils, 'testReadFileDefaultSheet97')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            % by default the first sheet is read (in this case High index)
            samples=XLSUtils.ReadFile(fullfile(fixturesRoot(),'testFile.xls'));

            % Check we have a correct numbre of samples
            testCase.assertEqual(27, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(8, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_speed_FT, 1500);
            testCase.assertEqual(samples(10).Polishing_time, 134);
        end

        function testReadFile97(testCase)
            % testReadFile97 repeats testReadFileDefaultSheet97's checks
            % on testFile.xls's explicit 'Polycarbonate' sheet
            %run(test_Util_XLSUtils, 'testReadFile97')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=XLSUtils.ReadFile(fullfile(fixturesRoot(),'testFile.xls'), 'Polycarbonate');

            % Check we have a correct numbre of samples
            testCase.assertEqual(36, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(11, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_Speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_Speed_FT, 1500);
            testCase.assertEqual(samples(10).Run, 10);
        end

        function testFilterByValue97(testCase)
            % testFilterByValue97 checks FilterByValue on testFile.xls's
            % 'High Index' sheet, for a numeric field, another numeric
            % field, and a char field
            %run(test_Util_XLSUtils, 'testFilterByValue97')
            %AQDEBUG este test falla en el Rx
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=XLSUtils.ReadFile(fullfile(fixturesRoot(),'testFile.xls'), 'High Index');

            speed=1500;
            filterResult=XLSUtils.FilterByValue(samples, 'Lens_speed_FT', speed);
            testCase.assertEqual(9, size(filterResult,2));
            testCase.assertTrue(all([filterResult(:).Lens_speed_FT]==speed));

            polTime=114;
            filterResult=XLSUtils.FilterByValue(samples, 'Polishing_time', polTime);
            testCase.assertEqual(9, size(filterResult,2));
            testCase.assertTrue(all([filterResult(:).Polishing_time]==polTime));

            Rx='-200/-200';
            filterResult=XLSUtils.FilterByValue(samples, 'Rx', Rx);
            testCase.assertEqual(9, size(filterResult,2));
            testCase.assertTrue(all(strcmp(Rx,{filterResult(:).Rx})));
        end

        function testReadFileDefaultSheet2010(testCase)
            % testReadFileDefaultSheet2010 repeats
            % testReadFileDefaultSheet97's checks on testFile.xlsx
            %run(test_Util_XLSUtils, 'testReadFileDefaultSheet2010')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            % by default the first sheet is read (in this case High index)
            samples=XLSUtils.ReadFile(fullfile(fixturesRoot(),'testFile.xlsx'));

            % Check we have a correct numbre of samples
            testCase.assertEqual(27, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(8, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_speed_FT, 1500);
            testCase.assertEqual(samples(10).Polishing_time, 134);
        end

        function testReadFile2010(testCase)
            % testReadFile2010 repeats testReadFile97's checks on
            % testFile.xlsx's explicit 'Polycarbonate' sheet
            %run(test_Util_XLSUtils, 'testReadFile2010')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=XLSUtils.ReadFile(fullfile(fixturesRoot(),'testFile.xlsx'), 'Polycarbonate');

            % Check we have a correct numbre of samples
            testCase.assertEqual(36, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(11, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_Speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_Speed_FT, 1500);
            testCase.assertEqual(samples(10).Run, 10);
        end

        function testFilterByValue2010(testCase)
            % testFilterByValue2010 repeats testFilterByValue97's checks
            % on testFile.xlsx's 'High Index' sheet
            %run(test_Util_XLSUtils, 'testFilterByValue2010')
            %AQDEBUG este test falla en el Rx
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=XLSUtils.ReadFile(fullfile(fixturesRoot(),'testFile.xlsx'), 'High Index');

            speed=1500;
            filterResult=XLSUtils.FilterByValue(samples, 'Lens_speed_FT', speed);
            testCase.assertEqual(9, size(filterResult,2));
            testCase.assertTrue(all([filterResult(:).Lens_speed_FT]==speed));

            polTime=114;
            filterResult=XLSUtils.FilterByValue(samples, 'Polishing_time', polTime);
            testCase.assertEqual(9, size(filterResult,2));
            testCase.assertTrue(all([filterResult(:).Polishing_time]==polTime));

            Rx='-200/-200';
            filterResult=XLSUtils.FilterByValue(samples, 'Rx', Rx);
            testCase.assertEqual(9, size(filterResult,2));
            testCase.assertTrue(all(strcmp(Rx,{filterResult(:).Rx})));
        end

        function testExceptionNoExcelFile(testCase)
            % testExceptionNoExcelFile checks ReadFile errors with the
            % expected message when given a non-excel file extension
            %run(test_Util_XLSUtils, 'testExceptionNoExcelFile')
            try
                import OM4MClassLib.Util.*;
                disp(Logging.WhoCalledMe());

                filename='testFileHighIndex.csv';
                samples=XLSUtils.ReadFile(filename); %#ok<NASGU>
            catch ME
                str='XLSUtils.ReadFile->input file must be a excel sheet: testFileHighIndex.csv';
                testCase.assertTrue(strcmp(str, ME.message));
            end
        end
    end
end
