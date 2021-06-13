--[[
    Base Rover 2021
    Ivan Jimenez
    INTEC - Santo Domingo, D.R.

]]


--[==[ Funciones para el UI

function speedChange_callback(ui,id,newVal)
    v=newVal
    w0 = v/Radio -- Rotación nominal Ruedas
    simUI.setLabelText(ui,2,tostring(v))
end

function angleChange_callback(ui,id,newVal)
    angulo=newVal
    simUI.setLabelText(ui,7,tostring(angulo))
end

function parar_callback(ui, id)
    sim.stopSimulation()
end

function pausa_callback(ui, id)
    local simulationState=sim.getSimulationState()
    if simulationState == sim.simulation_paused then  
        sim.startSimulation()
        simUI.setButtonText(ui,id,"Pausa")
    else
        sim.pauseSimulation()
        simUI.setButtonText(ui,id, "Seguir")
    end
end

function crearUI(v, angulo)
    -- Create the custom UI: Velocidad, Presencia, Color(G), Luminosidad
    xml = '<ui title="Robot speed" closeable="true" resizeable="true" activate="false" placement="relative" position="0,600">'..[[
    <group flat="true" style="margin:0; padding:0;">
        <hslider minimum="0" maximum="30" tick-interval="3" onchange="speedChange_callback" id="1" style="width: 200px; height:50px;"/>
        <label text="" style="margin=left: auto;" id="2"/>
        <group flat="true" layout="hbox" style="width:190px;">
            <group flat="true" style="width: 40%; margin:0;">
                <group layout="hbox" style="">
                  <group layout="vbox" flat="true" style="margin:0; padding:0;">
                      <label text="valL:" style="line-height: 1em;" />
                      <label text="valR:" style="" />
                  </group>
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="" style="" id="]]..ui_valL..[["/>
                      <label text="" style="" id="]]..ui_valR..[["/>
                  </group>
                </group>
                <group layout="hbox">
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="valC:" style=""/>
                      <label text="colorC:" style=""/>
                  </group>
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="" style="" id="]]..ui_valC..[["/>
                      <label text="" style="" id="]]..ui_colorC..[["/>
                  </group>
                </group>
            </group>
            <group flat="true" style="width: 20%">
                <label text="" style="margin-left:auto;" id="]]..ui_estado..[["/>
                <vslider minimum="0" maximum="90" tick-interval="5" on-change="angleChange_callback" id="]]..ui_angulo..[[" style="width: 100%; height:90%;"/>
                <label text="" style="margin-left:auto;" id="7"/>
            </group>
            <group flat="true" style="width: 40%; margin:0;padding:0;">
                <group flat="true" layout="hbox" style="padding:0;">
                    <button text="Pausa" on-click="pausa_callback" id="10" style="height:auto;"/>
                    <button text="Parar" on-click="parar_callback" id="9" style="height:auto;"/>
                </group>
                <group layout="hbox" style="padding:0;">
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="v:" style="" />
                      <label text="w:" style="" />
                  </group>
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="" style="width: 5em;" id="]]..ui_v..[["/>
                      <label text="" style="width: 5em;" id="]]..ui_w..[["/>
                  </group>
                </group>
                <group layout="hbox" style="padding:0;">
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="wL:" style="" />
                      <label text="wR:" style="" />
                  </group>
                  <group layout="vbox" flat="true" style="margin:0;">
                      <label text="" style="width: 5em;" id="]]..ui_wL..[["/>
                      <label text="" style="width: 5em;" id="]]..ui_wR..[["/>
                  </group>
                </group>
            </group>
        </group>
    </group>
    </ui>
    ]]
    
    ui=simUI.create(xml)
    simUI.setSliderValue(ui,1,v*10, false)
    simUI.setSliderValue(ui,6,angulo, false)
end
--]==]
function sysCall_init()
    -- do some initialization here
    objHandle=sim.getObjectAssociatedWithScript(sim.handle_self)
    
    ruedaL = sim.getObjectHandle("J_Rueda_L")
    ruedaR = sim.getObjectHandle("J_Rueda_R")
    brazo = sim.getObjectHandle("J_Brazo_R")

    sensorC = sim.getObjectHandle("Linea_SensorC")
    sensorR = sim.getObjectHandle("Linea_SensorR")
    sensorL = sim.getObjectHandle("Linea_SensorL")

    objetos = sim.getObjectHandle("Obj_Frente")

    sensorCajaColor = sim.getObjectHandle("Caja_Color")
    -- sensorCajaProx = sim.getObjectHandle("Caja_Sensor")
    sensorCajaProx = sim.getObjectHandle("Obj_Frente")

    camara = sim.getObjectHandle("Vision_Frente")

    apoyo = sim.getObjectHandle("Apoyo")
    
    led = sim.getObjectHandle("LED_RGB")

    -- COLORES 
    B = 4 -- Blanco
    R = 1 -- Rojo
    V = 2 -- Verde
    A = 3 -- Azul
    
    CYAN = {0, 0.92, .92}
    MAGENTA = {.92, 0 ,.92}
    NARANJA = {.95, .65, 0}
    ROJO = {.83, 0, 0}

    COL_TOLERANCE = {0.2,0.2,0.2}

    MIN_BLOB_SIZE = 0.1

    -- Estados
    --[[
        Estas variables representan las diferentas partes de una mision y sirven para activar los estados:
    ]]
    iniciando = false
    enBusquedaCaja = false
    enAcercarseCaja = false
    enRecojerCaja = false
    enBusquedaMeta = false
    enAcercarseMeta = false
    enDejarCaja = false

    bajandoLinea = false
    asegurandoCaja = false
    entrando = false
    acomodando = false
    buscandoLinea = false

    -- Señales
    nuevoEstado = false -- Representa si se solicitó cambiar de estado
    
    
    -- Condiciones
    hayCaja = false -- hay una caja al frente
    conectada =  false -- la caja esta conectada (para que no se caiga) [not used?]
    cajaCargada = false -- la caja esta sostenida por el brazo
    
    finalLinea = false -- se encontro el final de una linea (interrupcion)
    centroPista = false -- se detecta el centro de la pista
    sobreLinea = false -- estamos sobre una linea
    
    llevandoCaja = false -- llevando una caja a su color
    llevandoBuffer = false -- llevando una caja al buffer
    
    
    -- Memoria
    
    cajaAct = 0 -- color de la caja cargada
    cajaBuffer = 0 -- color de la caja en el buffer
    buffer = false -- hay una caja en el buffer
    -- colorCajaDes = 0 -- color de la caja que se busca (not needed?)

    lineaActual= 0 -- color de la linea sobre la que estamos
    lineaUltima = 0 -- color de la ultima linea visitada
    lineaBuscar = 0 -- color de la linea que se busca

    brazoArriba = false 

    -- Sensores
    valR = 0 -- Lectura sensor Derecho
    valL = 0 -- Lectura sensor Izquierdo
    maxVal = 0 -- Valor mas grande de sensores
    maxSensor = 0 -- Indica el sensor con valor mas grande (R:+1,L:-1)
    
    valLinea = 0 -- Lectura del sensor de línea
    colorLinea = 0 -- Color reporta el sensor de línea
    maxLinea = 0 -- Valor máximo leido por el sensor de línea


    distCaja = 0 -- Lectura sensor de caja (distancia)
    colorCaja = 0 -- Color de caja detectado

    -- Constantes
    L = 12.06  -- Distancia entre ruedas
    Radio = 3.5 -- radio de las ruedas
    V0 = 30   -- Velocidad nominal (cm/s)
    w0 = V0/Radio -- Rotación nominal Ruedas


    P_R = 3.5 -- Sensibilidad (ganancia) giro derecha
    P_L = 3.5 -- Sensibilidad (ganancia) giro izq

    wR = 0
    wL = 0

    -- Velocidades actuales
    v_act = 0
    w_act = 0

    valCentro = 0.6705882549 -- Valor del color del centro



    cubo_presente = false
    cubo_color = 0
    
    
    cam_centro = {0.5, 0.5}
    objeto_coords = cam_centro
  
    
   
    -- IDs de campos en UI
    ui_l_presencia = 2
    ui_l_color = 3
    ui_l_lum = 4

    ui_valL = 11
    ui_valR = 12

    ui_valC = 13
    ui_colorC = 14

    ui_wL = 21
    ui_wR = 22
    ui_v = 23
    ui_w = 24

    ui_estado = 5
    ui_angulo = 6

    v = V0
    angulo = 0.0

    -- Estado Inicial
    iniciando = true
    
    
    if crearUI ~= nil then
        crearUI(V0, angulo)
    end
