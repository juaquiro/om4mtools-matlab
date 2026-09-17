function checkStats_Toolbox()
    % checkStats_Toolbox errors unless the Statistics Toolbox is
    % installed with version >= 8.2

tb='stats'; %toolbox
v=ver(tb);
if(isempty(v))
    error('Statistics toolbox not installed');
end

tbv='8.2'; %minmum version
if verLessThan(tb, tbv)
    error(['stats toolbox is less than: ' tbv]);
end
end