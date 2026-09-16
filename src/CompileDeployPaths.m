% CompileDeployPaths compiles DeployPaths.m into a standalone executable
% Kept deliberately simple (single mcc call, no extra options) for
% cross-platform portability. Output lands next to DeployPaths.m, same
% base name.

mcc -m DeployPaths.m -v