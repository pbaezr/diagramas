function varargout = materiales(varargin)
% MATERIALES es una interfaz de usuario que permite elegir y modificar las
% leyes constitutivas para el esfuerzo axial en el acero y el hormigón.

% Licenciado bajos los términos del MIT.
% Copyright (c) 2019 Pablo Baez R.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @materiales_OpeningFcn, ...
                   'gui_OutputFcn',  @materiales_OutputFcn, ...
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

function materiales_OpeningFcn(hObject, ~, handles, varargin)
% definir tabs para el acero y el hormigón
handles.tabgp = uitabgroup(hObject,'units','pixels','position',[0 47 558 390]);
tab1 = uitab(handles.tabgp,'title','Acero');
tab2 = uitab(handles.tabgp,'title','Hormigón');
set(handles.uipanel1,'parent',tab1,'units','normalized','position',[0 0 1 1])
set(handles.uipanel2,'parent',tab2,'units','normalized','position',[0 0 1 1])

% creación de labels
textos(1) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>sh</sub>'),[10 131 15 15],handles.uibuttongroup1);
textos(2) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>su</sub>'),[10 102 15 15],handles.uibuttongroup1);
textos(3) = javacomponent(javax.swing.JLabel('<html>&epsilon;<sub>f</sub>'),[10 73 15 15],handles.uibuttongroup1);
textos(4) = javacomponent(javax.swing.JLabel('<html>E<sub>sh</sub>'),[10 44 15 15],handles.uibuttongroup1);
textos(5) = javacomponent(javax.swing.JLabel('<html>f<sub>su</sub>'),[10 15 15 15],handles.uibuttongroup1);
textos(6) = javacomponent(javax.swing.JLabel('<html>&times; E<sub>s</sub>'),[89 44 30 15],handles.uibuttongroup1);
textos(7) = javacomponent(javax.swing.JLabel('<html>&times; f<sub>y</sub>'),[89 15 30 15],handles.uibuttongroup1);
textos(8) = javacomponent(javax.swing.JLabel('<html>&times; E<sub>s</sub>'),[89 102 30 15],handles.uibuttongroup1);

textos(9) = javacomponent(javax.swing.JLabel('<html>&epsilon<sub>0</sub>'),[10 44 15 15],handles.uibuttongroup2);
textos(10) = javacomponent(javax.swing.JLabel('<html>&epsilon<sub>u</sub>'),[10 15 15 15],handles.uibuttongroup2);

textos(11) = javacomponent(javax.swing.JLabel('<html>&epsilon<sub>cr</sub>'),[10 44 15 15],handles.uibuttongroup3);
textos(12) = javacomponent(javax.swing.JLabel('<html>f<sub>cr</sub>'),[10 15 15 15],handles.uibuttongroup3);
textos(13) = javacomponent(javax.swing.JLabel('<html>&times; f''<sub>c</sub>'),[89 15 30 15],handles.uibuttongroup3);

for i = 1:length(textos)
    if i ~= 9, textos(i).setVisible(false); end
    textos(i).setFont(java.awt.Font('segoe ui',0,11));
    handles.textos(i) = textos(i);
end

% mostrar los parámetros actuales de la curva esfuerzo-deformación del acero
if isempty(varargin) % parámetros por defecto
    parametros.modeloAcero = {1 'Elastoplástico'};
    parametros.ef = 0.2;
    parametros.fy = 420;
    parametros.modeloHormigon = {1 'Saenz'};
    parametros.fc = 30;
    parametros.e0 = 0.002;
    parametros.modeloHormigonTrac = {1 'sin tracción'};
else
    parametros = varargin{1};
end
modeloAcero = parametros.modeloAcero;
handles.fy = parametros.fy;
if modeloAcero{1} == 1 % modelo elastoplástico
    handles.radiobutton1.Value = 1;
elseif modeloAcero{1} == 2 % modelo de Mander
    handles.radiobutton2.Value = 1;
    handles.edit1.String = num2str(parametros.esh);
    handles.edit2.String = num2str(parametros.esu);
    handles.edit3.String = num2str(parametros.ef);
    handles.edit4.String = num2str(parametros.Esh);
    handles.edit5.String = num2str(parametros.fsu);
else%if modeloAcero{1} == 3 % modelo de Menegotto y Pinto
    handles.radiobutton3.Value = 1;
    handles.edit6.String = num2str(parametros.ef);
    handles.edit7.String = num2str(parametros.E1);
end

% mostrar los parámetros actuales de la curva esfuerzo-deformación del hormigón
modeloHormigon = parametros.modeloHormigon;
handles.fc = parametros.fc; % fc en MPa
if modeloHormigon{1} == 1 % modelo de Saenz
    handles.radiobutton4.Value = 1;
    handles.edit8.String = num2str(parametros.e0);
