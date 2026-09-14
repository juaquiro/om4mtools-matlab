classdef ClassifierTypes
    %ClassifierTypes 
    %Types of Classifiers
    
    enumeration
        LogR, %logistic regression (supervised)
        NN, %neural network, using MATLAB NN toolbox (supervised)
        NN1, %neural network, using coursera ML code, NN with one hidden layer (supervised)
        LinReg, %linear regression (supervised)
        Zernikes, %adjust a surface using zernike polynomials (supervised)
        Chebyshev, %adjust a surface using Chebyshev polynomials (supervised)
        SVM, %MATLAB statistics toolbox supoort toolbox machine (supervised)
        KmeansCluster; %MATLAB statistics toolbox unsupervised kmeans clustering (unsupervised)
    end
    
end

