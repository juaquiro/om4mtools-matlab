%% generate peaks
close all
clear all

NC=400;
NR=301;
[x,y]=meshgrid(1:NC, 1:NR); x=x-0.5*NC; y=y-0.5*NR;

p=3*peaks(max([NR NC]));
p=imresize(p, [NR NC]);

pw=mod(p, 2*pi);
M1=abs(x+1i*(y+0.2*NR))<0.2*NC;
M2=abs((x+1i*(y-0.2*NR)))<0.2*NC;
M3=abs((x+1i*(y-0.1*NR)))>0.1*NC;
M=(M1|M2)&M3;


baseName='peaks';
name1=[num2str(NR) 'x' num2str(NC)];
ext_phase='.phase';
ext_mask='.mask';

pwu=uint8(255*mat2gray(pw.*M));
Mu=uint8(255*mat2gray(M));

%% phase
filename=[baseName name1 ext_phase];
fileID = fopen(filename,'w');
fwrite(fileID,pwu,'uint8');
fclose(fileID);

fileID = fopen(filename);
q=uint8(fread(fileID,[NR NC],'uint8'));
fclose(fileID);
figure; imshow(q)

%% mask
filename=[baseName name1 ext_mask];
fileID = fopen(filename,'w');
fwrite(fileID,Mu,'uint8');
fclose(fileID);

fileID = fopen(filename);
q=uint8(fread(fileID,[NR NC],'uint8'));
fclose(fileID)
figure; imshow(q)







