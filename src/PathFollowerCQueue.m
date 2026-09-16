classdef PathFollowerCQueue <  PathFollower
    % PathFollowerCQueue CQueue-based path follower for spatial image
    % processing - one CQueue per quality level, pops from the highest
    % non-empty level first
    %
    % Description:
    %   Based on the legacy PathFollower.cs implementation. See
    %   PathFollowerTypes for available types, PathFollowerFactory for a
    %   static factory, testFPAPathFollowerCQueue for unit tests, and
    %   PathFollowerModes for path-follower modes.

    %% props
    %protected
    properties (Access=protected)
        pixelQueueArr; % cell array of nLevels CQueue objects for pixel storage
        enqueuedMask; % binary mask of points already added to pixelQueueArr
    end

    %public
    properties
    end



    %% public methods
    methods
        function this=PathFollowerCQueue(nLevels, qualityImage, roiMask, followMode)
            % PathFollowerCQueue constructs a CQueue-based path follower
            % (concrete PathFollower implementation - see superclass)
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
        
        function P=GetNext(this)
            % GetNext adds PCurrent's neighbors, then pops and returns
            % the next pixel from the highest non-empty quality-level
            % queue ([] if all queues are empty)
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
        
        
        function this=AddPoint(this, P)
            % AddPoint pushes P (x, y) onto the queue matching its
            % quality level, if it wasn't already enqueued; errors if P
            % is outside roiMask
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
        function this=Init(this)
            % Init allocates enqueuedMask and one CQueue per quality level
            this.enqueuedMask=false(size(this.roiMask));
            
            import OM4MClassLib.DataStructs.*;
            this.pixelQueueArr=cell(1, this.nLevels);
            for n=1:this.nLevels
                this.pixelQueueArr{n}=CQueue;
            end
        end
    end
    
    
end

