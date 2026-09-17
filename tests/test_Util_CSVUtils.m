classdef test_Util_CSVUtils < matlab.unittest.TestCase
    % test_Util_CSVUtils tests OM4MClassLib.Util.CSVUtils
    %run(test_Util_CSVUtils)

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
        function testReadFile1(testCase)
            % testReadFile1 checks ReadFile's sample count, field count/
            % names and sample values for testFileHighIndex.csv
            %run(test_Util_CSVUtils, 'testReadFile1')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=CSVUtils.ReadFile('testFileHighIndex.csv');

            % Check we have a correct numbre of samples
            testCase.assertEqual(27, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(8, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_speed_FT, '1500');
            testCase.assertEqual(samples(10).Polishing_time, '134');
        end

        function testReadFile2(testCase)
            % testReadFile2 repeats testReadFile1's checks on
            % testFilePolycarbonate.csv (with an explicit empty
            % sheetName argument)
            %run(test_Util_CSVUtils, 'testReadFile2')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=CSVUtils.ReadFile('testFilePolycarbonate.csv', '');

            % Check we have a correct numbre of samples
            testCase.assertEqual(36, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(11, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_Speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_Speed_FT, '1500');
            testCase.assertEqual(samples(10).Run, '10');
        end

        function testCsvRead2Cell1(testCase)
            % testCsvRead2Cell1 checks CsvRead2Cell's outputs on
            % testFileHighIndex.csv, then round-trips it through
            % cell2csv in both 1997 (unquoted) and 2010 (quoted) Excel
            % formats and checks the two reloaded files differ (quoting
            % changes each field's stored text)
            %run(test_Util_CSVUtils, 'testCsvRead2Cell1')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            filename='testFileHighIndex.csv';
            [~, textData, rawData]=CSVUtils.CsvRead2Cell(filename);

            testCase.assertTrue(all(size(textData)==size(rawData)));
            a=textData(:); b=rawData(:);
            for n=1:length(a)
                testCase.assertEqual(a(n), b(n));
            end

            % Check we have a correct numbre of samples
            testCase.assertTrue(all(size(rawData)==[28 8]));

            %generate a csv with fields separated by ; and enclosed in ""
            separator=';';
            excelYear=2010;
            [pathStr,name,ext]=fileparts(filename);
            filename1=fullfile(pathStr, [name '2010' ext]);
            status = CSVUtils.cell2csv(filename1, rawData, separator, excelYear);
            testCase.assertTrue(status==1);

            %generate a csv with fields separated by ; and NOT enclosed in ""
            separator=';';
            excelYear=1997;
            [pathStr,name,ext]=fileparts(filename);
            filename2=fullfile(pathStr, [name '1997' ext]);
            status = CSVUtils.cell2csv(filename2, rawData, separator, excelYear);
            testCase.assertTrue(status==1);

            %ahora cargamos los 2 y comparamos, debido a que filename1 se ha salvado en
            %formato 1997 (no quotes "") y filename2 en formato 2010 (each cell with
            %quotes) the CsvRead2Cell no devuelve el mismo resultado
            [~, ~, rawData1]=CSVUtils.CsvRead2Cell(filename1);
            [~, ~, rawData2]=CSVUtils.CsvRead2Cell(filename2);

            testCase.assertTrue(all(size(rawData1)== size(rawData2)));
            a=rawData1(:); b=rawData2(:);
            for n=1:length(a)
                testCase.assertFalse(strcmp(a{n}, b{n}));
            end

            %remove the tempo file
            delete(filename1);
            delete(filename2);
        end


        function testReadFile3(testCase)
            % testReadFile3 duplicates testReadFile2's checks on
            % testFilePolycarbonate.csv
            %run(test_Util_CSVUtils, 'testReadFile3')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            samples=CSVUtils.ReadFile('testFilePolycarbonate.csv', '');

            % Check we have a correct numbre of samples
            testCase.assertEqual(36, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(11, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(isfield(samples,'Run'));
            testCase.assertTrue(isfield(samples,'Lens_Speed_FT'));
            testCase.assertTrue(isfield(samples,'Polishing_time'));

            % Check field values are correct
            testCase.assertEqual(samples(1).Lens_Speed_FT, '1500');
            testCase.assertEqual(samples(10).Run, '10');
        end

        function testCsvRead2Cell2(testCase)
            % testCsvRead2Cell2 checks CsvRead2Cell's outputs on
            % testFileHighIndex.csv, then checks a cell2csv round-trip
            % with default separator/format reproduces identical text
            %run(test_Util_CSVUtils, 'testCsvRead2Cell2')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            filename='testFileHighIndex.csv';
            [~, textData, rawData]=CSVUtils.CsvRead2Cell(filename);

            testCase.assertTrue(all(size(textData)==size(rawData)));
            a=textData(:); b=rawData(:);
            for n=1:length(a)
                testCase.assertEqual(a(n), b(n));
            end

            % Check we have a correct numbre of samples
            testCase.assertTrue(all(size(rawData)==[28 8]));

            %generate a csv with fields separated by ; and NOT enclosed in ""
            [pathStr,name,ext]=fileparts(filename);
            filename1=fullfile(pathStr, [name 'testCsvRead2Cell2' ext]);
            status = CSVUtils.cell2csv(filename1, rawData);
            testCase.assertTrue(status==1);

            %ahora cargamos y comparamos que son iguales
            [~, ~, rawData1]=CSVUtils.CsvRead2Cell(filename1);

            testCase.assertTrue(all(size(rawData1)== size(rawData)));
            a=rawData1(:); b=rawData(:);
            for n=1:length(a)
                testCase.assertTrue(strcmp(a{n}, b{n}));
            end

            %remove the tempo file
            delete(filename1);
        end


        function testReadWriteFileManos(testCase)
            % testReadWriteFileManos reads a real manuscript-transcription
            % csv, edits a few fields, writes it via WriteFile, and
            % checks the reloaded file reflects the edits (unchanged
            % elsewhere)
            %run(test_Util_CSVUtils, 'testReadWriteFileManos')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            filename='documentsDB8bpqrcopystAll.csv';
            samples=CSVUtils.ReadFile(filename);

            % Check we have a correct numbre of samples
            testCase.assertEqual(2306, size(samples,2));
            % Check each sample have a correct number of fields
            testCase.assertEqual(13, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(all(isfield(samples,{'ID','FID','Manuscrito','Folio','Linea','Palabra','ImagenDocumento','Copista','DocAutor','Certeza','Fecha','FicheroImagen','Notas'})));

            % Check field values are correct
            testCase.assertEqual(samples(1).ID, '');
            testCase.assertEqual(samples(1).FID, 'b');
            testCase.assertEqual(samples(30).DocAutor, '<d>mscodex63_wk1_body0002</d><a>Lope de Vega Carpio</a>');

            testCase.assertEqual(samples(628).ID, '');
            testCase.assertEqual(samples(628).FID, 'block');
            testCase.assertEqual(samples(628).FicheroImagen, 'block_01_MSS_014774_pag005r.jpg');

            %change DDBB and save it
            samples(1).ID='AQ';
            samples(1).FID='LO';
            samples(30).DocAutor= 'mi mama me mima';

            samples(628).ID='LO';
            samples(628).FID='SS';
            samples(628).FicheroImagen='mi prima la coja.jpg';

            [pathStr,name,ext]=fileparts(filename);
            filename1=fullfile(pathStr, [name 'testReadWriteManos' ext]);
            CSVUtils.WriteFile(samples, filename1);

            %check saved DDBB
            samples1=CSVUtils.ReadFile(filename1);

            % Check we have a correct numbre of samples
            testCase.assertEqual(2306, size(samples,2));

            % Check each sample have a correct number of fields
            testCase.assertEqual(13, size(fieldnames(samples),1));

            % Check field names are correct
            testCase.assertTrue(all(isfield(samples,{'ID','FID','Manuscrito','Folio','Linea','Palabra','ImagenDocumento','Copista','DocAutor','Certeza','Fecha','FicheroImagen','Notas'})));

            % Check field values are correct
            testCase.assertEqual(samples1(1).ID, 'AQ');
            testCase.assertEqual(samples1(1).FID, 'LO');
            testCase.assertEqual(samples1(30).DocAutor, 'mi mama me mima');

            testCase.assertEqual(samples1(628).ID, 'LO');
            testCase.assertEqual(samples1(628).FID, 'SS');
            testCase.assertEqual(samples1(628).FicheroImagen, 'mi prima la coja.jpg');

            delete(filename1);
        end

        function testExceptionNoCSVFile(testCase)
            % testExceptionNoCSVFile checks ReadFile errors with the
            % expected message when given a non-csv file extension
            %run(test_Util_CSVUtils, 'testExceptionNoCSVFile')
            try
                import OM4MClassLib.Util.*;
                disp(Logging.WhoCalledMe());

                filename='testFile.xls';
                samples=CSVUtils.ReadFile(filename); %#ok<NASGU>
            catch ME
                str='CSVUtils.CsvRead2Cell->input file must be a csv sheet: testFile.xls';
                testCase.assertTrue(strcmp(str, ME.message));
            end
        end
    end
end
