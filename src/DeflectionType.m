%> @file DeflectionType.m
%> @brief enumeration with the modes of a deflectometer
%> @copyright 2016 IOT
%> @author AQ 21MAR16
%> @see LensMapperMeasurement and class TransDeflAppInterface in repor
%> Perseus

% ======================================================================
%> @brief enumeration with the modes of a deflectometer
%
%> @details the modes can be "direct" or "moire".
%> DeflectionType enumeration of types of deflection info
%> In the FT method, by default the four side lobes are orderers in FF in a clockwise order
%>      2
%>    1 X 3
%>      4
%> When wr is passesd as a param the closest lobe to wr{1} is
%> located and numbered 1, the remaining lobes are numbered
%>  clockwise
%>  for a linear fringe pattern the numbering is 
%>    1 X 2
%>  or
%>      1 
%>      X 
%>      2        
%>   In Moire mode the fringe pattern is the Moire fringe formed by two high freq
%>   grids. In this case the X and Y lobes are 
%>   -LobeX=4;
%>   -LobeY=3;
%>   In Direct Mode the fringe pattern is a image of the deformed
%>   grid. In this case the X and Y lobes are 
%>   -LobeX=3;
%>   -LobeY=4;
% ======================================================================
classdef DeflectionType            
    enumeration
        %> no moire fringes, the grid is resolved by the camera
        Direct; 
        %> moire fringes. Lens Power between -5 and 5D
        Moire;  
        %> moire fringes. Lens power bellow -5D
        MoireExtMinus; 
        %> moire fringes. Lens power above 5D
        MoireExtPlus; 
    end
end