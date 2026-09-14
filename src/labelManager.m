classdef labelManager < handle
    % labelManager transforms a list of strings into a numeric label and
    % vice versa. It also tranforms integers into a matricial expression
    % (e. g. [1; 2; 3] to [0 0 1; 0 1 0; 1 0 0]) and vice versa
    % Copyright IOT
    % $Revision: 1 $  $Date: 09/05/2013 $
    % $JJ$
    
    %% Private properties
    properties
    end
    
    %% Public Methods
    methods
        
        % Constructor
        function this=labelManager()
        end
        
        
        % gety returns the numeric labels that corresponds to the given string label/s in
        % a given list of strings
        function y=gety(this,label,strList)
            
            try
                % Checking that label and strList are strings or cell arrays of strings
                msg=' must be a string or cell array of strings';
                
                if ~(iscellstr(label) || ischar(label))
                    error('labelManager:wrongInputLabelFormat',[inputname(2) msg])
                elseif ~(iscellstr(strList) || ischar(strList))
                    error('labelManager:wrongInputStrListFormat',[inputname(3) msg])
                end
                
                % Checking that the given label/s are contained in the strList
                if ischar(label)
                    label={label};
                end
                ulabel=unique(label);
                ulist=unique(strList);
                state=ismember(ulist,ulabel);
                condition=any(state);
                
                if ~condition
                    pattern='\n%s';
                    msg1=repmat(pattern,1,length(ulist));
                    error('labelManager:wrongLabelValue',['Elements present in the given list are '...
                        msg1 '\nInput ' inputname(2) ' must be equal to one, some or all this elements'],ulist{:});
                end
                y=find(state);
                y=y(:);
            catch ME
                throw(ME)
            end
        end
        
        
        % getlabels returns the string labels that corresponds to the given number/s in
        % a given list of strings
        function label=getlabel(this,numList,strList)
            
            try
                % Checking that numList is a non-zero positive int or a vector of
                % non-zero positive integers and strList is a string or cell array of strings
                msg1=' must be a integer or a vector of integers different from zero';
                msg2=' must be a string or cell array of strings';
                condition1=~all(ceil(numList)==floor(numList)); % Checks if there's any non-integer elements in numList
                condition2=any(numList<=0); % Checks if there are any zero elements in numList
                condition3=~iscellstr(strList); % Checks if strList is a cell array of strings
                condition4=~ischar(strList); % Checks if strList is a string
                
                if condition1 || condition2
                    error('labelManager:getlabel:wrongInput',[inputname(2) msg1])
                elseif condition3 && condition4
                    error('labelManager:getlabel:wrongInput',[inputname(3) msg2])
                end
                
                % Checking that the elemnts of the given numList are consistent
                % with the number of different labels is the given strList
                uNumList=unique(numList);
                uStrList=unique(strList);
                uStrElem=numel(uStrList);
                condition5=all(ismember(uNumList,1:uStrElem));
                
                if ~condition5
                    pattern='\t%s';
                    msg3=repmat(pattern,1,length(uNumList));
                    error('labelManager:getlabel:wrongLabel',['Elements present in the given list are '...
                        msg3 '\nInput ' inputname(2) ' must be equal to one, some or all this elements'],uNumList(:));
                end
                
                % Identifying each number of numList with the corresponding
                % label
                label=uStrList(uNumList);
            catch ME
                throw(ME)
            end
        end
    end
    
    
    %% Static methods
    methods (Static=true)
        
        function vec=ind2vec(ind)
            try
                
                % Checking that numList is a non-zero positive int or a vector of non-zero positive integers
                msg1=' must be a integer or a vector of positive integers different from zero';
                msg2=' must be a vector';
                condition1=~all(ceil(ind)==floor(ind)); % Checks if there's any non-integer elements in numList
                condition2=any(ind<=0); % Checks if there are any zero elements in numList
                condition3=any(size(ind)==1); % Checks if ind is a vector
                
                if ~condition3
                    error('labelManager:ind2vec:wrongInputFormat',[inputname(1) msg2])
                elseif condition1 || condition2
                    error('labelManager:ind2vec:wrongInputValue',[inputname(1) msg1])
                end
                
                % Encoding the decimal numbers from numLabel
                uniqueValues=unique(ind);
                n=length(uniqueValues);
                codedVal=fliplr(eye(n));
                
                % Replacing each element of numLabel by the corresponding
                % encoded version
                m=length(ind);
                vec=zeros(m,n);
                for i=1:n
                    index=(ind==i);
                    k=length(find(index));
                    vec(index,:)=repmat(codedVal(i,:),k,1);
                end
            catch ME
                throw(ME)
            end
        end
        
        
        function ind=vec2ind(vec)
            try
                
                % Input must be a matrix composed just by zeros and ones,
                % and there can only be one 1 per row
                msg1=' must be a vector or a matrix';
                msg2=' must be a vector or a matrix composed just by zeros and ones and there can only be one 1 per row';
                
                try % Condition 1 should check if vec is a matrix. If not, an error will appear when computing condition 2, which supposes vec to be a vector or matrix
                    condition2=all(all((+vec<0)+(+vec>1))); % Checks that vec is a matrix composed just by zeros and ones
                catch ME
                    error('labelManager:vec2ind:wrongInputFormat',[inputname(1) msg1])
                    
                end
                m=size(vec,1);
                n=length(find(vec));
                condition3=~isequal(n,m);
                
                if condition2 || condition3
                    error('labelManager:vec2ind:wrongInputValue',[inputname(1) msg2])
                end
                
                % Decoding the matLabel elements
                uniqueValues=unique(vec,'rows');
                n=length(uniqueValues);
                
                % Replacing each element of numLabel by the corresponding
                % decoded version
                ind=ones(size(vec,1),1);
                for i=1:n
                    index=ismember(vec,uniqueValues(i,:),'rows');
                    [ind(index)]=deal(i);
                end
                ind=ind(:);
            catch ME
                throw(ME)
            end
        end
    end
end

