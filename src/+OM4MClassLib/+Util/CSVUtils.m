classdef CSVUtils
    % CSVUtils is a static helper class for managing csv files with
    % semicolon (;) separators
    
    
    %% static methods
    methods(Static)
        function entries=ReadFile(fileName, varargin)
            % ReadFile returns an array of structs whose fields are
            % named after the headers in the first row of the csv file
            % (spaces replaced with underscores). Optional varargin{1}
            % (sheetName) is accepted but unused, kept for signature
            % compatibility with XLSUtils.ReadFile
            try
                import OM4MClassLib.Util.CSVUtils;
                
                %TODO el uso de varargin lo dejamos por compatibilidad con
                %XLSUtils
                % We only want 1 optional inputs at most
                numvarargs = length(varargin);
                if numvarargs > 1
                    exception = MException(['OM4M:' class(obj) ':TooManyInputs'],...
                        'requires at most 1 optional inputs: SheetName');
                    throw(exception);
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
                [~, headers, raw]=CSVUtils.CsvRead2Cell(fileName);
                
                %TODO limpiar esta parte pq headres (testData) ya viene
                %limpio
                % We supose that fields' names are in the first row
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
                %TODO quitar
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
                        ' -Here you can uncheck �Enable Protected View for files originating from the Internet�, ',...
                        ' �Enable Protected View for files located in potentially unsafe locations�, ',...
                        ' and �Enable Protected View for Outlook attachments�.  ',...
                        ' When you�ve made your selections, click OK, and Protected View will now be disabled.']);
                    
                    error('MATLAB:OM4M:XLSRead', msg);
                else
                    throw(ME);
                end
            end
            
        end
        function WriteFile(result, filename)
            % WriteFile writes struct array result into filename as a
            % semicolon-separated csv, using its field names as headers
            try
                import OM4MClassLib.Util.CSVUtils;
              
                headers = fieldnames(result)';
                NE = length(result);
                NF = length(headers);
                entries = cell(NE,NF);
                for i = 1 : NE
                    entries(i,:) = struct2cell(result(i))';
                end
                %use default values for year (1997 no "" enclosing) and
                %separator (;);
                status = CSVUtils.cell2csv(filename, [headers; entries]); 
                if ~status
                    exception = MException(['OM4M:' class(obj) ':WritingFailed'],...
                        'The entries was not dumped into the CSV sheet');
                    throw(exception);
                end
            catch ME
                throw(ME);
            end
        end
        
        function filteredEntries=FilterByValue(entries, fieldName, fieldValue)
            % FilterByValue returns the subset of entries (as returned
            % by ReadFile) whose fieldName equals fieldValue
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
        
        function filteredEntries=FilterByValuesAND(entries, varargin)
            % FilterByValuesAND returns the subset of entries (as
            % returned by ReadFile) matching all of the given
            % fieldName/fieldValue pairs (varargin), ANDed together
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
            % SelectByFieldName groups entries (as returned by ReadFile)
            % into a cell array, one cell per distinct char value of
            % fieldName, each holding the matching entries
            %  Note: delegates to XLSUtils.FilterByValuesAND rather than
            % this class's own (identical) FilterByValuesAND above
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
        
        function [num,txt,raw]=CsvRead2Cell(fileName)
            % CsvRead2Cell reads semicolon (;) csv files.
            %   [NUM,TXT,RAW]=CsvRead2Cell(File) reads data from csv file named FILE and returns
            %   empty in NUM. Also, returns the unprocessed data (numbers and text as strings) in cell array
            %   TXT, and the same unprocessed data (numbers and text as strings) in cell array RAW.
            %   The only important outpuit is Raw the other are maintained for
            %   compatibility with xlsread
            try
                import OM4MClassLib.Util.*;
                callFunc=Logging.WhoCalledMe();
                
                fid = fopen(fileName,'r');
                if fid == -1
                    retErrorMsg=['Can not open ' fileName];
                    error([callFunc, '->' retErrorMsg]);
                end
                
                [~,~,ext] = fileparts(fileName);
                if not(strcmp('.csv', ext))
                    retErrorMsg=['input file must be a csv sheet: ' fileName];
                    error([callFunc, '->' retErrorMsg]);                    
                end
                
                
                
                
                %read entire file assuming the maximum number of columns
                %extra columns are empty
                NCMax=100;
                delimiter=';';
                C = textscan(fid, repmat('%s',1,NCMax), 'delimiter',delimiter, 'CollectOutput',true);
                raw = C{1};
                
                % We supose that fields' names are in the first row of the sheet
                headers = raw(1,:);
                
                % We take field names until we find a column with an empty
                % name
                firstEmptyField=find(cellfun('isempty',headers),1);
                %number of headers
                NH=firstEmptyField-1;
                if(~isempty(firstEmptyField))
                    %trim raw data
                    raw=raw(:, 1:NH);
                end
                
                %keep outputs for compatibility
                txt=raw;
                num=[];
                
                fclose(fid);
                
            catch ME
                fclose(fid);
                throw(ME)
            end
        end
        
        function status=cell2csv(fileName, cellArray, separator, excelYear, decimal)
            % Writes cell array content into a *.csv file.
            %
            % CELL2CSV(fileName, cellArray, separator, excelYear, decimal)
            %
            % fileName     = Name of the file to save. [ i.e. 'text.csv' ]
            % cellArray    = Name of the Cell Array where the data is in
            % separator    = sign separating the values (default = ';')
            % excelYear    = depending on the Excel version, the cells are put into
            %                quotes before they are written to the file. The separator
            %                is set to semicolon (;)
            % decimal      = defines the decimal separator (default = '.')
            %
            %         by Sylvain Fiedler, KA, 2004
            % updated by Sylvain Fiedler, Metz, 06
            % fixed the logical-bug, Kaiserslautern, 06/2008, S.Fiedler
            % added the choice of decimal separator, 11/2010, S.Fiedler
            %
            % ver http://www.mathworks.com/matlabcentral/fileexchange/4400-cell-array-to-csv-file-cell2csv-m
            
            %% Checking f�r optional Variables
            if ~exist('separator', 'var')
                separator = ';';
            end
            
            if ~exist('excelYear', 'var')
                excelYear = 1997;
            end
            
            if ~exist('decimal', 'var')
                decimal = '.';
            end
            
            %% Setting separator for newer excelYears
            if excelYear > 2000
                separator = ';';
            end
            
            %% Write file
            datei = fopen(fileName, 'w');
            
            for z=1:size(cellArray, 1)
                for s=1:size(cellArray, 2)
                    
                    var = eval(['cellArray{z,s}']);
                    % If zero, then empty cell
                    if size(var, 1) == 0
                        var = '';
                    end
                    % If numeric -> String
                    if isnumeric(var)
                        var = num2str(var);
                        % Conversion of decimal separator (4 Europe & South America)
                        % http://commons.wikimedia.org/wiki/File:DecimalSeparator.svg
                        if decimal ~= '.'
                            var = strrep(var, '.', decimal);
                        end
                    end
                    % If logical -> 'true' or 'false'
                    if islogical(var)
                        if var == 1
                            var = 'TRUE';
                        else
                            var = 'FALSE';
                        end
                    end
                    % If newer version of Excel -> Quotes 4 Strings
                    if excelYear > 2000
                        var = ['"' var '"'];
                    end
                    
                    % OUTPUT value
                    fprintf(datei, '%s', var);
                    
                    % OUTPUT separator
                    if s ~= size(cellArray, 2)
                        fprintf(datei, separator);
                    end
                end
                if z ~= size(cellArray, 1) % prevent a empty line at EOF
                    % OUTPUT newline
                    fprintf(datei, '\n');
                end
            end
            % Closing file
            %status is negated to make return compatible with xlswrite
            status=fclose(datei);
            if status==0
                status=1;
            else
                status=0;
            end
            % END
        end
        
        
    end
    
end