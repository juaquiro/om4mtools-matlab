classdef Validation
    % Validation is a static helper class for parameter validation

    
    %% static methods
    methods(Static)
        function retMsg=CheckInputParam(v, vList)
            % CheckInputParam errors if v does not equal any element of
            % cell array vList; otherwise returns true
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            vName=inputname(1);
            vListName=inputname(2);
            
            retMsg=true;
            
            if not(iscell(vList))
                retMsg=[vListName ' must be a cell array'];
                error([callFunc, '->' retMsg]);
            end
            
            %check if v is any of the values of vList
            rc=true(size(vList));
            for n=1:length(vList)
                rc(n)=isequal(v,vList{n});
            end
            
            if not(any(rc))
                vStr=Validation.all2str(v); %for a matrix the string is 2D
                retMsg=[vName ' has invalid value: ' vStr(:)'];
                error([callFunc, '->' retMsg]);
            end
          
            %This alternative does not work with the more general case of
            %different types in vList
            %if not(any(v==[vList{:}]))
            %    retMsg=[vName ' has invalid value: ' Validation.all2str(v)];
            %    error([callFunc, '->' retMsg]);
            %end
            
            
        end
        
        function vStr=all2str(v)
            % all2str converts any MATLAB variable v (empty, char,
            % numeric, cell or struct) to a display string, without
            % using evalc/eval (which have known issues under the MATLAB
            % Compiler, see http://blogs.mathworks.com/loren/2008/06/19/writing-deployable-code/);
            % adapted from http://stackoverflow.com/questions/12799161/is-there-a-matlab-function-to-convert-any-data-structure-to-a-string
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();

            if isempty(v)
                if iscell(v)
                    vStr = '(empty cell)';
                elseif isstruct(v);
                    vStr = '(empty struct)';
                else
                    vStr = '(empty)';
                end
                return;
            end
            
            if ischar(v)
                vStr = v;
                return;
            end
            
            if isnumeric(v)
                vStr = num2str(v);
                return;
            end
            
            if iscell(v)
                vStr = Validation.all2str(v{1});
                for i=2:numel(v)
                    vStr = [vStr ', ' Validation.all2str(v{i})];
                end
                return;
            end
            
            if isstruct(v)
                vStr = '(structure)';
                return;
            end
            
            vName=inputname(1);
            retMsg=[vName ': has a unsuported type'];
            error([callFunc, '->' retMsg]);
        end
        
        function mustBeEqualSize(v1,v2)
            % mustBeEqualSize errors unless size(v1)==size(v2)
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            % Test for equal size
            if ~isequal(size(v1),size(v2))
                errorStruct.identifier = 'Size:notEqual';
                errorStruct.message = [callFunc '->Size of first input must equal size of second input.'];
                error(errorStruct);
            end
        end        
    end
    
end

