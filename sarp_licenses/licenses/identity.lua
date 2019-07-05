

Documents["Identity"] = function(data)
    local date = getRealTime(data["expire"])
    dxDrawImage(docX, docY, docW, docH, "files/identity.png")   
    dxDrawText(data["name"], docX + 220, docY + 57, docW + docX - 10, docH + docY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "left", "top") 
    dxDrawText(data["birth"], docX + 315, docY + 87, docW + docX - 10, docH + docY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "left", "top") 
    dxDrawText("Amerikai", docX + 345, docY + 122, docW + docX - 10, docH + docY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "left", "top") 
    dxDrawText(date.year + 1900 .. ". " .. string.format("%02d", date.month + 1) .. ". " .. string.format("%02d", date.monthday) .. ".", docX + 275, docY + 156, docW + docX - 10, docH + docY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "left", "top") 

    local signW, signH = 210, 30
    local signX, signY = docX + 33, docY + 195

    dxDrawText(data["name"], signX, signY + 3, signX + signW, signY + signH, tocolor(190, 190, 190, 255), 1, fonts.lunabar, "center", "top") 

    local picW, picH = 110, 123
    local picX, picY = docX + 32, docY + 57

    dxDrawRectangle(picX, picY, picW, picH, tocolor(100, 100, 100, 100))
end