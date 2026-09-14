classdef testQC_FeatureTest < matlab.unittest.TestCase
    %run(testQC_FeatureTest)
    %
    %NOTE: all tests but testConstructor call helper functions
    %(getQCDirectoriesTest, filterOKDirTest, genQCDataStTest, geteDPMTest,
    %getSWVersionTest) that do not exist anywhere in this repo, and point
    %at an external '..\TestDB\V07'/'..\TestDB\V08' directory that isn't
    %part of it either - these were never migrated/available and will
    %error on undefined function until that's resolved.

    methods(TestMethodSetup)
        function SetUp(testCase)
            close all
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
        function testConstructor(testCase)
            %run(testQC_FeatureTest, 'testConstructor')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            f=aFeatureFactory.Create(aFeatureTypes.FeatureTest);

            p=f.Get();
            testCase.assertTrue(isfield(p, char(aFeatureProps.M)));

            %is a DPMGobalMeStd feature
            testCase.assertEqual(aFeatureTypes.FeatureTest, f.Id);

            %zero samples
            testCase.assertEqual(0, f.m);

            %4 features
            testCase.assertEqual(4, f.n);
        end

        %check the calculate method
        function testCalculate(testCase)
            %run(testQC_FeatureTest, 'testCalculate')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %scan for PMFs
            rootQCdir='..\TestDB\V07';
            ListDir=getQCDirectoriesTest(rootQCdir);
            ListDir=filterOKDirTest(ListDir);
            StatsList=genQCDataStTest(ListDir);
            [eDPMList,StatsList]=geteDPMTest(StatsList);

            %calculate number of samples for testing
            %get LensIds
            lid={StatsList(:).LensId};
            %get Paths
            QCpath={StatsList(:).QCpath};
            %check if PMF or former mapper files
            newVersion=cellfun(@getSWVersionTest,lid,QCpath);
            %the Feature only search for PMFs
            m=length(newVersion); %number of samples
            y=rand(m, 1); %#ok<NASGU>
            labels=cell(m,1);
            d=dir;
            for j=1:m
                labels{j}=d(j+3).name;
            end

            %test Calculate
            f=aFeatureFactory.Create(aFeatureTypes.FeatureTest);

            %we can not set labels before calculate X
            %set bad labels
            try
                f.y=y;
            catch ME
                testCase.assertEqual(ME.message,  'FeatureTest->labels must be a mx1 vector: aFeature.set.y')
            end

            try
                f.labels=labels;
            catch ME
                testCase.assertEqual(ME.message,  'FeatureTest->labels must be a mx1 vector: aFeature.set.labels')
            end

            %calculate X
            f.Calculate(eDPMList);

            %check results, this feature already load labels and symbolic labels using StatsList
            X=[0.0268165728077233 0.0538220974993281 0.106103662112226 0.0631389608618205;...
                0.0218804012345679 0.0651405754150110 0.102299155535919 0.0907410990643244;...
                0.916255987202924 2.06414549462420 0.247890608228978 0.460842678778626;...
                0.443956001955035 1.40115149692605 0.292422538161835 0.571385771506796;...
                -0.520427926829268 1.05729646329649 0.254232635796909 0.458780500491894;...
                -0.712687443744374 1.35156783339707 0.345365500004803 0.594777351293266];
            %set labels
            y=[1 1 0 0 1 1]';
            labels={'Wrong', 'Wrong', 'Good', 'Good', 'Wrong', 'Wrong'}';
            f.y=y;
            f.labels=labels;

            testCase.assertEqual(X, f.X, 'AbsTol', 1e-10);
            testCase.assertEqual(y,f.y);
            cellfun(@(a,b) testCase.assertEqual(a,b), labels, f.labels);

            %set bad labels
            try
                f.y=ones(30, 50);
            catch ME
                testCase.assertEqual(ME.message,  'FeatureTest->y must be a mx1 vector: aFeature.set.y')
            end

            %set labels
            f.y=y;
            f.labels=labels;

            %m samples
            testCase.assertEqual(m, f.m);
            %4 features
            testCase.assertEqual(4, f.n);

            %get labels
            testCase.assertEqual(y, f.y);
            cellfun(@(a,b) testCase.assertEqual(a,b), labels, f.labels);
        end

        %check the Save+Load method
        function testSaveLoad(testCase)
            %run(testQC_FeatureTest, 'testSaveLoad')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %scan for PMFs
            rootQCdir='..\TestDB\V07';
            ListDir=getQCDirectoriesTest(rootQCdir);
            ListDir=filterOKDirTest(ListDir);
            StatsList=genQCDataStTest(ListDir);
            eDPMList=geteDPMTest(StatsList);

            %test Calculate
            f=aFeatureFactory.Create(aFeatureTypes.FeatureTest);

            %calculate X
            f.Calculate(eDPMList);
            X=f.X;
            y=f.y;
            labels=f.labels;

            %save
            aFeature.save(f, 'testAQ');

            clear('f');

            %reload
            f1=aFeature.load('testAQ');

            %check state
            testCase.assertEqual(X, f1.X, 'AbsTol', 1e-10);
            testCase.assertEqual(y,f1.y);
            testCase.assertEqual(labels, f1.labels);
        end

        %check the AddSamples
        function testAddSamples(testCase)
            %run(testQC_FeatureTest, 'testAddSamples')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %scan for PMFs
            rootQCdir='..\TestDB\V07';
            ListDir=getQCDirectoriesTest(rootQCdir);
            ListDir=filterOKDirTest(ListDir);
            StatsList=genQCDataStTest(ListDir);
            eDPMList=geteDPMTest(StatsList);

            f1=aFeatureFactory.Create(aFeatureTypes.FeatureTest);
            %calculate X
            f1.Calculate(eDPMList);
            X1=f1.X;
            y1=f1.y;
            labels1=f1.labels;
            m1=f1.m;

            %scan for PMFs
            rootQCdir='..\TestDB\V08';
            ListDir=getQCDirectoriesTest(rootQCdir);
            ListDir=filterOKDirTest(ListDir);
            StatsList=genQCDataStTest(ListDir);
            eDPMList=geteDPMTest(StatsList);

            f2=aFeatureFactory.Create(aFeatureTypes.FeatureTest);
            %calculate X
            f2.Calculate(eDPMList);
            X2=f2.X;
            y2=f2.y;
            labels2=f2.labels;
            m2=f2.m;

            f1.AddSamples(f2);

            testCase.assertEqual(m1+m2, f1.m);
            testCase.assertEqual([X1;X2], f1.X, 'AbsTol', 1e-10);
            testCase.assertEqual([y1;y2],f1.y);
            testCase.assertEqual([labels1;labels2], f1.labels);
        end

        %check the AddSamples
        function testgenTrainSets(testCase)
            %run(testQC_FeatureTest, 'testgenTrainSets')
            import OM4MClassLib.Util.*;

            fprintf('\n%s: ',Logging.WhoCalledMe());

            %scan for PMFs
            rootQCdir='..\TestDB\V07';
            ListDir=getQCDirectoriesTest(rootQCdir);
            ListDir=filterOKDirTest(ListDir);
            StatsList=genQCDataStTest(ListDir);
            eDPMList=geteDPMTest(StatsList);

            f=aFeatureFactory.Create(aFeatureTypes.FeatureTest);
            %calculate X
            f.Calculate(eDPMList);

            fTS=f.trainSets();

            testCase.assertTrue(isa(fTS.TRS, 'FeatureTest'));
            testCase.assertTrue(isa(fTS.TES, 'FeatureTest'));
            testCase.assertTrue(isa(fTS.CVS, 'FeatureTest'));

            %agregate the TrainSets
            fnew=aFeatureFactory.Create(aFeatureTypes.FeatureTest);
            fnew.AddSamples(fTS.TRS);
            fnew.AddSamples(fTS.TES);
            fnew.AddSamples(fTS.CVS);

            testCase.assertEqual(f.m, fnew.m); %same samples #
            testCase.assertEqual(f.n, fnew.n); %same features #
        end
    end
end
