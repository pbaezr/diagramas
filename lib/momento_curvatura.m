function [M,phi,c] = momento_curvatura(b,h,d1,d2,As1,As2,Pext,parametros,n,tolerancia,varargin)
% MOMENTO_CURVATURA calcula el diagrama M-phi para una seccion rectangular de hormigon armado.
%
% Variables de salida: 
%   -M: vector fila con los momentos asociados a cada curvatura (en kN*m)
%   -phi: vector fila con las curvaturas utilizadas (en 1/mm)
%   -c: vector fila con la ubicacion de los ejes neutros (en mm)
%
% Variables de entrada:
%   -b: ancho de la seccion rectangular (en mmm)
%   -h: altura de la seccion rectangular (en mmm)
%   -d1: distancia del borde superior de la seccion hasta el centroide del refuerzo As1 (en mmm)
%   -d2: distancia del borde superior de la seccion hasta el centroide del refuerzo As2 (en mmm)
%   -As1: area total del refuerzo inferior asociado a d1 (en mmm^2)
%   -As2: area total del refuerzo supeior asociado a d2 (en mmm^2)
%   -Pext: carga axial resultante en la seccion, considerada positiva si es de compresion (en kN)
%   -parametros: estructura que contiene los parametros que definen las leyes constitutivas de los materiales
%   -n: numero de segmentos en que se dividira la seccion (debe ser un entero positivo)
%   -tolerancia: error permitido en la sumatoria de fuerzas (en kN)
%   -varargin: valor que indica el sentido de la flexion, siendo igual a 1 o -1
%              (fibra superior o inferior es la mas comprimida, respectivamente)

% Licenciado bajos los terminos del MIT.
% Copyright (c) 2019 Pablo Baez R.

% conversion de kN a N
Pext = 1000*Pext;
tolerancia = 1000*tolerancia;

% parametros de los materiales
Es1 = 200000; % modulo de elasticidad inicial del acero (en MPa)
fy = parametros.fy; % tension de fluencia del acero (en MPa)
fcc = parametros.fc; % f'c del hormigon (en MPa)
Ecc = 4700*sqrt(fcc); % modulo de elasticidad del hormigon (en MPa)
beta1 = max(0.65,min(0.85,0.85-0.008*(fcc-30)));
eu = 0.003; % deformacion maxima a compresion del hormigon en el estado limite ultimo, segun ACI 318

% discretizacion elegida para el analisis seccional
dy = h/n; % altura de segmento
y = dy/2:dy:h-dy/2; % distancia a cada segmento (a sus centros) medida desde el borde inferior de la seccion

% definicion del rango de muestra para las curvaturas
nphi = 500; % se se considera un total de 500 curvaturas
signo_curvatura = 1; % se considera por defecto que la fibra superior es la mas comprimida (o menos traccionada)
ymax = h; % ubicacion, medida desde el borde inferior, de la fibra mas coprimida (por defecto, para phi>0, ymax=h)
if ~isempty(varargin)    
    signo_curvatura = varargin{1};
    if signo_curvatura == -1, ymax = 0; end % fibra inferior es la mas comprimida (o menos traccionada)
end
% se considera un phi maximo de 2 veces la curvatura teorica para la cual se alcanza una deformacion maxima de ec=eu=0.003
cu1 = (Pext+As1*fy-Es1*As2*eu+((Es1*As2*eu-As1*fy-Pext)^2+3.4*beta1*fcc*b*As2*Es1*eu*d2)^0.5)/(1.7*fcc*b*beta1);
cu2 = (Pext+As2*fy-Es1*As1*eu+((Es1*As1*eu-As2*fy-Pext)^2+3.4*beta1*fcc*b*As1*Es1*eu*(h-d1))^0.5)/(1.7*fcc*b*beta1);
cu = max(cu1,cu2);
phif = 2*signo_curvatura*eu/cu;
phi = linspace(0,phif,nphi);
dphi = phif/(nphi-1);

