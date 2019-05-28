function graficarDiagrama(handles)
% Esta función grafica el diagrama PM o M-phi, según corresponda.

% Licenciado bajos los términos del MIT.
% Copyright (c) 2019 Pablo Baez R.

handles.figure1.Pointer = 'watch';

% obtener valores de los inputs
b = handles.input_b.UserData; % ancho de la sección (en mm)
h = handles.input_h.UserData; % altura de la sección (en mm)
d2 = handles.input_d2.UserData; % ubicación de la armadura As2 (en mm)
d1 = handles.input_d1.UserData; % ubicación de la armadura As1 (en mm)
As2 = handles.input_As2.UserData; % área total de la armadura As2 (en mm^2)
As1 = handles.input_As1.UserData; % área total de la armadura As1 (en mm^2)
parametros = getappdata(handles.figure1,'parametrosMateriales');
fc = parametros.fc;
fy = parametros.fy;

if ~isempty(b) && ~isempty(h) && ~isempty(d2) && ~isempty(d1) && ~isempty(As2) && ~isempty(As1)

    axes(handles.axes1), cla
    grid on, hold on
    set(handles.axes1,'xlimmode','auto','ylimmode','auto')
    
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
        [M1,P,c1,phi1] = interaccionPM(b,h,d1,d2,As1,As2,fc,fy);
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
            [M2,~,c2,phi2] = interaccionPM(b,h,d1,d2,As1,As2,fc,fy,-1);
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
        [M,phi,c] = momento_curvatura(b,h,d1,d2,As1,As2,P,parametros,n,tol);
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
            [M2,phi2,c2] = momento_curvatura(b,h,d1,d2,As1,As2,P,parametros,n,tol,-1);
            
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