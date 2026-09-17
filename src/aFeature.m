classdef aFeature < handle & OM4MClassLib.DataStructs.IProps
    % aFeature abstract base class for ML features: holds the computed
    % feature matrix X plus labels y/labels, and splits them into
    % train/cross-validation/test sets (see trainSets)
    
    %% props
    
    %private
    properties (Access=protected)
        props;
    end
    
    %public no set
    properties (SetAccess=protected)
        X; %feature matrix (m x n)
        Id; %Feature indentifier, is a array of FeatureTypes see Cat
        n; %number of features
    end
    
    %public
    properties
        y; %numerical label vector (mx1)
        labels; %cell array of symbolic labels (normally strings)
        pInd; % cell which contains the index vactor of the random permutations. It can be used 
        % to reorder the QCStatsStruct in the same way as the data when
        % generating th etraining sets. Thus, each row of the X matrix can
        % be associated inmediately with the corresponding lens. The
        % components of the cell are the following sets of randomized indices:
        % {All,TRS,CVS,TES}
    end
    
    %dependent
    properties (Dependent)
        m; %number of samples
        trainSets; %this dependent property return 3 structures {X,y,labels} with the train sets
        % every time reshufles the indexs fro the 3 sets
        % TRS: TRain Set. It's a struct which contains the 60% of the X, y
        % and labels data
        % CVS: Cross Validation Set. It's a struct which contains the 20%
        % of the X, y and labels data
        % TES: Test Error Set. It's a struct which contains the last 20%
        % of the X, y and labels data
    end
    
    
    %% abstract methods, public interface
    methods (Abstract=true)
        % Calculate computes the feature matrix X from listObj, a mx1
        % array of objects
        Calculate(listObj);
    end
    
    %% property access method
    methods
        function set.y(this,value)
            % set.y validates value is a mx1 vector (or empty) before assigning
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            dim=size(value);
            % y must be a mx1 vector or be empty
            if isvector(value)
                if dim(2)~=1
                    retErrorMsg=['y must be a mx1 vector: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
            elseif ~isempty(value)
                retErrorMsg=['y must be a mx1 vector: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end            
            this.y = value;
        end
        
        function value = get.y(this)
            % get.y returns this.y, re-validating it is a mx1 vector (or empty)
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            dim=size(this.y);
            value=this.y;
            % y must be a mx1 vector or be empty
            if isvector(value)
                if dim(2)~=1
                    retErrorMsg=['labels must be a mx1 vector: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
            elseif ~isempty(value)
                retErrorMsg=['labels must be a mx1 vector: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end           
            value=this.y ;
        end
        
        function set.labels(this,value)
            % set.labels validates value is a mx1 cell array of strings
            % (or empty) before assigning
            import OM4MClassLib.Util.*;

            callFunc=Logging.WhoCalledMe();

            dim=size(value);
            % labels must be a mx1 cell array of strings or be empty
            if iscellstr(value)
                if dim(2)~=1
                    retErrorMsg=['labels must be a mx1 cell array of strings: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
            elseif ~isempty(value)
                retErrorMsg=['labels must be a mx1 cell array of strings: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end
            this.labels = value;
        end
        
        function value = get.labels(this)
            % get.labels returns this.labels, re-validating it is a mx1
            % cell array of strings (or empty)
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            dim=size(this.labels);
            value=this.labels;
            % labels must be a mx1 cell array of strings or be empty
            if iscellstr(value)
                if dim(2)~=1
                    retErrorMsg=['labels must be a mx1 cell array of strings: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                end
            elseif ~isempty(value)
                retErrorMsg=['labels must be a mx1 cell array of strings: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end
            value=this.labels ;
        end
        
        
        function value = get.X(this)
            % get.X returns the feature matrix
            value=this.X ;
        end

        function value = get.Id(this)
            % get.Id returns the feature type identifier
            value=this.Id ;
        end

        function value=get.m(this)
            % get.m returns the number of samples (rows of X)
            value=size(this.X,1);
        end

        function value=get.n(this)
            % get.n returns the number of features (columns of X)
            value=this.n;
        end

        function value=get.trainSets(this)
            % get.trainSets randomly shuffles X/y/labels (storing the
            % shuffle indices in this.pInd), then splits them into a 60%
            % train set (TRS), 20% cross-validation set (CVS), and 20%
            % test set (TES), returned as a struct with those 3
            % aFeature-typed fields (see UtilFunML.learningCurve)
            m=this.m; %samples number
            
            p=randperm(m);
            xi=this.X(p,:);            
            this.X=xi;       
            
            N1=round(0.6*m);
            N2=round(0.2*m);
            N=N1+N2;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Defining TRS, TRain Set
            TRS=aFeatureFactory.Create(this.Id);
            indTRS=1:N1;
            TRS.X=xi(indTRS,:);        
            
            % Definig CVS, Cross Validation Set
            CVS=aFeatureFactory.Create(this.Id);
            insCVS=N1+1:N;
            CVS.X=xi(insCVS,:);
            
            % Definig TES, Test Error Set
            TES=aFeatureFactory.Create(this.Id);
            indTES=N+1:m;
            TES.X=xi(indTES,:);  
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % y and labels
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % After running method Calculate, there are two possible
            % situations: y and labels are both empty or not
            if isempty(this.labels)
                [TRS.y,CVS.y,TES.y,TRS.labels,CVS.labels,TES.labels]=deal([]);
            else 
                yi=this.y(p);
                this.y=yi;
                TRS.y=yi(indTRS,:);
                CVS.y=yi(insCVS,:);
                TES.y=yi(indTES,:);
                
                lab=this.labels(p);
                this.labels=lab;
                TRS.labels=lab(indTRS,:);
                CVS.labels=lab(insCVS,:);
                TES.labels=lab(indTES,:);
            end
            
            this.pInd={p,indTRS,insCVS,indTES};
            value=struct('TRS', TRS, 'CVS', CVS, 'TES', TES);
        end
    end
    
    
    %% public interface
    methods
        function this=aFeature
            % aFeature constructs a feature with default props (see Init)
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('aFeatureProps');
            % Initialization
            this.Init();
        end

        function this=Cat(this, f)
            % Cat is meant to concatenate two features along the
            % feature dimension (n=n1+n2, same samples) - not yet
            % implemented, always errors
            error('not implemented');
            %comprobat que f es typo aFeatiure y que el Id no es el mismo
            %concatenar X de forma que el numero de featires es n=n1+n2 y
            %se mantiene el de muestras (y las etiquetas)
            %Id es ahora un array con dos enumFeatureTypes [id1, id2]
        end

        function this=AddSamples(this, f)
            % AddSamples appends f's X/y/labels (same feature Id) as
            % extra rows/samples onto this feature's X/y/labels
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            
            
            if not(isa(f, 'aFeature'))
                retErrorMsg=['Only a aFeature object is admitted: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end
            
            if not(f.Id==this.Id)
                retErrorMsg=['Only aFeature with the same Id is admitted: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end
            
            X1=this.X;
            X2=f.X;
            XX=[X1;X2];
            
            y1=this.y;
            y2=f.y;
            yy=[y1;y2];
            
            labels1=this.labels;
            labels2=f.labels;
            ylabels=[labels1;labels2];
            
            %set props
            this.X=XX;
            this.y=yy;
            this.labels=ylabels;
        end
    end
    
    
    %% private methods
    methods (Access=private)
        function this=Init(this)
            % Init sets the default aFeatureProps.M prop to an empty cell
            try
                
                %ini props
                this.Set(char(aFeatureProps.M), {});
            catch ME
                throw(ME);
            end
        end
        
    end
    
    
    %% public IProps interface
    %check Get implementation��
    %if a prop must be made dependent override corresponding function in
    %child class
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
            % Set assigns propvals to props
            this.props.Set(props, propvals);
        end
    end

    %% Static methods
    methods (Static=true)
        function save(feature,varargin)
            % save writes feature to a .mat file (default name = class
            % name + date, or varargin{1} if given)
            try
                
                if not(isa(feature, 'aFeature'))
                    error('Only a aFeature object is admitted')
                end
                
                switch nargin
                    case 1
                        complete_name=class(feature);
                        parts=regexp(complete_name,'\.','split');
                        np=length(parts);
                        feature_name=parts{np};
                        feature_name=[feature_name '_' date];
                    case 2
                        feature_name=varargin{1};
                    otherwise
                        error('aFeature:saveError',['No input arguments are needed to '...
                            'save a feature. A specific name for the generated .mat file '...
                            'can be optionally provided by the user']);
                end
                
                save(feature_name,'feature')
            catch ME
                throw(ME)
            end
        end
        
        function obj=load(filename)
            % load reads a feature previously saved by save() from
            % filename (.mat extension optional, added automatically)
            try

                % Checking if the filename was introduced with or without
                % the correct file extension, and adding it if neccesary
                [~,~,ext]=fileparts(filename);
                fileExt='.mat';
                if isempty(ext)
                    filename=[filename fileExt];
                elseif ~ismember({ext},{fileExt}) % wrong extension case
                    error('aFeature:ErrorLoadFeature','Only a .mat file is admitted to be loaded')
                end
                
                % Checking the contents of the file before loading it
                S=load(filename);
                if not(isa(S.feature, 'aFeature'))
                    error('aFeature:ErrorLoadFeature','the mat file does not contain a feature object')
                end
                
                obj=S.feature;
            catch ME
                throw(ME)
            end
        end
    end
end
