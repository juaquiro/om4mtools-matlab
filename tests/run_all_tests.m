function results = run_all_tests()
%RUN_ALL_TESTS Run the om4mtools-matlab matlab.unittest suite (no hardware).
%
% Discovers every matlab.unittest.TestCase in tests/ (legacy mtest-style
% files with no modern equivalent are silently skipped - they are not
% valid TestCase classes) and runs them with src/ and tests/fixtures/ on
% the path. Tests tagged 'Hardware' (require real cameras, motors, power
% sources, etc.) are excluded - see run_hardware_tests.m to run those.
%
% Syntax:
%   results = run_all_tests();
%   run('tests/run_all_tests.m')
%
% Note: some remaining tests require external data intentionally excluded
% from this repo (Coursera course files) and will fail/error - that is
% expected, see DECISIONS.md.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
setupPath();

suite = matlab.unittest.TestSuite.fromFolder(thisDir);

isHardwareTest = arrayfun(@(t) ismember('Hardware', t.Tags), suite);
nExcluded = nnz(isHardwareTest);
suite = suite(~isHardwareTest);

runner = matlab.unittest.TestRunner.withTextOutput();
results = runner.run(suite);

fprintf('\n%d passed, %d failed, %d incomplete (of %d) - %d Hardware-tagged tests excluded\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results), nExcluded);

end