else
    if modeloHormigon{1} == 2 % modelo de Hognestad
        handles.radiobutton5.Value = 1;
    elseif modeloHormigon{1} == 3 % modelo de Thorenfeldt con constantes según Collins y Porasz
        handles.radiobutton6.Value = 1;
    else%if modeloHormigon{1} == 4 % modelo de Thorenfeldt con constantes según Carreira y Kuang-Han            
        handles.radiobutton7.Value = 1;
    end
    handles.edit8.String = num2str(parametros.e0);
    handles.edit9.String = num2str(parametros.eu);
end

modeloHormigonTrac = parametros.modeloHormigonTrac;
if modeloHormigonTrac{1} == 1 % sin resistencia a tracción
    handles.radiobutton8.Value = 1;
    handles.edit15.String = num2str(0.62/4700);
    handles.edit16.String = num2str(0.62*1/sqrt(parametros.fc));
else%if modeloHormigonTrac{1} == 1 % con resistencia lineal-elástica hasta la rotura
    handles.radiobutton9.Value = 1;
    handles.edit15.String = num2str(parametros.ecr); 
    handles.edit16.String = num2str(parametros.fcr);
end

% graficar las curvas según los parámetros predefinidos
uibuttongroup1_SelectionChangedFcn([],[],handles)
uibuttongroup2_SelectionChangedFcn([],[],handles)
uibuttongroup3_SelectionChangedFcn([],[],handles)

% inicializar variable que almacenará los parámetros elegidos
handles.parametros = [];

% Choose default command line output for materiales
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes materiales wait for user response (see UIRESUME)
uiwait(handles.figure1);

function varargout = materiales_OutputFcn(hObject, ~, handles)
varargout{1} = handles.parametros;
delete(hObject);

function edit1_Callback(hObject, ~, handles) %#ok<*DEFNU>
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit2_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit3_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit4_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit5_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit6_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit7_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaAcero(handles)

function edit8_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaHormigon(handles)

function edit9_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaHormigon(handles)

function edit15_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaHormigon(handles)

function edit16_Callback(hObject, ~, handles)
hObject.String = num2str(evalin('base',hObject.String));
graficarCurvaHormigon(handles)

% esta función se ejecuta cuando se selecciona una nueva ley constitutiva para el acero 
function uibuttongroup1_SelectionChangedFcn(~, ~, handles)
flags={'off' 'on'};
flag = get(handles.radiobutton2,'Value') == 1;
if flag
    set(handles.textos(1),'visible',true,'text','<html>&epsilon;<sub>sh</sub>')
    set(handles.textos(2),'visible',true,'text','<html>&epsilon;<sub>su</sub>')
else
    if get(handles.radiobutton3,'Value') == 1        
        set(handles.textos(1),'visible',true,'text','<html>&epsilon;<sub>f</sub>')
        set(handles.textos(2),'visible',true,'text','<html>E<sub>1</sub>')
    else%if get(handles.radiobutton1,'Value') == 1
        for i = 1:8, handles.textos(i).setVisible(false); end
        for i = 1:7, handles.(['edit',num2str(i)]).Visible = 'off'; end
        graficarCurvaAcero(handles)
        return
    end    
end

handles.textos(8).setVisible(~flag);
for i = 3:7, handles.textos(i).setVisible(flag); end
for i = 1:5, handles.(['edit',num2str(i)]).Visible = flags{flag+1}; end % solo para ahorrar código
for i = 6:7, handles.(['edit',num2str(i)]).Visible = flags{~flag+1}; end

graficarCurvaAcero(handles)

% función que se ejecuta cuando se selecciona una nueva ley constitutiva para el hormigón
function uibuttongroup2_SelectionChangedFcn(~, ~, handles)
flags={'off' 'on'};
flag = get(handles.radiobutton4,'Value') == 1;
handles.edit9.Visible = flags{~flag+1};
handles.textos(10).setVisible(~flag)
graficarCurvaHormigon(handles)

% función que se ejecuta cuando se considera o excluye la resistencia a tracción del hormigón
function uibuttongroup3_SelectionChangedFcn(~, ~, handles)
flags={'off' 'on'};
flag = get(handles.radiobutton8,'Value') == 1;
for i = 11:13, handles.textos(i).setVisible(~flag); end
for i = 15:16, handles.(['edit',num2str(i)]).Visible = flags{~flag+1}; end
graficarCurvaHormigon(handles)

% función que se ejecuta cuando el botón 'Aceptar' es presionado
function pushbutton1_Callback(hObject, ~, handles)

opcionAcero = handles.uibuttongroup1.SelectedObject.UserData;
opcionHormigon = handles.uibuttongroup2.SelectedObject.UserData;
opcionHormigonTrac = handles.uibuttongroup3.SelectedObject.UserData;

% definir los parámetros según el modelo utilizado
if opcionAcero == 1
    parametros.modeloAcero = {1 'Elastoplástico'};
    parametros.ef = 0.2; % se pone este límite solo para efectos prácticos
