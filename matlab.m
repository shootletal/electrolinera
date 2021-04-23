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
disp("ÁREAS DE ANÁLISIS EN UNA CIUDAD")
disp("1.Centro ")
disp("2.Periferia ")
areaCiudad=input("Eliga la zona de la ciudad en la cual será implementada la electrolinera: ");
numMonteCarlo=input("Indique el número de iteracciones para el Montecarlo: ");
%% 
%variables iniciales 
%Marcas de los vehículos eléctricos con sus respectivas caracteristicas  
global infoDeVe
infoDeVe=["Nissan" "Renault" "Toyota" "BYD";112 65 69 300];% kW ...........corregir caracteristicas de potencia del ev

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
function [dataHistorico] = funExcelHistorico(nombreArchivo, numTotalCalles, numMonteCarlo)
    
    for contaCalles = 1:1:numTotalCalles
        
        TablaHistorico = readtable( nombreArchivo, 'sheet', strcat('opcion', num2str(contaCalles)) )
        
        funMonteCarlo(numMonteCarlo, TablaHistorico);
    end
end

%%
%Función para elegir la marca del EV y la cantidad que necesitan ser
%cargados, fun principal 
function m= funMonteCarlo(numMonteCarlo, TablaHistorico)
    
    %global nodos; global carga; global tr;
    %Llamar a la función que analizo las calles candidatas en una determinada
    %zona de la ciudad
    matrizRapida = [];
    matrizSemi = [];
    [a b] = size(TablaHistorico);
    
   %Numero de veces que se aplica montecarlo para cada calle o km
    for iterMonte=1:1:numMonteCarlo
        
        % Este for va analizando los datos por cada hora con sus repectivo
        % flujo vehicular e incertidumbres 
        for contaHorario=1:1:a
            flujo = TablaHistorico.Flujo(contaHorario);
            numEv = round(flujo * 0.10)
            %Cuantos vehiculos electricos necesitan ser cargados, para lo cual obtiene aleatorio de 0 a numEv
            incerNeedCharger = randi([0 numEv])
            disp("-------------------------------------------------------------------")
            disp(strcat("Analisis de la calle: ", TablaHistorico.Calle(contaHorario), "a las ", datestr(TablaHistorico.Hora(contaHorario),'HH:MM AM')))
            disp(strcat("Existen un total de ",num2str(numEv)," de vehiculos electricos" ))
            disp(strcat("Necesitan ser cargados ",num2str(incerNeedCharger)," del total"))
            disp("-------------------------------------------------------------------")
            
            %Inicia las incertidumbres para los vehiculos que necesitan ser
            %cargados
            for  iteracion=1:1:incerNeedCharger             
                iteracion
                % Obtiene la incertidumbre de cuantos vehiculos necesitan
                % ser cargados en la electrolinera de carga rapida
                needchargerFast=randi([0 incerNeedCharger]);
                matrizRapida = funElectrolineraMarca(iteracion, TablaHistorico.Hora(contaHorario) ,TablaHistorico.Calle(contaHorario), 1, "Rapida" ,needchargerFast)
                
                % Obtiene la incertidumbre de cuantos vehiculos necesitan
                % ser cargados en la electrolinera de carga Semi
                needchargerSemi= randi([0 (incerNeedCharger - needchargerFast )]);
                matrizSemi = funElectrolineraMarca(iteracion, TablaHistorico.Hora(contaHorario) ,TablaHistorico.Calle(contaHorario),2, "Semi" ,needchargerSemi)
                pause
                needchargerSlow = incerNeedCharger - needchargerFast - needchargerSemi;
                disp(" ")
                disp("-------------------------------------------------------------------")
                disp(strcat(" Se cargaran en la oficina o casa ", num2str(needchargerSlow)," vehiculos"))
                %
                %horaDeCargaPorCalle(contadorCallesCandidatas), nombreDeCalleCandidata(contadorCallesCandidatas), flujoDeVe,1); 

                %--------------------------------------  FIN DE LLMADO funMarca  -------------------------------------------- %
                
                disp(strcat("-----------FIN DE ITERACION Nº--",int2str(iteracion), " ----------"))
            end
        end  
    end 
    m=1;
end 

