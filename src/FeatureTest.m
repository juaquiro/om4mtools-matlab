classdef FeatureTest < aFeature
    %FeatureGlobalMeStd
    %   This class describes a Feature that calculates the global Mean
    %   Error and Std of the DPM ins transmission mode
    
    %% private props
    properties (Access=private)
    end
    
    %% public methods
    methods
        % constructor
        function  this=FeatureTest()
            %%% Pre Initialization %%%
            % Any code not using first output argument (this)
            
            %%% no hay
            
            %%% Object Initialization %%%
            % Call superclass constructor before accessing object
            % You cannot conditionalize this statement
            
            % para pasar los varargin hay que serializarlos {:}
            this = this@aFeature();
            
            %%% Post Initialization %%%
            % Any code, including access to object
            this.Init();
        end
    end
    
    %% public abstract interface of aFeature
    methods
        % this feature get a list (cell array) of QCStatsStruct strtucts and
        % computes 4 features by sample the global me and sdc for Seq and C
        function this=Calculate(this, eDPMList)
            try
                import OM4MClassLib.Util.*
                callFunc=Logging.WhoCalledMe();
                
                % Number of samples
                le=length(eDPMList);
                
                % Check that input eDPMList is a cell array
                if not(iscell(eDPMList))
                    retErrorMsg=['input must be a Cell array of eDPMs: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
                
                % Check that all the elements contained in input eDPMList are DPMStructs
                isDPMCheck=false(1,le);
                for i=1:le
                    isDPMCheck(i)=isDPMStructTest(eDPMList{i});
                end
                if any(not(isDPMCheck))
                    retErrorMsg=['all inputs must be DPMStructs ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
                

                % Calculate features
                this.X=zeros(le, this.n);
                for i=1:le
                    Seq=eDPMList{i}.Seq; MSeq=not(isnan(Seq));
                    
                    C=eDPMList{i}.C; MC=not(isnan(C));
                    this.X(i, :)=[mean(Seq(MSeq)), std(Seq(MSeq)),...
                        mean(C(MC)), std(C(MC))];
                end
                
                labels=this.labels;
                y=this.y;
                
                if ~isempty(labels) && isempty(y)
                    %set numeric labels
                    y=pi*ones(le,1);    %init with a rare number
                    u=unique(labels);
                    ny=length(u);
                    for i=1:ny
                        ind=ismember(labels,u{i});
                        y(ind)=i-1;
                    end
                    if(any(y==pi))
                        retErrorMsg=['there is a missing label: ' callFunc];
                        error([class(this) '->' retErrorMsg]);
                    end
                    this.y=y;
                end
                
            catch ME
                throw(ME);
            end
        end
        
    end
    
    
    
    %% private methods
    methods (Access=private)
        %Initialize
        function this=Init(this)
            
            this.Id=aFeatureTypes.FeatureTest;
            this.n=4;
        end
    end
    
end
