classdef UtilTime
    %UtilTime Static Helper Class for time management
    
    
    %% static methods
    methods(Static)
        %this waits for n seconnds and display a waitvar
        function WaitForNSeconds(N, waitMsg)
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