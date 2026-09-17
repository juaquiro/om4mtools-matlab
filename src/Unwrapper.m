classdef Unwrapper <  handle & OM4MClassLib.DataStructs.IProps
    % Unwrapper abstract interface for phase unwrappers

    %% props    
    %private
    properties (Access=private)
        props;
    end
    
    %% protected abstract methods
    %each subclass must implement a protected funcion 
    methods (Abstract=true, Access=protected)
        % DoUnwrapp performs the actual unwrapping using the props set
        % by Process (phase/bmask/qual), storing the result via Set
        this=DoUnwrapp(this);
    end
    
    
    
    %% public methods
    methods
        function this=Unwrapper()
            % Unwrapper constructs an unwrapper with default props (see Init)
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('UnwrapperProps');

            % Props Initialization
            this.Init();
        end

        function this=Process(this, phase, bmask, qual)
            % Process validates/normalizes phase, bmask and qual (both
            % normalized to [0-1] internally), then unwraps via DoUnwrapp
            this.ValidateNormalice(phase, bmask, qual);
            this.DoUnwrapp();
        end
        
                        
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init sets the default thresh_flag/fatten props (shared by all unwrappers)
            %for all unwrappers
            this.Set(char(UnwrapperProps.thresh_flag), 0); %threshold the quality map, by default no threshold
            this.Set(char(UnwrapperProps.fatten), 5); %in px fatten the poxels with qual==0
        end
    end
    
    %% protected methods
    methods (Access=private)
        function this=ValidateNormalice(this, phase, bmask, qual)
            % ValidateNormalice normalizes bmask/qual to [0-1] (zeroing
            % qual outside bmask), checks phase/bmask/qual are same-sized
            % matrices, and stores them via Set - shared by all unwrappers
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            %impose ranges
            bmask=mat2gray(double(bmask)); % [0-1]
            qual=mat2gray(double(qual)); % [0-1]
            qual(not(bmask))=0; %outside bmask qual is cero
            
            
            if not(ismatrix(phase))                
                retMsg=[inputname(2) ' must be a Matrix'];
                error([callFunc, '->' retMsg]);
            end
            
            if not(isequal(size(phase), size(bmask)))
                retMsg=[inputname(2) ' and ' inputname(3) ' have different size'];
                error([callFunc, '->' retMsg]);
            end
            
            if not(isequal(size(phase), size(qual)))
                retMsg=[inputname(2) ' and ' inputname(4) ' have different size'];
                error([callFunc, '->' retMsg]);
            end

            this.Set(char(UnwrapperProps.bmask), bmask);
            this.Set(char(UnwrapperProps.phase), phase);
            this.Set(char(UnwrapperProps.qual), qual);
        end
    end
    
    %% public IProps interface
    %check Get implementation��
    methods
        function ret=Get(this, props)
            % Get returns the value of props, or the full props struct if
            % called with no props argument
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end

        function this=Set(this, props, propvals)
            % Set assigns propvals to props (no extra validation
            % currently active - see commented-out template below,
            % copied from Demodulator.Set but never adapted for UnwrapperProps)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();

%             switch props
%                 case char(DemodulatorProps.zList)
%                     if not(iscell(propvals))
%                         retErrorMsg=['zList must be a cell array: <<' char(propvals) '>>, ' callFunc];
%                         error([class(this) '->' retErrorMsg]);
%                     end
%                 case char(DemodulatorProps.NL)
%                     % validate NL
%                     % list of valid values for NL
%                     vList={2, 4};
%                     r=Validation.CheckInputParam(propvals, vList);
%             end

            this.props.Set(props, propvals);
        end
    end
    
    
    
    
end

