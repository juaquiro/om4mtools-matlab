classdef UnwrapperVoid < Unwrapper
    % UnwrapperVoid dummy unwrapper for testing purposes only - returns
    % phase masked by bmask/qual, with no actual unwrapping

    %% public methods
    methods
        function  this=UnwrapperVoid()
            % UnwrapperVoid constructs a dummy test unwrapper
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
            % Init no-op: UnwrapperVoid needs no extra state beyond Unwrapper's
        end
    end

    %% protected abstract interface
    methods (Access=protected)
        function this=DoUnwrapp(this)
            % DoUnwrapp returns phase masked by bmask and qual>0, with no
            % actual phase unwrapping (this is a dummy unwrapper)
            %get data for unwrapping, already validates and normaliced
            bmask=this.Get(char(UnwrapperProps.bmask));
            phase=this.Get(char(UnwrapperProps.phase));
            qual=this.Get(char(UnwrapperProps.qual));
            
            %unwrapp
            unw=phase.*bmask.*(qual>0);
            this.Set(char(UnwrapperProps.unw), unw);
        end
    end
    
    
end

