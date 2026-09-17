classdef testMLPolynomicFeatureMapper < matlab.unittest.TestCase
    % testMLPolynomicFeatureMapper tests polynomicFeatureMapper.Go
    % against brute-force monomial expansions for various feature counts
    % and orders p
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
        
        function testML_polynomicFeatureMapper01(testCase)
            % testML_polynomicFeatureMapper01 checks Go's this.powers
            % and X_mapped/output for p=3 on 3 real lens-QC features
            % loaded via TrainingDataLoader
            % Checking that it works with the data we already have

            import OM4MClassLib.Util.* Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            % Generating X
            QCStatsFile='QCStatsReport2Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegStdTCErr,...
                EnumFeatureNames.TrDx};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            %if X includes the bias, it must be removed!!! and added after mapping
            
            % Generating X_poly
            p=3;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            % Checking the powers property
            powersCell=cell(1,p);
            powersCell{1}=ones(1,p);
            powersCell{2}=[2 0 0;1 1 0;1 0 1;0 2 0;0 1 1;0 0 2];
            powersCell{3}=[3 0 0;2 1 0;2 0 1;1 2 0;1 1 1;1 0 2;0 3 0;0 2 1;0 1 2;0 0 3];
            testCase.assertEqual(A.powers,powersCell)
            
            % Checking X_poly
            m=size(X,1);
            for i=1:m
                X1=X(i,1);
                X2=X(i,2);
                X3=X(i,3);
                X_test=[X1 X2 X3... % Order 1
                    X1^2 X1*X2 X1*X3 X2^2 X2*X3 X3^2.... % Order 2
                    X1^3 X1^2*X2 X1^2*X3 X1*X2^2 X1*X2*X3 X1*X3^2 X2^3 X2^2*X3 X2*X3^2 X3^3]; % Order 3
                testCase.assertEqual(X_test,X_poly(i,:))
                testCase.assertEqual(X_test,A.X_mapped(i,:))
            end
        end
        
        function testML_polynomicFeatureMapper02(testCase)
            % testML_polynomicFeatureMapper02 checks Go for 2 samples of
            % 4 features (bias already removed), p=2
            % 2 sets of 4 Xi (4 Xi + bias), p=2. Bias is internally removed

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Generating X_poly
            %if X includes the bias, it must be removed!!! and added after mapping
            X=[1 2 3 0.5;-1 -2 -3 -0.5];
            p=2;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            % Generating Xtest and checking X_poly
            m=size(X,1);
            for i=1:m
                X1=X(i,1);
                X2=X(i,2);
                X3=X(i,3);
                X4=X(i,4);
                Xtest=[X1 X2 X3 X4... % Order 1
                    X1^2 X1*X2 X1*X3 X1*X4 X2^2 X2*X3 X2*X4 X3^2 X3*X4 X4^2]; % Order 2
                testCase.assertEqual(Xtest,X_poly(i,:))
            end
        end
        
        function testML_polynomicFeatureMapper03(testCase)
            % testML_polynomicFeatureMapper03 checks Go for 2 samples of
            % 3 features, p=3
            % 2 sets of 3 Xi, p=3

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Generating X_poly
            %if X includes the bias, it must be removed!!! and added after mapping
            X=[1 2 3;0.5 -3 -1];
            p=3;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            % Generating Xtest and checking X_poly
            m=size(X,1);
            for i=1:m
                X1=X(i,1);
                X2=X(i,2);
                X3=X(i,3);
                Xtest=[X1 X2 X3... % Order 1
                    X1^2 X1*X2 X1*X3 X2^2 X2*X3 X3^2.... % Order 2
                    X1^3 X1^2*X2 X1^2*X3 X1*X2^2 X1*X2*X3 X1*X3^2 X2^3 X2^2*X3 X2*X3^2 X3^3]; % Order 3
                testCase.assertEqual(X_poly(i,:),Xtest)
            end
        end
        
        function testML_polynomicFeatureMapper04(testCase)
            % testML_polynomicFeatureMapper04 checks Go for 3 samples of
            % 2 features, p=6
            % 3 sets of 2 Xi, p=6

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Generating X_poly
            %if X includes the bias, it must be removed!!! and added after mapping
            X=[1 2;3 4;0.1 0.5];
            p=6;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            % Generating Xtest and checking X_poly
            m=size(X,2);
            for i=1:m
                X1=X(i,1);
                X2=X(i,2);
                Xtest=[X1 X2... % Order 1
                    X1^2 X1*X2 X2^2.... % Order 2
                    X1^3 X1^2*X2 X1*X2^2 X2^3.... % Order 3
                    X1^4 X1^3*X2 X1^2*X2^2 X1*X2^3 X2^4.... % Order 4
                    X1^5 X1^4*X2 X1^3*X2^2 X1^2*X2^3 X1*X2^4 X2^5.... % Order 5
                    X1^6 X1^5*X2 X1^4*X2^2 X1^3*X2^3 X1^2*X2^4 X1*X2^5 X2^6]; % Order 6
                testCase.assertEqual(Xtest,X_poly(i,:))
            end
        end
        
        function testML_polynomicFeatureMapper05(testCase)
            % testML_polynomicFeatureMapper05 checks Go for 2 samples of
            % 4 features, p=3
            % 2 sets of 4 Xi, p=3

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Generating X_poly
            %if X includes the bias, it must be removed!!! and added after mapping
            X=[1 2 3 4;0.1 0.25 0.5 0.75];
            p=3;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            % Generating Xtest and checking X_poly
            m=size(X,1);
            for i=1:m
                X1=X(i,1);
                X2=X(i,2);
                X3=X(i,3);
                X4=X(i,4);
                Xtest=[X1 X2 X3 X4... % Order 1
                    X1^2 X1*X2 X1*X3 X1*X4 X2^2 X2*X3 X2*X4 X3^2 X3*X4 X4^2.... % Order 2
                    X1^3 X1^2*X2 X1^2*X3 X1^2*X4 X1*X2^2 X1*X2*X3 X1*X2*X4 X1*X3^2 X1*X3*X4... % Order 3
                    X1*X4^2 X2^3 X2^2*X3 X2^2*X4 X2*X3^2 X2*X3*X4 X2*X4^2 X3^3 X3^2*X4 X3*X4^2 X4^3]; % Order 3
                testCase.assertEqual(Xtest,X_poly(i,:))
            end
        end
        
        function testML_polynomicFeatureMapper06(testCase)
            % testML_polynomicFeatureMapper06 checks Go with p=1 is the
            % identity (X_poly==X) for 3 samples of 4 features
            %p=1

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            % Generating X_poly
            %if X includes the bias, it must be removed!!! and added after mapping
            X=[1 2 3 4;0.1 0.25 0.5 0.75; 1 0 0 0];
            p=1;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            
            % Generating Xtest and checking X_poly
            m=size(X,1);
            for i=1:m
                X1=X(i,1);
                X2=X(i,2);
                X3=X(i,3);
                X4=X(i,4);
                Xtest=[X1 X2 X3 X4]; % Order 1
                testCase.assertEqual(size(Xtest),size(X_poly(i,:)));
                testCase.assertEqual(Xtest,X_poly(i,:))
            end
        end
        
        function testML_polynomicFeatureMapper07(testCase)
            % testML_polynomicFeatureMapper07 checks Go with p=1 is the
            % identity on X loaded from the bugMapperGo.mat fixture
            % (a regression fixture for a previously found bug)
            %p=1 con un fichero de PL

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            s=load('bugMapperGo', 'X');
            
            % Generating X_poly
            %if X includes the bias, it must be removed!!! and added after mapping
            X=s.X;
            p=1;
            A=polynomicFeatureMapper();
            X_poly=A.Go(X,p);
            
            
            % Generating Xtest and checking X_poly
            m=size(X,1);
            for i=1:m
                testCase.assertEqual(size(X(i,:)),size(X_poly(i,:)));
                testCase.assertEqual(X(i,:),X_poly(i,:))
            end
        end
        
    end
    
end

