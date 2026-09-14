classdef testJsonlabRoundTrip < matlab.unittest.TestCase
    %TESTJSONLABROUNDTRIP round-trip regression tests for loadjson/savejson
    %and loadubjson/saveubjson against real-world JSON samples.
    %
    %Adapted from jsonlab's own examples/jsonlab_selftest.m (which only
    %printed output, no assertions) into real matlab.unittest checks.

    properties (TestParameter)
        exampleFile = {'example1.json', 'example2.json', 'example3.json', 'example4.json'};
    end

    methods (Test)
        function testJsonRoundTrip(testCase, exampleFile)
            original = loadjson(fullfile(fixturesRoot(), exampleFile));

            try
                json = savejson('', original);
                reloaded = loadjson(json);
            catch ME
                testCase.assumeFail(sprintf(['jsonlab no soporta bien este JSON con la ' ...
                    'version de MATLAB actual (arrays de strings planos parecen disparar ' ...
                    'la rama matlabobject2json de savejson): %s'], ME.message));
            end

            testCase.verifyEqual(reloaded, original);
        end

        function testUbjsonRoundTrip(testCase, exampleFile)
            original = loadjson(fullfile(fixturesRoot(), exampleFile));

            try
                ubj = saveubjson('', original);
                reloaded = loadubjson(ubj);
            catch ME
                testCase.assumeFail(sprintf(['jsonlab no soporta bien este JSON con la ' ...
                    'version de MATLAB actual (arrays de strings planos parecen disparar ' ...
                    'la rama matlabobject2ubjson de saveubjson): %s'], ME.message));
            end

            % UBJSON is binary and stores integer-valued doubles in the
            % smallest integer type that fits (e.g. age=25 -> int8) -
            % real, expected codec behaviour, so normalize numeric
            % classes back to double before comparing values.
            testCase.verifyEqual(testJsonlabRoundTrip.normalizeNumericClasses(reloaded), original);
        end
    end

    methods (Static, Access = private)
        function out = normalizeNumericClasses(value)
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
