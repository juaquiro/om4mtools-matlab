classdef XLSUtils
    %XLSUtils Static Helper Class for managing xls files
    
    
    %% static methods
    methods(Static)
        % This function returns an array of structs whose fields are named
        % after the headers in the first row of the xls file. Spaces are
        % replaced with underscores.
        function entries=ReadFile(fileName, varargin)
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                % We only want 1 optional inputs at most
                numvarargs = length(varargin);
                if numvarargs > 1
                    exception = MException(['OM4M:' class(obj) ':TooManyInputs'],...
                        'requires at most 1 optional inputs: SheetName');
                    throw(exception);
                end
                
                [~,~,ext] = fileparts(fileName);
                if (not(strcmp('.xlsx', ext)) && not(strcmp('.xls', ext)))
                    retErrorMsg=['input file must be a excel sheet: ' fileName];
                    error([callFunc, '->' retErrorMsg]);                    
                end
                
                % set defaults for optional inputs
                % SheetName=1; This will load the default sheet
                optargs = {1};
                % now put these defaults into the optargs cell array,
                % and overwrite the ones specified in varargin.
                optargs(1:numvarargs) = varargin;
                % Place optional args in memorable variable names
                [sheetName] = optargs{:};
                
                % Read values from file
                [values headers raw]=xlsread(fileName, sheetName);
                
                % We supose that fields' names are in the first row of the sheet
                auxFields = headers(1,:);
                
                % We take field names until we find a column with an empty
                % name
                firstEmptyField=find(cellfun('isempty',auxFields),1);
                if(~isempty(firstEmptyField))
                    auxFields = auxFields(1:firstEmptyField-1);
                end
                
                %Samples and fields arrays initialization
                entries(1:size(raw,1)-1)=struct();
                fields(1:size(auxFields,2))={[]};
                
                for sIndex=1:size(entries,2)
                    for fIndex=1:size(auxFields,2)
                        % We can't include spaces in a field name, so we replace spaces whit
                        % underscores
                        fields{fIndex}=strrep(auxFields{fIndex}, ' ', '_');
                        entries(sIndex).(fields{fIndex})= raw{sIndex+1,fIndex};
                    end
                end
            catch ME
                if (strcmp(ME.identifier,'MATLAB:COM:E2148140012'))
                    [p,n,e] = fileparts(fileName);
                    msg=sprintf('%s %s', [n e], [':disable Protected View in Microsoft Office ',...
                        ' to open file ',...                        
                        '. See http://www.jonathanmoeller.com/screed/?p=3131',...
                        'To modify (or disable entirely) Protected View in any ',...
                        'Microsoft Office 2010 application follow this steps \n',...
                        ' -Go to the File tab\n',...
                        ' -Click on Options.\n',...
                        ' -When the Options dialog box appears, click on the Trust Center category in the left-hand column.\n',...
                        ' -Click on the Trust Center Settings button on the right-hand side of the Options dialog box.\n',...
                        ' -When the Trust Center dialog box opens up, click on the Protected View settings in the left-hand column.',...
                        ' -Here you can uncheck “Enable Protected View for files originating from the Internet”, ',...
                        ' “Enable Protected View for files located in potentially unsafe locations”, ',...
                        ' and “Enable Protected View for Outlook attachments”.  ',...
                        ' When you’ve made your selections, click OK, and Protected View will now be disabled.']);
                    
                    error('MATLAB:OM4M:XLSRead', msg);
                else
                    throw(ME);
                end
            end
            
        end
        % This function writes an array of structs in a xls file whose headers are named
        % with the fields of the struct
        function WriteFile(result, filename, varargin)
            try                
                % set defaults for optional inputs
                % SheetName=1; This will load the default sheet
                optargs = {1,'A1'};
                % now put these defaults into the optargs cell array,
                % and overwrite the ones specified in varargin.
                numvarargs=length(varargin);
                optargs(1:numvarargs) = varargin;
                % Place optional args in memorable variable names
                [sheetName,Position] = optargs{:};
                headers = fieldnames(result)';
                NE = length(result);
                NF = length(headers);
                entries = cell(NE,NF);
                for i = 1 : NE
                    entries(i,:) = struct2cell(result(i))';
                end
                status = xlswrite(filename, [headers; entries], sheetName, Position);
                if ~status
                    exception = MException(['OM4M:' class(obj) ':WritingFailed'],...
                        'The entries was not dumped into the XLS sheet');
                    throw(exception);
                end
            catch ME
                throw(ME);
            end
        end
        
        % Filter an array of entries obtained with 'ReadFile' based on one
        % field's value. Returns a new array with the entries that pass the
        % filter.
        function filteredEntries=FilterByValue(entries, fieldName, fieldValue)
            try                
                if(ischar(fieldValue))
                    filteredEntries=entries(strcmp(fieldValue,{entries(:).(fieldName)}));
                else
                    filteredEntries=entries([entries(:).(fieldName)]'== fieldValue);
                end
            catch ME
                throw(ME)
            end 
        end
        
        % Filter an array of entries obtained with 'ReadFile' based on more
        % than one field's value. Returns a new array with the entries that pass the
        % filter.
        function filteredEntries=FilterByValuesAND(entries, varargin)
            try                
                error(nargchk(2, numel(fieldnames(entries))*2, nargin, 'struct'));
                numVarArgIn= length(varargin);
                if mod(numVarArgIn,2) == 1
                    exception = MException(['OM4M:' class(obj) ':WrongInputs'],...
                        'requires an odd number of parameters to complete the properties pair: fieldName, fieldValue');
                    throw(exception);                    
                end
                filterAND = true(1,length(entries));
                for idx = 1:2:numVarArgIn-1
                    if(ischar(varargin{idx+1}))
                       filter = strcmp(varargin{idx+1},{entries(:).(varargin{idx})});
                    else
                       filter = [entries(:).(varargin{idx})]'== varargin{idx+1};
                    end
                    filterAND = filterAND & filter;
                end
                filteredEntries = entries(filterAND);
            catch ME
                throw(ME)
            end
        end
        % Filter an array of entries obtained with 'ReadFile' indexing them
        % as the value of a field (Organize the entries by fieldName). 
        % Returns a new cell array where each cell contains all the
        % entries where the fieldName has the same value.
        function result=SelectByFieldName(entries, fieldName)
            try 
                import OM4MClassLib.Util.XLSUtils;
                result = cell(1,1);                
                fieldNames = {entries.(fieldName)};
                idxDoc = 1;
                while ~isempty(fieldNames)
                    fieldValue = fieldNames{1};
                    if ~ischar(fieldValue)
                        fieldNames = fieldNames(2:end);
                    else
                        filteredEntries = XLSUtils.FilterByValuesAND(entries,fieldName,fieldValue);
                        result{idxDoc} = filteredEntries;
                        idxDoc = idxDoc + 1;
                        fieldNames(strcmp(fieldNames,fieldValue)) = '';    
                    end
                end
            catch ME
                throw(ME)
            end
        end
    end
    
end