% inicializar variables
M = zeros(1,nphi); % momentos resultantes para cada curvatura
c = zeros(1,nphi); % profundidad del eje neutro para cada curvatura
ec = zeros(1,nphi); % deformacion unitaria maxima de compresion para cada curvatura
indSaltoPhi = zeros(1,nphi); % indices de las curvaturas excluidas

% inicializar los parametros de la iteracion
dp = 0; % error inicial considerado
eo = 0; % deformacion unitaria inicial considerada (en h/2)
J = Ecc*b*h+Es1*(As1+As2); % rigidez inicial considerada
c(1) = Inf; % phi = 0 ---> c = inf
i = 2; % las iteraciones inician para phi > 0
k = 1; % contador de curvaturas en que no hubo convergencia

% iteraciones para cada curvatura
while i <= nphi || ec(end) < 0.008
    % agregar nueva curvatura si es que se supero el limite predefinido sin
    % alcanzar la deformacion maxima del hormigon no confinado (ec = 0.008)
    if i > nphi
        nphi = nphi+1;
        phi(i) = phi(i-1)+dphi;
    end
    
    error = tolerancia+1; % para entrar en un nuevo ciclo de iteraciones para la curvatura siguiente
    numIteraciones = 0; % contador de iteraciones para la curvatura phi(i)
    
    % iteraciones (se considerara esfuerzos/deformaciones/fuerzas positivas para la compresion)
    while error > tolerancia % test de convergencia
        numIteraciones = numIteraciones+1;        
        
        % correccion de las deformaciones unitarias
        deo = J^-1*dp;
        eo = eo+deo; % deformacion unitaria en h/2
        e = eo+phi(i)*(y-h/2);
        es = eo+phi(i)*[h/2-d1,h/2-d2];
        
        % calculo de tensiones, rigideces tangentes y fuerzas en el acero inferior y superior (que se consideran puntuales)
        [fs,Es] = curvaAcero(es,parametros);
        Fs = fs.*[As1,As2];
        
        % calculo de tensiones, rigideces tangentes y fuerzas en cada segmento de hormigon
        [fc,Ec] = curvaHormigon(e,parametros);
        Fc = fc*b*dy;
        
        % calculo de tensiones del hormigon en las zonas donde esta distribuida la armadura
        % (para cuantias de acero chicas este calculo es poco relevante)
        fc_As = curvaHormigon(es,parametros);
        Fc_ficticia = fc_As.*[As1,As2]; % estas fuerzas son descontadas para obtener la contribucion real del hormigon
        
        % calculo del error en la sumatoria de fuerzas
        dp = Pext-(sum(Fs)+sum(Fc)-sum(Fc_ficticia));
        error = abs(dp);
        
        % actualizar rigidez J para nueva iteracion
        if numIteraciones < 11
            J = sum(Ec)*b*dy+sum(Es.*[As1,As2]);
        else % si hay divergencia, descartar phi
            indSaltoPhi(k) = i;
            k = k+1;
            break
        end
    end
    
    % terminar analisis si el elemento colapso
    if J == 0
        nphi = i-1;
        break
    end

    % almacenar los resultados asociados a la curvatura phi(i)
    M(i) = (sum(Fs.*[h-d1,h-d2])+sum(Fc.*y)-sum(Fc_ficticia.*[h-d1,h-d2])-Pext*h/2)*10^-6;
    ec(i) = eo+phi(i)*(ymax-h/2);
    c(i) = ec(i)/abs(phi(i));
    i = i+1;
end

% redimensionar los resultados excluyendo los datos en que no hubo convergencia
ind = ~ismember(1:nphi,indSaltoPhi);
phi = phi(ind);
M = M(ind);
c = c(ind);
ec = ec(ind); %#ok<*NASGU>

end

