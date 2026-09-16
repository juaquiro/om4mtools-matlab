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
%
% Also writes the full Command Window output (per-test pass/fail plus a
% failed/incomplete name list) to tests/run_all_tests.log, so the run can
% be handed off without keeping the MATLAB session attached - see
% .gitignore, this log is local/untracked.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
setupPath();

suite = matlab.unittest.TestSuite.fromFolder(thisDir);

isHardwareTest = arrayfun(@(t) ismember('Hardware', t.Tags), suite);
nExcluded = nnz(isHardwareTest);
suite = suite(~isHardwareTest);

runner = matlab.unittest.TestRunner.withTextOutput();

logFile = fullfile(thisDir, 'run_all_tests.log');
diary(logFile);
diary on;
try
    results = runner.run(suite);
catch ME
    diary off;
    rethrow(ME);
end

fprintf('\n%d passed, %d failed, %d incomplete (of %d) - %d Hardware-tagged tests excluded\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results), nExcluded);

failedNames = {results([results.Failed]).Name};
incompleteNames = {results([results.Incomplete]).Name};

if ~isempty(failedNames)
    fprintf('\nFailed tests:\n');
    fprintf('  %s\n', failedNames{:});
end
if ~isempty(incompleteNames)
    fprintf('\nIncomplete tests:\n');
    fprintf('  %s\n', incompleteNames{:});
end

diary off;

end
