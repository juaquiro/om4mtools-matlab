%> @file CQueue.m
%> @brief implemntation of a queue struct
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR20

% ======================================================================
%> @brief CQueue define a queue data strcuture
%> @details It likes java.util.Queue, however, it could use CQueue.content() to
%> return all the data (in cells) of the Queue, and it is a litter faster
%> than java's Queue.<BR>
%>
%>   - q = CQueue(c); c is a cells, and could be omitted
%>   - s.size() return the numble of element
%>   - s.isempty() return true when the queue is empty
%>   - s.empty() delete all the elements in the queue.
%>   - s.push(el) push el to the top of qeueu
%>   - s.pop() pop out the the beginning of queue, and return the element
%>   - s.front() return the the the beginning element of the qeueu
%>   - s.back() return the the the rear element of the qeueu
%>   - s.remove() remove all data from the queue
%>   - s.content() return all the data of the queue (in the form of a cells with size [s.size(), 1]
%> @see CList, CStack
%> @copyright zhang@zhiqiang.org, 2010.
%> @see testCQueue.m
% ======================================================================
classdef CQueue < handle
    
    properties (Access = private)
        %> a cell, to maintain the data
        buffer
        %> the start position of the queue
        beg
        %> the end position of the queue
        rear
        % the actually data is buffer(beg:rear-1)
    end
    
    properties (Access = public)
        %> Queue capacity
        capacity
    end
    
    methods
        function obj = CQueue(c) % 初始化
            if nargin >= 1 && iscell(c)
                obj.buffer = [c(:); cell(numel(c), 1)];
                obj.beg = 1;
                obj.rear = numel(c) + 1;
                obj.capacity = 2*numel(c);
            elseif nargin >= 1
                obj.buffer = cell(100, 1);
                obj.buffer{1} = c;
                obj.beg = 1;
                obj.rear = 2;
                obj.capacity = 100;
            else
                obj.buffer = cell(100, 1);
                obj.capacity = 100;
                obj.beg = 1;
                obj.rear = 1;
            end
        end
        
        function s = size(obj) % 队列长度
            if obj.rear >= obj.beg
                s = obj.rear - obj.beg;
            else
                s = obj.rear - obj.beg + obj.capacity;
            end
        end
        
        % ======================================================================
        %> @brief return true when the queue is empty
        % ======================================================================
        function b = isempty(obj)
            b = ~logical(obj.size());
        end
        
        function s = empty(obj) % clear all the data in the queue
            s = obj.size();
            obj.beg = 1;
            obj.rear = 1;
        end
        
        function push(obj, el) % 压入新元素到队尾
            if obj.size >= obj.capacity - 1
                sz = obj.size();
                
                %AQDEBUG solucion de https://es.mathworks.com/matlabcentral/fileexchange/28922-list--queue--stack
                %cambiar if obj.rear >= obj.front
                if obj.rear >= obj.beg
                    obj.buffer(1:sz) = obj.buffer(obj.beg:obj.rear-1);
                else
                    obj.buffer(1:sz) = obj.buffer([obj.beg:obj.capacity 1:obj.rear-1]);
                end
                obj.buffer(sz+1:obj.capacity*2) = cell(obj.capacity*2-sz, 1);
                obj.capacity = numel(obj.buffer);
                obj.beg = 1;
                obj.rear = sz+1;
            end
            obj.buffer{obj.rear} = el;
            obj.rear = mod(obj.rear, obj.capacity) + 1;
        end
        
        function el = front(obj) % 返回队首元素
            if obj.rear ~= obj.beg
                el = obj.buffer{obj.beg};
            else
                el = [];
                warning('CQueue:NO_DATA', 'try to get data from an empty queue');
            end
        end
        
        function el = back(obj) % 返回队尾元素
            
            if obj.rear == obj.beg
                el = [];
                warning('CQueue:NO_DATA', 'try to get data from an empty queue');
            else
                if obj.rear == 1
                    el = obj.buffer{obj.capacity};
                else
                    el = obj.buffer{obj.rear - 1};
                end
            end
            
        end
        
        function el = pop(obj) % 弹出队首元素
            if obj.rear == obj.beg
                error('CQueue:NO_Data', 'Trying to pop an empty queue');
            else
                el = obj.buffer{obj.beg};
                obj.beg = obj.beg + 1;
                if obj.beg > obj.capacity, obj.beg = 1; end
            end
        end
        
        function remove(obj) % 清空队列
            obj.beg = 1;
            obj.rear = 1;
        end
        
        function display(obj) % 显示队列
            if obj.size()
                if obj.beg <= obj.rear
                    for i = obj.beg : obj.rear-1
                        disp([num2str(i - obj.beg + 1) '-th element of the stack:']);
                        disp(obj.buffer{i});
                    end
                else
                    for i = obj.beg : obj.capacity
                        disp([num2str(i - obj.beg + 1) '-th element of the stack:']);
                        disp(obj.buffer{i});
                    end
                    for i = 1 : obj.rear-1
                        disp([num2str(i + obj.capacity - obj.beg + 1) '-th element of the stack:']);
                        disp(obj.buffer{i});
                    end
                end
            else
                disp('The queue is empty');
            end
        end
        
        function c = content(obj) % 取出队列元素
            if obj.rear >= obj.beg
                c = obj.buffer(obj.beg:obj.rear-1);
            else
                c = obj.buffer([obj.beg:obj.capacity 1:obj.rear-1]);
            end
        end
    end
end