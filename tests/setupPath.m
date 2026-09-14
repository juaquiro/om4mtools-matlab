function setupPath()
%SETUPPATH Add every folder the test suite needs to the MATLAB path.
%
% Called from every test's TestMethodSetup - so each test stays runnable
% standalone (e.g. run(testFPADemodulator) from a fresh MATLAB session) -
% and from run_all_tests.m / run_hardware_tests.m. addpath is idempotent,
% so calling this repeatedly (once per test, per suite run) is harmless.
%
% Replaces the old per-domain helpers (testAAAddReferencesPath.m,
% testAAAddReferencesPathFPA.m, testAAAddReferencesPathStandardHW.m,
% testAddReferemcesML_hg.m) with a single one - see DECISIONS.md.
%
% Adds:
%   - tests/            (this file's own directory)
%   - src/
%   - the fixtures data root (see fixturesRoot.m) - the local Dropbox
%     mirror, not tests/fixtures/ (kept empty on purpose, see its README.md)
%   - the legacy IOT2DPU/deploy folder - holds PUFlynMdMex.mexw64, the
%     compiled MEX binary behind UnwrapperTypes.FlynMd (used throughout
%     the FPA demodulator tests), still pending its own Fase 2 migration
%     to mex/src/ (see TODO.md). NOT a no-op like the old ClassLib/UtilLib
%     legacy paths the FPA/StandardHW helpers used to add - those are
%     genuinely gone now (fully migrated), this one is still load-bearing.
%
% Syntax:
%   setupPath()

thisDir = fileparts(mfilename('fullpath'));

addpath(thisDir);
addpath(fullfile(thisDir, '..', 'src'));
addpath(fixturesRoot());
addpath(fullfile(thisDir, '..', 'om4mtools-matlab', 'IOT2DPU', 'deploy'));

end
