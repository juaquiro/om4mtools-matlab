classdef Validation
    %LOGGING Static Helper Class for v validation
    
    
    %% static methods
    methods(Static)
        %this function launch an exception if v is not in the cell list vList
        function retMsg=CheckInputParam(v, vList)
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
        
        %this funcion transform to text any MATLAB variable. Its makes a
        %differnece if the function is deployed or not becasue evalc and
        %eval have known issues with the compiler, see http://blogs.mathworks.com/loren/2008/06/19/writing-deployable-code/
        %the dolution for the not(isdeployed) and the isdeployed cases are from http://stackoverflow.com/questions/12799161/is-there-a-matlab-function-to-convert-any-data-structure-to-a-string
        %we are going to avid the vStr = evalc(['disp(v)']); solution for
        %Compiler compativility
        function vStr=all2str(v)
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
        
        %> @brief this function validates equal size for v1 and v2
        %> @param v1 1st element
        %> @param v2 2nd element
        %> @author AQ 18SEP20
        function mustBeEqualSize(v1,v2)
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