end
-- El robot solo puede mover una caja a la vez
-- El robot no puede detectar otra caja si ya lleva una
-- El robot tiene tres sensores de color hacia el piso: uno en el centro atrás y dos de luz en los extremos
-- El robot tiene un sensor de proximidad para detectar la caja en su control 
-- El robot tiene un sensor de color en para ver el color de la caja en su control
-- El robot se mueve usando motores DC (en realidad son steppers)
-- El motor del brazo es un servo






-- ************************ Sub-funciones ****************************
function posBrazo(p, grados) -- grados=false
    local grads = grados or true

    local pos = grads and p*math.pi/180 or p
    --p = p*math.pi/180
    sim.setJointTargetPosition(brazo,pos)
    angulo = grads and p or p*180/math.pi
    
    if ui then
        sliderUI(ui_angulo,angulo)
    end
end 

function abrir()
    posBrazo(90)
end

function cerrar()
    posBrazo(0)
end

function mover(wL_d,wR_d)
    -- Mueve el robot seteando las velocidades angulares de cada motor
    wL, wR = wL_d, wR_d
    sim.setJointTargetVelocity(ruedaL, wL) -- si fueran steppers seria una Position
    sim.setJointTargetVelocity(ruedaR, wR)    
end

function drive(v,w)
    
    v_act = v 
    w_act = w
    local vL, vR
    vR = (2*v+L*w)/2 
    vL = (2*v-L*w)/2 -- -vR/2.98
    -- Hay que probar cuando el robot cambia el arco
    wL, wR = vL/Radio, vR/Radio -- Hay un punto donde toca vL*alph (alp >1) para garantizar arco
    mover(wL,wR)
