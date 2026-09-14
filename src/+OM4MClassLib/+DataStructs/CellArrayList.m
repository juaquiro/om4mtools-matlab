%> @file CellArrayList.m
%> @brief this file contains a class to create a cell array list
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16
%> @see testCellArrayList

% ======================================================================
%> @brief cell array realisation of a List
%
%> CELLARRAYLIST A cell array realisation of the List ADT
%>   Refer to the description in the abstract superclass List for
%>   full detail.  This class is a concrete implementation of the List
%>   ADT - a useful 1D data structure for storing a heterogeneous set
%>   of elements.
%
%>   Written by Bobby Nedelkovski
%>   The MathWorks Australia Pty Ltd
%>   @copyright 2009-2010, The MathWorks, Inc.
%
%>   <BR>2009-Oct-06: Remove property 'numElts' as it's defined in superclass.Detailed informations about the class.
% ======================================================================
classdef CellArrayList < OM4MClassLib.DataStructs.List
    
    properties(Access=private)
        %> Capacity of pre-allocated list
        capacity;
        
        %> Flat Cell Array storage container for elements
        list;
    end
    
    
    properties(Constant=true, GetAccess=private)
        %> 2010-Apr-07: Define arbitrary size for initial list capacity.
        INITIAL_CAPACITY = 10;
    end
    
    methods % Public Access
        % Constructor.
        % ======================================================================
        %> @brief Class constructor
        % ======================================================================
        function newObj = CellArrayList()
            % Use an arbitrary initial list capacity and pre-allocate.
            newObj.numElts  = 0;
            newObj.capacity = newObj.INITIAL_CAPACITY;
            newObj.list     = cell(newObj.capacity,1);
        end
        
        % ======================================================================
        %> @brief Concrete implementation.  See List superclass.
        % ======================================================================
        
        function numElts = length(obj)
            numElts = obj.numElts;
        end
        
        % ======================================================================
        %> @brief Concrete implementation.  See List superclass.
        % ======================================================================
        
        function empty = isempty(obj)
            empty = obj.numElts==0;
        end
        
        
        
        % ======================================================================
        %> @brief Concrete implementation.  See List superclass.
        %>
        %>  This method accepts elements of any data type as input.
        %>  Using a cell array vector 'cav' will populate the list with
        %>  numel(cav) unique elements, otherwise the input will be treated as
        %>  a single element.
        % ======================================================================
        function add(varargin)
            % Check correct number of input args.
            error(nargchk(2,3,nargin));
            
            % Extract input args.
            obj  = varargin{1};
            elts = varargin{2};
            if nargin == 3
                loc = varargin{3};
                assert(isnumeric(loc) && isscalar(loc) && floor(loc)==loc,...
                    'MATLAB:List:CellArrayList','Location must be a scalar integer.');
                assert(1<=loc && loc<=obj.numElts+1,...
                    'MATLAB:List:CellArrayList',['Location must be in [1:' int2str(obj.numElts+1) ']']);
            else
                % If no location parameter supplied, append elements to end of
                % list.
                loc = obj.numElts+1;
            end
            
            % The elements of a single row or column cell array will be stored
            % as unique elements in the list.
            if iscell(elts) && isvector(elts)
                % Get number of new elements.
                n = numel(elts);
            else
                n = 1;
                elts = {elts};
            end
            
            % 2010-Apr-07: Bug fix to avoid infinite while-loop when capacity
            % reaches 0.  This occurs when capacity = numElts and remove() is
            % called numElts consecutive times to reduce capacity to 0.
            if obj.capacity == 0
                % Re-initialise the list.
                obj.capacity = obj.INITIAL_CAPACITY;
                obj.list     = cell(obj.capacity,1);
            end
            
            % Ensure sufficient space is available for new elements.
            resizeRequired = false;
            while n > obj.capacity-obj.numElts
                obj.capacity = 2*obj.capacity;
                resizeRequired = true;
            end
            
            % If the capacity was re-sized, create new list otherwise place
            % new elements in the existing list.
            % ***NOTE: Assignment by parts is more memory efficient than
            % concatenating parts to assign by whole.
            if resizeRequired
                tempList = cell(obj.capacity,1);
                tempList(1:loc-1) = obj.list(1:loc-1);
                tempList(loc:loc+n-1) = elts;
                % Existing elements in the list may be shifted to make way for
                % the new elements.
                if loc <= obj.numElts
                    tempList(loc+n:obj.numElts+n) = obj.list(loc:obj.numElts);
                end
                obj.list = tempList;
            else
                % Shift existing elements to end of list prior to inserting
                % the new elements in place.
                if loc <= obj.numElts
                    obj.list(loc+n:obj.numElts+n) = obj.list(loc:obj.numElts);
                end
                obj.list(loc:loc+n-1) = elts;
            end
            
            % Save new total number of elements.
            obj.numElts = obj.numElts+n;
        end
        
        % Concrete implementation.  See List superclass.
        % NOTE:  The input 'locs' is a scalar or 1D array of integers
        % i.e. [1,2,3]
        function elts = get(obj,locs)
            % Check input args.
            assert(obj.numElts~=0,...
                'MATLAB:List:CellArrayList','List is currently empty.');
            assert(isnumeric(locs) && isvector(locs) && isequal(floor(locs),locs),...
                'MATLAB:List:CellArrayList','Locations must be an integer vector.');
            assert(all(1<=locs & locs<=obj.numElts),...
                'MATLAB:List:CellArrayList',['Locations must be in [1:' int2str(obj.numElts) ']']);
            
            if numel(locs) > 1
                elts = obj.list(locs);
            else
                elts = obj.list{locs};
            end
        end
        
        % ======================================================================
        %> @brief Concrete implementation.  See List superclass.
        %>
        %> @param obj instance of the class.
        %> @param locs The input 'locs' is a scalar or 1D array of integers, i.e. [1,2,3]
        % ======================================================================
        function elts = remove(obj,locs)
            elts = obj.get(locs);
            % Automatically remove and shift down existing elements in same
            % contiguous memory space.
            obj.list(locs) = [];
            % 2009-Oct-06: Bug fix exclude duplicate locations from the total
            % count of removed elements.
            n = numel(unique(locs));
            obj.numElts = obj.numElts-n;
            obj.capacity = obj.capacity-n;
        end
        
        
        % ======================================================================
        %> @brief Concrete implementation.  See List superclass.
        % ======================================================================      
        function count = countOf(obj,elt)
            count = numel(obj.locationsOf(elt));
        end
        
        % Concrete implementation.  See List superclass.
        function locs = locationsOf(obj,elt)
            locs = find(cellfun(@(c)isequal(c,elt),obj.list));
        end
        
        % Overloaded.  Specialised display method.
        function display(obj)
            celldisp(obj.list(1:obj.numElts),'list');
        end
    end % methods
end % classdef
