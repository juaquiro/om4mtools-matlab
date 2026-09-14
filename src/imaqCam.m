classdef imaqCam < handle & OM4MClassLib.DataStructs.IProps
    %imaqCam describes a camera configures using the imaqtool
    %his class inherits from handle and implements interface IProps
    
    
    %% propiedades
    
    %% protected props
    properties (Access=protected)
        props; % Camera propierties proetcted for potential inheritance
    end
    
    properties (Access=public) %GetAccess=private, SetAccess=private
        vid; %camera vid
        src; %vid sourcec.
        isStopped; %StopCam is executed
        sizeCData; %CData size of hImage (it does not must be the same than ImageSize that is linked with the acquisition device)
        FilterImagesFlag; %Filter data from acquired images to reduce noise
        FilterWindow; %Window size selected for filtering.
    end
    
    properties (Access=public) %GetAccess=public, SetAccess=public
        hImage; %handle of a image object is used for the preview function and the depicting of the results
        Data; %imaqCamData for hdr imaging
        gc; %geometric calibrator
    end
    
    %size of the captured image
    properties (Dependent=true, GetAccess=public, SetAccess=private)
        %ImageSize; %[NRows, NCols, NBands]
    end
    
    
    
    %% metodos publicos
    methods
        % constructor
        % vidIniFunc is a handle to a video object Initialization function
        % as the ones generated from imaqtool->file->Generate matlab code file
        function this=imaqCam(vidIniFunc)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            try                
            %check input
            if not(isa(vidIniFunc, 'function_handle'))
                retMsg=[inputname(1) ' must be a function handle. The funcion must be created with imaqtool->file->Generate matlab code file'];
                error([callFunc, '->' retMsg]);
            end
            
            this.StopAllCameras();
            this.vid=vidIniFunc(); %load the vid object from the function handle vidIniFunc
            this.src=getselectedsource(this.vid);
            this.gc=camGeomCal();
            
            %check vid
            if not(isa(this.vid, 'videoinput')) || not(isvalid(this.vid))
                retMsg=[inputname(1) ' function does not initailice a valid video object'];
                error([callFunc, '->' retMsg]);
            end
            
            % Initialization
            this.Init();
            
            catch ME                
                this.vid=imaqCam.getFirstImaqCamAvailable;                
                this.src=getselectedsource(this.vid);
                this.gc=camGeomCal();
                
                % Initialization
                this.Init();
                retMsg=[ME.message, 'ERROR LOADING CAM: USING FIRST IMAQ CAM AVAILABLE'];
                opts = struct('WindowStyle','modal','Interpreter','tex');
                warndlg(retMsg, 'Warning', opts);
            end                                    
        end
        
        %this function gets the src props, its possible values and status
        %this function adds the current value
        function srcInfo=getSrcInfo(this)            
            %get props info
            srcInfo=propinfo(this.src);
            %get props vals
            srcPropNames = fieldnames(srcInfo) ;
            for n=1:length(srcPropNames)
                propName=srcPropNames{n};
                %add current value
                srcInfo.(propName).Value=this.src.(propName);
            end
            
        end
        
        %set a src property
        function setSrcProp(this, propName, propVal)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            if isprop(this.src,propName)
                this.src.(propName) = propVal;
            else
                retMsg=[propName ': Invalid property'];
                warning([callFunc, '->' retMsg]);
            end
        end
        
        %get a src property
        function propVal=getSrcProp(this, propName)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            if isprop(this.src,propName)
            propVal=this.src.(propName);
            else
                retMsg=[propName ': Invalid property'];
                warning([callFunc, '->' retMsg]);
                propVal=NaN;
            end
        end
        
        
        %destructor se ejecuta cdo eliminamos imaqCam
        function delete(this)
            if isa(this.vid, 'videoinput')
                stop(this.vid);
                delete(this.vid);
            end
        end
        
        %this function os called for all hImage set ops
        function set.hImage(this, value)
            this.hImage=value;
            
            if ishandle(this.hImage)
                this.sizeCData=size(get(this.hImage, 'CData'));
                setappdata(this.hImage, 'sizeCData', this.sizeCData);
            end
        end
        
    end
    
    %% metodos publicos
    methods (Access=public)
        
        %start both devices
        function Start(this)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            %via software no es posible la sincronizacion si el trigger
            %esta a manual podemos mas o menos lanzarlo de forma sincrona
            %asumimos que la mayor parte del tiempo se va en la
            %inicializacion
            this.isStopped=false;
            
            if not(strcmp(this.vid.TriggerType, 'manual'))
                retMsg=['Invalid Trigger type trigger must be manual'];
                error([callFunc, '->' retMsg]);
            end
            
            if not(isrunning(this.vid))
                start(this.vid);
                %damos una pausa para dar tiempo a que las camaras se
                %inicializen OK
                pause(1);
                
            end
            
            %init data
            this.Data=imaqCamData;
            this.Data.VideoResolution=this.vid.VideoResolution;
            
        end
        
        %this function capture a snapshot of camera
        %the optional parameter indicates where hdr is on or not, default
        %is hdrFlag=false;
        function Capture(this, varargin)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            numvarargs = length(varargin);
            if numvarargs > 3
                retMsg=[callFunc ': requires at most 3 optional inputs the hdrImage, forceRadCal and geomCal'];
                error(retMsg);
            end
            
            % set defaults for optional inputs for [hdrImage, forceRadCal, geomCal]
            optargs = {false, false, false};
            
            % now put these defaults into the valuesToUse cell array,
            % and overwrite the ones specified in varargin.
            optargs(1:numvarargs) = varargin;
            % or ...
            % [optargs{1:numvarargs}] = varargin{:};
            
            % Place optional args in memorable variable names
            [hdrImage, forceRadCal, geomCal] = optargs{:};
            
            %las camaras tienen que estar running
            if not(isrunning(this.vid))
                retMsg=['Cameras must be running before ' callFunc];
                error([callFunc, '->' retMsg]);
            end
            
            if not(hdrImage)
                
                %primero lanzo el trigger y comienza la adquisicion
                %(el trigger esta a manual)
                trigger(this.vid);
                
                %espero a completar la adquisicion
                wait(this.vid, 10, 'logging');
                
                %getData
                [this.Data.I, ~, metadata] = getdata(this.vid, 1);
                
                if this.FilterImagesFlag == true
                    
                    for j = 1:size(this.Data.I,3) %Filter each image chanel 
                        
                        this.Data.I(:,:, j)=medfilt2(this.Data.I(:,:, j), this.FilterWindow);
                    
                    end
                    
                end
                
                this.Data.timeStamp=datestr(metadata.AbsTime,'mmm.dd,yyyy HH:MM:SS.FFF');
                
                if this.vid.FramesAvailable
                    stop(this.vid)
                    retMsg=[CallFunc ':LostFrame'];
                    warning(retMsg);
                end
                
                %undistort capture
                if geomCal
                    [this.Data.I, this.Data.X, this.Data.Y]=this.gc.undistortImage(double(this.Data.I));
                end
                
                
            else %hdrFlag==true
                propName='Exposure';
                srcInfo=this.getSrcInfo();
                
                expRange=srcInfo.(propName).ConstraintValue;
                
                
                maxExpVal=this.props.Get(char(imaqCamProps.maxExpVal)); % see Init to check default
                if expRange(2)< maxExpVal
                    maxExpVal = expRange(2);
                end
                
                expVals=maxExpVal:-1:expRange(1);
                exposureTimes=2.^double(expVals); %in s
                
                numExposures=length(expVals);
                tmax=1.5*exposureTimes(1); %in s
                imList=cell(1, numExposures);
                
                for n=1:numExposures
                    %set exp time
                    this.Stop();
                    this.setSrcProp(propName, expVals(n));
                    this.Start();
                    
                    %primero lanzo el trigger y comienza la adquisicion
                    %(el trigger esta a manual)
                    trigger(this.vid);
                    
                    %espero 2 exposuretimes a completar la adquisicion
                    wait(this.vid, tmax, 'logging');
                    
                    %getData
                    [I, ~, ~] = getdata(this.vid, 1);
                    [~,~,NP]=size(I);
                    %if GV convert to RGB
                    if NP==1
                        I=cat(3, I, I, I);
                    end
                    
                    if this.FilterImagesFlag == true
                    
                        for j = 1:size(I,3) %Filter each image chanel 
                        
                            I(:,:, j)=medfilt2(I(:,:, j), this.FilterWindow);
                    
                        end
                    
                    end
                
                    imList{n}=I;
                    
                    if this.vid.FramesAvailable
                        stop(this.vid)
                        retMsg=[CallFunc ':LostFrame'];
                        warning(retMsg);
                    end
                end
                
                % precompute the weighting function value
                % for each pixel
                weights = zeros(1, 255);
                for i=1:256
                    weights(i) = weight(i,1,256);
                end
                
                imSize=this.Data.VideoResolution;
                numPixels=imSize(1)*imSize(2);
                % load and sample the images
                [zRed, zGreen, zBlue, sampleIndices] = makeImageMatrixFromIm(imList, numPixels);
                
                B = zeros(size(zRed,1)*size(zRed,2), numExposures);
                
                %fprintf('Creating exposures matrix B\n')
                for i = 1:numExposures
                    B(:,i) = log(exposureTimes(i));
                end
                
                l=50; %lambda
                % solve the system for each color channel
                hdrCalFile=this.props.Get(char(imaqCamProps.hdrCalFile)); %see Init for default
                if forceRadCal
                    % fprintf('Solving for red channel\n')
                    [gRed,lERed]=gsolve(zRed, B, l, weights);
                    % fprintf('Solving for green channel\n')
                    [gGreen,lEGreen]=gsolve(zGreen, B, l, weights);
                    % fprintf('Solving for blue channel\n')
                    [gBlue,lEBlue]=gsolve(zBlue, B, l, weights);
                    save(hdrCalFile,'gRed', 'gGreen', 'gBlue');
                else
                    if exist(hdrCalFile, 'file') == 2
                        load(hdrCalFile);
                    else
                        retMsg=[callFunc ' HDR calibration file not found: ' hdrCalFile];
                        error(retMsg);
                    end
                end
                
                
                % compute the hdr radiance map
                %fprintf('Computing hdr image\n')
                
                hdrMap = hdrFromIm(imList, gRed, gGreen, gBlue, weights, B);
                %luminance
                L = 0.2125 * hdrMap(:,:,1) + 0.7154 * hdrMap(:,:,2) + 0.0721 * hdrMap(:,:,3);
                %tonemap
                
                % specify resulting brightness of the tonampped image. See reinhardGlobal.m
                % for details
                a = 0.72;
                % specify saturation of the resulting tonemapped image. See reinhardGlobal.m
                % for details
                saturation = 0.6;
                [ldrGlobal, ~ ] = reinhardGlobal( hdrMap, a, saturation );
                
                
                %save data to this.Data
                this.Data.I = hdrMap;
                this.Data.imList=imList;
                this.Data.L=L;
                this.Data.exposureTimes=exposureTimes;
                this.Data.toneMap=ldrGlobal;
                
                %undistort HDR specific
                if geomCal
                    [this.Data.L, ~, ~]=this.gc.undistortImage(this.Data.L);
                    [this.Data.toneMap, ~, ~]=this.gc.undistortImage(this.Data.toneMap);
                    [this.Data.I, this.Data.X, this.Data.Y]=this.gc.undistortImage(this.Data.I);
                else
                    [NR, NC, ~]=size(this.Data.I);
                    [this.Data.X, this.Data.Y]=meshgrid(1:NC, 1:NR);
                end
            end
            
            
            
            
            
        end
        
        
        
        
        %stop acquisition
        function Stop(this)
            stop(this.vid);
        end
        
        % set the UpdatePreviewWindowFcn, hFcn handle to a updatefunction
        function SetUpdatePreviewWindowFcnCamera(this, hFcn)
            this.StopPreview();
            %pass props to the hImage so callback functions can use them
            %without being connect to ythe imaqCam class
            setappdata(this.hImage,'camProps',this.props);
            setappdata(this.hImage,'UpdatePreviewWindowFcn',hFcn);
            this.StartPreview();
        end
        
        
        function StartPreview(this)
            preview(this.vid, this.hImage);
        end
        
        function StopPreview(this)
            stoppreview(this.vid);
        end
        
        
        % get the image size used
        function imSize = ImageSize(this)
            vidRes = get(this.vid, 'VideoResolution');
            nBands = get(this.vid, 'NumberOfBands');
            NR=vidRes(2);
            NC=vidRes(1);
            imSize=[NR, NC, nBands];
            
        end
        
    end
    
    %% metodos privados
    methods (Access=private)
        function this=Init(this)
            
            
            
            %in R2015 the import (import OM4MClassLib.DataStructs.*;) does not work properly we must qualify the whole class name
            this.props=OM4MClassLib.DataStructs.PropsEnumList('imaqCamProps');
            
            %forzamos la configuracion del trigger a manual
            triggerconfig(this.vid, 'manual');
            
            %1 frame por triger y que paren cdo se llegue a los frames
            %indicados en TriggerRepeat
            set(this.vid, 'FramesPerTrigger', 1, 'TriggerRepeat', Inf);
            
            %aqui especificamos cada cuantas frames se ejectuta el evento FramesAcquired
            set(this.vid, 'FramesAcquiredFcnCount', 1);
            
            %this is usefull for some callbacks that have as input
            %parameter the vid object
            this.vid.UserData=this.vid;
            
            %init data
            this.Data=imaqCamData;
            this.Data.VideoResolution=this.vid.VideoResolution;
            
            %if the hImage are not init the setPreviewFcn does not
            %work
            %init hImages:
            ImSize=this.ImageSize;
            NR=ImSize(1); NC=ImSize(2);
            hFigure=figure('Toolbar','none',...
                'Menubar', 'none',...
                'NumberTitle','Off',...
                'Name','imaqCam Preview Window', 'Visible', 'off');
            
            %handle to RGB image
            this.hImage=imshow(cat(3,zeros(NR, NC), zeros(NR, NC), zeros(NR, NC)));
            
            %init isProcessing
            this.isStopped=false;
            
            %init filter values
            this.FilterImagesFlag=false;
            this.FilterWindow = [10 10];
            
            %init values for props
            detectCornerParams.QualityLevel=0.001;
            detectCornerParams.Method='Harris';
            detectCornerParams.SensitivityFactor=0.04;
            this.props.Set(char(imaqCamProps.detectCornerParams), detectCornerParams);
            this.props.Set(char(imaqCamProps.maxExpVal), 1); %1 sec
            this.props.Set(char(imaqCamProps.hdrCalFile), 'gMatrix.mat');
            
            %this prop must be set before use of the detect corners call
            %back see tests for more infor. Here basically changes the
            %screen resolution when used and makes necessary the prsence of
            %the computer vision toobox
            %this.props.Set(char(imaqCamProps.drawObject), vision.ShapeInserter);
            
            
            %en caso de quere usar los callbacks de froma asincrona se
            %pueden usar de esta forma
            %pata poder pasar this.vidR como parametro adicional (adicional
            %a this.vidL y event) a CameraLTriggerEventCallback hay que
            %usar esta notacion de cell array ver Creating Callback
            %Functions
            %this.vidL.TriggerFcn={'HWCameras.TriggerEventCallback'};
            %this.vidL.FramesAcquiredFcn={'HWCameras.CameraLFramesAcquiredEventCallback'};
            
            %DEBUG AQ para depuracion dejar comentado en general
            %aqui llamamos a imaqcallback (ver ayuda) cada trigger
            %set(this.vid,'TriggerFcn',@imaqcallback)
            
            %DEBUG AQ descomentar para que salga la info de captura de vidR
            % set(this.vidR,'FramesAcquiredFcn',@imaqcallback)
            % si quisieramos recuperar algo de info desde dentro de la
            % callback o la sacamos a traves de la funcion getdata(vid)
            % o pasamos una variable en UserData del vid
            % si lo que queremos es pasar parametros sin mas se puede
            % hacer mediante la notacion
            % this.vidL.FramesAcquiredFcn={'funName',par1,par2,...};
            
            %aqui llamamos a
            %'imaqCam.CameraLFramesAcquiredEventCallback' para cada
            %frame capturado
            %this.vid.FramesAcquiredFcn={'imaqCam.FrameAcquiredEventCallback'};
        end
    end
    
    
    %% metodos estaticos
    methods(Static)        
        %this function save the object imaqCam and optionally accepts a
        %fileName
        function save(camObj,fileName)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            camClassName='imaqCam';
            
            if not(isa(camObj, camClassName))
                nameCamObj = inputname(1);
                retMsg=[nameCamObj ' must be a ' camClassName ' object'];
                error([callFunc, '->' retMsg]);
            end
            
            save(fileName,'camObj');
        end
        
        function camObj=load(fileName)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            camClassName='imaqCam';
            
            S=load(fileName);
            camObj=S.camObj;
            
            if not(isa(camObj, camClassName))
                retMsg=[fileName ' does not contain a ' camClassName ' object'];
                error([callFunc, '->' retMsg]);
            end
        end
        
        
        %solo sirve para quitar el UpdatePreviewWindowFcn
        function VoidUpdatePreviewCallback(obj,event,hImage)
            set(hImage, 'CData', event.Data);
        end
        
        %this function callback transform input frame from RGB to YCbCr color space
        function toYCBCRCallback(obj,event,hImage)
            % get current image frame.
            I=event.Data; %esto es lo correcto pero tb se puede usar I=getsnapshot(obj);
                                   
            set(hImage, 'CData', rgb2ycbcr(I));
        end
        
        %this function callback insert in real time the lens marks used by the transmision deflectometer
        function insertLensMarks(obj,event,hImage, lensMarks)
            % get current image frame.
            I=event.Data; %esto es lo correcto pero tb se puede usar I=getsnapshot(obj);
                                  
            % get image size
            [NR, NC, NP]=size(I);
            xm=round(0.5*NC);
            ym=round(0.5*NR);
            lineH=[1, ym, NC, ym];
            lineV=[xm, 1, xm, NR];
            allLines=[lineH; lineV];
            
            %Computer Vision ToolBox insert lines
            I = insertShape(I, 'line', allLines,'LineWidth',5);
            
            %insert marks at 32 mm
            mm2px=NC/lensMarks.imageSizeX;%mm            
            xc=lensMarks.pos;%mm
            circleL=[ xm-xc*mm2px, ym, 20 ];
            circleR=[ xm+xc*mm2px, ym, 20 ];
            allCircles=[circleL; circleR];
            I = insertShape(I, 'circle', allCircles,'LineWidth',5);
            
            
                                   
            set(hImage, 'CData', I);
        end

        
        %this function callback detect corners in a preview windos using
        %the parameters specified at props
        function detectEdgeCallback(obj,event,hImage)
            % get current image frame.
            I=event.Data; %esto es lo correcto pero tb se puede usar I=getsnapshot(obj);
            
            [~, ~, NP]=size(I);
            if NP==3
                g=edge(rgb2gray(I));
            else
                g=edge(I);
            end
            
            set(hImage, 'CData', cat(3, g, g, g));
            
        end
        
        %this function callback subtract a ref image from input frames
        function subtractRefImageCallback(obj,event,hImage, refImage)
             % this is useful for preview purpouses
            % obj — The video input object being previewed
            % event — An event structure containing image frame information. For more information, see below.
            % himage — A handle to the image object that is being updated
            % refImage referencia image to subtract for every input image
            % in event. It must be same type that event.Data
            % to pass this function handle use
            % refImage=ones(10); %a example value
            %then define a functon handle of three params
            %[obj,event,hImage] and pass refImage as a fixed param
            % f=@(obj,event,hImage)imaqCam.subtractRefImageCallback(obj,event,hImage, refImage)
            
            % get current image frame.
            I=event.Data; %esto es lo correcto pero tb se puede usar I=getsnapshot(obj);
            dI=imsubtract(I, refImage);
           
            set(hImage, 'CData', dI);
            
        end
        
        
        %this function callback substract input image from ref image in a preview windos using
        %the parameters specified at camProps
        function detectCornerPointsCallback(obj,event,hImage)
            % This callback function detect corner points in the input image and overtites it with markers
            % this is useful for preview purpouses
            % obj — The video input object being previewed
            % event — An event structure containing image frame information. For more information, see below.
            % himage — A handle to the image object that is being updated
            
            % this callback is based in the update_livehistogram_display.m callback
            % example
            
            % get current image frame.
            I=event.Data; %esto es lo correcto pero tb se puede usar I=getsnapshot(obj);
            [NR, NC, NP]=size(I);
            
            %transform to uint8 GV
            if(NP==3)
                g=uint8(rgb2gray(I));
            else
                g=I;
            end
            
            %detect corners
            %aqui mostramos como recuperar los parametros que se han
            %pasado previamente en la funcion SetUpdatePreviewWindowFcnCamera
            camProps=getappdata(hImage, 'camProps');
            detectCornerParams=camProps.Get(char(imaqCamProps.detectCornerParams));
            C = corner(g,...
                'QualityLevel', detectCornerParams.QualityLevel, ...
                'method', detectCornerParams.Method,...
                'SensitivityFactor', detectCornerParams.SensitivityFactor);
            
            
            r=int32(C(:,1))';  c=int32(C(:,2))';
            if(isempty(r)||isempty(r))
                r=int32(1);
                c=int32(1);
            end
            nC=length(r);
            
            %circle radius R=4 px
            R=4*ones(1, nC, 'int32');
            circles2draw=[r;c;R]'; %Mx3
            
            %draw circles on image
            %if we don clone at the end we must release
            %shapes = clone(detectCornerParams.drawObject);
            shapes = clone(camProps.Get(char(imaqCamProps.drawObject)));
            shapes.Shape = 'Circles';
            %ver http://www.mathworks.com/help/toolbox/vision/ref/vision.shapeinserterclass.html
            %tb se podria hacer con un objeto MarkerInserter
            shapes.BorderColor = 'custom';
            shapes.CustomBorderColor=[255*ones(nC, 1), zeros(nC, 1), zeros(nC, 1)];
            
            
            %to draw in color input image must be RGB
            I=step(shapes, I, circles2draw);
            %g=step(shapes, cat(3, g, g, g), circles2draw);
            %release(shapes); if we do not clone we must release
            
            sizeCData=getappdata(hImage, 'sizeCData');
            if(length(sizeCData)==2) %solo hay dos dimensiones
                set(hImage, 'CData', rgb2gray(I));
            else
                set(hImage, 'CData', I);
            end
            %drawnow; % Refresh the display. this is necesary in the
            %update_livehistogram_display.m, however here it generates a 'UpdatePreviewWindowFcn' event that makes a
            %second call to detectCornerPointsCallback with the data
            %already modified by the shapes object
        end
        
        
        % este evento se lanza inmediantamente despues de ejecutar el
        % trigger
        function TriggerEventCallback(vid, event)
            
        end
        
        %este evento se ejecuta tras la captura de un frame por parte de
        %la camara
        function FrameAcquiredEventCallback(vid, event)
            %DEBUG AQ descomentar para que salga el tiempo de captura en
            %pantalla
            imaqcallback(vid, event);
        end
        
        %stops, delete an clear all remaining vids
        function StopAllCameras()
            vids=imaqfind;
            
            for n=1:length(vids)
                stop(vids(n));
                delete(vids(n));
                clear vids(n);
            end
        end
        
        % get the first winvideo camera avalilable
        function [vidwv, devicewv]=getFirstImaqCamAvailable()
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            imaqInfo = imaqhwinfo;
            if isempty(imaqInfo.InstalledAdaptors)
                vidwv=[];
                devicewv=[];
                retMsg=['No Image Acquisition adaptors found (check with imaqtool)' ];
                warndlg([callFunc, '->' retMsg]);
            else
            
            vidwv=videoinput('winvideo', 1);
            devicewv = getselectedsource(vidwv);
            end
        end
        
        function vid=getVidFromName(adaptorName, name, vidFormat)
            %             adaptorName='winvideo';
            %             name='HD WebCam';
            %             vidFormat = 'MJPG_160x120';
            
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            info = imaqhwinfo(adaptorName);
            deviceIDList=info.DeviceIDs; %cell array of IDs
            N=length(deviceIDList);
            namesList=cell(1, N);
            for n=1:N
                dev_info = imaqhwinfo(adaptorName, deviceIDList{n});
                namesList{n}=dev_info.DeviceName;
            end
            
            index = find(ismember(namesList, name));
            if isempty(index)
                retMsg=[callFunc ' : error loading Adaptor ' adaptorName ' for Camera ' name ' with Format ' vidFormat];
                error(retMsg);
            end
            deviceID=deviceIDList{index};
            
            vid=videoinput(adaptorName, deviceID, vidFormat);
            
            %if desired some general props can be set for example
            
            %src = getselectedsource(vid);
            %             vid.FramesPerTrigger = 1;
            %             vid.ReturnedColorspace = 'grayscale';
            %
            %             if isprop(src, 'ExposureMode')
            %                 src.ExposureMode = 'manual';
            %             end
            %
            %             if isprop(src, 'GainMode')
            %                 src.GainMode = 'manual';
            %             end
            %
            %             if isprop(src, 'BacklightCompensation')
            %                 src.BacklightCompensation = 'off';
            %             end
            %
            %             if isprop(src, 'WhiteBalanceMode')
            %                 src.ExposureMode = 'manual';
            %             end
            
        end
        
        
        
        function CDS = GenCamDataStruct()
            [~, CDSFields]=enumeration('EnumImaqCamData');
            vals=cell(size(CDSFields)); %empty cell array
            CDS=cell2struct(vals, CDSFields);
            
            %set def values for all fields
            for n=1:length(CDSFields)
                CDS.(CDSFields{n})=[];
            end
            
        end
        
        %this function checks if CDS is a structire according to EnumImaqCamData
        function r=isCamDataStruct(CDS)
            
            f1=fieldnames(CDS); %CDS field names
            [~, f2]=enumeration('EnumImaqCamData');  %enumeration field names
            
            r=isequal(f1, f2);
        end
        
        
    end
    
    %% get set nethods
    methods
        %devolvemos la imagen de momento
        function value = get.Data(this)
            value=this.Data;
        end
    end
    
    
    %% public IProps interface
    %check Get implementation¡¡
    methods
        % Get interface, note the no parameter
        function ret=Get(this, props)
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end
        
        %Set interface
        function this=Set(this, props, propvals)
            switch props
                case 'geomCalFile'
                    this.gc.loadCal(propvals);
            end
            
            this.props.Set(props, propvals);
        end
    end
end