end

function arco(v,rad)
    -- Moverse en un arco a una velocidad v
    local w = v/rad
    drive(v,w)
end

function detener()
    mover(0,0)
end

function movAve(mem, new, alpha)
    return alpha*mem + (1-alpha)*new
end

-- ************************ Camara ****************************

function leerCamaraFiltro(sensor)
    local res, packColors, packFiltro, pack3 =  sim.readVisionSensor(sensor)
        
    return res and packFiltro or {}

    --print(packColors)
    --print(packFiltro)
    --print(pack3)
end


function printBlobs(blobs)
    local num_blobs, vars
    local size, ort, x, y, w, h = 3,4,5,6,7,8

    num_blobs = blobs[1]
    vars = blobs[2]
    if num_blobs < 1 then
        return
    end 

    for i=1,num_blobs,1 do
        local m = (i-1)*vars
        local str = string.format( "%d: %0.3f @ (%0.3f, %0.3f) as w: %0.3f, h: %0.3f", i, blobs[m+size], blobs[m+x], blobs[m+y], blobs[m+w], blobs[m+h])
        print(str)
    end
end

function findMaxBlob(blobs)
    local num_blobs, vars
    local size, ort, x, y, w, h = 3,4,5,6,7,8

    num_blobs = blobs[1]
    vars = blobs[2]

    if num_blobs < 1 then
        return 0
    end 

    local max_val, max_i = 0, 1
    -- buscar el max (indice)
    for i=1,num_blobs,1 do
        local m = (i-1)*vars
        if blobs[m+size] > max_val then 
            max_val = blobs[m+size]
            max_i = i
        end
    end
    return max_i
