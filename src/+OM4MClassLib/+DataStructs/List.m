classdef List < handle
   %LIST High level abstraction of the List Abstract Data Type (ADT)
   %  Intent:  Provides a useful 1D data structure (or container) for
   %  storing an ordered heterogeneous set of elements.
   %
   %  Motivation:  MATLAB R2009a provides the "containers.Map" data
   %  structure for storing an unordered heterogeneous set of elements -
   %  the Map ADT is a container that is indexed with a "key" of any data
   %  type.  A List ADT is a data container that is indexed by integers.
   %  The benefit in using a List ADT opposed to a native MATLAB cell array
   %  is the List ADT hides the complexity in the implementation of the
   %  operations you would perform to insert and remove elements in/from
   %  arbitrary positions, for example.
   %
   %  Implementation:  The List ADT can be implemented using any native
   %  MATLAB data container.  For instance, one could use a cell array or
   %  object reference links (Linked List) as place holders for data.
   % 
   %  Written by Bobby Nedelkovski
   %  The MathWorks Australia Pty Ltd
   %  Copyright 2009-2010, The MathWorks, Inc.

   % 2009-Oct-06: Change abstract class property from abstract to
   % concrete protected.
   % Common properties of all List implementations.
   properties(Access=protected)
      numElts;  % Number of elements in list
   end
   
   methods(Abstract) % Public Access
      % Overloaded.  Return the number of elements in the list.
      % Input:
      %    obj = instance of concrete implementation of this abstraction
      % Output:
      %    numElts = number of elements (integer) in the list
      % Preconditions:
      %    <none>
      % Postconditions:
      %    <none>
      numElts = length(obj);

      % Overloaded.  Query the list if it has any elements.
      % Input:
      %    obj = instance of concrete implementation of this abstraction
      % Output:
      %    empty = boolean value 'true' := list is empty
      % Preconditions:
      %    <none>
      % Postconditions:
      %    <none>
      empty = isempty(obj);
      
      % Overloaded.  Insert an element or vector of heterogeneous (in
      % data types) elements in the list starting at the specified
      % location.
      % Input:
      %    obj  = instance of concrete implementation of this abstraction
      %    elts = single element or vector of elements to add to list
      %    loc  = single location or insertion point in list (optional)
      %           if not used, 'elts' will be appended to end of list
      % Output:
      %    empty = boolean value 'true' := list is empty
      % Preconditions:
      %    verify if supplied elts is a single data type or vector of data
      %    types
      %    loc is integer between 1 & numElts+1
      % Postconditions:
      %    list := [list elts] (appending)
      %    list := [list(1:loc-1)  elts  list(loc:numElts)] (inserting)
      %    numElts := numElts + length(elts)
      add(varargin);
      
      % Overloaded.  Retrieve an element from the list.
      % Input:
      %    obj  = instance of concrete implementation of this abstraction
      %    locs = single location or vector of locations of elements to
      %           retrieve from list
      % Output:
      %    elts = single element or vector of elements retrieved from list
      % Preconditions:
      %    list must not be empty
      %    locs is single or vector of integers (can be with repetition)
      %    locs is between 1 & numElts
      % Postconditions:
      %    returned handle objects are references
      elts = get(obj, locs);
      
      % Overloaded.  Remove elements from the list.
      % Input:
      %    obj  = instance of concrete implementation of this abstraction
      %    locs = single location or vector of locations of elements to
      %           remove from list
      % Output:
      %    elts = single element or vector of elements removed from list
      % Preconditions:
      %    list must not be empty
      %    locs is single or vector of integers (can be with repetition)
      %    locs is between 1 & numElts
      % Postconditions:
      %    numElts := numElts - length(locs)
      %    list(locs) := [ ]
      %    returned handle objects are references
      elts = remove(obj, locs);
      
      % Returns the number of occurances of an element in the list.
      % Input:
      %    obj = instance of concrete implementation of this abstraction
      %    elt = a single element of any data type
      % Output:
      %    count = number of occurances of an element in the list
      % Preconditions:
      %    elt is single data type
      % Postconditions:
      %    <none>
      count = countOf(obj, elt);
        
      % Return a vector in ascending order of all the positions an element
      % occurs in the list.
      % Input:
      %    obj = instance of concrete implementation of this abstraction
      %    elt = a single element of any data type
      % Output:
      %    locs = locations, as an array of integers, of all occurances of
      %           an element in list
      % Preconditions:
      %    elt is single data type
      % Postconditions:
      %    <none>
      locs = locationsOf(obj, elt);
   end % methods
end % classdef
