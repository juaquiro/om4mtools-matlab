function results = run_hardware_tests()
% run_hardware_tests Run only the tests tagged 'Hardware'.
%
% These tests require real hardware to be connected (cameras, motors,
% power sources) and are excluded from run_all_tests.m. Run this manually
% at the bench with the relevant equipment attached and configured (see
% each test's TestMethodSetup for required config files).
%
% Syntax:
%   results = run_hardware_tests();
%   run('tests/run_hardware_tests.m')

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
setupPath();

suite = matlab.unittest.TestSuite.fromFolder(thisDir);

isHardwareTest = arrayfun(@(t) ismember('Hardware', t.Tags), suite);
suite = suite(isHardwareTest);

if isempty(suite)
    fprintf('\nNo Hardware-tagged tests found.\n');
    results = suite;
    return
end

runner = matlab.unittest.TestRunner.withTextOutput();
results = runner.run(suite);

fprintf('\n%d passed, %d failed, %d incomplete (of %d)\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), numel(results));

end
