classdef PathFollower <  handle
    % PathFollower abstract interface for path followers, useful when
    % processing igrams in the spatial domain
    %
    % Description:
    %   See PathFollowerTypes for available types, PathFollowerFactory
    %   for a static factory, testFPAPathFollowerCQueue for unit tests,
    %   PathFollowerCQueue for a concrete implementation,
    %   PathFollowerModes for path-follower modes, and "Quality Map" in
    %   Servin, Quiroga & Padilla, "Fringe Pattern Analysis for Optical
    %   Metrology: Theory, Algorithms, and Applications," Wiley-VCH (2014).

    %% props
    %private
    properties (Access=protected)
        PCurrent; % current pixel
        roiMask; % binary processing ROI
        NR; % roiMask row count
        NC; % roiMask column count
        connectedRows;
        connectedCols;
        nLevels; % number of levels of the quality map
    end

    %public
    properties
        qualityMap; % quality map used to guide the path follower
    end


    %% abstract methods
    %public interface
    methods (Abstract=true)
        % GetNext returns the next available point from the path follower
        P=GetNext(this); %

        % AddPoint adds point P (x, y) to the path follower's queue,
        % usually called once to seed it
        this=AddPoint(this, P); %
    end
    
    
    
    %% public methods
    methods
        function this=PathFollower(nLevels, qualityImage, roiMask, followMode)
            % PathFollower constructs a path follower, computing its
            % discrete quality map (see ComputeQualityMap) from
            % qualityImage/roiMask/nLevels/followMode (see PathFollowerModes)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            if isscalar(qualityImage) || isscalar(roiMask)
                retErrorMsg=['quality image and/or roiMask must be a matrix>'  callFunc];
                error([class(this) '->' retErrorMsg])
            end
            
            %validate inputs CheckInputParam raises and exception in case
            %of error
            vList={1, 2, 3, 4, 5, 6};
            r=Validation.CheckInputParam(nLevels, vList);
            
            %validate followMode
            if not(isa(followMode, 'PathFollowerModes'))
                retErrorMsg=['followMode must be a PathFollowerModes enumeration>'  callFunc];
                error([class(this) '->' retErrorMsg])
            end
            
            this.qualityMap=this.ComputeQualityMap(qualityImage, roiMask, nLevels, followMode);
            this.nLevels=nLevels;
            this.roiMask=roiMask;
            this.PCurrent=[];
            [this.NR, this.NC]=size(this.roiMask);
            this.connectedRows=[-1, -1, 0, 1, 1, +1,  0, -1];
            this.connectedCols=[ 0, +1, 1, 1, 0, -1, -1, -1];
        end
        
        
        
        function this=Add4Neighbour(this)
            % Add4Neighbour adds PCurrent's 4-connected neighbors that
            % fall inside roiMask to the pixel queue (via AddPoint)
            N=length(this.connectedCols);
            if not(isempty(this.PCurrent))
                for n=1:N
                    r=this.PCurrent.y+this.connectedRows(n);
                    c=this.PCurrent.x+this.connectedCols(n);
                    
                    if r>0 && r<=this.NR
                        if c>0 && c<=this.NC
                            if(this.roiMask(r,c))
                                %P=OM4MClassLib.DataStructs.Pixel(c,r);
                                P.x=c; P.y=r; %esto ahora 4 segundos para una imagen 100x100
                                this.AddPoint(P);
                            end
                        end
                    end
                end
            end
        end %function this=Add4Neighbour(this)
        
    end
    
    
    %% private methods
    methods (Access=private)
        
    end
    
    
    %%static methods
    methods(Static)
        
        function qualityMap=ComputeQualityMap(qualityImage, roiMask, nLevels, followMode)
            % ComputeQualityMap discretizes qualityImage into nLevels
            % levels, per followMode (see PathFollowerModes): abs
            % magnitude, absdel2 (Laplacian), absgrad (gradient
            % magnitude), image (raw values), or distance-to-mask
            % (optionally combined with qualityImage)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            switch followMode
                case PathFollowerModes.abs
                    %all values will be in the range [1 nLevels]
                    qualityMap=round((nLevels-1)*mat2gray(abs(qualityImage)))+1;
                case PathFollowerModes.absdel2
                    %all values will be in the range [1 nLevels]
                    qualityMap=round((nLevels-1)*mat2gray(del2(qualityImage)))+1;
                case PathFollowerModes.absgrad
                    %all values will be in the range [1 nLevels]
                    [dx, dy]=gradient(qualityImage);
                    q=abs(dx+1i*dy);
                    qualityMap=round((nLevels-1)*mat2gray(q))+1;
                case PathFollowerModes.image
                    %all values will be in the range [1 nLevels]
                    qualityMap=round((nLevels-1)*mat2gray(qualityImage))+1;
                case PathFollowerModes.distance2Mask
                    %all values will be in the range [1 nLevels] in this
                    %case 0 if for roi=false
                    has_bwdist = ~isempty(which('bwdist'));
                    if has_bwdist
                        q=bwdist(not(roiMask));
                        qualityMap=ceil((nLevels)*mat2gray(q));
                    else
                        retErrorMsg=['function bwdist() does not exist: '  callFunc];
                        error([class(this) '->' retErrorMsg]);
                    end
                case PathFollowerModes.dist2MaskImage %combines quality map and distance to the mask
                    %all values will be in the range [1 nLevels] in this
                    %case 0 if for roi=false
                    has_bwdist = ~isempty(which('bwdist'));
                    if has_bwdist
                        q=bwdist(not(roiMask));
                        q=q.*mat2gray(qualityImage);
                        qualityMap=ceil((nLevels)*mat2gray(q));
                    else
                        retErrorMsg=['function bwdist() does not exist: '  callFunc];
                        error([class(this) '->' retErrorMsg]);
                    end
                    
                    
            end
        end
        
        
        
    end
    
end