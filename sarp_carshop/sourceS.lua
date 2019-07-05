
local parkingPositions = {
    {2161.9658203125, -1143.6215820313, 24.853321075439, 0, 0, 90},
    {2161.7326660156, -1147.8012695313, 24.426229476929, 0, 0, 90},
    {2161.46875, -1152.5961914063, 23.938905715942, 0, 0, 90},
    {2161.6159667969, -1162.5300292969, 23.816854476929, 0, 0, 90},
    {2161.1982421875, -1167.6115722656, 23.81520652771, 0, 0, 90},
    {2160.751953125, -1172.7290039063, 23.819984436035, 0, 0, 90},
    {2160.8679199219, -1177.7672119141, 23.816753387451, 0, 0, 90},
    {2161.0400390625, -1182.5433349609, 23.817918777466, 0, 0, 90},
    {2160.7436523438, -1187.3402099609, 23.819089889526, 0, 0, 90},
    {2161.4279785156, -1191.7807617188, 23.820175170898, 0, 0, 90},
    {2161.7133789063, -1196.6436767578, 23.862409591675, 0, 0, 90},
    {2161.2258300781, -1157.7612304688, 23.84143447876, 0, 0, 90},

    {2148.9135742188, -1133.9088134766, 25.567834854126, 0, 0, 270},
    {2148.5546875, -1138.4818115234, 25.488945007324, 0, 0, 270},
    {2148.4133300781, -1143.1497802734, 24.978689193726, 0, 0, 270},
    {2148.294921875, -1147.7744140625, 24.465311050415, 0, 0, 270},
    {2148.2353515625, -1152.6044921875, 23.937337875366, 0, 0, 270},
    {2147.6496582031, -1157.3684082031, 23.845174789429, 0, 0, 270},
    {2147.8662109375, -1161.7802734375, 23.8203125, 0, 0, 270},
    {2147.9294433594, -1166.1296386719, 23.8203125, 0, 0, 270},
    {2147.8747558594, -1170.9593505859, 23.8203125, 0, 0, 270},
    {2147.7468261719, -1175.6798095703, 23.8203125, 0, 0, 270},
    {2147.9387207031, -1180.3111572266, 23.8203125, 0, 0, 270},
    {2147.8500976563, -1185.0539550781, 23.8203125, 0, 0, 270},
    {2147.8986816406, -1189.8778076172, 23.8203125, 0, 0, 270},
    {2147.6645507813, -1194.6234130859, 23.835622787476, 0, 0, 270},
    {2147.8759765625, -1199.0772705078, 23.891159057617, 0, 0, 270},
    {2148.4296875, -1203.4699707031, 23.847724914551, 0, 0, 270},
}

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

function buyVehicle(buyerElement, vehicleID, vehicleCost, factionID)
    assert(getElementType(buyerElement) == "player", "Bad argument @ 'buyVehicle' [expected player at argument 1, got "..type(buyerElement).."]")
    assert(type(vehicleID) == "number", "Bad argument @ 'buyVehicle' [expected number at argument 2, got "..type(vehicleID).."]")
    assert(type(vehicleCost) == "number", "Bad argument @ 'buyVehicle' [expected number at argument 3, got "..type(vehicleCost).."]")

    

    if factionID and tonumber(factionID) then
            exports.sarp_groups:setGroupMoney(factionID, -vehicleCost)
            local random = math.random(1, #parkingPositions)
            local position = {parkingPositions[random][1], parkingPositions[random][2], parkingPositions[random][3], parkingPositions[random][4], parkingPositions[random][5], parkingPositions[random][6], 0, 0}
            exports["sarp_vehicles"]:makeVehicle(vehicleID, buyerElement, factionID, position, 255, 255, 255)
            exports["sarp_alert"]:showAlert(buyerElement, "info", "Gratulálok! Sikeresen megvetted a járművet " .. exports.sarp_groups:getGroupPrefix(factionID) .. " részére!", "A jármű oda kint a parkolóban vár.")
        
    else
        if exports["sarp_core"]:takeMoney(buyerElement, vehicleCost, "new vehicle") then
            local random = math.random(1, #parkingPositions)
            local position = {parkingPositions[random][1], parkingPositions[random][2], parkingPositions[random][3], parkingPositions[random][4], parkingPositions[random][5], parkingPositions[random][6], 0, 0}
            exports["sarp_vehicles"]:makeVehicle(vehicleID, buyerElement, 0, position, 255, 255, 255)
            exports["sarp_alert"]:showAlert(buyerElement, "info", "Gratulálok! Sikeresen megvetted a járművet!", "A jármű oda kint a parkolóban vár.")
        else
            exports["sarp_alert"]:showAlert(buyerElement, "error", "Sajnálom, de nicns elengenőd pénzed", "ahhoz, hogy megvedd ezt a járművet.")
        end
    end
end
registerEvent("sarp_carshopS:buyVehicle", root, buyVehicle)

