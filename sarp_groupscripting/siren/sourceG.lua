gpsBlips = {}

allowedVehicles = {
    [599] = true, -- Police Ranger
    [598] = true, -- Police LS/SF/LV
    [597] = true, -- Police LS/SF/LV
    [596] = true, -- Police LS/SF/LV
    [523] = true, -- HPV1000
    [490] = true, -- FBI Rancher
    [528] = true, -- FBI Truck 
    [407] = true, -- Fire Truck
    [544] = true, -- Fire Truck with ladder
    [416] = true, -- Ambulance
    [427] = true, -- Enforcer
    [433] = true, -- Barracks
    [570] = true, -- Patriot
    [432] = true, -- Rhino
    [601] = true, -- S.W.A.T.
    [428] = true, -- Securicar
}

vehiclesSiren = {
    -- Police
    [599] = {
        [1] = "federal_signal_smart_1.wav",
        [2] = "federal_signal_smart_2.wav",
        [3] = "federal_signal_smart_3.wav",
        ["horn"] = "federal_signal_smart_horn.wav", 
    },
    [598] = {
        [1] = "federal_signal_smart_1.wav",
        [2] = "federal_signal_smart_2.wav",
        [3] = "federal_signal_smart_3.wav",
        ["horn"] = "federal_signal_smart_horn.wav", 
    },
    [597] = {
        [1] = "federal_signal_smart_1.wav",
        [2] = "federal_signal_smart_2.wav",
        [3] = "federal_signal_smart_3.wav",
        ["horn"] = "federal_signal_smart_horn.wav", 
    },
    [596] = {
        [1] = "federal_signal_smart_1.wav",
        [2] = "federal_signal_smart_2.wav",
        [3] = "federal_signal_smart_3.wav",
        ["horn"] = "federal_signal_smart_horn.wav", 
    },
    [527] = {
        [1] = "federal_signal_smart_1.wav",
        [2] = "federal_signal_smart_2.wav",
        [3] = "federal_signal_smart_3.wav",
        ["horn"] = "federal_signal_smart_horn.wav", 
    },
    [528] = {
        [1] = "federal_signal_smart_1.wav",
        [2] = "federal_signal_smart_2.wav",
        [3] = "federal_signal_smart_3.wav",
        ["horn"] = "federal_signal_smart_horn.wav", 
    },
    -- Fire & EMS
    [407] = { -- Fire truck
        [1] = "whelen_alternate_manual.wav",
        [2] = "whelen_alternate_mech.wav",
        [3] = "whelen_alternate_wail.wav",
        ["horn"] = "whelen_gamma_horn.wav", 
    },
    [544] = { -- Fire truck ladder
        [1] = "whelen_alternate_manual.wav",
        [2] = "whelen_alternate_mech.wav",
        [3] = "whelen_alternate_wail.wav",
        ["horn"] = "whelen_gamma_horn.wav", 
    },
    [416] = { -- Ambulance
        [1] = "whelen_ws2100_1.wav",
        [2] = "whelen_ws2100_2.wav",
        [3] = "federal_signal_smart_1.wav",
        ["horn"] = "whelen_gamma_horn.wav", 
    },
}

sirenPos = {
    [597] = {
        [1] = { 
            {-0.3, 0.32, 0.8, 255, 0, 0, 225, 225}, -- ELSŐ FENT
            {0.3, 0.32, 0.8, 0, 0, 255, 225, 225}, -- ELSŐ FENT

            {-0.3, -1.5, 0.8, 255, 0, 0, 225, 225}, -- HÁTSÓ FENT
            {0.3, -1.5, 0.8, 0, 0, 255, 225, 225},-- HÁTSÓ FENT

            {-0.3, -2.9, 0.23, 255, 255, 0, 225, 225}, -- HÁTSÓ LENT
            {0.3, -2.9, 0.23, 255, 255, 0, 225, 225}, -- HÁTSÓ LENT

            {-0.3, 2.6, 0.125, 255, 0, 0, 225, 225}, -- ELSŐ LENT
            {0.3, 2.6, 0.125, 0, 0, 255, 225, 225} -- ELSŐ LENT
        },
        [2] = {
            {-0.3, 0.32, 0.8, 255, 0, 0, 255, 255},
            { 0.3, 0.32, 0.8, 0, 0, 255, 255, 255},
        },
    },
    [596] = {
        [1] = { 
            {-0.3, -0.42, 1.02, 255, 0, 0, 255, 255},
            {0.3, -0.42, 1.02, 0, 0, 255, 255, 255},
            {-0.3, -2.9, 0.3, 255, 255, 0, 225, 225},
            {0.3, -2.9, 0.3, 255, 255, 0, 225, 225},
        },
        [2] = {
            {-0.3, -0.42, 1.02, 255, 0, 0, 255, 255},
            {0.3, -0.42, 1.02, 0, 0, 255, 255, 255},
        },
    },
    [598] = {
        [1] = {
            {-0.3, -0.2, 1, 255, 0, 0, 225, 225},
            {0.3, -0.2, 1, 0, 0, 255, 225, 225},

            {-0.45, -2.4, 0.45, 255, 255, 0, 225, 225},
            {0.45, -2.4, 0.45, 255, 255, 0, 225, 225},
        },
        [2] = {
            {-0.3, -0.2, 1, 255, 0, 0, 225, 225},
            {0.3, -0.2, 1, 0, 0, 255, 225, 225},
        }
    },
    [416] = {
        [1] = {
            {-0.8, 0.5, 1.8, 255, 0, 0, 225, 225}, -- tető elöl
            {0.8, 0.5, 1.8, 0, 0, 255, 225, 225}, -- tető elöl

            {-0.3, 3.15, 0.15, 255, 0, 0, 225, 225}, -- hűtőrács
            {0.3, 3.15, 0.15, 0, 0, 255, 225, 225}, -- hűtőrács

            {-1.1, -3.75, 1.75, 0, 0, 255, 225, 225}, -- hátul felül
            {1.1, -3.75, 1.75, 0, 0, 255, 225, 225}, -- hátul felül

            {-1.1, -3.75, 0.75, 255, 0, 0, 225, 225}, -- hátul alul
            {1.1, -3.75, 0.75, 255, 0, 0, 225, 225}, -- hátul alul
        },
        [2] = {
            {-0.8, 0.5, 1.8, 255, 0, 0, 225, 225}, -- tető elöl
            {0.8, 0.5, 1.8, 0, 0, 255, 225, 225}, -- tető elöl

            {-1.1, -3.75, 1.15, 255, 150, 0, 225, 225}, -- hátul középen
            {1.1, -3.75, 1.15, 255, 150, 0, 225, 225}, -- hátul középen

            {-1, -3.75, -0.1, 255, 150, 0, 225, 225}, -- hátul alul
            {1, -3.75, -0.1, 255, 150, 0, 225, 225}, -- hátul alul

            {-0.5, -3.75, 1.7, 255, 255, 255, 225, 225}, -- hátul felül
            {0.5, -3.75, 1.7, 255, 255, 255, 225, 225}, -- hátul felül
        }
    }
}

function getAllowedVehicles()
    return allowedVehicles
end