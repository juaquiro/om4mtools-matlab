function p = fixturesRoot()
% fixturesRoot absolute path to the test fixtures data.
%Tests that build subfolder-relative fixture paths (e.g. '.\DiscoRGBFluo\...')
%need this because such paths only resolve against the current folder, not
%against addpath entries - unlike bare filenames, which resolve either way.
%
%Personal project, run only on machines where the Dropbox mirror exists -
%fixtures live at <dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab
%(see tests/fixtures/README.md) instead of being copied into tests/fixtures/
%and fetched via download_fixtures.sh, which duplicated ~11 GB for no
%benefit on a single-user, local-only setup.
p = dropbox('AQ_EXP', 'DataSetsForTesting', 'om4mtools-matlab');
end
