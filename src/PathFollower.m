%> @file PathFollower.m
%> @brief This file contains the PathFollower class
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16


% ======================================================================
%> @brief this class implements the PathFollower abstract interface
%> @details this class is very useful in procesing igrams in the spatial
%> realm.
%> @see PathFollowerTypes for avalible path follower types
%> @see PathFollowerFactory for a static factory
%> @see testFPAPathFollowerCQueue for unit tests
%> @see PathFollowerCQueue
%> @see PathFollowerModes for modes of path follower
%> @see look for "Quality Map" in Servin, M., Quiroga, J. A., & Padilla, M. (2014). Fringe Pattern Analysis for Optical Metrology: Theory, Algorithms, and Applications. Wiley vch.
% ======================================================================
classdef PathFollower <  handle
    %PathFollower 
    
    %% props
    %private
    properties (Access=protected)
        %> current pixel
        PCurrent;
        %> binary processing ROI
        roiMask;
        %> roiMask size R
        NR;
        %> roiMask size C
        NC;
        connectedRows;
        connectedCols;
        %> Number of levels of the Quality Map
        nLevels;
    end
    
    %public
    properties
        %> Quality map to guide the path follower
        qualityMap;
    end
    
    
    %% abstract methods
    %public interface
    methods (Abstract=true)
        % ======================================================================
        %> @brief get next point from the pathFollower        
        %> @return next available Point
        % ======================================================================
        P=GetNext(this); %
        
        % ======================================================================
        %> @brief this funcion adds a point to the path follower, usually it is used once
        %> @param P XY point to add to the queue
        %> @param this instance of the class.
        % ======================================================================
        this=AddPoint(this, P); %
    end
    
    
    
    %% public methods
    methods
        % ======================================================================
        %> @brief constructor
        %> @param nLevels Quality map number of levels
        %> @param qualityImage Quality image to guide the process
        %> @param roiMask ROU
        %> @param followMode see PathFollowerModes
        % ======================================================================        
        function this=PathFollower(nLevels, qualityImage, roiMask, followMode)
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
        
        
        
        % ======================================================================
        %> @brief Adds the 4 connected Neighbours of point PCurrent to the pixel Queues
        % ======================================================================
        function this=Add4Neighbour(this)
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
        
        % ======================================================================
        %> @brief this funcion calculate the discrete qualityMap from the quality image using nLevels and followMode and roiMask
        %> @param nLevels Quality map number of levels
        %> @param qualityImage Quality image to guide the process
        %> @param roiMask ROU
        %> @param followMode see PathFollowerModes
        % ======================================================================
        function qualityMap=ComputeQualityMap(qualityImage, roiMask, nLevels, followMode)
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