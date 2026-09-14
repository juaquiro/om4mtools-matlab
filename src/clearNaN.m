function noNaNcellArray=clearNaN(cellArray)

% clearNaN reads the NaN elements in a cell array and remove them,
% re-defining its size. The purpose of this function derives from the fact
% that when reading QCConclusions.xlsx sometimes empty cells that once were
% not empty appear as a NaN.
% 
% Inputs: cellArray is a cell array.
% 
% Outputs: noNaNcellArray is a the result of removing NaN elements from
% cellArray and re-definig its size. If there are not any NaN elements,
% noNaNcellArray==cellArray.
% 
% See also cellfun.
%
% Copyright IOT
% $Revision: 1 $  $Date: 08/11/2012 $
% $JJ$

z=cellfun(@(V) any(~isnan(V(:))), cellArray);
noNaNcellArray=cellArray(z);

