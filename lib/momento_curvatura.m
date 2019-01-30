function [M,phi,c] = momento_curvatura(b,h,d1,d2,As1,As2,Pext,parametros,n,tolerancia,varargin)
% MOMENTO_CURVATURA calcula el diagrama M-phi para una secci�n rectangular de hormig�n armado.
%
% Variables de salida: 
%   -M: vector fila con los momentos asociados a cada curvatura (en kN*m)
%   -phi: vector fila con las curvaturas utilizadas (en 1/mm)
%   -c: vector fila con la ubicaci�n de los ejes neutros (en mm)
%
% Variables de entrada:
%   -b: ancho de la secci�n rectangular (en mmm)
%   -h: altura de la secci�n rectangular (en mmm)
%   -d1: distancia del borde superior de la secci�n hasta el centroide del refuerzo As1 (en mmm)
%   -d2: distancia del borde superior de la secci�n hasta el centroide del refuerzo As2 (en mmm)
%   -As1: �rea total del refuerzo inferior asociado a d1 (en mmm^2)
%   -As2: �rea total del refuerzo supeior asociado a d2 (en mmm^2)
%   -Pext: carga axial resultante en la secci�n, considerada positiva si es de compresi�n (en kN)
%   -parametros: estructura que contiene los par�metros que definen las leyes constitutivas de los materiales
%   -n: n�mero de segmentos en que se dividir� la secci�n (debe ser un entero positivo)
%   -tolerancia: error permitido en la sumatoria de fuerzas (en kN)
%   -varargin: valor que indica el sentido de la flexi�n, siendo igual a 1 � -1
%              (fibra superior o inferior es la m�s comprimida, respectivamente)

% Licenciado bajos los t�rminos del MIT.
% Copyright (c) 2019 Pablo Baez R.

% conversi�n de kN a N
Pext = 1000*Pext;
tolerancia = 1000*tolerancia;

% par�metros de los materiales
Es1 = 200000; % m�dulo de elasticidad inicial del acero (en MPa)
fy = parametros.fy; % tensi�n de fluencia del acero (en MPa)
fcc = parametros.fc; % f'c del hormig�n (en MPa)
Ecc = 4700*sqrt(fcc); % m�dulo de elasticidad del hormig�n (en MPa)
beta1 = max(0.65,min(0.85,0.85-0.008*(fcc-30)));
eu = 0.003; % deformaci�n m�xima a compresi�n del hormig�n en el estado l�mite �ltimo, seg�n ACI 318

% discretizaci�n elegida para el an�lisis seccional
dy = h/n; % largo de segmento
y = 0:dy:h; % distancia a cada segmento (a sus extremos) medida desde el borde inferior de la secci�n

% definici�n del rango de muestra para las curvaturas
nphi = 500; % se se considera un total de 500 curvaturas
signo_curvatura = 1; % se considera por defecto que la fibra superior es la m�s comprimida (o menos traccionada)
ymax = h; % ubicaci�n, medida desde el borde inferior, de la fibra m�s coprimida (por defecto, para phi>0, ymax=h)
if ~isempty(varargin)    
    signo_curvatura = varargin{1};
    if signo_curvatura == -1, ymax = 0; end % fibra inferior es la m�s comprimida (o menos traccionada)
end
% se considera un phi m�ximo de 1.5 veces la curvatura te�rica para la cual se alcanza una deformaci�n m�xima de ec=eu=0.003
cu1 = (Pext+As1*fy-Es1*As2*eu+((Es1*As2*eu-As1*fy-Pext)^2+3.4*beta1*fcc*b*As2*Es1*eu*d2)^0.5)/(1.7*fcc*b*beta1);
cu2 = (Pext+As2*fy-Es1*As1*eu+((Es1*As1*eu-As2*fy-Pext)^2+3.4*beta1*fcc*b*As1*Es1*eu*(h-d1))^0.5)/(1.7*fcc*b*beta1);
cu = max(cu1,cu2);
phif = 1.5*signo_curvatura*eu/cu;
phi = linspace(0,phif,nphi);% 

% inicializar variables
Fc = zeros(1,n); % fuerzas en cada segmento de hormig�n
yc = zeros(1,n); % brazos de palanca de cada fuerza Fc
M = zeros(1,nphi); % momentos resultantes para cada curvatura
c = zeros(1,nphi); % profundidad del eje neutro para cada curvatura
ec = zeros(1,nphi); % deformaci�n unitaria m�xima de compresi�n para cada curvatura

