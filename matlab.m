% Montecarlo para NIVELES DE INCERTIDUMBRE para ubicación de electrolineras
% ------- --- Defininir y elegir el area de análisis ----
% ----------- Definir el número de iteraaciones para Montecarlo ---
% ----------- Definir las incertidumbres --------
%                   *** 1. Cuantos EV son en la carretera del area
%                   seleccionada (10% considerados)
%                   *** 2. Cuantos EV necesitan ser cargados del total d ev
%                   *** 3. Que marca de EV necesitan cargar 
%                   *** 4. Que cantidad de batería tienen cada modelo 
%                   *** 5. Que electrolinera utiliza para la recarga 
%                   
% ------------ELECCIÓN DE LAS ZONAS DE CIUDAD Y NUMERO PARA MONTECARLO POR
% ------------CONSOLA 
%ANALISIS FUNDAMENTAL NUMERO 1%
disp("ÁREAS DE ANÁLISIS EN UNA CIUDAD")
disp("1.Centro ")
disp("2.Periferia ")
areaCiudad=input("Eliga la zona de la ciudad en la cual será implementada la electrolinera: ");
numMonteCarlo=input("Indique el número de iteracciones para el Montecarlo: ");
%% 
%variables iniciales 
%Marcas de los vehículos eléctricos con sus respectivas caracteristicas  
global infoDeVe
infoDeVe=["Nissan" "Renault" "Toyota" "BYD";112 65 69 300;24 22 20 20];% kW ...........corregir caracteristicas de potencia del ev

global tablaDeIncertidumbre;


%Selección del area de análisis (el programa)
if areaCiudad==1 
    numCallesAnalizar = input('Ingrese numero de calles a analizar: ');
    w=funExcelHistorico("HistoricoCentro.xlsx", numCallesAnalizar, numMonteCarlo);
 elseif areaCiudad==2
    numKmAnalizar = input('Ingrese numero de kilometros a analizar: ');
    w=funExcelHistorico("HistoricoPeriferia.xlsx", numKmAnalizar, numMonteCarlo);
    
end
 
%%
%FUNCIONES PARA LOS DIFERENTES NIVELES DE INCERTIDUMBRE
%
%llamar al Excel y analizar los datos de entrada para las diferentes areas
%de la ciudad 
function dataHistorico = funExcelHistorico(nombreArchivo, numTotalCalles, numMonteCarlo)
    
    for contaCalles = 1:1:numTotalCalles
        
        TablaHistorico = readtable( nombreArchivo, 'sheet', strcat('opcion', num2str(contaCalles)) )
        
        funMonteCarlo(numMonteCarlo, TablaHistorico);
    end
    dataHistorico = 1;
end

%%
%Función para elegir la marca del EV y la cantidad que necesitan ser
%cargados, fun principal 
function m= funMonteCarlo(numMonteCarlo, TablaHistorico)
    
    %global nodos; global carga; global tr;
    %Llamar a la función que analizo las calles candidatas en una determinada
    %zona de la ciudad
    
    [a b] = size(TablaHistorico);
   %Numero de veces que se aplica montecarlo para cada calle o km
    for iterMonte=1:1:numMonteCarlo
        disp("-------------------------------------------------------------------")
            disp(strcat("MonteCarlo iteracion "," ", int2str(iterMonte)));
            disp("-------------------------------------------------------------------")
        % Este for va analizando los datos por cada hora con sus repectivo
        % flujo vehicular e incertidumbres 
        celdaExcel = 1;
        for contaHorario=1:1:a
            horaAnalisis = datestr(TablaHistorico.Hora(contaHorario),'HH:MM AM');
            flujo = TablaHistorico.Flujo(contaHorario);
            numEv = round(flujo * 0.10);
            %Cuantos vehiculos electricos necesitan ser cargados, para lo cual obtiene aleatorio de 0 a numEv
            incerNeedCharger = randi([0 numEv]);
            disp("-------------------------------------------------------------------")
            disp(strcat("Analisis de la calle: ", TablaHistorico.Calle(contaHorario), "a las ", horaAnalisis))
            disp(strcat("Existen un total de ",num2str(numEv)," de vehiculos electricos" ))
            disp(strcat("Necesitan ser cargados ",num2str(incerNeedCharger)," del total"))
            disp("-------------------------------------------------------------------")
             
            
            varNames = {'Escenarios','Calle','Hora','Marca','Potencia Vehiculo','Capacidad Bateria','Incertidumbre Bateria','Faltante Bateria'};
            sizetable = [incerNeedCharger length(varNames)];
            varTypes = {'double','string','string','string','double','double','double','double'};
            matrizVehiculo = funTable(sizetable,varTypes,varNames);
            
            
            for  iteracion=1:1:incerNeedCharger             
                % Obtiene la incertidumbre de cuantos vehiculos necesitan
                % ser cargados en la electrolinera de carga rapida
                matrizVehiculo(iteracion,:) = funMarca(iteracion, horaAnalisis ,TablaHistorico.Calle(contaHorario));   
                
            end
            matrizVehiculo
            filename = strcat("IncertidumbreCalle",TablaHistorico.Calle(contaHorario),".xlsx");
            sheetname = strcat("MonteCarlo"," ", int2str(iterMonte));
               
            if(celdaExcel == 1)            
               writetable(matrizVehiculo,filename,'Sheet',sheetname);
               celdaExcel = 2;
            else
                celda = strcat('A',int2str(celdaExcel));
               writetable(matrizVehiculo,filename,'Sheet',sheetname,'Range',celda,'WriteVariableNames',false);
            end
            celdaExcel = celdaExcel+incerNeedCharger+1;
            
            %--------------------------------------  FIN DE LLMADO funMarca  -------------------------------------------- %
            disp(strcat("-----------FIN DE ITERACION EN HORA--",horaAnalisis, " ----------"))
            
        end  
    end 
    m=1;
end 

%%
%Porcentaje de batería con el que cuenta el EV, considerando las
%electrolineras rápidas y semi rapidas, fun 2 
function vectorVehiculo = funMarca(numIteracion, horaCalleAnalizada, nombreCalleAnalizada) 
    global infoDeVe; 
    %Obtiene incertidumbre de marca%
    [x y]= size(infoDeVe);
    
    incerMarca=randi([1 y]);
    vectorVehiculo = {};
    
    %Incertidumbre porcentaje de bateria del vehiculo%
    incerPorcentajeBateria = randi([5 70]);
    faltanteBateria = 100 - incerPorcentajeBateria;
    %Respuesta de vector%
    vectorVehiculo = {numIteracion, nombreCalleAnalizada, horaCalleAnalizada, infoDeVe(1,incerMarca), infoDeVe(2,incerMarca),infoDeVe(3,incerMarca), incerPorcentajeBateria, faltanteBateria};
end 

%%
%funciones de ayuda para crear vectores con cantidad de espacios n 
function Tabla = funTable(sizetable, varTypes , varNames)
    Tabla = table('Size',sizetable,'VariableTypes',varTypes, 'VariableNames',varNames);
end
