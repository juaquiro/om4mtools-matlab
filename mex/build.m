function build()
%BUILD Compile the IOT2DPU MEX project and refresh mex/bin/.
%
% Runs MSBuild on mex/src/IOT2DPU.sln (Release|x64, targets PUFlynMdMex
% and PUMexLib only -- the flynmd/fmg/goldbc projects are standalone
% legacy command-line tools, not needed by MATLAB) and copies the
% resulting binaries into mex/bin/. Windows-only: MSBuild.exe is
% located via vswhere.exe (Visual Studio 2017+) or, failing that, PATH.
%
% PUFlynMdMex.vcxproj / PUMexLib.vcxproj already have a post-build step
% that copies each project's own output to mex/src/deploy/ (relative to
% $(SolutionDir)) -- this function creates that folder up front (the
% post-build "copy" command does not create missing directories) and
% copies everything that lands there into mex/bin/, overwriting the
% committed binaries.
%
% Both .vcxproj files reference MATLAB headers/libs via
% $(MATLAB)extern\include and $(MATLAB)extern\lib\win64\microsoft --
% $(MATLAB) is not defined anywhere in the project files themselves, so
% without an ambient MATLAB environment variable set the include would
% fail to resolve. This function passes matlabroot() in explicitly as
% an MSBuild property instead of relying on that.
%
% Retargeted 2026-09-14 from PlatformToolset v120 (Visual Studio 2013)
% to v143 (Visual Studio 2022) -- see DECISIONS.md for the full
% writeup, including how the resulting mex/bin/ binaries were verified
% (run(testFPAUnwrapper), 5/5 passed) before committing. That test
% class only asserts numerically on the Void unwrapper path, not
% FlynMd -- rebuilding with a different compiler is presumed safe for
% pure C algorithm code with no assertion-backed numerical regression
% check, not proven bit-identical.
%
% Syntax:
%   run('mex/build.m')
%
% Version: 0.1.0 | Date: 2026-09 | Author: OM4M Group

if ~ispc
    error('om4mtools:mexBuildWindowsOnly', ...
        'mex/build.m requires MSBuild/Visual Studio and only runs on Windows.');
end

thisDir = fileparts(mfilename('fullpath'));
slnPath = fullfile(thisDir, 'src', 'IOT2DPU.sln');
deployDir = fullfile(thisDir, 'src', 'deploy');
binDir = fullfile(thisDir, 'bin');

if ~isfolder(deployDir)
    mkdir(deployDir);
end

msbuild = locateMSBuild();

cmd = sprintf(['"%s" "%s" /t:PUFlynMdMex,PUMexLib /p:Configuration=Release ' ...
    '/p:Platform=x64 /p:MATLAB=%s\\ /verbosity:minimal'], ...
    msbuild, slnPath, matlabroot());
fprintf('%s\n', cmd);
status = system(cmd);
if status ~= 0
    error('om4mtools:mexBuildFailed', ...
        'MSBuild failed (exit code %d) -- see its output above.', status);
end

deployed = dir(fullfile(deployDir, '*'));
deployed = deployed(~[deployed.isdir]);
if isempty(deployed)
    error('om4mtools:mexBuildEmptyDeployOutput', ...
        '%s exists but is empty -- nothing to copy into mex/bin/.', deployDir);
end

for k = 1:numel(deployed)
    source = fullfile(deployDir, deployed(k).name);
    copyfile(source, binDir, 'f');
    fprintf('Copied %s -> mex/bin/\n', deployed(k).name);
end

fprintf('Build complete: %d file(s) updated in mex/bin/.\n', numel(deployed));
fprintf('If MATLAB already has the old MEX loaded, run "clear mex" before using the new one.\n');

end

function msbuild = locateMSBuild()
%LOCATEMSBUILD Find MSBuild.exe via vswhere, falling back to PATH.

programFilesX86 = getenv('ProgramFiles(x86)');
vswhere = fullfile(programFilesX86, 'Microsoft Visual Studio', 'Installer', 'vswhere.exe');

if isfile(vswhere)
    findCmd = sprintf('"%s" -latest -requires Microsoft.Component.MSBuild -find "MSBuild\\**\\Bin\\MSBuild.exe"', vswhere);
    [status, out] = system(findCmd);
    if status == 0 && ~isempty(strtrim(out))
        lines = strsplit(strtrim(out), newline);
        msbuild = strtrim(lines{1});
        return
    end
end

[status, ~] = system('where msbuild');
if status == 0
    msbuild = 'msbuild';
    return
end

error('om4mtools:mexBuildNoMSBuild', ...
    ['Could not find MSBuild.exe via vswhere.exe or PATH. Install Visual ' ...
     'Studio (or the standalone Build Tools) with the "Desktop development ' ...
     'with C++" workload.']);

end
