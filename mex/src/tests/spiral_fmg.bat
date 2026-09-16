REM .\debug\mainfmg -input spiral.257x257.phase -format byte -output spiral.257x257.aq -xsize 157 -ysize 458 -mode max_corr -bmask spiral.257x257.mask -corr spiral.257x257.corr -tsize 3 -debug yes -cycles 1 -iter 2 -thresh yes -fat n
fmg -input spiral.257x257.phase -format byte -output spiral.257x257.aq -xsize 257 -ysize 257 -mode min_var -debug yes -cycles 1 -iter 2 -thresh yes -fat n
