function DeployPaths
%DeployPaths es una utilidad que permite ver los paths que percive un Mfile
%compilado. Es muy util para determinar los paths percibidos entre
%diferentes sistemas operativos. Ver CompileDeployPaths.
%Para el .M En PCWIN y MAC los paths apuntan a donde deben
%el EXE en PCWIN tb funciona como se espera, pwd apunta al sitio donde esta
%el EXE
%
%PROBLEMA: en MAC si lanzamos el app desde Finder haciendo click en el bundle (.app)  pwd, y system('pwd'); apuntan al raiz "/"
%alternativa 1) configurar una variable de entorno MANOSID,
%leerla mediente un system('echo $MANOSID'); y hacer un cd
%cd('/Users/eduardopascual/Documents/MATLAB/AQ/SCC/om4mmatlabutils/UtilLib/DeployPaths');
%alternativa 2) usar el batch .sh que genera el compilador de MAC y
%ejecutar el app bundle especificando donde esta el MCR de MATLAB (ver el
%readme.txt que se genera con la compilacion)
% para DeployPaths en el MAC de la oficina esto se haria desde el
% directorio donde esta el app ejecutar:
% ./run_DeployPaths.sh /Applications/MATLAB_R2013a.app
% en un ordenador sin MATLAB me imagino que habra que usar el path donde se
% instale el MCR
   

str=sprintf('PLATFORM INDEPENDENT\n\npwd: %s\n\nctfroot: %s\n\nmfilename: %s\n\ncd: %s', pwd, ctfroot, mfilename('fullpath'), cd);
msgbox(str);

C=computer();
switch C
    case {'PCWIN', 'PCWIN64'}
        
    case 'MACI64'                
        [s, p]=system('pwd');
        [s, h]=system('echo $HOME');        
        strMAC=sprintf('MAC\n\npwd: %s\n\n HOME: %s\n\n',p, h);
        msgbox(strMAC);        
    otherwise
        error('computer-architecture not supported');
end
%f=uigetfile();
M = importdata('myfile.txt', ' ', 1);
 for k = [3, 5]
     disp(M.colheaders{1, k})
     disp(M.data(:, k))
     disp(' ')
 end

end