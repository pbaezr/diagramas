function varargout = diagramas(varargin)
% DIAGRAMAS es una interfaz de usuario que permite calcular los diagramas
% de interacción P-M y de Momento-Curvatura de una sección rectangular de
% hormigón armado.

% Licenciado bajos los términos del MIT.
% Copyright (c) 2019 Pablo Baez R.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @diagramas_OpeningFcn, ...
                   'gui_OutputFcn',  @diagramas_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function diagramas_OpeningFcn(hObject, ~, handles, varargin)

path = pwd;
if isdeployed, path = fileparts(mfilename('fullpath')); end
addpath(fullfile(path,'lib'))

% definición de variable que indica si los datos ingresados son válidos
% (con lo que los diagramas pueden ser desplegados)
handles.datosValidos = false;
handles.armadurasSimetricas = false;

set(handles.uipanel4,'position',handles.uipanel3.Position,'title',['Resultados para ',char(981)])

% creación de labels (los "static texts" de Matlab no permiten el uso de html...)
textos(1) = javacomponent(javax.swing.JLabel('<html>d<sub>2</sub>'),[10 259 23 15],handles.uipanel1);
textos(2) = javacomponent(javax.swing.JLabel('<html>d<sub>1</sub>'),[10 230 23 15],handles.uipanel1);
textos(3) = javacomponent(javax.swing.JLabel('<html>A<sub>s2</sub>'),[10 201 23 15],handles.uipanel1);
textos(4) = javacomponent(javax.swing.JLabel('<html>A<sub>s1</sub>'),[10 172 23 15],handles.uipanel1);
textos(5) = javacomponent(javax.swing.JLabel('<html>f''<sub>c</sub>'),[10 143 23 15],handles.uipanel1);
textos(6) = javacomponent(javax.swing.JLabel('<html>f<sub>y</sub>'),[10 113 23 15],handles.uipanel1);

textos(7) = javacomponent(javax.swing.JLabel('<html>&#1013;'),[10 46 20 15],handles.uipanel2);
textos(7).setEnabled(false);
handles.textoError = textos(7);

textos(8) = javacomponent(javax.swing.JLabel('<html>&#981;'),[10 102 23 15],handles.uipanel3);
textos(9) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>s2</sub>'),[10 44 23 15],handles.uipanel3);
textos(10) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>s1</sub>'),[10 15 23 15],handles.uipanel3);

textos(11) = javacomponent(javax.swing.JLabel('<html>&#981;'),[10 162 23 15],handles.uipanel4);
textos(12) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>c</sub>'),[10 73 23 15],handles.uipanel4);
textos(13) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>s2</sub>'),[10 44 23 15],handles.uipanel4);
textos(14) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>s1</sub>'),[10 15 23 15],handles.uipanel4);

% estandarización de fuente (segoe ui de 11px)
for i = 1:length(textos), textos(i).setFont(java.awt.Font('segoe ui',0,11)); end

% creación y personalización de los outputs
outputs = {'phi_1','c_1','es2_1','es1_1','M_2','c_2','ec_2','es2_2','es1_2'};
parent = handles.uipanel3;
pos = [33 100 49 21];
tooltip = 'curvatura';
for i = 1:length(outputs)
    if i == 2 || i == 6
        tooltip='profundidad del eje neutro';
    elseif i == 3 || i == 8
        tooltip='<html>deformación unitaria del <br>acero a compresión';
    elseif i == 4 || i == 9
        tooltip='<html>deformación unitaria del <br>acero a tracción';
    elseif i == 5
        pos=[33 129 49 21];
        tooltip=[];
        parent=handles.uipanel4;
    elseif i == 7
        tooltip = 'deformación máxima en el hormigón';
    end
    handles.(outputs{i}) = javacomponent(javax.swing.JLabel(''),pos,parent);
    handles.(outputs{i}).setBackground(java.awt.Color(0.94,0.94,0.94));
    handles.(outputs{i}).setBorder(javax.swing.BorderFactory.createLineBorder(java.awt.Color(0.67,0.68,0.7),1));
    handles.(outputs{i}).setFont(java.awt.Font('Segoe ui',0,11));
    handles.(outputs{i}).setHorizontalAlignment(0)
    handles.(outputs{i}).setToolTipText(tooltip);
    pos = pos-[0 29 0 0];
end

