--[[
    Base Rover 2021
    Ivan Jimenez
    INTEC - Santo Domingo, D.R.

]]

function inicializacion()
    --out=sim.auxiliaryConsoleOpen("Debug", 15,1)
    camara = sim.getObjectHandle("Vision_Frente")
    
    local p = 0.6 -- 0.92 color original
    CYAN = {0, p, p}
    MAGENTA = {p, 0 , p}
    NARANJA = {p, p*p, 0}
    ROJO = {p, 0, 0}


    ROJO_TOLERANCE = {0.2,0.1,0.1}
    COL_TOLERANCE = {0.1,0.1,0.1}


end

function sysCall_vision(inData)

    local pack = leerCamaraBlobs(inData.handle)

    local outData={}
    outData.trigger=true

    outData.packedPackets={pack}
    return outData

end

function ejecucion()
    --leerCamara(camara)
    --sim.auxiliaryConsolePrint(out, "\n Hello")
    --printBlobs(detect)
    --print(leerCentroBlob( detect,  findMaxBlob(detect) ))
    
end

function leerCamaraBlobs(sensor)
    -- Leer la imagen desde el sensor
    simVision.sensorImgToWorkImg(sensor)

    -- Buscar un color para hacerle blob detection
    simVision.selectiveColorOnWorkImg(sensor, CYAN, COL_TOLERANCE, true, true, false)

    --simVision.blobDetectionOnWorkImg(
    --    number handle,number threshold,number minBlobSize,bool diffColor,table_3 overlayColor={1.0,0.0,1.0}))
    local trig, pack = simVision.blobDetectionOnWorkImg(sensor, 0.1, .1, false, {1.0,0.0,1.0})
    
    -- local detect =  sim.unpackFloatTable(pack)

    -- Devolver la imagen para visualizacion
    simVision.workImgToSensorImg(sensor)
    return pack
end