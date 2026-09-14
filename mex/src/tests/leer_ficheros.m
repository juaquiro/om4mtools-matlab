%% longs 
clear all
close all
basename='longs.152x458'; sizeI=[152 458];
f=fopen([basename,'.phase'], 'r') ;phase=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.surf'], 'r', 'b');surf=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq'], 'r');surfaq=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq.qual'], 'r');qual=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.mask'], 'r');mask=fread(f, sizeI, 'uchar'); fclose(f);

%% isola 
clear all
close all
basename='isola.157x458'; sizeI=[157 458];
f=fopen([basename,'.phase'], 'r') ;phase=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.surf'], 'r', 'b');surf=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq'], 'r');surfaq=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq.qual'], 'r');qual=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.mask'], 'r');mask=fread(f, sizeI, 'uchar'); fclose(f);



%% spiral
clear all
close all
basename='spiral.257x257'; sizeI=[257 257];
f=fopen([basename,'.phase'], 'r') ;phase=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.surf'], 'r', 'b');surf=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq'], 'r');surfaq=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq.qual'], 'r');qual=fread(f, sizeI, 'uchar'); fclose(f);

%% peaks
clear all
close all
basename='peaks201x300'; sizeI=[201 300];
f=fopen([basename,'.phase'], 'r') ;phase=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.aq'], 'r');surfaq=fread(f, sizeI, 'float'); fclose(f);
f=fopen([basename,'.aq.qual'], 'r');qual=fread(f, sizeI, 'uchar'); fclose(f);
f=fopen([basename,'.mask'], 'r');mask=fread(f, sizeI, 'uchar'); fclose(f);