end


function leerCentroBlob(blobs, ind)
    
    if blobs[1] == 0 or ind < blobs[1] then
        return {} --no existe
    end

    local vars = blobs[2]
    local size, ort, x, y, w, h = 3,4,5,6,7,8
    local m = (ind-1)*vars

    return {blobs[m+x],blobs[m+y]}
end


--[[
function leerBlob(blobs, ind, size, ort, x, y, w, h)
end
--]]

function leerDimsBlob(blobs, ind)
    if blobs[1] == 0 or ind < blobs[1] then
        return {} --no existe
    end

    local vars = blobs[2]
    local size, ort, x, y, w, h = 3,4,5,6,7,8
    local m = (ind-1)*vars
    return {blobs[m+size],blobs[m+w], blobs[m+h]}
end


-- ************************ Sensing ****************************
function leerDistancia(sensor)
  local presencia, dist, punto, objeto = sim.readProximitySensor(sensor)
  -- los Extra para referencia en codigo
  return (presencia>-1) and dist or 0
end

function leerIntensidad(sensor)
  -- Devuelve la intensidad de la luz detectada
  local presencia, r = sim.readVisionSensor(sensor)
  return (presencia > -1) and r[11] or 0 -- ¿o -1?
end


function leerSensorColor(sensor)
    local presencia, r = sim.readVisionSensor(sensor)
    return (presencia > -1) and r or nil
end

function leerColor(sensor, color)
  -- Devuelve la intensidad de un color a medir
  local r = leerSensorColor(sensor)
  local base = 10 -- Leer Mean
  local i = color%4 + base + 1-- Porque R está en [2], y para leer I en [1] como Blanco
  return r and r[i] or 0 -- ¿o -1?
end

function extraerColor(sensor)
  -- Devuelve el color que se está viendo
  local presencia, res = sim.readVisionSensor(sensor)
  -- r[15] = {min(I,R,G,B,d), max(i,R,G,B,d), mean(i,R,G,B,d)}
  if (presencia > -1) then
    local base = 10 -- Leer Mean
    local r, v, a
    local i, j, k 
    i = R + base + 1
    j = V + base + 1
    k = A + base + 1

    r,v,a = res[i], res[j], res[k]
    local val = (r>v) and (r>a and R) or (v>a and V) or A

    return val
  end
  
  return presencia -- o 0
end

function pruebaCaja()
  local color = 0
    -- r[15] = {min(I,R,G,B,d), max(i,R,G,B,d), mean(i,R,G,B,d)}
    presencia, r = sim.readVisionSensor(colorCajaS)
    if (presencia > -1) then
        luminosidad = r[11]
        color = r[13]

        if ui then
            --simUI.setLabelText(ui,ui_l_presencia, tostring(presencia))
            simUI.setLabelText(ui,ui_l_color, string.sub(color,1,6))
            simUI.setLabelText(ui,ui_l_lum, string.sub(luminosidad,1,6))
        end
    end
end

function conectarCaja()
  if not conectada and hayCaja then
    local r, dist, punto, objeto = sim.readProximitySensor(sensorCajaProx)
    if objeto ~= nil then
        padre = sim.getObjectParent(objeto)
        --sim.setObjectParent(objeto, apoyo, 1)
        conectada = true
    end
  end
end

function soltar(ui,id)    
    if conectada then
        sim.setObjectParent(objeto, padre, 1)
        conectada = false
    end
end



