function [M,P,c,phi_red] = interaccionPM(b,h,d1,d2,As1,As2,fc,fy,varargin)
% INTERACCIONPM calcula el diagrama P-M para una sección rectangular de hormigón armado.
%
% Variables de salida:
%   -M: vector fila con los momentos asociados a cada carga axial (en kN*m)
%   -P: vector fila con las cargas axiales utilizadas (en kN)
%   -c: vector fila con la ubicación de los ejes neutros (en mm)
%   -phi_red: vector fila con los factores de reduccion de resistencia
%             calculados acorde la deformación axial del acero a tracción
%
% Variables de entrada:
%   -b: ancho de la sección rectangular (en mmm)
%   -h: altura de la sección rectangular (en mmm)
%   -d1: distancia del borde superior de la sección hasta el centroide del refuerzo As1 (en mmm)
%   -d2: distancia del borde superior de la sección hasta el centroide del refuerzo As2 (en mmm)
%   -As1: área total del refuerzo inferior asociado a d1 (en mmm^2)
%   -As2: área total del refuerzo supeior asociado a d2 (en mmm^2)
%   -fc: f'c, resistencia a compresión del hormigón según especificaciones del ACI318 (en MPa)
%   -fy: tensión de fluencia del acero (en MPa)
%   -varargin: valor que indica el sentido de la flexión, siendo igual a 1 ó -1
%              (fibra superior o inferior es la más comprimida, respectivamente)

% Licenciado bajos los términos del MIT.
% Copyright (c) 2019 Pablo Baez R.

% parámetros de los materiales
Es1 = 200000; % módulo de elasticidad inicial del acero (en MPa)
ey = fy/Es1; % deformación de fluencia del acero (0.0021 para fy=420)
eu = 0.003; % deformación máxima para la cual se estima la resistencia de la sección, según ACI-318
beta1 = max(0.65,min(0.85,0.85-0.008*(fc-30)));

% definición del rango de muestra para las cargas axiales
n = 500; % se se considera un total de 500 cargas axiales
Pmax = 0.85*fc*(b*h-As1-As2)+fy*(As1+As2);
Pmin = -fy*(As1+As2);
P = sort([linspace(Pmin,Pmax,n-1) 0.8*Pmax]); % vector de cargas axiales, en N    

% definir sentido de flexión
signo_curvatura = 1; % se considera por defecto que la fibra superior es la más comprimida (ó menos traccionada)
if ~isempty(varargin)
    signo_curvatura = varargin{1};
    if signo_curvatura == -1 % fibra inferior es la más comprimida (o menos traccionada)
        % invertir los parámetros geométricos de la sección
        d1_2 = h-d2;
        d2_2 = h-d1;
        As1_2 = As2;
        As2_2 = As1;

        d1 = d1_2;
        d2 = d2_2;
        As1 = As1_2;
        As2 = As2_2;
    end
end

% inicializar variables
M = zeros(1,n); % momentos resultantes para cada carga axial
et = zeros(1,n);% deformación en el acero a tracción
phi_red = zeros(1,n); % factor de reducción de resiatencia
c = zeros(1,n); % profundidad del eje neutro

% definir valores límites para la profundidad del eje neutro
clim1 = eu*d1/(eu+ey); % si c<=clim1 As1 está fluyendo (en tracción)
clim2 = eu*d2/(eu-ey); % si c>=clim2 As2 está fluyendo (en compresión)

% calcular la carga axial límite para la cual c > h/beta1 (altura del bloque equivalente de Whitman es igual a h)
fs1 = min(Es1*eu/h*(h-beta1*d1),fy);
fs2 = min(Es1*eu/h*(h-beta1*d2),fy);
Plim = 0.85*fc*(b*h-As1-As2)+As1*fs1+As2*fs2;

% calcular el momento asociado a P=Pmax (igual a 0 si la sección es armada simétricamente respecto a su eje medio horizontal)
Mo = -10^-6*signo_curvatura*fy*(As1*(d1-h/2)-As2*(h/2-d2));

for i = 1:n
    if P(i) <= Plim % la curvatura es tal que c <= h/beta1
		% calcular valores probables de c asumiendo a priori si las armaduras fluyen o no
        c1 = (P(i)+fy*(As1-As2))/(0.85*fc*b*beta1);
        c2 = (P(i)+Es1*(As1*ey-As2*eu)+((Es1*(As2*eu-As1*ey)-P(i))^2+3.4*beta1*fc*b*As2*Es1*eu*d2)^0.5)/(1.7*fc*b*beta1);
        c3 = (P(i)-Es1*(As1*eu+As2*ey)+((P(i)-Es1*(As1*eu+As2*ey))^2+3.4*beta1*fc*b*As1*Es1*eu*d1)^0.5)/(1.7*fc*b*beta1);
        c4 = (P(i)-eu*Es1*(As1+As2)+((P(i)-eu*Es1*(As1+As2))^2+3.4*beta1*fc*b*(As1*d1+As2*d2)*Es1*eu)^0.5)/(1.7*fc*b*beta1);
        
		% determinar cuál de los valores de c es consistente
        if c1 <= clim1 && c1 >= clim2 % ambas armaduras están fluyendo (As1 en tracción y As2 em compresión)
            c(i) = c1;        
            fs = fy*[1 1];        
        elseif c2 <= clim1 && c2 < clim2 && c2 > 0 % As1 fluye, pero As2 no
            c(i) = c2;
            fs = [fy, Es1*eu*(c(i)-d2)/c(i)];
        elseif c3 > clim1 && c3 >= clim2 % As1 no fluye, pero As2 si lo hace
            c(i) = c3;
            fs = [Es1*eu*(d1 - c(i))/c(i), fy];
        else % ninguna de las armaduras fluye
            c(i) = c4;
            fs = Es1*eu/c(i)*[d1 - c(i), c(i)-d2];
        end
		
		% determinar el factor de reducción de resistencia acorde la deformación axial del acero a tracción
        et(i) = eu*(d1 - c(i))/c(i);
        phi_red(i) = phiFactor(et(i),ey);
        
        % calcular el momento resultante
        M(i) = 10^-6*signo_curvatura*(0.85*fc*b*beta1*c(i)*(h-beta1*c(i))/2+As2*fs(2)*(h/2-d2)+As1*fs(1)*(d1-h/2));
        if P(i) == Pmin, M(i) = 10^-6*signo_curvatura*fy*(As1*(d1-h/2)-As2*(h/2-d2)); end % M=0 para secciones armadas simétricamente
    else % si la curvatura es tal que c > h/beta1      
        es = (P(i)-0.85*fc*(b*h-As1-As2)-As2*fy)/(As1*Es1); % se supone que As2 está fluyendo y As1 no
        c(i) = eu*d1/(eu-es);
        phi_red(i) = 0.65; % todas las fibras de la sección están comprimidas
        M(i) = Mo+(M(i-1)-Mo)*(P(i)-Pmax)/(P(i-1)-Pmax); % se interpola linealmente con el par (M(i-1),P(i-1)) y (Mo,Pmax)
%         M(i) = 10^-6*signo_curvatura*(As2*fy*(h/2-d2)-As1*min(Es1*es,fy)*(d1-h/2)); % solución teórica
    end
end

P = P/1000; % conversión de N a kN

end

% función que calcula el factor de reduccion de resistencia acorde a la deformación axial del acero a tracción
function phi = phiFactor(et,ey)
if et < ey % compresión controla
    phi = 0.65;
elseif et < 0.005 % zona de transición
    phi = 0.65+0.25*(et-ey)/(0.005-ey);
else%if et >= 0.005 % tracción controla
    phi = 0.9;
end
end
