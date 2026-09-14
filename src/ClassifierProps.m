classdef ClassifierProps
    %ClassifierProps 
    %   alowed props for Classifiers    
    enumeration
        lambda,%regularization parameter (lambda) for LR and linReg, C parameter (~1/lambda) for SVN
        hiddenSizes; %number and sizes of NN hidden layers
        p; % order of polynomic transformation
        sigma; %sigma for the rbf (default kernel function) kernel of the SVM
        KF; %Kernel function for SVM (default rbf)
        showplot;%flag used by the SVM classifier to show 2D plots
        KFp; %polinomic kernel function order for SVM
        %isSupervised; %true (default) or false, this flag indicates if the classifier training is supervised or not
        svcType; %supervised Classifier type for unsupervised classifers (default LogR)
        normalize; %It's a logical which indicates if data normalization is wanted to be performed or not
        d; %mean inter cluster distance
        featureType; %this is a aFeatureType enum that indicates what was the feature used to train the classifier, default value is aFeatureTypes.Unknown 
        zOrder; %Order of the zernike polynomial used be ClassifierZernikes
        mu; %Relative weight of the deviation from constant curvature when training a ClassifierZernikes.
        zernikeRadius; %Radius of the circle where the ClassifierZernike is defined. Set to 0 for automatic calculation from input data.
        chebOrder;
        %isRegression; %this flags indicates whether the current classifier is a lineal regression (vs a classification)
        thetaFreeStyle, % Cell which contains the NN weigths, necessary to be extracted for the lifeSyile app (only applies to NN1 classifier)
    end
    
end

