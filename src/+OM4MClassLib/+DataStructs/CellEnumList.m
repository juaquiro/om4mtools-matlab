classdef CellEnumList
    %CELLENUMLIST is a list base in a fix enumeration values specified in
    %the DataTypes enumeration of the constructor
    % the enumeration must inherit from int32 and all members must have an arbitary integer value >= 1
    %% privarte props
    properties (Access=private)
        Data; %cell array list of DataTypes
        %enumeration with the data types, it is very advisable to use as
        %integer vañlues from 1 to n without gaps
        DataTypes; 
    end
    
    %% constructor
    methods
        % DataTypes is a string with the name of the enumeration
        function this=CellEnumList(DataTypes)
            try
                import OM4MClassLib.DataStructs.*;
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                this.Data=CellArrayList();
                this.DataTypes=DataTypes;
                
                members=enumeration(this.DataTypes);
                indexMembers=double(members);
                
                if(any(indexMembers<=0))
                    retErrorMsg=['all indexs in ' this.DataTypes ' must be > 0'];
                    error([callFunc ' generated an error: ' retErrorMsg]);
                end
                
                for n=0:max(indexMembers)
                    this.Data.add([]);
                end
            catch ME
                throw(ME)
            end
            
        end
    end
    
    %% public methods
    
    methods
        %retrieves the valueType/s measurement/s
        %valueType can be a single value or a cell array
        function value=Get(this, valueType)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                if(isempty(valueType))
                    vl=enumeration(this.DataTypes); %array of all DataType objects
                    valueType=cell(size(vl')); %cell of all DataType objects
                    for n=1:length(vl)
                        valueType{n}=vl(n);
                    end
                end
                
                inValueTypeIsCell=iscell(valueType);                
                if(length(valueType)==1 && not(inValueTypeIsCell)) %convert to cell
                    valueType={valueType};
                end
                
                value=cell(1, length(valueType));
                for n=1:length(valueType)
                    
                    if(not(isa(valueType{n}, this.DataTypes)))
                        retErrorMsg=['value must be a ' this.DataTypes];
                        error(['OM4M:' class(this) ], ...
                            [callFunc ' generated an error: ' retErrorMsg]);
                    end
                    
                    
                    value{n}=this.Data.get(valueType{n});
                    
                    %AQDEBUG no esta claro que surva para algo, si un valor
                    %no se usa simplemente vuelve vacio
                    %if isempty(value{n})
                    %    retErrorMsg=[ 'value ' char(valueType{n}) ' is empty'];
                    %    warning([class(this) '->' callFunc '->' retErrorMsg]);
                    %end
                end
                
                if(length(valueType)==1 && not(inValueTypeIsCell)) %convert return value
                    value=value{1};
                end
                
                
            catch ME
                throw(ME)
            end
        end
        
        %sets the valueType/s measurement/s
        %valueType and value can be a single value or a cell array
        function Set(this, valueType, value)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                %for number this is equivalent to isempty(value) but to
                %objects like empty Lists no 
                if(any(size(value)==0))                    
                    retErrorMsg='value is empty';
                    error(['OM4M:' class(this) ], ...
                        [callFunc ' generated an error: ' retErrorMsg]);
                end
                
                if(length(valueType)==1 && not(iscell(valueType))) %convert to cell
                    valueType={valueType};
                    value={value};
                end
                
                if(length(value)~=length(valueType))
                    retErrorMsg='diferent array length';
                    error(['OM4M:' class(this) ], ...
                        [callFunc ' generated an error: ' retErrorMsg]);
                end
                
                for n=1:length(valueType)
                    this.Data.remove(double(valueType{n}));
                    this.Data.add(value{n}, double(valueType{n}));
                end
                
            catch ME
                throw(ME)
            end
        end
        
        %Returns an enumeration of the stored valueTypes
        function list=GetTypeList(this)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                list=enumeration(this.DataTypes);
                
            catch ME
                throw(ME)
            end
        end
    end
    
end

