classdef DeflectionType
    % DeflectionType enumeration of deflectometer fringe-pattern modes
    % (direct or moire), used by LensMapperMeasurement
    %
    % Description:
    %   In the FT method, the four side lobes are ordered clockwise in
    %   the Fourier plane:
    %        2
    %      1 X 3
    %        4
    %   When wr is passed as a param, the lobe closest to wr{1} is
    %   located and numbered 1, the rest numbered clockwise; for a linear
    %   fringe pattern the numbering is "1 X 2" or "1 / X / 2" instead.
    %   In Moire mode the fringe pattern is the moire formed by two
    %   high-frequency grids, and the X/Y lobes are LobeX=4, LobeY=3. In
    %   Direct mode the fringe pattern is an image of the deformed grid
    %   itself, and LobeX=3, LobeY=4.
    enumeration
        Direct; % no moire fringes, the grid is resolved by the camera
        Moire; % moire fringes, lens power between -5 and 5D
        MoireExtMinus; % moire fringes, lens power below -5D
        MoireExtPlus; % moire fringes, lens power above 5D
    end
end