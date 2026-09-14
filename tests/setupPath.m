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
%   - mex/bin/          - holds PUFlynMdMex.mexw64 and PUMexLib.dll, the
%     compiled MEX behind UnwrapperTypes.FlynMd (used throughout the FPA
%     demodulator tests). Migrated here from the legacy IOT2DPU/deploy
%     folder (see TODO.md Fase 2, DECISIONS.md).
%
% Syntax:
%   setupPath()

thisDir = fileparts(mfilename('fullpath'));

addpath(thisDir);
addpath(fullfile(thisDir, '..', 'src'));
addpath(fixturesRoot());
addpath(fullfile(thisDir, '..', 'mex', 'bin'));

end