% funcion que calcula el esfuerzo y rigidez tangente en el acero
% dependiendo de la deformacion unitaria y la ley constitutiva del material
function [fs,Es] = curvaAcero(es,parametros)

% parametros de la curva tension-deformacion del acero de refuerzo
opcionAcero = parametros.modeloAcero; % tipo de curva
Es1 = 200000; % modulo de elasticidad inicial del acero (en MPa)
fy = parametros.fy; % tension de fluencia del acero (en MPa)
ey = fy/Es1; % deformacion unitaria de fluencia del acero

% inicializar variables
m = length(es);
fs = zeros(1,m); % tensiones en el acero
Es = zeros(1,m); % modulo de elasticidad tangente del acero (derivada de la funcion fs)

% calcular para cada capa de refuerzo (generalmente se simplifica considerando una capa inferior y otra superior)
if opcionAcero{1} == 1 % modelo elastoplastico
    ef = parametros.ef; % maxima deformacion unitaria permitida
    Es2 = Es1*parametros.Es2; % modulo de elasticidad despues del tramo lineal-elastico del acero (en MPa)    
    
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
    esh = parametros.esh; % deformacion para la cual inicia el endurecimiento del acero
    esu = parametros.esu; % deformacion unitaria para la cual se genera la maxima tension
    ef = parametros.ef; % maxima deformacion unitaria permitida en el acero
    Esh = Es1*parametros.Esh;  % pendiente inicial post-fluencia del acero (en MPa) 
    fsu = fy*parametros.fsu; % maximo esfuerzo que puede alcanzar el acero (en MPa)
    p = Esh*(esu-esh)/(fsu-fy); % parametro que define la curva post-fluencia

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

% funcion que calcula el esfuerzo y rigidez tangente en el hormigon
% dependiendo de la deformacion unitaria y la ley constitutiva del material
function [fc,Ec] = curvaHormigon(e,parametros)

% parametros de la curva esfuerzo-deformacion del hormigon
opcionHormigon = parametros.modeloHormigon; % tipo de curva para la compresion
opcionHormigonTrac = parametros.modeloHormigonTrac; % tipo de curva para la traccion
fcc = parametros.fc; % f'c
e0 = parametros.e0; % deformacion unitaria para la cual se genera el maximo esfuerzo
ef = parametros.ef; % maxima deformacion unitaria permitida en el hormigon

% inicializar variables
n = length(e); % numero de segmentos en que se divide la seccion
fc = zeros(1,n); % tensiones en el hormigon
Ec = zeros(1,n); % modulo de elasticidad tangente del hormigon (derivada de la funcion fc)

% calcular para cada segmento de hormigon
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
            if e(i) <= e0 % tramo parabolico ascendente
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
            if opcionHormigon{1} == 3 % modelo de Thorenfeldt calibrado segun Collins y Porasz
                r = 0.8+fcc/17;
                if e(i) > e0, k = 0.67+fcc/62; end
            else%if opcionHormigon{1} == 4 % modelo de Thorenfeldt calibrado segun Carreira y Kuang-Han
                r = 1.55+(fcc/32.4)^3;
            end
            fc(i) = fcc*r*(e(i)/e0)/(r-1+(e(i)/e0)^(r*k));
            Ec(i) = fcc*r/e0*(r-1+(1-r*k)*(e(i)/e0)^(r*k))/(r-1+(e(i)/e0)^(r*k))^2;
        end
    else
        if opcionHormigonTrac{1} == 1 % sin resistencia a traccion
            fc(i) = 0;
            Ec(i) = 0;
        else%if opcionHormigonTrac{1} == 2 % con resistencia lineal-elastica hasta la rotura 
            if e(i) <= -0.62/4700
                fc(i) = 0;
                Ec(i) = 0;
            else
                Ecc = 4700*sqrt(fcc);
                fc(i) = Ecc*e(i);
                Ec(i) = Ecc;
            end
        end
    end
end
end
