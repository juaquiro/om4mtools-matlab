function build()
%BUILD Compile the IOT2DPU MEX project and refresh mex/bin/.
%
% Runs MSBuild on mex/src/IOT2DPU.sln (Release|x64) and copies the
% resulting binaries into mex/bin/. Windows-only: MSBuild.exe is
% located via vswhere.exe (Visual Studio 2017+) or, failing that, PATH.
%
% Each relevant project (PUFlynMdMex.vcxproj, PUMexLib.vcxproj) already
% has a post-build step that copies its own output to mex/src/deploy/
% (see those .vcxproj files) -- this function copies everything that
% lands there into mex/bin/, overwriting the committed binaries.
%
% Known caveat (found 2026-09-14, see DECISIONS.md): the .vcxproj files
% still target PlatformToolset v120 (Visual Studio 2013). On a machine
% without that toolset installed, MSBuild fails with MSB8020 before
% compiling anything. Installing the VS2013 (v120) build tools, or
% retargeting the solution to a current toolset, is required first --
% deliberately left for the separate "compile for all platforms" TODO
% item, not done as part of this script, since retargeting an unverified
% ~15-year-old C codebase to a modern MSVC could silently change
% numerical behaviour of the unwrapping algorithm without a way to
% verify that here.
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

msbuild = locateMSBuild();

cmd = sprintf('"%s" "%s" /t:Build /p:Configuration=Release /p:Platform=x64 /verbosity:minimal', ...
    msbuild, slnPath);
fprintf('%s\n', cmd);
status = system(cmd);
if status ~= 0
    error('om4mtools:mexBuildFailed', ...
        'MSBuild failed (exit code %d) -- see its output above.', status);
end

if ~isfolder(deployDir)
    error('om4mtools:mexBuildNoDeployOutput', ...
        ['Build succeeded but %s was not created -- check the post-build ' ...
         'events in PUFlynMdMex.vcxproj / PUMexLib.vcxproj.'], deployDir);
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
