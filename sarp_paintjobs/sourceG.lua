paintjobs = {
    [596] = { -- Textúra, Elérési hely, Név, Csak frakciónak
        {"*LAPD*", "sheriff1.png", "Sheriff Department", true},
        {"*LAPD*", "sheriff2.png", "Sheriff Department", true},
    },
    [598] = { -- Textúra, Elérési hely, Név, Csak frakciónak
        {"*SCPD*", "sheriff1.png", "Sheriff Department", true},
        {"*SCPD*", "sheriff2.png", "Sheriff Department", true},
    },
    [525] = { -- Textúra, Elérési hely, Név, Csak frakciónak
        {"*towlogo*", "lsc.png", "Los Santos Customs", true},
    },
    [427] = { -- Textúra, Elérési hely, Név, Csak frakciónak
        {"*body*", "sheriff1.png", "Sheriff Department", true},
    },
}

function getVehiclePaintjobs(vehicle)
    if not vehicle then
        return false
    end

    local modelID = getElementModel(vehicle)
    if paintjobs[modelID] then
        return paintjobs[modelID]
    end
    return false
end


function getModelPaintjobs(modelID)
    if not modelID then
        return false
    end

    if paintjobs[modelID] then
        return paintjobs[modelID]
    end
    return false
end