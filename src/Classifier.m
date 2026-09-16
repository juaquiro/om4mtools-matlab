classdef Classifier < handle & OM4MClassLib.DataStructs.IProps
    % Classifier abstract base class for the OM4M classifier hierarchy
    %
    % Syntax:
    %   classifier = ClassifierXxx()
    %   classifier.Train(X, y)
    %   [pred, prb] = classifier.Predict(X)
    %
    % Description:
    %   Defines the common training/prediction/error-function pipeline
    %   (feature mapping, normalization, then subclass-specific
    %   hypothesis/theta calculation) shared by every concrete classifier
    %   (ClassifierLR, ClassifierSVM, ClassifierNN, etc.). Concrete
    %   subclasses only need to implement the abstract methods below.

    %% protected props
    properties (Access=protected)
        props;
        normalizer;
        theta;
        featureMapper;
        normalize;
        n; %number of features
    end
    
    %% abstract methods, protected interface
    methods (Abstract=true, Access=protected)
        % HypothesisP predicts labels/probabilities for the given (already
        % normalized/mapped) feature matrix X
        p=HypothesisP(X);
        % CalculateTheta fits this.theta from feature matrix X and labels y
        CalculateTheta(X,y);
        % RawDataErrorFun computes the error struct used by ErrorFunction
        errorStruct=RawDataErrorFun(X, y, lambda);
        % isTrained returns true once CalculateTheta has been run
        r=isTrained(this);
    end

        %% abstract methods, public interface
    methods (Abstract=true)
        % isSupervised returns true if this classifier requires labels y
        r=isSupervised(this);
        % isRegression returns true if this classifier predicts a
        % continuous value instead of a discrete class
        r=isRegression(this);
    end

    
    %% protected interface, only for internal use of unsupervised classiers that are composed with a supervised classifier
    methods (Access=protected)
        % setProps copies this classifier's props onto another classifier c
        function this=setProps(this, c)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            
            if not(isa(c, 'Classifier'))
                retErrorMsg=['input must be a classifier object: ' callFunc];
                error([class(this) '->' retErrorMsg]);
            end
            
            %get all props
            p=enumeration('ClassifierProps');
            %iterate the props
            for n=1:length(p);
                v=this.Get(char(p(n)));
                c.Set(char(p(n)), v);
            end
        end
        
        % checkSVM_Toolbox errors if the Statistics Toolbox is missing or
        % older than the minimum version this classifier needs
        function this=checkSVM_Toolbox(this)
            import OM4MClassLib.Util.*;
            callFunc=Logging.WhoCalledMe();
            tb='stats'; %toolbox
            v=ver(tb);
            if(isempty(v))
                error('Statistics toolbox not installed');
            end
            
            tbv='8.2'; %minmum version
            if verLessThan(tb, tbv)
                retErrorMsg=[callFunc ' :stats toolbox is less than ' tbv];
                error([class(this) '->' retErrorMsg])
            end
        end
    end
    
    
    %% public interface
    methods
        % Classifier constructs a classifier with default props (see Init)
        function this=Classifier()
            import OM4MClassLib.DataStructs.*;
            this.props=PropsEnumList('ClassifierProps');

            % Initialization
            this.Init();
        end

        % Train fits the classifier on feature matrix X and labels y
        % (feature-mapped and normalized internally per this.props)
        function Train(this, X,y)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                %get number of features
                this.n=size(X, 2);
                
                if this.isSupervised 
                    m=size(X, 1); %number of samples                    
                    if not(all(size(y)==[m,1]))
                        retErrorMsg=['for a supervised classifier y must be a mx1 vector: ' callFunc];
                            error([class(this) '->' retErrorMsg]);                        
                    end
                elseif not(isscalar(y)) || not(rem(y,1) == 0)
                        retErrorMsg=['for a unsupervised classifier y must be a integer: ' callFunc];
                            error([class(this) '->' retErrorMsg]);                                                                
                end
                
                
                %polinomic mapping
                p=this.Get((char(ClassifierProps.p))); %polynomic order
                X=this.featureMapper.Go(X, p);
                
                if this.Get(char(ClassifierProps.normalize))
                    this.normalizer.CalcParams(X);
                    %the Train with normalization assumes a full train set
                    %with all labels
                    if not(isa(this, 'ClassifierLinReg')) && this.isSupervised()
                        UtilFunML.checkTrainSetLabels(y);
                    end
                end
                
                %normalize
                X=this.normalizer.Go(X);
                
                this.CalculateTheta(X,y);                     
                
            catch ME
                rethrow(ME);
            end
        end
        
        % Predict returns the predicted label/value pred and its
        % probability/confidence prb (rounded to 3 digits) for X
        function [pred,prb]=Predict(this, X)
            try
                import OM4MClassLib.Util.*;
                
                callFunc=Logging.WhoCalledMe();
                
                %check if the classifier is trained or not
                if not(this.isTrained)
                    retErrorMsg=['the classifier is not trained: ' callFunc];
                    error([class(this) '->' retErrorMsg]);
                    
                end
                
                %check number of features
                nf=size(X, 2);
                if nf~=this.n
                    retErrorMsg=['feature number mismatch between Train and Predict: ' callFunc];
                    error([class(this) '->' retErrorMsg]);                    
                end                
                
                             
                %polynomic mapping
                p=this.Get((char(ClassifierProps.p))); %polynomic order
                X=this.featureMapper.Go(X, p);
                
                %normalize
                X=this.normalizer.Go(X);
                
                
                [pred,prb]=this.HypothesisP(X);
                prb=round(10^3*prb)/10^3; % Prob with 3 digits
                
            catch ME
                throw(ME);
            end
            
        end
        
        
        % ErrorFunction computes the error struct for (X, y), including
        % the same feature mapping/normalization as Train - needed to
        % compute the learning curve
        function errorStruct=ErrorFunction(this, X, y)
            try
                
                %polynomic mapping
                p=this.Get((char(ClassifierProps.p))); %polynomic order
                X=this.featureMapper.Go(X, p);
                %normalize
                X=this.normalizer.Go(X);
                
                errorStruct=this.RawDataErrorFun(X, y);
            catch ME
                throw(ME);
            end
        end                
        
        % GetTheta returns the fitted model parameters
        function theta=GetTheta(this)
            theta=this.theta;
        end
    end


    %% private methods
    methods (Access=private)
        % Init sets every classifier prop to its default value
        function this=Init(this)
            try
                
                this.normalizer=featureNormalizer();
                this.featureMapper=polynomicFeatureMapper();
                this.n=0; %defaullt number of features
                %ini props
                this.props.Set(char(ClassifierProps.lambda), 1);
                this.props.Set(char(ClassifierProps.hiddenSizes), 10);
                this.props.Set(char(ClassifierProps.p), 1);
                this.props.Set(char(ClassifierProps.sigma), 0.1);                
                this.props.Set(char(ClassifierProps.KF), 'rbf');
                this.props.Set(char(ClassifierProps.showplot), false);
                this.props.Set(char(ClassifierProps.KFp), 1);
                this.props.Set(char(ClassifierProps.svcType), ClassifierTypes.SVM);                                                
                this.props.Set(char(ClassifierProps.normalize), false);
                this.props.Set(char(ClassifierProps.featureType), aFeatureTypes.Unknown);  
                
                %ini theta
                this.theta=[];
                
            catch ME
                throw(ME);
            end
        end
        
    end
    
    
    %% public IProps interface
    %check Get implementation��
    methods
        % Get returns the value of props, or the full props struct if
        % called with no props argument
        function ret=Get(this, props)
            if nargin==1
                ret=this.props.Get();
            else
                ret=this.props.Get(props);
            end
        end
        
        % Set assigns propvals to props, type-checking featureType/svcType
        function this=Set(this, props, propvals)
            import OM4MClassLib.Util.*;
            
            callFunc=Logging.WhoCalledMe();
            switch props
                case char(ClassifierProps.featureType)
                    if not(isa(propvals, 'aFeatureTypes'))
                        retErrorMsg=['featureType must be of type aFeatureTypes: <<' char(propvals) '>>, ' callFunc];
                        error([class(this) '->' retErrorMsg]);
                    end      
                case char(ClassifierProps.svcType)
                    if not(isa(propvals, 'ClassifierTypes'))
                        retErrorMsg=['svcType must be of type ClassiferTypes: <<' char(propvals) '>>, ' callFunc];
                        error([class(this) '->' retErrorMsg]);
                    end                          
            end
            this.props.Set(props, propvals);
        end
    end
    
    %% Static methods
    methods (Static=true)
        % save writes classifier to a .mat file (default name = class name
        % + date, or varargin{1} if given); also exports to XML if
        % classifier is an NNoCV (OpenCV-backed) classifier
        function save(classifier,varargin)
            try
                
                if not(isa(classifier, 'Classifier'))
                    error('Only a classifier object is admitted')
                end
                
                switch nargin
                    case 1
                        complete_name=class(classifier);
                        parts=regexp(complete_name,'\.','split');
                        np=length(parts);
                        classifier_name=parts{np};
                        classifier_name=[classifier_name '_' date];
                    case 2
                        classifier_name=varargin{1};
                    otherwise
                        error('Classifier:saveError',['No input arguments are needed to '...
                            'save a classifier. A specific name for the generated .mat file '...
                            'can be optionally provided by the user']);
                end
                
                save(classifier_name,'classifier')
                
                % If the classifier is an openCV classifier (FreeStyle),
                % the classifier is also saved in XML using the
                % corresponding method of the wrapper
                if isa(classifier,'NNoCV')
                    [~,baseName]=fileparts(classifier_name);
                    classifier.save([baseName,'.xml']);
                end
                
            catch ME
                throw(ME)
            end
        end
        
        % load reads a classifier previously saved by save() from filename
        % (.mat extension optional, added automatically)
        function obj=load(filename)
            try
                
                % Checking if the filename was introduced with or without
                % the correct file extension, and adding it if neccesary
                [~,~,ext]=fileparts(filename);
                fileExt='.mat';
                if isempty(ext)
                    filename=[filename fileExt];
                elseif ~ismember({ext},{fileExt}) % wrong extension case
                    error('Classifier:ErrorLoadClassifier','Only a .mat file is admitted to be loaded')
                end
                
                % Checking the contents of the file before loading it
                vars=whos('-file',filename);
                classes={vars.class};
                [~,classifier_types]=enumeration('ClassifierTypes');
                classifier_types=[classifier_types;'LR'];
                classifier_types=cellfun(@(x) char(x),classifier_types,'UniformOutput',0);
                classifier_types_OK=cellfun(@(x) ['Classifier' x],classifier_types,'UniformOutput',0);                
                if ~any(ismember(classifier_types_OK,classes))
                    error('Classifier:LoadWrongContents',['The file which is requested to load '...
                        'doesn�t content a classifier'])
                end
                S=load(filename);
                obj=S.classifier;
            catch ME
                throw(ME)
            end
        end       
    end
    
end
