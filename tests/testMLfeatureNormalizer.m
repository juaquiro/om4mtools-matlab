classdef testMLfeatureNormalizer < matlab.unittest.TestCase
    % testMLfeatureNormalizer tests featureNormalizer
    %before running the tests
    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
            setupPath();
        end
    end
    
    %clear after the test
    methods(TestMethodTeardown)
        function TearDown(testCase)
            %restore path captured at session start (see resetPath.m), not MATLAB's factory path
            matlabpath(resetPath); %#ok<RESETPATH>
        end
    end
    
    methods (Test)
        
        function testML_UtilFunML_featureNormalizer_Go(testCase)
            % testML_UtilFunML_featureNormalizer_Go checks Go() output
            % has zero mean/unit std, both on the fitted data and on a
            % subset of it (looser tolerance)

            import OM4MClassLib.Util.*;
            
            
            
            X=100*randn(1000, 10)+30;
            
            n=featureNormalizer();
            n.CalcParams(X);
            X_norm=n.Go(X);
            
            mu=mean(X_norm);
            sigma=std(X_norm);
            
            tol=1e-10;
            testCase.assertTrue(all(abs(mu-zeros(1, length(mu)))<=tol));
            testCase.assertTrue(all(abs(sigma-ones(1, length(mu)))<=tol));
            
            %si repetimos con un subset la cosa sigue funcionado en tolerancias
            X=X(1:700, :);
            X_norm=n.Go(X);
            
            mu=mean(X_norm);
            sigma=std(X_norm);
            
            tol=1e-1;
            testCase.assertTrue(all(abs(mu-zeros(1, length(mu)))<=tol));
            testCase.assertTrue(all(abs(sigma-ones(1, length(mu)))<=tol));
        end
    end
    
end

