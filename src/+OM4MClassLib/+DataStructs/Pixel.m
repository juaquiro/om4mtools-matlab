function p=Pixel(x,y)
% Pixel this is the constructor for the pixel estructure
% x stands for cols and y stands for rows
% if x, y are vectors or matrix, fisrt they are serialiced as a column
% vector and the an struct array is created using the struct constructor
% and num2cell
%
% Copyright: AQ IOT, 2018.
p=struct('x', num2cell(x(:)), 'y', num2cell(y(:)));
end

