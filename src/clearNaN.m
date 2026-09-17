function noNaNcellArray=clearNaN(cellArray)
% clearNaN removes NaN elements from cellArray, re-sizing it
% accordingly (noNaNcellArray==cellArray if there are no NaN elements).
% Exists because reading QCConclusions.xlsx sometimes turns previously
% non-empty cells that are now empty into NaN.
%
% See also cellfun.
z=cellfun(@(V) any(~isnan(V(:))), cellArray);
noNaNcellArray=cellArray(z);