% inicializar los par�metros de la iteraci�n
dp = 0; % error inicial considerado
eo = 0; % deformaci�n unitaria inicial considerada (en h/2)
J = Ecc*b*h+Es1*(As1+As2); % rigidez inicial considerada
c(1) = Inf; % phi=0 ---> c=inf

% c�lculo del momento asociado a cada curvatura
for i = 2:nphi
    error = tolerancia+1; % para entrar en un nuevo ciclo de iteraciones para la curvatura siguiente
    numIteraciones = 0; % contador de iteraciones para
    
    % iteraciones (se considerar� esfuerzos/deformaciones/fuerzas positivas para la compresi�n)
    while error > tolerancia % test de convergencia
        % si no es posible lograr el equilibrio de fuerzas (secci�n colaps�??), finalizar el an�lisis
        if J == 0 || numIteraciones > 10, return, end
        
        % correcci�n de las deformaciones unitarias
        deo = J^-1*dp;
        eo = eo+deo; % deformaci�n unitaria en h/2
        e = eo+phi(i)*(y-h/2);
        es = eo+phi(i)*[h/2-d1,h/2-d2];
        
        % c�lculo de tensiones, rigideces tangentes y fuerzas en el acero inferior y superior (que se consideran puntuales)
        [fs,Es] = curvaAcero(es,parametros);
        Fs = fs.*[As1,As2];
        
        % c�lculo de tensiones, rigideces tangentes, fuerzas y brazos de palanca en cada segmento de hormig�n
        [fc,Ec] = curvaHormigon(e,parametros);
        for k = 1:n
            Fc(k) = 0.5*(fc(k)+fc(k+1))*b*dy; % se usa un punto de integraci�n --> �rea del trapecio en el perfil de tensiones
            if Fc(k) ~= 0, yc(k) = y(k)+dy/3*(fc(k)+2*fc(k+1))/(fc(k)+fc(k+1)); end % yc(k)=0.5*(y(k)+y(k+1));
        end
        
        % c�lculo del error en la sumatoria de fuerzas
        dp = Pext-(sum(Fc)+sum(Fs));
        error = abs(dp);
        
        % actualizar rigidez J para nueva iteraci�n
        J = sum(Ec)*b*dy+sum(Es.*[As1,As2]);
        numIteraciones = numIteraciones+1;
    end

    % resultados para la curvatura phi(i)
    M(i) = (sum(Fc.*yc)+sum(Fs.*[h-d1,h-d2])-Pext*h/2)*10^-6;
    ec(i) = eo+phi(i)*(ymax-h/2);
    c(i) = ec(i)/abs(phi(i));
end

end

% funci�n que calcula el esfuerzo y rigidez tangente en el acero
% dependiendo de la deformaci�n unitaria y la ley constitutiva del material
function [fs,Es] = curvaAcero(es,parametros)

% par�metros de la curva tensi�n-deformaci�n del acero de refuerzo
opcionAcero = parametros.modeloAcero; % tipo de curva
Es1 = 200000; % m�dulo de elasticidad inicial del acero (en MPa)
fy = parametros.fy; % tensi�n de fluencia del acero (en MPa)
ey = fy/Es1; % deformaci�n unitaria de fluencia del acero

% inicializar variables
m = length(es);
fs = zeros(1,m); % tensiones en el acero
Es = zeros(1,m); % rigidez tangente o pendiente en la curva tensi�n-deformaci�n del acero

% calcular para cada capa de refuerzo (generalmente se simplifica considerando una capa inferior y otra superior)
if any(opcionAcero{1} == [1 3]) % modelo elastopl�stico o de Menegotto y Pinto    
    ef = parametros.ef; % m�xima deformaci�n unitaria permitida
    Es2 = 0; % m�dulo de elasticidad despu�s tramo lineal-el�stico del acero (en MPa)
    if opcionAcero{1} == 3, Es2 = Es1*parametros.E1; end % si el modelo no es elasto-pl�stico perfecto, Es2>0
    
    for i = 1:m
        if abs(es(i)) <= ey
            fs(i) = Es1*es(i);
            Es(i) = Es1;
        elseif abs(es(i)) <= ef
            fs(i) = sign(es(i))*(fy+Es2*(abs(es(i))-ey));
            Es(i) = Es2;
        else
            fs(i) = 0;
            Es(i) = 0;
        end
    end
