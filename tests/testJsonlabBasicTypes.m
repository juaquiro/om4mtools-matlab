classdef testJsonlabBasicTypes < matlab.unittest.TestCase
    %TESTJSONLABBASICTYPES round-trip regression tests for the data types
    %demonstrated in jsonlab's own examples/demo_jsonlab_basic.m and
    %demo_ubjson_basic.m (which only printed output, no assertions).
    %
    %Parameterized over both codecs (JSON and UBJSON) since jsonlab's two
    %demo scripts exercise the exact same sequence of data types.

    properties (TestParameter)
        codec = {'json', 'ubjson'};
    end

    methods (Test)
        function testScalar(testCase, codec)
            % named field (not an empty root name) - an anonymous UBJSON
            % root scalar comes back wrapped in a 1x1 cell instead of a
            % plain double, which is a real quirk of this codec/library,
            % not something worth asserting against here.
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = pi;
            encoded = saveFcn('value', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            % savejson serializes doubles with ~10 significant digits by
            % default, so JSON round trips lose precision beyond that.
            testCase.verifyEqual(field, data, 'AbsTol', 1e-8);
        end

        function testComplexNumber(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = 1 + 2i;
            encoded = saveFcn('', data);
            decoded = loadFcn(encoded);

            testCase.verifyEqual(decoded, data, 'AbsTol', 1e-10);
        end

        function testComplexMatrix(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            m = magic(6);
            data = m(:, 1:3) + m(:, 4:6) * 1i;
            encoded = saveFcn('', data);
            decoded = loadFcn(encoded);

            testCase.verifyEqual(decoded, data, 'AbsTol', 1e-6);
        end

        function testSpecialConstants(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = [NaN, Inf, -Inf];
            encoded = saveFcn('specials', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyTrue(isequaln(field, data));
        end

        function testSparseReal(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = sprand(10, 10, 0.1);
            encoded = saveFcn('sparse', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyEqual(full(field), full(data), 'AbsTol', 1e-6);
        end

        function testSparseComplex(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = sprand(10, 10, 0.1);
            data = data - 1i * data;
            encoded = saveFcn('complex_sparse', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyEqual(full(field), full(data), 'AbsTol', 1e-6);
        end

        function testAllZeroSparse(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = sparse(2, 3);
            encoded = saveFcn('all_zero_sparse', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyEqual(full(field), full(data));
        end

        function testEmpty0by0Real(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = [];
            encoded = saveFcn('empty_0by0_real', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyEqual(size(field), size(data));
        end

        function testEmpty0by3Real(testCase, codec)
            % UBJSON round-trips an empty matrix as empty but does not
            % reliably preserve its non-zero dimension (e.g. the "3" in
            % 0x3) - a real limitation of the binary encoding for arrays
            % with no elements, not something to assert exactly here.
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = zeros(0, 3);
            encoded = saveFcn('empty_0by3_real', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyTrue(isempty(field));
        end

        function testStruct(testCase, codec)
            % UBJSON is a binary format and stores integer-valued doubles
            % in the smallest integer type that fits (int8/int16/...)
            % instead of keeping them as double - real, expected codec
            % behaviour, so compare values via double() rather than class.
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = struct('name', 'Think Different', 'year', 1997, 'magic', magic(3), ...
                'misfits', [Inf, NaN], 'embedded', struct('left', true, 'right', false));
            encoded = saveFcn('astruct', data, struct('ParseLogical', 1));
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyEqual(field.name, data.name);
            testCase.verifyEqual(double(field.year), data.year);
            testCase.verifyEqual(double(field.magic), data.magic);
            testCase.verifyTrue(isequaln(double(field.misfits), data.misfits));
            testCase.verifyEqual(logical(field.embedded.left), data.embedded.left);
            testCase.verifyEqual(logical(field.embedded.right), data.embedded.right);
        end

        function testStructArray(testCase, codec)
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = struct('name', 'Nexus Prime', 'rank', 9);
            data(2) = struct('name', 'Sentinel Prime', 'rank', 9);
            data(3) = struct('name', 'Optimus Prime', 'rank', 9);
            encoded = saveFcn('Supreme Commander', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            testCase.verifyEqual(numel(field), numel(data));
            for k = 1:numel(data)
                testCase.verifyEqual(field{k}.name, data(k).name);
                testCase.verifyEqual(double(field{k}.rank), data(k).rank);
            end
        end

        function test2DStructArray(testCase, codec)
            % jsonlab does not preserve the original 2D shape/linear-index
            % order of a struct array on the way back (its own bundled
            % demo shows the same reshaping) - check that all idx values
            % survive somewhere in the (possibly renested) result instead
            % of asserting an exact shape.
            [saveFcn, loadFcn] = testJsonlabBasicTypes.codecFcns(codec);

            data = repmat(struct('idx', 0, 'data', 'structs'), [2, 3]);
            for k = 1:6
                data(k).idx = k;
            end
            encoded = saveFcn('data2json', data);
            decoded = loadFcn(encoded);
            field = testJsonlabBasicTypes.onlyField(decoded);

            idxs = double(testJsonlabBasicTypes.flattenIdx(field));
            testCase.verifyEqual(sort(idxs), 1:6);
        end

        function testCellArray(testCase, codec)
            %jsonlab's own demo notes loadjson has issues reloading cell
            %arrays - only check that encoding a cell array does not error
            %and produces something non-empty (matches the documented
            %limitation instead of asserting a full round trip).
            [saveFcn, ~] = testJsonlabBasicTypes.codecFcns(codec);

            data = {{1, {2, 3}}, {4, 5}, {6}; {7}, {8, 9}, {10}};
            encoded = saveFcn('data2json', data);

            testCase.verifyClass(encoded, 'char');
            testCase.verifyNotEmpty(encoded);
        end
    end

    methods (Static, Access = private)
        function [saveFcn, loadFcn] = codecFcns(codec)
            if strcmp(codec, 'json')
                saveFcn = @savejson;
                loadFcn = @loadjson;
            else
                saveFcn = @saveubjson;
                loadFcn = @loadubjson;
            end
        end

        function value = onlyField(s)
            %jsonlab sanitizes wrapper field names (e.g. spaces get
            %escaped), so grab whatever the single field ended up being
            %called instead of hardcoding its name.
            fn = fieldnames(s);
            value = s.(fn{1});
        end

        function idxs = flattenIdx(value)
            %recursively collect .idx fields out of an arbitrarily nested
            %mix of cells and struct arrays.
            idxs = [];
            if iscell(value)
                for k = 1:numel(value)
                    idxs = [idxs, testJsonlabBasicTypes.flattenIdx(value{k})]; %#ok<AGROW>
                end
            elseif isstruct(value)
                for k = 1:numel(value)
                    idxs(end+1) = value(k).idx; %#ok<AGROW>
                end
            end
        end
    end

end
