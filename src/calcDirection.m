% FUNCION DE ESTIMADOR REGULARIZADO PARA
% EL CALCULO DE LA FASE ASOCIADA A LAS ISOCLINAS
% EN FOTOELASTICIDAD
% wtheta = mapa del angulo de orientacion (mod pi)
% wbeta = mapa del angulo de direccion (mod 2pi) 
% q = Mapa de calidad para la estimacion
% m = mascara
% t = Tamaño de la region para el estimador (t*2+1)
% mu = Parametro de regularizacion
% r0 pto inicial, [] lo busca automaticamente del maximo de q

function [wbeta]=calcDirection(wtheta,q,m,t,mu,r0)
%% INICIALIZA VALORES
n=size(wtheta);
px=ones(n);py=ones(n);q=abs(q).*m;
s=zeros(n);wbeta=zeros(n);
dx=cos(wtheta).*m;dy=sin(wtheta).*m;

%% DEFINE EL TAMAÑO DEL ARREGLO PARA EL HISTOGRAMA DEL ALGORITMO DE STRÖBEL
na=10;maxi=0;
q=round(q./max(max(q))*(na-1))+1;
for k=1:na
    [ry,rx]=find(q==k);
    if maxi<length(ry) maxi=length(ry);end
end
hy=zeros(na,maxi);hx=zeros(na,maxi);
front=zeros(1,na);final=zeros(1,na);

%% ALGORITMO DE STRÖBEL PARA SEGUIR EL MAPA DE CALIDAD EN LA ESTIMACION
cont=0;ind=1;

if isempty(r0)
    [yy,xx]=find(q==(max(q(:))));y=yy(1);x=xx(1); % Determina las coordenadas de arranque de la estimacion
else
    x=r0(1);
    y=r0(2);
end

px(y,x)=-dy(y,x);py(y,x)=dx(y,x);
wbeta(y,x)=atan2(dy(y,x),dx(y,x));s(y,x)=1;

puntos_total=sum(sum(m));
handle_bar = waitbar(0,'Please wait...');

while ind>0
    xx=[x-1;x-1;x-1;x;x;x+1;x+1;x+1];yy=[y-1;y;y+1;y-1;y+1;y-1;y;y+1];
    for k=1:8
        if s(yy(k),xx(k))==0 & m(yy(k),xx(k))>0 & xx(k)>t & xx(k)<n(2)-t+1 & yy(k)>t & yy(k)<n(1)-t+1
            xt=xx(k);yt=yy(k);
            dx2=dx(yt-t:yt+t,xt-t:xt+t);dy2=dy(yt-t:yt+t,xt-t:xt+t);
            s2=s(yt-t:yt+t,xt-t:xt+t);m2=m(yt-t:yt+t,xt-t:xt+t);
            px2=px(yt-t:yt+t,xt-t:xt+t);py2=py(yt-t:yt+t,xt-t:xt+t);
            G(1,1)=sum(sum(dx2.^2.*m2))+mu*sum(sum(s2.*m2));
            G(1,2)=sum(sum(dy2.*dx2.*m2));
            b(1)=mu*sum(sum(px2.*s2.*m2));
            G(2,2)=sum(sum(dy2.^2.*m2))+mu*sum(sum(s2.*m2));
            b(2)=mu*sum(sum(py2.*s2.*m2));
            G(2,1)=G(1,2);
            R=inv(G)*b';
            px(yt,xt)=R(1);py(yt,xt)=R(2);
            wbeta(yt,xt)=atan2(-px(yt,xt),py(yt,xt));
            
            s(yt,xt)=1;h=q(yt,xt);
            if final(h)==maxi final(h)=1;
            else final(h)=final(h)+1;end
            hx(h,final(h))=xt;hy(h,final(h))=yt;
            if front(h)==0 front(h)=1;end
            cont=cont+1;
        end
    end
    
    
    %SACA LAS COORDENADAS DEL HISTOGRAMA
    %PARA LA SIGUIENTE ESTIMACIÓN
    k=na;ind=0;
    while ind==0 && k>0
        ind=front(k);
        if ind>0
            x=hx(k,front(k));
            y=hy(k,front(k));
            if front(k)==final(k)
                front(k)=0;final(k)=0;
            else
                if front(k)==maxi front(k)=1;
                else front(k)=front(k)+1;end
            end
        end
        k=k-1;
    end
    
    %DESPLIEGA LA IMAGEN DE LA FASE EN LAPSOS
    if mod(cont, 500)==0
        waitbar(cont/puntos_total)
        imagesc(wbeta); figure(gcf);
        drawnow;
    end
end
close(handle_bar)