else%if opcionAcero{1} == 2 % modelo de Mander
    esh = parametros.esh; % deformaci�n para la cual inicia el endurecimiento del acero
    esu = parametros.esu; % deformaci�n unitaria para la cual se genera la m�xima tensi�n
    ef = parametros.ef; % m�xima deformaci�n unitaria permitida en el acero
    Esh = Es1*parametros.Esh;  % pendiente inicial post-fluencia del acero (en MPa) 
    fsu = fy*parametros.fsu; % m�ximo esfuerzo que puede alcanzar el acero (en MPa)
    p = Esh*(esu-esh)/(fsu-fy); % par�metro que define la curva post-fluencia

    for i = 1:m
        if abs(es(i)) <= ey
            fs(i) = Es1*es(i);
            Es(i) = Es1;
        elseif abs(es(i)) <= esh
            fs(i) = sign(es(i))*fy;
            Es(i) = 0;
        elseif abs(es(i)) <= ef
            fs(i) = sign(es(i))*(fsu+(fy-fsu)*abs((esu-abs(es(i)))/(esu-esh))^p);
            Es(i) = p*(fsu-fy)*abs(esu-abs(es(i)))^(p-1)/(esu-esh)^p;
        else
            fs(i) = 0;
            Es(i) = 0;
        end
    end
end
end

% funci�n que calcula el esfuerzo y rigidez tangente en el hormig�n
% dependiendo de la deformaci�n unitaria y la ley constitutiva del material
function [fc,Ec] = curvaHormigon(e,parametros)

% par�metros de la curva esfuerzo-deformaci�n del hormig�n
opcionHormigon = parametros.modeloHormigon; % tipo de curva para la compresi�n
opcionHormigonTrac = parametros.modeloHormigonTrac; % tipo de curva para la tracci�n
fcc = parametros.fc; % f'c
e0 = parametros.e0; % deformaci�n unitaria para la cual se genera el m�ximo esfuerzo
ef = parametros.ef; % m�xima deformaci�n unitaria permitida en el hormig�n

% inicializar variables
n = length(e); % n�mero de segmentos en que se divide la secci�n
fc = zeros(1,n); % tensiones en el hormig�n
Ec = zeros(1,n); % rigidez tangente o pendiente en la curva esfuerzo-deformaci�n del hormig�n

% calcular para cada segmento de hormig�n
for i = 1:n
    if e(i) >= 0
        if opcionHormigon{1} == 1 % modelo de Saenz
            if e(i) <= 2*e0
                fc(i) = fcc*(2*e(i)/e0-(e(i)/e0)^2);
                Ec(i) = 2*(fcc/e0)*(1-e(i)/e0);
            else
                fc(i) = 0;
                Ec(i) = 0;
            end
        elseif opcionHormigon{1} == 2 % modelo de Hognestad
            if e(i) <= e0 % tramo parab�lico ascendente
                fc(i) = fcc*(2*e(i)/e0-(e(i)/e0)^2);
                Ec(i) = 2*(fcc/e0)*(1-e(i)/e0);
            elseif e(i) <= ef % tramo lineal descendente
                fc(i) = fcc*(1-0.15*(e(i)-e0)/(ef-e0));
                Ec(i) = -0.15*fcc/(ef-e0);
            else
                fc(i) = 0;
                Ec(i) = 0;
            end
        else
            k = 1;
            if opcionHormigon{1} == 3 % modelo de Thorenfeldt calibrado seg�n Collins y Porasz
                r = 0.8+fcc/17;
                if e(i) > e0, k = 0.67+fcc/62; end
            else%opcionHormigon{1} == 4 % modelo de Thorenfeldt calibrado seg�n Carreira y Kuang-Han
                r = 1.55+(fcc/32.4)^3;
            end
            fc(i) = fcc*r*(e(i)/e0)/(r-1+(e(i)/e0)^(r*k));
            Ec(i) = fcc*r/e0*(r-1+(1-r*k)*(e(i)/e0)^(r*k))/(r-1+(e(i)/e0)^(r*k))^2;
        end
    else
        if opcionHormigonTrac{1} == 1 % sin resistencia a tracci�n
            fc(i) = 0;
            Ec(i) = 0;
        else%if opcionHormigonTrac{1} == 2 % con resistencia lineal-el�stica hasta la rotura 
            if e(i) <= -parametros.ecr
                fc(i) = 0;
                Ec(i) = 0;
            else
                Ecc = fcc*parametros.fcr/parametros.ecr;
                fc(i) = Ecc*e(i);
                Ec(i) = Ecc;
            end
        end
    end
end
end
