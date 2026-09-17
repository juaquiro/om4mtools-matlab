classdef testJsonlabRoundTrip < matlab.unittest.TestCase
    % testJsonlabRoundTrip round-trip regression tests for loadjson/savejson
    %and loadubjson/saveubjson against real-world JSON samples.
    %
    %Adapted from jsonlab's own examples/jsonlab_selftest.m (which only
    %printed output, no assertions) into real matlab.unittest checks.

    properties (TestParameter)
        exampleFile = {'example1.json', 'example2.json', 'example3.json', 'example4.json'};
    end

    methods(TestMethodSetup)
        function SetUp(testCase)
            setupPath();
        end
    end

    methods(TestMethodTeardown)
        function TearDown(testCase)
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end

    methods (Test)
        function testJsonRoundTrip(testCase, exampleFile)
            % testJsonRoundTrip checks savejson(loadjson(exampleFile))
            % round-trips back to the same value (example4.json is
            % expected to fail, see the assumeFail below)
            original = loadjson(fullfile(fixturesRoot(), exampleFile));

            if strcmp(exampleFile, 'example4.json')
                % example4.json's 3rd top-level element is a JSON array of 3
                % objects, each wrapping a [1,2] double via jsonlab's own
                % "_ArrayType_"/"_ArraySize_"/"_ArrayData_" struct encoding -
                % deliberately written that way (it's jsonlab's own selftest
                % fixture) to force loadjson to keep them as 3 separate 1x2
                % arrays in a cell, rather than one matrix. savejson has no
                % way to reproduce that wrapping when serializing a plain
                % cell of numeric arrays - it writes plain nested JSON
                % arrays instead ("[[1,0],[1,1],[1,2]]"), and loadjson's
                % (version-independent, pure sscanf) fast-array parser then
                % auto-collapses that uniform array-of-arrays into a single
                % 3x2 matrix on reload. This is a JSON-format ambiguity
                % (plain JSON can't distinguish "3 separate arrays" from "one
                % matrix"), not a MATLAB-version compatibility bug - see
                % DECISIONS.md. testUbjsonRoundTrip for the same fixture
                % passes: UBJSON's binary array encoding doesn't have this
                % ambiguity.
                testCase.assumeFail(['testJsonRoundTrip/example4.json: JSON-format ambiguity, ' ...
                    'not a MATLAB-version bug - see comment above and DECISIONS.md']);
            end

            json = savejson('', original);
            reloaded = loadjson(json);

            testCase.verifyEqual(reloaded, original);
        end

        function testUbjsonRoundTrip(testCase, exampleFile)
            % testUbjsonRoundTrip checks
            % saveubjson(loadjson(exampleFile)) round-trips back to the
            % same value (after normalizing UBJSON's compact integer
            % types back to double)
            original = loadjson(fullfile(fixturesRoot(), exampleFile));

            ubj = saveubjson('', original);
            reloaded = loadubjson(ubj);

            % UBJSON is binary and stores integer-valued doubles in the
            % smallest integer type that fits (e.g. age=25 -> int8) -
            % real, expected codec behaviour, so normalize numeric
            % classes back to double before comparing values.
            testCase.verifyEqual(testJsonlabRoundTrip.normalizeNumericClasses(reloaded), original);
        end
    end

    methods (Static, Access = private)
        function out = normalizeNumericClasses(value)
            % normalizeNumericClasses recursively casts every non-double
            % numeric value inside value (struct/cell/array) to double
            if isstruct(value)
                out = value;
                fn = fieldnames(value);
                for i = 1:numel(value)
                    for f = 1:numel(fn)
                        out(i).(fn{f}) = testJsonlabRoundTrip.normalizeNumericClasses(value(i).(fn{f}));
                    end
                end
            elseif iscell(value)
                out = cellfun(@testJsonlabRoundTrip.normalizeNumericClasses, value, 'UniformOutput', false);
            elseif isnumeric(value) && ~isa(value, 'double')
                out = double(value);
            else
                out = value;
            end
        end
    end

end
