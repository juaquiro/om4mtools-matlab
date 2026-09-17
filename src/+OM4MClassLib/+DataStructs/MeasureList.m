classdef MeasureList < handle
    %MeasureList This class descrives a measure array list of Cells
    %   It can store any kind of mesurement object, from a picture to a
    %   structure
    
    %% properties
    properties (Access=protected)
        MList; %this is a CellArrayList of objects representing measurements
    end
    
    properties (Dependent=true, SetAccess=private)
        Length;
        IsEmpty;
    end
    
    methods (Abstract)
        Export(this, varargin);
        Add(this, obj);
        %Import(this, varargin);        
    end
    
    
    %% public methods
    methods
        function this=MeasureList()
            % MeasureList constructs an empty measurement list backed by
            % a CellArrayList
            import OM4MClassLib.DataStructs.*;
            try
                this.MList=CellArrayList();
            catch ME
                throw(ME)
            end
        end     
        
        function this=Remove(this, pos)
            % Remove removes the element(s) at position(s) pos
            try
                this.MList.remove(pos);
            catch ME
                throw(ME)
            end
            
        end
        
        function cap=Get(this, pos)
            % Get returns the element(s) at position(s) pos
            try
                cap=this.MList.get(pos);
            catch ME
                throw(ME)
            end
        end
        
        function this=Save(this, fileName)
            % Save saves this MeasureList (variable 'this') to fileName
            try
                save(fileName, 'this');
            catch ME
                throw(ME)
            end
        end
        
        function this=Load(this, fileName)
            % Load loads this.MList from the 'this' variable saved by
            % Save() into fileName
            try
                obj=load(fileName, 'this');
                this.MList=obj.this.MList;
            catch ME
                throw(ME)
            end
        end
    end
    
    %% get-set methods
    methods
        function L=get.Length(this)
            % get.Length returns the number of stored elements
            try
                L=this.MList.length;
            catch ME
                throw(ME)
            end
        end
        
        function res=get.IsEmpty(this)
            % get.IsEmpty returns true if the list has no elements
            try
                res=this.MList.isempty();
            catch ME
                throw(ME)
            end
            
        end
    end
    
end
