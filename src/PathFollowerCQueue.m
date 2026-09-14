%> @file PathFollowerCQueue.m
%> @brief File iwth the PathFollowerCQueue implementation
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16


% ======================================================================
%> @brief this class implements a CQueue based path follower for spatial image processing
%> @details this class is based in Proyectos\Legacy\Iot-om4m\Om4mLib\Trunk\src\XtremeFringe\PathFollower.cs and uses the CQueue class for the queue storage
%> @see PathFollowerTypes for avalible path follower types
%> @see PathFollowerFactory for a static factory
%> @see testFPAPathFollowerCQueue for unit tests
%> @see PathFollowerCQueue
%> @see PathFollowerModes for modes of path follower
%> @see look for "Quality Map" in Servin, M., Quiroga, J. A., & Padilla, M. (2014). Fringe Pattern Analysis for Optical Metrology: Theory, Algorithms, and Applications. Wiley vch.
% ======================================================================
classdef PathFollowerCQueue <  PathFollower
        
    %% props
    %protected
    properties (Access=protected)
        %> cell Array of nLevels Queues for pixel storage
        pixelQueueArr; 
        
        %> binary mask of the points already put into pixelQueueArr
        enqueuedMask; 
    end
    
    %public
    properties
    end
    
    
    
    %% public methods
    methods
        % ======================================================================
        %> @brief constructor Concrete implementation.  See superclass.
        % ======================================================================
        function this=PathFollowerCQueue(nLevels, qualityImage, roiMask, followMode)
            %%% Pre Initialization %%%
            % Any code not using first output argument (this)
            
            %%% no hay
            
            %%% Object Initialization %%%
            % Call superclass constructor before accessing object
            % You cannot conditionalize this statement
            
            % para pasar los varargin hay que serializarlos {:}
            this = this@PathFollower(nLevels, qualityImage, roiMask, followMode);
            
            %%% Post Initialization %%%
            % Any code, including access to object
            this.Init();
        end
        
        % ======================================================================
        %> @brief abstract interface of PathFollower
        %> @details this function return the next pixel in the queue with the higest quality. If all queues are empty returns empty
        %> @param this instance of the class.
        % ======================================================================
        
        function P=GetNext(this)
            this.Add4Neighbour();
            P=[];
            for n=this.nLevels:-1:1
                if not(this.pixelQueueArr{n}.isempty())
                    this.PCurrent=this.pixelQueueArr{n}.pop();
                    P=this.PCurrent;
                    break;
                end
            end
        end
        
        
        % ======================================================================
        %> @brief abstract interface of PathFollower
        %> @details this function adds a point to the queues if not previuosly added
        %> @param P XY point to add to the queue
        %> @param this instance of the class.
        % ======================================================================
        function this=AddPoint(this, P)
            %import OM4MClassLib.Util.*;
            %callFunc=Logging.WhoCalledMe();
            callFunc='PathFollower:AddPoint';
            
            if this.roiMask(P.y, P.x)==0
                retErrorMsg=['Point not in ROI: '  callFunc];
                error([class(this) '->' retErrorMsg]);
            end
            
            if this.enqueuedMask(P.y, P.x)==false
                levelP=this.qualityMap(P.y, P.x);
                %sometimes for constant QualityImages the resulting quality
                %map is zero
                if levelP==0 levelP=levelP+1; end
                this.pixelQueueArr{levelP}.push(P);
                
                this.enqueuedMask(P.y, P.x)=true;
            end
        end
        
        
        
    end
    
    
    %% private methods
    methods (Access=private)
        % ======================================================================
        %> @brief private Init
        %> @details this function is called form the constructor
        %> @param this instance of the class.
        % ======================================================================
        function this=Init(this)
            this.enqueuedMask=false(size(this.roiMask));
            
            import OM4MClassLib.DataStructs.*;
            this.pixelQueueArr=cell(1, this.nLevels);
            for n=1:this.nLevels
                this.pixelQueueArr{n}=CQueue;
            end
        end
    end
    
    
end

