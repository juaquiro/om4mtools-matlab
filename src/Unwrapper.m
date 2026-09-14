classdef Unwrapper <  handle & OM4MClassLib.DataStructs.IProps
    %Demodulator this class implements the Demodulator abstract interface

    %% props    
    %private
    properties (Access=private)
        props;
    end
    
    %% protected abstract methods
    %each subclass must implement a protected funcion 
    methods (Abstract=true, Access=protected)
        this=DoUnwrapp(this);        
    end
    
    
    
    %% public methods
    methods
        %constructor
        function this=Unwrapper()
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('UnwrapperProps');
            
            % Props Initialization
            this.Init();
        end
        
        %processing function
        %bmask and qual are normalized [0-1] 
        function this=Process(this, phase, bmask, qual)
            this.ValidateNormalice(phase, bmask, qual);
            this.DoUnwrapp();            
        end
        
                        
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)            
            %for all unwrappers
            this.Set(char(UnwrapperProps.thresh_flag), 0); %threshold the quality map, by default no threshold
            this.Set(char(UnwrapperProps.fatten), 5); %in px fatten the poxels with qual==0
        end
    end
    
    %% protected methods
    methods (Access=private)
        %this is for use in all derived unwrappers if needed
        function this=ValidateNormalice(this, phase, bmask, qual)            
            %for all unwrappers
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

