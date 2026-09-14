function p = resetPath()
%RESETPATH  Snapshot/restore helper for the MATLAB path used by tests.
%
% The first call in a MATLAB session captures the current path - whatever
% the user already had on it (their own projects, toolboxes, support
% packages) - and returns it. Every later call returns that same
% captured snapshot, so tests can do:
%
%   matlabpath(resetPath); %#ok<RESETPATH>
%
% in TestMethodTeardown to restore exactly what was on the path before
% the test suite started running. This replaces matlabpath(pathdef),
% which resets to MATLAB's factory-installation path and silently
% discards anything the user had on their own path - see DECISIONS.md,
% "pathdef no es resetPath", for the full rationale.
%
% Syntax:
%   p = resetPath()

persistent capturedPath
if isempty(capturedPath)
    capturedPath = path();
end
p = capturedPath;

end
