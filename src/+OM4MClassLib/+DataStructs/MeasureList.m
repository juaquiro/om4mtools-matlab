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
        % constructor
        function this=MeasureList()
            import OM4MClassLib.DataStructs.*;
            try
                this.MList=CellArrayList();
            catch ME
                throw(ME)
            end
        end     
        
        %remove object
        function this=Remove(this, pos)
            try
                this.MList.remove(pos);
            catch ME
                throw(ME)
            end
            
        end
        
        %Get object
        function cap=Get(this, pos)
            try
                cap=this.MList.get(pos);
            catch ME
                throw(ME)
            end
        end
        
        function this=Save(this, fileName)
            try
                save(fileName, 'this');
            catch ME
                throw(ME)
            end
        end
        
        function this=Load(this, fileName)
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
            try
                L=this.MList.length;
            catch ME
                throw(ME)
            end
        end
        
        function res=get.IsEmpty(this)
            try
                res=this.MList.isempty();
            catch ME
                throw(ME)
            end
            
        end
    end
    
end
