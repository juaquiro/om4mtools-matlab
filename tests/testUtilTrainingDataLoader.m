classdef testUtilTrainingDataLoader < matlab.unittest.TestCase
    % testUtilTrainingDataLoader tests TrainingDataLoader (loads lens QC
    % stats from an xlsx report into ML-ready feature/label matrices,
    % filtered by eye/lens type, and splits them into train/CV/test sets)
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
        
        function testUtil_TrainingDataLoader01(testCase)
            % testUtil_TrainingDataLoader01 checks X/y/labels for both
            % eyes, all lens types, labelData=Type (QCStatsReport2Clases.xlsx)
            % Both eyes, all lenses, Type as labelData, QCStatsReport2Clases.xlsx

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport2Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTSeqErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.TrDx};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            labels=TDL.labels;
            
            % Checking the size and contents of each property
            % X property
            StatsStruct=XLSUtils.ReadFile(QCStatsFile);
            Xrows=length(clearNaN({StatsStruct(:).LensId}));
            Xcolumns=length(ListFeatureNames);
            
            testCase.assertEqual(size(X),[Xrows Xcolumns]);
            testCase.assertEqual([StatsStruct(1:Xrows).NoRegMeanTSeqErr],X(:,1)');
            testCase.assertEqual([StatsStruct(1:Xrows).NoRegStdTCErr],X(:,2)');
            testCase.assertEqual([StatsStruct(1:Xrows).TrDx],X(:,3)');
            
            % y property
            % The corresponding number to each different label is assigned in
            % alphabetical order, so in this case Good will be identified as
            % number 1 and Wrong as number 2
            ytest=zeros(703,1);
            [ytest(1:478)]=deal(2);
            [ytest(479:end)]=deal(1);
            
            testCase.assertEqual(ytest,y);
            
            % labels property
            testLabels=cell(Xrows,1);
            [testLabels{1:479}]=deal('Wrong');
            [testLabels{479:end}]=deal('Good');
            
            testCase.assertEqual(length(labels),length(testLabels));
            testCase.assertEqual(testLabels,labels);
            
        end
        
        function testUtil_TrainingDataLoader02(testCase)
            % testUtil_TrainingDataLoader02 checks X/y/labels filtered to
            % the right eye and progressive lenses only, labelData=Type
            % (QCStatsReport3Clases.xlsx)
            % Right eye, just progressive lenses, Type as labelData, QCStatsReport3Clases.xlsx

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr, EnumFeatureNames.meanTCErr...
                EnumFeatureNames.StdTCErr, EnumFeatureNames.TrThetaRot};
            LensType=EnumLens.Progressive;
            Eye=EnumEye.R;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            labels=TDL.labels;
            
            % Checking the size and contents of each property
            % X property
            StatsStruct=XLSUtils.ReadFile(QCStatsFile);
            eyeR={StatsStruct(:).Eye};
            indEyeR=strcmp('R',eyeR);
            lensProg={StatsStruct(:).isProgressive};
            indLensProg=strcmp('YES',lensProg);
            indexer=indEyeR & indLensProg;
            Xrows=length({StatsStruct(indexer).LensId});
            Xcolumns=length(ListFeatureNames);
            
            testCase.assertEqual(size(X),[Xrows Xcolumns]);
            testCase.assertEqual([StatsStruct(indexer).NoRegMeanTCErr],X(:,1)');
            testCase.assertEqual([StatsStruct(indexer).NoRegStdTCErr],X(:,2)');
            testCase.assertEqual([StatsStruct(indexer).meanTCErr],X(:,3)');
            testCase.assertEqual([StatsStruct(indexer).StdTCErr],X(:,4)');
            testCase.assertEqual([StatsStruct(indexer).TrThetaRot],X(:,5)');
            
            % y property
            % The corresponding number to each different label is assigned in
            % alphabetical order, so in this case Anomalous will be identified as
            % number 1, Good as number 2 and Wrong as number 3
            ytest=zeros(401,1);
            [ytest(1:233)]=deal(3);
            [ytest(234:350)]=deal(2);
            [ytest(351:end)]=deal(1);
            
            testCase.assertEqual(ytest,y);
            
            % labels property
            testLabels=cell(Xrows,1);
            [testLabels{1:234}]=deal('Wrong');
            [testLabels{234:351}]=deal('Good');
            [testLabels{351:end}]=deal('Anomalous');
            
            testCase.assertEqual(length(labels),length(testLabels));
            testCase.assertEqual(testLabels,labels);
            
        end
        
        function testUtil_TrainingDataLoader03(testCase)
            % testUtil_TrainingDataLoader03 checks X/y/labels filtered to
            % the left eye and monofocal lenses only, labelData=QCpath
            % (QCStatsReport3Clases.xlsx)
            % Left eye, just monofocal lenses, QCpath as labelData, QCStatsReport3Clases.xlsx

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.QCpath;
            ListFeatureNames={EnumFeatureNames.TrDx, EnumFeatureNames.TrDy, EnumFeatureNames.TrThetaRot};
            LensType=EnumLens.Monofocal;
            Eye=EnumEye.L;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            labels=TDL.labels;
            
            % Checking the size and contents of each property
            % X property
            StatsStruct=XLSUtils.ReadFile(QCStatsFile);
            eyeR={StatsStruct(:).Eye};
            indEyeR=strcmp('L',eyeR);
            lensProg={StatsStruct(:).isProgressive};
            indLensProg=strcmp('NO',lensProg);
            indexer=indEyeR & indLensProg;
            Xrows=length({StatsStruct(indexer).LensId});
            Xcolumns=length(ListFeatureNames);
            
            testCase.assertEqual(size(X),[Xrows Xcolumns]);
            testCase.assertEqual([StatsStruct(indexer).TrDx],X(:,1)');
            testCase.assertEqual([StatsStruct(indexer).TrDy],X(:,2)');
            testCase.assertEqual([StatsStruct(indexer).TrThetaRot],X(:,3)');
            
            % y property
            % y property
            % The corresponding number to each different label is assigned in
            % alphabetical order
            ytest=[1 7 7 7 8 8 12 13 14 14 14 15 17 18 19 19 21 26 28 2 3 4 5 6 8 8 16....
                19 19 23 24 25 27 29 30 7 9 10 11 20 22]';
            
            testCase.assertEqual(ytest,y)
            
            % labels property
            testLabels={'\\iot7\Quality_Controls\Balester_Optical\Balester_Optical_1'...
                '\\iot7\Quality_Controls\Cione\Cione_1'...
                '\\iot7\Quality_Controls\Cione\Cione_1'...
                '\\iot7\Quality_Controls\Cione\Cione_1'...
                '\\iot7\Quality_Controls\Cione\Cione_2'...
                '\\iot7\Quality_Controls\Cione\Cione_2'...
                '\\iot7\Quality_Controls\I-Coat\I-Coat_1'...
                '\\iot7\Quality_Controls\I-Coat\I-Coat_2'...
                '\\iot7\Quality_Controls\IOH\IOH_1'...
                '\\iot7\Quality_Controls\IOH\IOH_1'...
                '\\iot7\Quality_Controls\IOH\IOH_1'...
                '\\iot7\Quality_Controls\IOH\IOH_2'...
                '\\iot7\Quality_Controls\Kaiser_Richmond\Kaiser_Richmond_1'...
                '\\iot7\Quality_Controls\Lens_Tech_Optical\Lens_Tech_Optical_1'...
                '\\iot7\Quality_Controls\MauiJim\MauiJim_2'...
                '\\iot7\Quality_Controls\MauiJim\MauiJim_2'...
                '\\iot7\Quality_Controls\New_Look_optical\New_Look_optical_2'...
                '\\iot7\Quality_Controls\RiteStyle_Optical\RiteStyle_Optical_2'...
                '\\iot7\Quality_Controls\VSP_Tech_Center_(Dtech)\VSP_Tech_Center_(Dtech)_1\DTech_A'...
                '\\iot7\Quality_Controls\Caledonian\Caledonian_1'...
                '\\iot7\Quality_Controls\CapitolOptical\CapitolOptical_1'...
                '\\iot7\Quality_Controls\CapitolOptical\CapitolOptical_2'...
                '\\iot7\Quality_Controls\CherryOptical_Detroit\CherryOptical_1'...
                '\\iot7\Quality_Controls\CherryOptical_GreenBay\CherryGreenBay_1'...
                '\\iot7\Quality_Controls\Cione\Cione_2'...
                '\\iot7\Quality_Controls\Cione\Cione_2'...
                '\\iot7\Quality_Controls\Kaiser_Permanente\Kaiser_Permanente_1'...
                '\\iot7\Quality_Controls\MauiJim\MauiJim_2'...
                '\\iot7\Quality_Controls\MauiJim\MauiJim_2'...
                '\\iot7\Quality_Controls\Perfect_Optics\Perfect_Optics_1'...
                '\\iot7\Quality_Controls\Perfect_Optics\Perfect_Optics_2'...
                '\\iot7\Quality_Controls\RiteStyle_Optical\RiteStyle_Optical_1'...
                '\\iot7\Quality_Controls\VSP_Sacramento\VSP_Sacramento_1'...
                '\\iot7\Quality_Controls\VSP_Tech_Center_(Dtech)\VSP_Tech_Center_(Dtech)_1\DTech_B'...
                '\\iot7\Quality_Controls\VSP_Tech_Center_(Dtech)\VSP_Tech_Center_(Dtech)_1\DTech_C'...
                '\\iot7\Quality_Controls\Cione\Cione_1'...
                '\\iot7\Quality_Controls\ClassicOptical\ClassicOptical_1'...
                '\\iot7\Quality_Controls\CostaDelMar\CostaDelMar_1'...
                '\\iot7\Quality_Controls\FirstLookOptical\FirstLook_1'...
                '\\iot7\Quality_Controls\New_Look_optical\New_Look_optical_1'...
                '\\iot7\Quality_Controls\Pech_Optical\Pech_Optical_1'}';
            
            testCase.assertEqual(length(labels),length(testLabels));
            testCase.assertEqual(testLabels,labels);
            
        end
        
        function testUtil_TrainingDataLoader04(testCase)
            % testUtil_TrainingDataLoader04 checks the TTS/TRS/CVS/TES
            % struct split: TTS matches {X,y,labels}, TRS+CVS+TES row
            % counts sum to TTS's, and no TRS row appears in CVS/TES
            % Checking the {X,y,labels} structs TTS, TRS, CVS, TES

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.TrDx, EnumFeatureNames.TrDy, EnumFeatureNames.TrThetaRot...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            X=TDL.X;
            y=TDL.y;
            labels=TDL.labels;
            TTS=TDL.TTS;
            TRS=TDL.TRS;
            CVS=TDL.CVS;
            TES=TDL.TES;
            
            % Checking TTS
            testStruct.X=X;
            testStruct.y=y;
            testStruct.labels=labels;
            testCase.assertEqual(testStruct,TTS);
            
            % Checking the size of TRS, CVS and TES
            % Columns
            ncolX=size(X,2)*ones(1,4);
            ncoly=size(y,2)*ones(1,4);
            ncollab=size(labels,2)*ones(1,4);
            testCase.assertEqual([size(TTS.X,2),size(TRS.X,2),size(CVS.X,2),size(TES.X,2)],ncolX)
            testCase.assertEqual([size(TTS.y,2),size(TRS.y,2),size(CVS.y,2),size(TES.y,2)],ncoly)
            testCase.assertEqual([size(TTS.labels,2),size(TRS.labels,2),size(CVS.labels,2),size(TES.labels,2)],ncollab)
            % Rows
            testCase.assertTrue(size(TTS.X,1)==size(TRS.X,1)+size(CVS.X,1)+size(TES.X,1))
            
            % Checking that any element of CVS and TES is contained in TRS
            trsX=TRS.X;
            cvsX=CVS.X;
            tesX=TES.X;
            Xtest=[cvsX;tesX];
            
            for i=1:size(trsX,1)
                for j=size(Xtest,1)
                    testCase.assertFalse(all(trsX(i,:)==Xtest(j,:)))
                end
            end
            
            
            % Checking that all the data of CVS and TES is different, no matter the
            % order of appearance
            for i=1:size(cvsX,1)
                for j=size(tesX,1)
                    testCase.assertFalse(all(cvsX(i,:)==tesX(j,:)))
                end
            end
            
        end
        
        function testUtil_TrainingDataLoader05(testCase)
            % testUtil_TrainingDataLoader05 checks two TrainingDataLoader
            % instances (same inputs) produce identical TTS but
            % different (randomized) TRS/CVS/TES splits
            % Checking that 2 instances to the class TraninigDataLoader generates the
            % same TTS, but different TRS, CVS and TES

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.TrDx, EnumFeatureNames.TrDy, EnumFeatureNames.TrThetaRot...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            % First instance
            TDL1=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            TTS1=TDL1.TTS;
            TRS1=TDL1.TRS;
            CVS1=TDL1.CVS;
            TES1=TDL1.TES;
            
            % Second instance
            TDL2=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            TTS2=TDL2.TTS;
            TRS2=TDL2.TRS;
            CVS2=TDL2.CVS;
            TES2=TDL2.TES;
            
            testCase.assertEqual(TTS1,TTS2);
            testCase.assertFalse(isequal(TRS1,TRS2));
            testCase.assertFalse(isequal(CVS1,CVS2));
            testCase.assertFalse(isequal(TES1,TES2));
            
        end
        
        function testUtil_TrainingDataLoader06(testCase)
            % testUtil_TrainingDataLoader06 checks every TrainingDataLoader
            % public property has SetAccess='private'
            % Checking that all TrainigDataLoader object properties are private

            import  OM4MClassLib.Util.*;
            fprintf('\n%s: ',Logging.WhoCalledMe());
            
            QCStatsFile='QCStatsReport3Clases.xlsx';
            labelData=EnumLabelData.Type;
            ListFeatureNames={EnumFeatureNames.TrDx, EnumFeatureNames.TrDy, EnumFeatureNames.TrThetaRot...
                EnumFeatureNames.NoRegMeanTCErr, EnumFeatureNames.NoRegStdTCErr};
            LensType=EnumLens.All;
            Eye=EnumEye.B;
            
            TDL=TrainingDataLoader(QCStatsFile, labelData, ListFeatureNames, LensType, Eye);
            
            prop=properties(TDL);
            for i=1:length(prop)
                p=findprop(TDL,prop{i});
                testCase.assertEqual(p.SetAccess,'private')
            end
        end
    end
    
end

