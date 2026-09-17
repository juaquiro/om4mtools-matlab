function [CurvDer]=CalculateCurvatureDer(X,Y, ZMatrix)
    % CalculateCurvatureDer evaluates, at points (X,Y), the four
    % third-order partial derivatives (d3P/dx3, d3P/dx2dy, d3P/dy2dx,
    % d3P/dy3) of each XY-equivalent polynomial in ZMatrix (as returned
    % by Zernikes.PolyEquivalent), stacking the four results per term
    % into columns of CurvDer (4*length(X) rows)
    import Zernikes.*


    matSize=size(ZMatrix);
    monomialCount=matSize(3);
    CurvDer=zeros(4*length(X), monomialCount);
    for i=1:monomialCount
        Pcoeffs=ZMatrix(:,:,i);
        
        Px=Poly2.Derive(Pcoeffs,1);
        Py=Poly2.Derive(Pcoeffs,2);
        Pxx=Poly2.Derive(Px,1);
        Pyy=Poly2.Derive(Py,2);
        
        Pxxx=Poly2.Derive(Pxx,1);
        Pxxy=Poly2.Derive(Pxx,2);        
        Pyyx=Poly2.Derive(Pyy,1);
        Pyyy=Poly2.Derive(Pyy,2);
        
        CurvDer(:,i)=[  Poly2.Evaluate(X,Y,Pxxx);
                        Poly2.Evaluate(X,Y,Pxxy);
                        Poly2.Evaluate(X,Y,Pyyx);
                        Poly2.Evaluate(X,Y,Pyyy); ];
        
    end

end