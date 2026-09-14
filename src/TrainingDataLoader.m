classdef TrainingDataLoader < handle
    %TRAININGDATALOADER this object is resposible of loading the data and
    %labels for training a clasifier
    % Copyright IOT
    % $Revision: 1 $  $Date: 19/02/2013 $
    % $JJ$
    
    %% private props
    
    properties (GetAccess = 'public', SetAccess = 'private')
        % X is a mxn matrix, where m is the number of lenses and n is the number of
        % ListFeatureNames. Each row of X contains the corresponding values
        % of ListFeatureNames
        X;
        % y is a vector of length equal to m. y contains values which belong 
        % to range 1:k, where k is the number of classes of the column
        % labelData. Each different k corresponds to a different class
        y;
        % labels is a list of m elements which contains the corresponding
        % strings of each sample of X, i. e. a list of 'Good', 'Anomalous'
        % and 'Wrong' when labelData is Type
        labels;
        
        % TrainData {x,y,labels} structures
        
        % TTS: Total Train Set. It's a struct which contains all the X, y
        % and labels data
        TTS;
        % TRS: TRain Set. It's a struct which contains the 60% of the X, y
        % and labels data
        TRS;
        % CVS: Cross Validation Set. It's a struct which contains the 20% 
        % of the X, y and labels data
        CVS;
        % TES: Test Error Set. It's a struct which contains the last 20% 
        % of the X, y and labels data
        TES;
    end
    
    %% Constructor
    methods
        % QCStatsFile is the name of the excel QCStats file
        % labelData is the name of the column used to clasify. It's a
        % EnumLabelData element
        % ListNameData is a cell array of EnumNameData elements
        % LensType is an EnumLens element
        % Eye is an EnumEye element
        function this=TrainingDataLoader(QCStatsFile, LabelData, ListFeatureNames, LensType, Eye)
            try
                
                import OM4MClassLib.Util.*;
                
                % Checking the inputs
                if ~(isa(LabelData, 'EnumLabelData') && isa(LensType,'EnumLens') && isa(Eye,'EnumEye'))
                    error('LabelData must be a EnumLabelData, LensType must be a EnumLens and Eye must be a EnumEye');
                end
                
                for n=1:length(ListFeatureNames)
                    if ~isa(ListFeatureNames{n},'EnumFeatureNames')
                        error('Each element of ListFeatureNames must be a EnumFeatureNames');
                    end
                end
                
                if ~exist(QCStatsFile,'file')
                    error('QCStatsFile doesn´t exist in the current folder or in the specified path');
                end
                
                this.ini(QCStatsFile, LabelData, ListFeatureNames, LensType, Eye);
                this.GetTrainSets;
                
            catch ME
                throw(ME)
            end
        end
    end
    
    %% Private methods
    methods (Access = 'private')
        
        function ini(this,QCStatsFile, LabelData, ListFeatureNames, LensType, Eye)
            
            import OM4MClassLib.Util.*;
            
            % Definig the indexer
            StatsStruct=XLSUtils.ReadFile(QCStatsFile);
            NFixed=length(clearNaN({StatsStruct(:).LensId}));
            switch Eye
                case EnumEye.R
                    lEye=strcmp(char(EnumEye.R),{StatsStruct(1:NFixed).Eye})';
                case EnumEye.L
                    lEye=strcmp(char(EnumEye.L),{StatsStruct(1:NFixed).Eye})';
                case EnumEye.B
                    lEye=true(NFixed,1);
            end
            
            switch LensType
                case EnumLens.Progressive
                    lLens=strcmp('YES',{StatsStruct(1:NFixed).isProgressive})';
                case EnumLens.Monofocal
                    lLens=strcmp('NO',{StatsStruct(1:NFixed).isProgressive})';
                case EnumLens.All
                    lLens=true(NFixed,1);
            end
            Indexer=lEye & lLens;
            
            % Defining X
            
            ListFeatureNames=cellfun(@char,ListFeatureNames,'UniformOutput',false);
            ValuesCell=cell(1,length(ListFeatureNames));
            for i=1:length(ValuesCell)
                ValuesCell{i}=[StatsStruct(Indexer).(ListFeatureNames{i})]';
            end
            this.X=[ValuesCell{:}];
            
            % Defining y
            
            labelCell={StatsStruct(Indexer).(char(LabelData))}';
            uniqueLabelValues=unique(labelCell);
            ycell=labelCell;
            
            for i=1:length(uniqueLabelValues)
                ycell=cellfun(@(x) strrep(x,uniqueLabelValues{i},int2str(i)),...
                    ycell,'UniformOutput',0);
            end
            
            ycell=cellfun(@(x) str2double(x),ycell,'UniformOutput',0);
            ycell=cell2mat(ycell);
            this.y=ycell;
            
            % Definig labels
                       
            this.labels=labelCell;
            
        end
    end
     %% Public methods
    methods (Access = 'public')
        
        function [TTS, TRS, CVS, TES]=GetTrainSets(this)
            
            % Definig TTS
            TTS(1).X=this.X;
            TTS(1).y=this.y;
            TTS(1).labels=this.labels;
            this.TTS=TTS;
            
            % Disordering elements
            m=size(TTS.X,1);
            p=randperm(m);
            N1=round(0.6*m);
            N2=round(0.2*m);
            N=N1+N2;
            ttsX=TTS.X; ttsX=ttsX(p,:);
            ttsy=TTS.y; ttsy=ttsy(p);
            ttslab=TTS.labels; ttslab=ttslab(p);
            
            % Defining TRS
            TRS.X=ttsX(1:N1,:);
            TRS.y=ttsy(1:N1,:);
            TRS.labels=ttslab(1:N1,:);
            this.TRS=TRS;
            
            % Definig CVS
            CVS.X=ttsX(N1+1:N,:);
            CVS.y=ttsy(N1+1:N,:);
            CVS.labels=ttslab(N1+1:N,:);
            this.CVS=CVS;
            
            % Definig TES
            TES.X=ttsX(N+1:end,:);
            TES.y=ttsy(N+1:end,:);
            TES.labels=ttslab(N+1:end,:);
            this.TES=TES;
            
        end
    end
end




