% definición de parámetros iniciales para las curvas tensión-deformación de los materiales
% (aplicables solo para el diagrama M-phi, a excepción de f'c y fy)
parametros.modeloAcero = {1 'Elastoplástico'};
parametros.ef = 0.2;
parametros.fy = 420;
parametros.modeloHormigon = {1 'Saenz'};
parametros.fc = 30;
parametros.e0 = 0.002;
parametros.modeloHormigonTrac = {1 'sin tracción'};
handles.parametros = parametros;

% creación de figura explicativa de los inputs
axes(handles.axes2)
grid on, hold on, axis off, axis equal
plot([0 1.5 1.5 0 0],[0 0 2 2 0],'color','k','linewidth',1.5)
plot([0.375 1.125 1.125 0.375],[0.33 0.33 1.66 1.66],'o','markeredgecolor','k','markerfacecolor','k')

plot([-0.4 0],[0 0],'color',0.7*[1 1 1])
plot([-0.4 2.35],[2 2],'color',0.7*[1 1 1])
plot([1.2 2.35],[1.66 1.66],'color',0.7*[1 1 1])
plot([1.2 2.2],[0.33 0.33],'color',0.7*[1 1 1])

text(0.75,-0.5,'b','fontsize',7.5,'horizontalalignment','center')
text(-0.65,1.1,'h','fontsize',7.5)
text(2,1.1,'d_1','fontsize',7.5)
text(2.45,1.83,'d_2','fontsize',7.5)
text(0.75,0.33,'A_{s1}','fontsize',7.5,'horizontalalignment','center','verticalalignment','bottom')
text(0.75,1.66,'A_{s2}','fontsize',7.5,'horizontalalignment','center','verticalalignment','top')

annotation(handles.uipanel1,'doublearrow',[0.185 0.185],[0.07 0.25],'head1width',3,'head2width',3,'head1length',3,'head2length',3,'headstyle','vback3')
annotation(handles.uipanel1,'doublearrow',[0.7 0.7],[0.1 0.25],'head1width',3,'head2width',3,'head1length',3,'head2length',3,'headstyle','vback3')
annotation(handles.uipanel1,'doublearrow',[0.8 0.8],[0.22 0.25],'head1width',3,'head2width',3,'head1length',3,'head2length',3,'headstyle','vback3')
annotation(handles.uipanel1,'doublearrow',[0.24 0.64],[0.045 0.045],'head1width',3,'head2width',3,'head1length',3,'head2length',3,'headstyle','vback3')

% Choose default command line output for diagramas
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

function varargout = diagramas_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;

function input_b_Callback(hObject, ~, handles) %#ok<*DEFNU>
verificarInput(hObject,handles,10,@(x)x>0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo.')

function input_h_Callback(hObject, ~, handles)
verificarInput(hObject,handles,10,@(x)x>0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo.')

function input_d2_Callback(hObject, ~, handles)
verificarInput(hObject,handles,10,@(x)x>0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo.')

function input_d1_Callback(hObject, ~, handles)
verificarInput(hObject,handles,10,@(x)x>0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo.')

function input_As2_Callback(hObject, ~, handles)
verificarInput(hObject,handles,100,@(x)x>=0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo o cero.')

function input_As1_Callback(hObject, ~, handles)
verificarInput(hObject,handles,100,@(x)x>=0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo o cero.')

function input_n_Callback(hObject, ~, handles)
verificarInput(hObject,handles,1,@(x)rem(x,1) == 0 && x > 0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo o cero.')

function input_error_Callback(hObject, ~, handles)
verificarInput(hObject,handles,10,@(x)x>0,'El valor ingresado (directamente o mediante el uso de funciones) debe ser un real positivo.')

function input_P_Callback(hObject, ~, handles)
verificarInput(hObject,handles,10,@(x)isreal(x),'El valor ingresado (directamente o mediante el uso de funciones) debe ser un número real.')

function verificarInput(hObject,handles,factorConversion,condicion,mensajeError)
hObject.UserData = [];
try
    input = evalin('base',hObject.String);
    hObject.String = num2str(input);
    if feval(condicion,input)
        hObject.UserData = factorConversion*input;
        graficarDiagrama(handles) % recalcular el diagrama
    else
        axes(handles.axes1), cla 
        errordlg(mensajeError,'Error en el ingreso de datos','modal')
    end
catch
    axes(handles.axes1), cla    
    errordlg(mensajeError,'Error en el ingreso de datos','modal')
end

function input_fc_Callback(hObject, ~, handles)
fc = [16 20 25 30 35]; % valores de f'c en MPa más usuales (en Chile, por lo menos)
handles.parametros.fc = fc(hObject.Value); % el objeto es un popupmenu
graficarDiagrama(handles)

function input_fy_Callback(hObject, ~, handles)
fy = [280 420]; % valores de fy en MPa típicos para el acero utilizado en hormigón armado
handles.parametros.fy = fy(hObject.Value);
graficarDiagrama(handles)

function radiobutton1_KeyPressFcn(~, eventdata, handles)
if ~isempty(strfind(eventdata.Key,'arrow'))
    handles.radiobutton2.Value = 1;
    uibuttongroup1_SelectionChangedFcn([],[],handles)
end

function radiobutton2_KeyPressFcn(~, eventdata, handles)
if ~isempty(strfind(eventdata.Key,'arrow'))
    handles.radiobutton1.Value = 1;
    uibuttongroup1_SelectionChangedFcn([],[],handles)
end

function radiobutton3_KeyPressFcn(~, eventdata, handles)
if ~isempty(strfind(eventdata.Key,'arrow'))
    handles.radiobutton4.Value = 1;
    input_carga_Callback(handles.input_carga, [], handles)
end

function radiobutton4_KeyPressFcn(~, eventdata, handles)
if ~isempty(strfind(eventdata.Key,'arrow'))
    handles.radiobutton3.Value = 1;
    input_carga_Callback(handles.input_carga, [], handles)
end

function uibuttongroup1_SelectionChangedFcn(~, ~, handles)
% determinar la opción escogida (diagrama P-M o M-phi)
flag = handles.radiobutton1.Value == 1;

% mostrar, ocultar o inhabilitar objetos según la opción
flags={'off' 'on'};
handles.textoError.setEnabled(~flag);
handles.uipanel3.Visible = flags{flag+1};
handles.uipanel4.Visible = flags{~flag+1};
obj = {'pushbutton1' 'input_n' 'input_error' 'input_P' 'text16' 'text17' 'text33' 'text34' 'text48' 'text49'};
for i = 1:length(obj), handles.(obj{i}).Enable = flags{~flag+1}; end

graficarDiagrama(handles) % graficar el diagrama correspondiente

function uibuttongroup2_SelectionChangedFcn(~, ~, handles)
input_carga_Callback(handles.input_carga, [], handles)

function pushbutton1_Callback(hObject, ~, handles)
% definición de los prámetros de las curvas tensión-deformación de los materiales
parametros2 = materiales(handles.parametros); % si no hay modificación, parametros2 = []

if ~isempty(parametros2)
    handles.parametros = parametros2; % almacenar los nuevos parámetros      
    handles.text48.String = ['Acero: ',parametros2.modeloAcero{2}];
    handles.text49.String = ['Hormig: ',parametros2.modeloHormigon{2},', ',parametros2.modeloHormigonTrac{2}];
    guidata(hObject,handles);
    graficarDiagrama(handles) % recalcular el diagrama M - phi
end

function graficarDiagrama(handles)
handles.figure1.Pointer = 'watch';

% obtener valores de los inputs
b = handles.input_b.UserData; % ancho de la sección (en mm)
h = handles.input_h.UserData; % altura de la sección (en mm)
d2 = handles.input_d2.UserData; % ubicación de la armadura As2 (en mm)
d1 = handles.input_d1.UserData; % ubicación de la armadura As1 (en mm)
As2 = handles.input_As2.UserData; % área total de la armadura As2 (en mm^2)
As1 = handles.input_As1.UserData; % área total de la armadura As1 (en mm^2)

if ~isempty(b) && ~isempty(h) && ~isempty(d2) && ~isempty(d1) && ~isempty(As2) && ~isempty(As1)

    axes(handles.axes1), cla
    grid on, hold on
    
    % verificar la congruencia de los valores de d1 y d2
    if d2 > h || d1 > h || d2 > d1
        errordlg('Los valores de d1 y d2 no deben ser mayores que h, además de que d1 > d2.','Incongruencia en los datos','modal')
        handles.figure1.Pointer = 'arrow';
        handles.datosValidos = false;
        return
    end
    handles.datosValidos = true; % actualizar estatus
    handles.armadurasSimetricas = As1 == As2 && d2 == h-d1;

    if handles.radiobutton1.Value == 1 % diagrama P - M
        % obtención, conversión de unidades y almacenamiento de los resultados
        [M1,P,c1,phi1] = interaccionPM(b,h,d1,d2,As1,As2,handles.parametros.fc,handles.parametros.fy);
        M1 = 0.1*M1; % conversión de kN-m a tonf-m
        P = 0.1*P; % conversión de kN a tonf
        c1 = 0.1*c1; % conversión de mm a cm
        resultadosPM.M1 = M1;
        resultadosPM.P = P;
        resultadosPM.c1 = c1;
        
        % identificar el límite superior de compresión por concepto de la excentricidad accidental, que solo aplicaría a columnas y no a muros 
        [~,ind] = min(abs(P-0.8*P(end)));        
        
        % graficar curva Pn - Mn
        curvaNominal = plot(M1,P,'linewidth',1);            

        % graficar curva reducida por el factor phi
        curvaReducida = plot([phi1(1:ind).*M1(1:ind) 0],[phi1(1:ind).*P(1:ind) phi1(ind)*P(ind)],'color','r');
        plot(phi1(ind:end).*M1(ind:end),phi1(ind:end).*P(ind:end),'--','color','r')

        % graficar rama M < 0 si es necesario (sección armada de forma no simétrica)
        if ~handles.armadurasSimetricas            
            [M2,~,c2,phi2] = interaccionPM(b,h,d1,d2,As1,As2,handles.parametros.fc,handles.parametros.fy,-1);
            M2 = 0.1*M2;
            c2 = 0.1*c2;
            resultadosPM.M2 = M2;
            resultadosPM.c2 = c2;            
            
            plot(M2(end:-1:1),P(end:-1:1),'linewidth',1,'color',[0 0.447 0.741]);            
            plot([0 phi2(ind:-1:1).*M2(ind:-1:1)],[phi2(ind)*P(ind) phi2(ind:-1:1).*P(ind:-1:1)],'color','r');
            plot(phi2(end:-1:ind).*M2(end:-1:ind),phi2(end:-1:ind).*P(end:-1:ind),'--','color','r')                        
            plot([0 0],ylim,'color',[0.5 0.5 0.5]) % trazar recta para M = 0
        end
        
        plot(xlim,[0 0],'color',[0.5 0.5 0.5]) % trazar recta para P = 0

        leyenda = legend([curvaNominal curvaReducida],{'P_n - M_n','\phiP_n - \phiM_n'});
        set(leyenda,'fontsize',8,'location','northeast');

        xlabel('M [tonf\timesm]')
        ylabel('P [tonf]')

        handles.resultadosPM = resultadosPM;
    else%if handles.radiobutton2.Value == 1 % diagrama M - phi
        % obtener parámetros para el análisis seccional
        n = handles.input_n.UserData;
        tol = handles.input_error.UserData;
        P = handles.input_P.UserData;
        
        % verificar que estos parametros sean válidos
        if isempty(n) || isempty(tol) || isempty(P), return, end

        % obtención, conversión de unidades y almacenamiento de los resultados
        [M,phi,c] = momento_curvatura(b,h,d1,d2,As1,As2,P,handles.parametros,n,tol);
        M = 0.1*M;
        phi = 10*phi;
        c = 0.1*c;
        resultadosMphi.M1 = M;
        resultadosMphi.phi = phi;
        resultadosMphi.c1 = c;        
        
        legend off
        plot(phi,M,'linewidth',1)
        
        % mostrar punto donde ec=0.003
        [~,ind_eu] = min(abs(phi.*c-0.003)); % 
        plot(phi(ind_eu),M(ind_eu),'o','markerfacecolor','r','markeredgecolor','b')
        
        % si la sección no está armada simétricamente, incluir la rama con phi<0
        if ~handles.armadurasSimetricas
            [M2,phi2,c2] = momento_curvatura(b,h,d1,d2,As1,As2,P,handles.parametros,n,tol,-1);
            
            M2 = 0.1*M2;
            phi2 = 10*phi2;
            c2 = 0.1*c2;
            resultadosMphi.M2 = M2;
            resultadosMphi.phi2 = phi2;
            resultadosMphi.c2 = c2;

            plot(phi2,M2,'linewidth',1,'color',[0 0.4470 0.7410]);            
            
            [~,ind_eu] = min(abs(-phi2.*c2-0.003)); % 
            plot(phi2(ind_eu),M2(ind_eu),'o','markerfacecolor','r','markeredgecolor','b')
            
            plot(xlim,[0 0],[0 0],ylim,'color',[0.5 0.5 0.5])
        end
            
        xlabel('\phi [1/cm]')
        ylabel('M [tonf\timesm]')
        
        handles.resultadosMphi = resultadosMphi;
    end
else
    handles.datosValidos = false;
end

handles.figure1.Pointer = 'arrow';
guidata(handles.figure1,handles)


function input_carga_Callback(hObject, ~, handles)
% incialización de outputs dependientes de la carga axial especificada
phi = [];
c = [];
es1 = [];
es2 = [];

try
    % obtener la carga axial
    P = evalin('base',hObject.String);
    
    if isreal(P)
        % actualizar el "static text"
        hObject.String = num2str(P);
        
        % obtener variables y reconvertirlas a centímetros
        h = 0.1*handles.input_h.UserData;
        dd = 0.1*handles.input_d2.UserData;
        d = 0.1*handles.input_d1.UserData;

        if handles.datosValidos            
            % obtener resultados (valores de P, M y phi) 
            resultados = handles.resultadosPM;
            eu = 0.003; % deformación unitaria de compresión en el estado límite último
            
            % calcular c, phi, es1 y es2 para la carga axial especificada
            c = interp1(resultados.P,resultados.c1,P); % se interpola con la curva Pn-Mn
            if handles.radiobutton3.Value == 1 % phi > 0
                phi = eu/c;
                es1 = -eu*(d-c)/c;
                es2 = eu*(c-dd)/c;
            else%if handles.radiobutton4.Value == 1 % phi < 0
                if ~handles.armadurasSimetricas
                    c = interp1(resultados.P,resultados.c2,P);
                end
                phi = -eu/c;
                es1 = eu*(c-(h-d))/c;
                es2 = -eu*(h-c-dd)/c;
            end
        end
    else
        errordlg('El valor ingresado (directamente o mediante el uso de funciones) debe ser un número real.','Error en el ingreso de datos','modal')
    end
catch
    errordlg('El valor ingresado (directamente o mediante el uso de funciones) debe ser un número real.','Error en el ingreso de datos','modal')
end    

% actualización de outputs (objetos Java de tipo JLabels)
handles.phi_1.setText(num2str(phi,'%0.2g'))
handles.c_1.setText(num2str(c,'%.2f'));
handles.es1_1.setText(num2str(es1,'%.5f'));
handles.es2_1.setText(num2str(es2,'%.5f'));


function input_phi_Callback(hObject, ~, handles)
% incialización de outputs dependientes de phi
M = []; % momento
c = []; % profundidad del eje neutro
ec = []; % deformación unitaria de la fibra más comprimida
es1 = []; % deformación unitaria del acero As1
es2 = []; % deformación unitaria del acero As2

axes(handles.axes1)
delete(findobj(gca,'type','line','tag','punto'))

try
    % obtener phi
    phi = evalin('base',hObject.String);    

    if isreal(phi)
        % actualizar el "static text"
        hObject.String = num2str(phi);
        
        if handles.datosValidos            
            % obtener resultados (valores de M, phi y c)
            resultados = handles.resultadosMphi;
            
            % obtener variables y reconvertirlas a centímetros
            h = 0.1*handles.input_h.UserData;
            d2 = 0.1*handles.input_d2.UserData;
            d1 = 0.1*handles.input_d1.UserData;            
            
            % calcular c, M, ec, es1 y es2 para la curvatura especificada
            if handles.armadurasSimetricas || phi >= 0
                phi = abs(phi);
                c = interp1(resultados.phi,resultados.c1,phi);
                M = interp1(resultados.phi,resultados.M1,phi);
                ec = c*phi;
                es1 = -ec*(d1-c)/c;
                es2 = ec*(c-d2)/c;
            else
                c = interp1(resultados.phi2,resultados.c2,phi);
                M = interp1(resultados.phi2,resultados.M2,phi);
                ec = -c*phi;
                es1 = ec*(c-(h-d1))/c;
                es2 = -ec*(h-c-d2)/c;
            end
            
            % graficar el par (phi,M) en el diagrama
            hold on
            plot(phi,M,'o','markerfacecolor',[0 0.4470 0.7410],'markeredgecolor','b','tag','punto')
        end
    else
        errordlg('El valor ingresado (directamente o mediante el uso de funciones) debe ser un número real.','Error en el ingreso de datos','modal')
    end
catch
    errordlg('El valor ingresado (directamente o mediante el uso de funciones) debe ser un número real.','Error en el ingreso de datos','modal')
end

% actualización de outputs (objetos Java de tipo JLabels)
handles.M_2.setText(num2str(M,'%.2f'));
handles.c_2.setText(num2str(c,'%.2f'));
handles.ec_2.setText(num2str(ec,'%.5f'));
handles.es1_2.setText(num2str(es1,'%.5f'));
handles.es2_2.setText(num2str(es2,'%.5f'));
