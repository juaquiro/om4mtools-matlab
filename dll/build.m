function build()
%BUILD Compile the CProjector DLL project and refresh dll/bin/.
%
% Runs MSBuild directly on dll/src/CProjector/CProjector.vcxproj
% (Release|x64) and copies the resulting binaries into dll/bin/.
% Windows-only: MSBuild.exe is located via vswhere.exe (Visual Studio
% 2017+) or, failing that, PATH.
%
% Unlike mex/build.m, there is no .sln wrapping this project -- only
% CProjector, out of the legacy CHighPerform.sln's three DLL projects,
% was recovered (see DECISIONS.md). CProjector.vcxproj's PostBuildEvent
% still references $(SolutionDir) (it copies headers/dll/lib into a
% Deploy folder next to the project), so SolutionDir is passed in
% explicitly as dll/src/ instead of coming from an actual .sln. That
% lands the post-build output in dll/src/Deploy/, mirroring
% mex/src/deploy/, and this function copies from there into dll/bin/
% the same way mex/build.m does for mex/bin/.
%
% CProjector.vcxproj also references MATLAB headers/libs via
% $(MATLAB)extern\include and $(MATLAB)extern\lib\win64\microsoft --
% passed in explicitly as matlabroot(), same reason as mex/build.m.
%
% Syntax:
%   run('dll/build.m')
%
% Version: 0.1.0 | Date: 2026-09 | Author: OM4M Group

if ~ispc
    error('om4mtools:dllBuildWindowsOnly', ...
        'dll/build.m requires MSBuild/Visual Studio and only runs on Windows.');
end

thisDir = fileparts(mfilename('fullpath'));
srcDir = fullfile(thisDir, 'src');
vcxprojPath = fullfile(srcDir, 'CProjector', 'CProjector.vcxproj');
deployDir = fullfile(srcDir, 'Deploy');
binDir = fullfile(thisDir, 'bin');

if ~isfolder(deployDir)
    mkdir(deployDir);
end

msbuild = locateMSBuild();

% Both /p: values below are quoted, and the trailing backslash right
% before each closing quote is doubled -- a single one there escapes
% the quote instead of ending the value (Windows command-line argv
% rule: N backslashes then a quote -> floor(N/2) literal backslashes,
% and an odd N also escapes the quote). Built via plain concatenation,
% not sprintf, so these literal backslashes can't get reinterpreted as
% sprintf escape sequences. See mex/build.m for the same pattern.
solutionDirArg = ['/p:SolutionDir="' srcDir '\\"'];
matlabArg = ['/p:MATLAB="' matlabroot() '\\"'];
cmd = ['"' msbuild '" "' vcxprojPath '" ' ...
    '/p:Configuration=Release /p:Platform=x64 ' solutionDirArg ' ' matlabArg ' /verbosity:minimal'];
fprintf('%s\n', cmd);
status = system(cmd);
if status ~= 0
    error('om4mtools:dllBuildFailed', ...
        'MSBuild failed (exit code %d) -- see its output above.', status);
end

% The .vcxproj's PostBuildEvent copies every *.h next to CProjector.cpp
% into Deploy/ (framework.h, pch.h -- internal-only, not part of
% CProjector.h's own #include chain) plus the import .lib -- none of
% that is needed by loadlibrary()/calllib() at runtime, so only the
% known-needed files are copied into dll/bin/ (same set already there:
% the dll plus the header and the one header it #includes).
requiredFiles = {'CProjector.dll', 'CProjector.h', 'shrhelp.h'};
deployed = dir(fullfile(deployDir, '*'));
deployed = deployed(ismember({deployed.name}, requiredFiles));
if numel(deployed) < numel(requiredFiles)
    missing = setdiff(requiredFiles, {deployed.name});
    error('om4mtools:dllBuildMissingDeployOutput', ...
        'Expected %s in %s but missing: %s.', strjoin(requiredFiles, ', '), ...
        deployDir, strjoin(missing, ', '));
end

for k = 1:numel(deployed)
    source = fullfile(deployDir, deployed(k).name);
    try
        copyfile(source, binDir, 'f');
    catch copyError
        error('om4mtools:dllBuildLockedTarget', ...
            ['Could not overwrite dll/bin/%s -- it is likely still loaded by ' ...
             'another MATLAB session (a loadlibrary() DLL stays locked on ' ...
             'Windows once used, until that session runs unloadlibrary or ' ...
             'closes). Free it there and re-run build(). Original error: %s'], ...
            deployed(k).name, copyError.message);
    end
    fprintf('Copied %s -> dll/bin/\n', deployed(k).name);
end

fprintf('Build complete: %d file(s) updated in dll/bin/.\n', numel(deployed));
fprintf('If MATLAB already has the old library loaded, run "unloadlibrary CProjector" before using the new one.\n');

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

error('om4mtools:dllBuildNoMSBuild', ...
    ['Could not find MSBuild.exe via vswhere.exe or PATH. Install Visual ' ...
     'Studio (or the standalone Build Tools) with the "Desktop development ' ...
     'with C++" workload.']);

end
