classdef UtilTime
    %UtilTime Static Helper Class for time management
    
    
    %% static methods
    methods(Static)
        function WaitForNSeconds(N, waitMsg)
            % WaitForNSeconds blocks for N seconds (N>=1), showing a
            % waitbar with title waitMsg updated once per second
            import OM4MClassLib.Util.*
            callFunc=Logging.WhoCalledMe();
            
            N=double(uint8(N));
            if N<1
                retMsg=[inputname(N) ' must be > 1'];
                error([callFunc, '->' retMsg]);
            end
            
            h=waitbar(0, waitMsg);                          
            for n=1:N
                pause(1);              
                waitbar(n/N, h)
                %drawnow;
            end
            close(h);
        end
    end
    
end