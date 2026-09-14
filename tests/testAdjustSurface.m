classdef testAdjustSurface< matlab.unittest.TestCase
    
    methods(Test)
        function testUno(testCase) %#ok<*DEFNU>
            import Zernikes.*;
            import ML.*;

            x=-10:10;
            y=-10:10;
            [xx,yy]=meshgrid(x,y);
            xx=xx(:);
            yy=yy(:);
            z=sqrt(50^2-(xx.^2+yy.^2));
            

            order=464;
            cvRatio=0.1;

            cl=ClassifierFactory.Create(ClassifierTypes.LinReg);

            [Zcoef,CMatrix,J, Jcv]=AdjustSurface(xx,yy,z+3e-4*randn(size(z)),order, cvRatio, cl);
            plot(Zcoef);
            disp(J);
            disp(Jcv);
            
            [xx,yy]=meshgrid(x,y);
            z=reshape(z,size(xx));
            cz=Poly2.Evaluate(xx,yy,CMatrix);
            mesh(cz(3:end-2,3:end-2)-z(3:end-2,3:end-2));
            sqrt(mean(mean((cz(3:end-2,3:end-2)-z(3:end-2,3:end-2)).^2)))
        end
    end
end