%%
%Porcentaje de batería con el que cuenta el EV, considerando las
%electrolineras rápidas y semi rapidas, fun 2 
function matrizTipoElectrolinera = funElectrolineraMarca(numIteracion, horaCalleAnalizada, nombreCalleAnalizada, incerElectrolinera,tipoElectrolinera, numNeedchargerElectrolinera) 
    global infoDeVe; 
    
    disp("-------------------------------------------------------------------")
    disp(strcat("Se realizá la carga en una electrolinera ", tipoElectrolinera ," y seran cargados ",int2str(numNeedchargerElectrolinera)))
    disp("-------------------------------------------------------------------")
    matriz = [];
    for contaNeedChargerElectrolinera = 1:1: numNeedchargerElectrolinera   
        incerMarca=randi([1 length(infoDeVe)]);
        disp(strcat("El vehiculo ",num2str(contaNeedChargerElectrolinera)  ," es de marca: ", infoDeVe(1,incerMarca)));
        
        if incerElectrolinera == 1  %Electrolinera de carga Rapida        
            if incerMarca == 1 %Representa a Nissan
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 50 );  %Confirmar datos de la electrolinera Rapida para Nissan  
            elseif incerMarca == 2  %Representa a Renault
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 60 );  %Confirmar datos de la electrolinera Rapida para Renault
            elseif incerMarca == 3 % Representa a Toyota
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 80 );  %Confirmar datos de la electrolinera Rapida para Toyota
            elseif incerMarca == 4 % Representa a BYD
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 70 );  %Confirmar datos de la electrolinera Rapida para BYD
            end
                  
        elseif incerElectrolinera == 2  %Electrolinera de carga Semi
            if incerMarca == 1 %Representa a Nissan
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 70 );  %Confirmar datos de la electrolinera Semi para Nissan      
            elseif incerMarca == 2  %Representa a Renault
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 70 );  %Confirmar datos de la electrolinera Semi para Renault
            elseif incerMarca == 3 % Representa a Toyota
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 70 );  %Confirmar datos de la electrolinera Semi para Toyota
            elseif incerMarca == 4 % Representa a BYD
                [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectrolinera] = funTiempoCarga( infoDeVe(2,incerMarca), 110, 70 );  %Confirmar datos de la electrolinera Semi para BYD
            end
            
        end       
        matriz(contaNeedChargerElectrolinera,:) = [contaNeedChargerElectrolinera,potenciaElectrolinera,incerPorcentajeBateria,faltanteBateria, tiempoCargaVehiculo];       
        marcas(contaNeedChargerElectrolinera,1) = infoDeVe(1,incerMarca);
    end
    
    %varNames = {"IteracionVehiculo", "Marca","Potencia Electrolinera","Incertidumbre Bateria", "Faltante Bateria","Tiempo Carga Vehiculo" };
    varNames = {'iteracion Vehiculo','Marca','Potencia Electrolinera','Incertidumbre Bateria','Faltante Bateria','Tiempo Carga Vehiculo'};
    matrizTipoElectrolinera = table(matriz(:,1), marcas, matriz(:,2), matriz(:,3), matriz(:,4), matriz(:,5),'VariableNames',varNames);
end 

%%
function [tiempoCargaVehiculo, incerPorcentajeBateria , faltanteBateria, potenciaElectro] = funTiempoCarga(potenciaVehiculo,  potenciaElectrolinera, tiempoElectrolinera)
    
    potenciaElectro = potenciaElectrolinera;
    incerPorcentajeBateria = randi([5 70]); 
    faltanteBateria = 100 - incerPorcentajeBateria;
    
    tiempoCargaMarca = (str2num(potenciaVehiculo)*potenciaElectrolinera)/tiempoElectrolinera; %Confirmar formula para tiempo de carga de vehiculo
    tiempoCargaVehiculo = (faltanteBateria*tiempoCargaMarca)/100;  %Corregir la formula
    
    disp(strcat('El faltante de bateria es  ', num2str(faltanteBateria),' tiempo de carga es de  ', num2str(tiempoCargaVehiculo) ))
    
    
end
%%
%funciones de ayuda para crear vectores con cantidad de espacios n 
function vector=funVector(numEspacios,h)
    for n=1:1:numEspacios
        vector(n)=h;
                
    end
end

%%
function matriz=funMatriz(fila,columna, valor)
    for n=1:1:filas
        for m=1:1:columna
            matriz(n,m)= valor;
        end           
    end
end