-- ************************ Acciones ****************************
-- todas son non-blocking (hacen un cambio en las velocidades o posiciones y siguen)
function buscarCaja()
    -- Usa la cámara para ubicar una caja, antes de acercarse
    if #objeto_coords == 0 then -- No hay cajas a la vista
        -- objeto_coords = cam_centro -- Deberia causar un giro
        objeto_coords = {1.0, 0.5} -- Deberia causar un giro
    end
    print(objeto_coords)
    -- orientarse en direccion al objeto
    local Kp_w = 1
    local Kp_v = 1*V0
    local w = Kp_w*(cam_centro[1] - objeto_coords[1])
    local v = -Kp_v*(cam_centro[2] - objeto_coords[2])
    drive(v,w)
end

function acercarACaja()
    if #objeto_tam == 0 then -- No hay cajas a la vista
        objeto_coords = cam_centro -- Deberia detenerlo
        objeto_tam = {0, 1, 0} 
    end
    --print(objeto_tam)
    -- print(objeto_coords)
    -- acercarse en algun tipo de arco al objeto
    local Kp_w = 1
    local Kp_v = 0.5*V0
    local w = Kp_w*(cam_centro[1] - objeto_coords[1])
    local v = Kp_v*(objeto_tam[3])
    drive(v,w)


end

function seguirLinea()
    --- El robot esta frente/sobre una linea y la sigue
    --local wL, wR

    -- TODO: Revisar que estoy sobre la linea que quiero?? O mejor dedicarlo a esto y ya
    -- if colorLinea == lineaActual then ... 

    -- Si detecta a un lado, hala para ese lado

    -- Para cambiar la sensibilidad segun cuan "lleno" esté el cuadro del sensor
    local reg = 1 --maxLinea>0 and valLinea/maxLinea or 1 --Multiplicador normalizado 
    --local reg = 1
    wL = w0*(1-valL*P_L)*reg -- - valL*P_L -- Tentativo
    wR = w0*(1-valR*P_R)*reg  -- - valR*P_R
    mover(wL, wR) -- Enviar nuevo valor

    
end


function acomodarCentro()
    -- Seguir avanzando hasta que ambos lados lean "suficiente"
        -- Ganancias dberían variar según color (Blanco simpre estará a la derecha si vengo de Verde)
    local G_L, G_R = 1,1
  
    wL = (0.45 - valL)*G_L -- el más alto avanza más
    wR = (1 - valR)*G_R  -- valR*P_R
    mover(wL, wR) -- Enviar nuevo valor

end



function recogerCaja()
  -- El robot ubicó la caja y necesita acercarse para recogerla
  -- Usar la lectura del sonar para decidir cuando cerrar
    print(distCaja)
    local v = distCaja*25

    if distCaja < 0.07 then
        cerrar()
        --v = 0
    end
    drive(v, 0)
end

function soltarCaja()
  -- El robot dejó una línea y debe soltar la caja
end


-- **************************** Estados ****************************
function Inicio()
    -- 
    if not nuevoEstado then
        if maxLinea > 0.1 then
            nuevoEstado = true
            enBusquedaCaja = true
            iniciando = false
            return
        end
    else
       
        nuevoEstado = false
        if ui then
            textoUI(ui_estado,"Inicio")
        end
        --wL = w0
        --wR = wL
    end
    --drive(v/4,0)
end


function BuscandoCaja()
    -- Se mueve para orientar la cámara hacia uno de los cubos
    -- Pudiera Necesitar: 
    --      saber si hay un color preferido
    --      saber en qué dirección conviene girar
    -- Termina: 
    --      cuando una caja (blob) se encuentra en el centro de la imagen
    --      Cuando no encuentra una caja en un tiempo determinado

    if not nuevoEstado then -- Si estabamos en el estado 
        if #objeto_coords ~= 0 then
            local e = distancia2(cam_centro, objeto_coords)
            if e < 0.002 then -- Salir
                nuevoEstado = true
                enAcercarseCaja = true
                enBusquedaCaja = false
            end
        end
    else -- Si acabamos de entrar al estado
        if ui then
            textoUI(ui_estado,"Buscando Caja")
        end
        nuevoEstado = false

        -- Pasa a la cámara el color a buscar
    end
    -- Acción del estado
    buscarCaja()