elseif opcionAcero == 2
    parametros.modeloAcero = {2 'Mander'};
    parametros.esh = str2double(handles.edit1.String);
    parametros.esu = str2double(handles.edit2.String);
    parametros.ef = str2double(handles.edit3.String);
    parametros.Esh = str2double(handles.edit4.String);
    parametros.fsu = str2double(handles.edit5.String);
else%if opcionAcero == 3
    parametros.modeloAcero = {3 'Menegotto'};
    parametros.ef = str2double(handles.edit6.String);
    parametros.E1 = str2double(handles.edit7.String);
end
parametros.fy = handles.fy;

if opcionHormigon == 1
    parametros.modeloHormigon = {1 'Saenz'};
    parametros.e0 = str2double(handles.edit8.String);
else    
    if opcionHormigon == 2
        parametros.modeloHormigon = {2 'Hognestad'};
    elseif opcionHormigon == 3
        parametros.modeloHormigon = {3 'Thorenfeldt 1'};
    else%if opcionHormigon == 4
        parametros.modeloHormigon = {4 'Thorenfeldt 2'};
    end
    parametros.e0 = str2double(handles.edit8.String);
    parametros.eu = str2double(handles.edit9.String);
end
parametros.fc = handles.fc;

if opcionHormigonTrac == 1
    parametros.modeloHormigonTrac = {1 'sin tracción'};    
else%if opcionHormigonTrac == 2
    parametros.modeloHormigonTrac = {2 'con tracción'};
    parametros.ecr = str2double(handles.edit15.String);
    parametros.fcr = str2double(handles.edit16.String);
end

% almacenar los nuevos parámetros definidos
handles.parametros = parametros;
guidata(hObject, handles);

close(handles.figure1);

% función que se ejecuta cuando el botón 'Cancelar' es presionado
function pushbutton2_Callback(hObject, ~, handles)
handles.parametros = [];
guidata(hObject, handles);
close(handles.figure1);

% función que grafica curva esfuerzo-deformación del acero según el modelo y los parámetros definidos
function graficarCurvaAcero(handles)
opcionAcero = handles.uibuttongroup1.SelectedObject.UserData;
ey = handles.fy/200000; % deformación unitaria de fluencia
axes(handles.axes1), cla

if opcionAcero == 1
    plot([0 ey 0.15],[0 1 1])
elseif opcionAcero == 2
    esh = str2double(handles.edit1.String);
    esu = str2double(handles.edit2.String);
    ef = str2double(handles.edit3.String);
    Esh = str2double(handles.edit4.String);    
    fsu = str2double(handles.edit5.String);
    p = Esh*(esu-esh)/(fsu-1)/ey;
    e = linspace(esh,ef);
    f = fsu+(1-fsu)*abs((esu-e)/(esu-esh)).^p;
    plot([0 ey e],[0 1 f])
else%eif opcionAcero == 3
    ef = str2double(handles.edit6.String);
    E1 = str2double(handles.edit7.String);
    plot([0 ey ef],[0 1 1+E1*(ef-ey)/ey])
    xlim([0 ef])
end

grid on
handles.axes1.FontSize = 8;
xlabel(handles.axes1,[char(949),'_s'])
ylabel(handles.axes1,'f_s / f_y')

% función que grafica curva esfuerzo-deformación del hormigón
function graficarCurvaHormigon(handles)
opcionHormigon = handles.uibuttongroup2.SelectedObject.UserData;
opcionHormigonTrac = handles.uibuttongroup3.SelectedObject.UserData;

axes(handles.axes2), cla

e0 = str2double(handles.edit8.String);
if opcionHormigon ~= 1    
    eu = str2double(handles.edit9.String);
    if opcionHormigon == 2
        e = linspace(0,e0);
    	f = 2*e/e0-(e/e0).^2;
    	plot([e e0 eu],[f 1 0.85])
    else
        fc = handles.fc;
        if opcionHormigon == 3
            r = 0.8+fc/17;
            k = [ones(1,50),(0.67+fc/62)*ones(1,50)];
        else%if opcionHormigon == 4
            r = 1.55+(fc/32.4)^3;
            k = 1;
        end
        e = [linspace(0,e0,50) linspace(e0,eu,50)];
        f = r*(e/e0)./(r-1+(e/e0).^(r*k));
        plot(e,f)
    end
else
    eu = 2*e0;
    e = linspace(0,eu);
    f = 2*(e/e0)-(e/e0).^2;
    plot(e,f)
end

if opcionHormigonTrac == 2
    ecr = str2double(handles.edit15.String);
    fcr = str2double(handles.edit16.String);
    hold on
    plot([-ecr 0],[-fcr 0],'color',[0 0.447 0.741])
    xlim([-ecr eu])
    ylim([-fcr 1])
else
    xlim([0 eu])
    ylim([0 1])
end

grid on
handles.axes2.FontSize = 8;
xlabel(handles.axes2,[char(949),'_c'])
ylabel(handles.axes2,'f_c / f ''_c')

function figure1_CloseRequestFcn(hObject, ~, ~)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end
