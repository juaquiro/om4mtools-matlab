function [ SMatrix] = GetScaling( r, n )
% GetScaling Builds a scaling matrix to compensate the fact that the measured area
% can be bigger than the unit circle
%   r is the radius of the measured area and n is the principal order of
%   the higher order zernike polynomial.

    % Dimension of the output matrix
    D = n + 1;
    
    %Calculation of it components
    [i, j] = ndgrid(1:D);
    SMatrix = (1/r).^(i + j - 3);

end