end


function AcercandoCaja()
    -- Se mueve hacia la caja tratando de ubicarla con un perfil específico en la imagen
    -- Pudiera necesitar:
    --      Distinguir entre una cara y otra
    --      Algun tipo de arco para acomodar
    -- Termina:
    --      Cuando la caja tiene un W y Y adecuados

    if not nuevoEstado then -- Si estabamos en el estado 
        if #objeto_coords ~= 0 and objeto_tam[3] < MIN_BLOB_SIZE*1.2 then
            nuevoEstado = true
            enAcercarseCaja = false
            enRecojerCaja = true
        end

    else -- Si acabamos de entrar al estado
        print("--------- Acercar")
        if ui then
            textoUI(ui_estado,"Acercando a Caja")
        end
        nuevoEstado = false
        -- Pasa a la cámara el color a buscar
    end
    -- Acción del estado
    
    abrir()
    acercarACaja()
end

function RecogiendoCaja()
    -- Acomoda la caja frente al vehiculo y la asegura (la levanta)
    -- Pudiera necesitar:
    --      Saber la distancia a la cara de la caja
    --      Confirmar el color de la cara
    if not nuevoEstado then -- Si estabamos en el estado 
        

    else -- Si acabamos de entrar al estado
        print("--------- Recoger")
        if ui then
            textoUI(ui_estado,"Recogiendo Caja")
        end
        nuevoEstado = false

    end
    -- Acción del estado
    recogerCaja()
end

function BuscandoMeta()
    --
end

function AcercandoMeta()
    --
end

function DejandoCaja()
    --
end

function Subiendo()
    -- Sigue una línea hasta el circulo

    if not nuevoEstado then -- Si estabamos en el estado 
        --print(("%0.2f, (%0.2f, %0.2f), %0.2f"):format(valLinea/maxLinea, valLinea, wR, math.sqrt(wL*wL+wR*wR)))
        --if valLinea < 0.15*maxLinea then
        if valLinea < 0.1 or math.sqrt(wL*wL+wR*wR) < 0.1  then
            nuevoEstado = true
            subiendoLinea = false
            -- Cambiar a Entrando
            entrando = true
            --maxLinea = 0 -- resetear
            drive(0,0)
            return
        end
    else -- Si acabamos de entrar al estado
        nuevoEstado = false
        if ui then
            textoUI(ui_estado,"Subiendo")
        end
    end
    seguirLinea()
    

end

function Bajando()
    -- Sigue una línea hasta su final
end

function Asegurando()
    -- Busca y recoge, o deja, una caja al final de una línea
end

function Decidiendo()
    -- Elige lo que toca hace en el centro

    if not nuevoEstado then
    
    else
        if ui then
            textoUI(ui_estado,"Decidiendo")
        end
        nuevoEstado = false
    end

end

function Entrando()
    -- [[
    
    if not nuevoEstado then
        if math.abs(valLinea - valCentro) < 0.1 then 
            nuevoEstado = true
            entrando = false
            acomodando = true
            if ui then
               textoUI(ui_estado, "Dejando: Entrando")
            end
            drive(0,0)
            return
        end

    else
        if ui then
            textoUI(ui_estado,"Entrando")
        end
        nuevoEstado = false
        maxLinea = 0
    end

    entrarCentro()
end

function Acomodando()
    -- Se acomoda y busca una linea

    if not nuevoEstado then
        local l = {valL,0,valR}
        local val = l[2-maxSensor] -- Elige el sensor opuesto
        --print( ("%0.2f, %0.2f, %0.2f"):format(val, 0.2*maxVal, maxVal) )
        local alpha = 0.7

        maxVal =  alpha*maxVal + (1-alpha)*val

        topVal = (maxVal>topVal) and maxVal or topVal
        print( ("%0.2f, %0.2f, %0.2f"):format(topVal/val, val, topVal) )
        if val < 0.3*maxVal then
            
            detener()
            --return
        end
    else
        if ui then
            textoUI(ui_estado,"Acomodando")
        end
        nuevoEstado = false
        --maxVal = (valR > valL) and valR or valL
        maxVal, topVal = 0,0.001
        maxSensor = (valR > valL) and 1 or -1
    end
    acomodarCentro()
end
--]=]

