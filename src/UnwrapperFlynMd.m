classdef UnwrapperFlynMd < Unwrapper
    % UnwrapperFlynMd Flynn minimum-discontinuity phase unwrapper, backed
    % by the compiled PUFlynMdMex MEX function (see mex/build.m)

    %% props
    %private
    properties (Access=private)
        Lib,
        LibH,
        LibFun,
    end

    %% public methods
    methods
        function  this=UnwrapperFlynMd()
            % UnwrapperFlynMd constructs a Flynn min-discontinuity unwrapper
            %%% Pre Initialization %%%
            % Any code not using first output argument (this)
            
            %%% no hay
            
            %%% Object Initialization %%%
            % Call superclass constructor before accessing object
            % You cannot conditionalize this statement
            
            % para pasar los varargin del constructor habria hay que serializarlos {:}
            this = this@Unwrapper();
            
            %%% Post Initialization %%%
            % Any code, including access to object
            this.Init();
        end      
               
    end
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init no-op: UnwrapperFlynMd needs no extra state beyond Unwrapper's
        end
    end

    %% protected abstract interface
    methods (Access=protected)
        function this=DoUnwrapp(this)
            % DoUnwrapp unwraps phase via the PUFlynMdMex MEX function
            %get data for unwrapping, already validates and normaliced
            bmask=this.Get(char(UnwrapperProps.bmask));
            phase=this.Get(char(UnwrapperProps.phase));
            qual=this.Get(char(UnwrapperProps.qual));
            
            %get params for unwrapping
            thresh_flag=this.Get(char(UnwrapperProps.thresh_flag));
            fatten=this.Get(char(UnwrapperProps.fatten));  
                        
            %unwrapp
            unw=PUFlynMdMex(phase, bmask, qual, thresh_flag, fatten);
            this.Set(char(UnwrapperProps.unw), unw);
        end
    end
    
    
end

