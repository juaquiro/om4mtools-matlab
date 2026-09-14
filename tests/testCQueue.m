%> @file testCQueue.m
%> @brief init tests for CQueue
%> @details NA
%> @copyright 2016 IOT
%> @author AQ 21MAR16
%> @see CQueue

% ======================================================================
%> @brief unit test class for CQueue
%> @details And here we can put some more detailed informations about the class.
% ======================================================================
classdef testCQueue < matlab.unittest.TestCase
    %run(testCQueue)
    
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            %clear classes
            setupPath();
        end
    end
    
    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m), not MATLAB's factory path
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end
    
    
    methods (Test)
        function testQueueWithInts(testCase)
            %run(testCQueue, 'testQueueWithInts')
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());

            %for some reason the import some times does not work
            import OM4MClassLib.DataStructs.*;       
            q=OM4MClassLib.DataStructs.CQueue;
            
            testCase.assertTrue(q.isempty);
            testCase.assertEqual(0, q.size);
            
            data=magic(3); data=data(:);
            N=length(data);
            
            for n=1:N
                q.push(data(n));
                
                testCase.assertEqual(n, q.size);
                testCase.assertFalse(q.isempty);
            end
            
            %vaciamos la cola y verificamos de nuevo tama�o
            testCase.assertEqual(N, q.empty);
            testCase.assertTrue(q.isempty);
            
            %si pedimos un elemento a una cola vacia salta un error
            %"Trying to pop an empty queue" 
            try
                p=q.pop();
            catch ME
                testCase.assertEqual(ME.message,'Trying to pop an empty queue')
            end
            
            testCase.assertEqual(0, q.size);
            
            %llenamos y vaciamos uno a uno
            for n=1:N
                q.push(data(n));
            end
            
            for n=N:-1:1
                dataQ(n)=q.pop();
                testCase.assertEqual(n-1, q.size);
            end
            
            testCase.assertEqual(data, flipud(dataQ'));
            
            
            
        end
        
        function testQueueWithPixels(testCase)
            %run(testCQueue, 'testQueueWithPixels')
            
            import OM4MClassLib.Util.*;
            disp(Logging.WhoCalledMe());
        
            import OM4MClassLib.DataStructs.*;         
            q=OM4MClassLib.DataStructs.CQueue;
            
            testCase.assertTrue(q.isempty);
            testCase.assertEqual(0, q.size);
            
            datax=rand(3,100);
            datay=fliplr(datax);
            pList=OM4MClassLib.DataStructs.Pixel(datax, datay);
            N=length(pList);
            
            disp('PASO 1/3 llenamos la cola y verificamos de nuevo tama�o');
            for n=1:N
                q.push(pList(n));
                
                testCase.assertEqual(n, q.size);
                testCase.assertFalse(q.isempty);
            end
            
            disp('PASO 2/3 vaciamos la cola de golpe y verificamos de nuevo tama�o');            
            testCase.assertEqual(N, q.empty);
            testCase.assertTrue(q.isempty);
            testCase.assertEqual(0, q.size);
                                    
            disp('PASO 3/3 vaciamos la cola y de uno en uno');            
            %llenamos y vaciamos uno a uno
            for n=1:N
                q.push(pList(n));
            end
            
            for n=N:-1:1
                pListQ(n)=q.pop();
                testCase.assertEqual(n-1, q.size);
            end
            
            %al comparar son la mismas listas pero una esta invertida
            for n=1:N
                testCase.assertEqual(pList(n), pListQ(N-n+1));
            end                       
            
        end
        
        
        
    end
end