function revisarEstado(cond, st)
    return cond and st()
end

-- **************************** Coppelia ****************************
function sysCall_actuation()
    -- put your actuation code here
    -- [[
    revisarEstado(iniciando, Inicio)
    revisarEstado(enBusquedaCaja, BuscandoCaja)
    revisarEstado(enAcercarseCaja, AcercandoCaja)
    revisarEstado(enRecojerCaja, RecogiendoCaja)
    --revisarEstado(subiendoLinea, Subiendo)
    --revisarEstado(entrando, Entrando)
    --revisarEstado(acomodando,Acomodando)
    -- ]]
    --arco(30, 24)
    --drive(15,0)
    posBrazo(angulo)
    
    if ui then
        actualizarUI()
    end

end

function sysCall_sensing()
    -- leer los 6 sensores
    
    -- Laterales
    valL = leerIntensidad(sensorL)
    valR = leerIntensidad(sensorR)
    -- Centro
    valLinea = leerIntensidad(sensorC) -- o leerColor(sensorC, lineaActual)
    colorLinea = extraerColor(sensorC)

    if valLinea>maxLinea then 
        maxLinea = valLinea
        print("Nuevo max: ".. maxLinea)
    end
    -- Frente (caja)
    distCaja = leerDistancia(sensorCajaProx)
    colorCaja = extraerColor(sensorCajaColor)
    
    local cam = leerSensorColor(camara)
    local c = cam and {cam[6+R], cam[6+V], cam[6+A]} -- RGB : RVA
    
    local blobs = leerCamaraFiltro(camara)
    local max_blob = findMaxBlob(blobs)
    objeto_coords = leerCentroBlob(blobs, max_blob)
    objeto_tam = leerDimsBlob(blobs, max_blob)
    
    
end




function sysCall_cleanup()
    -- do some clean-up here
    sim.setJointTargetVelocity(ruedaR,0.0)
    sim.setJointTargetVelocity(ruedaL,0.0)
end


-- **************************** Utilidad ****************************

function dotP(a,b)
    if #a ~= #b then
        error("No coincide el no. de elementos")
        return nil
    end
    local s = 0    
    for i=1,#a,1 do
        s = s + a[i]*b[i]
    end
    return s
end

function dotP2(a,b)
    return a[1]*b[1]+a[2]*b[2]
end

function distancia2(a,b)
    local e = {b[1]-a[1], b[2]-a[2]}
    return dotP2(e,e)
end

-- See the user manual or the available code snippets for additional callback functions and details
--[==[ Funciones del UI 
function numeroUI(id,valor)
    simUI.setLabelText(ui,id,("%0.3f"):format(valor))
end

function textoUI(id,str)
    simUI.setLabelText(ui,id,str)
end

function sliderUI(id,valor)
    simUI.setSliderValue(ui,id,valor)
end
function actualizarUI()
    numeroUI(ui_valL, valL)
    numeroUI(ui_valR, valR)

    numeroUI(ui_valC, valLinea)
    numeroUI(ui_colorC, colorLinea)

    numeroUI(ui_v, v_act)
    numeroUI(ui_w, w_act)

    numeroUI(ui_wR, wR)
    numeroUI(ui_wL, wL)
end

--]==] 