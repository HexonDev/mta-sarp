Documents = {}

screenX, screenY = guiGetScreenSize()

docW, docH = 512, 256
docX, docY = (screenX - docW) / 2, (screenY - docH) / 2

local docType = nil
local docData = nil
local docVisible = false

function showDocument(documentType, documentData)
    if Documents[documentType] and documentData then
        docType = documentType
        docData = documentData
        docVisible = true
    else
        docType = nil
        docData = nil
        docVisible = false
    end
end
addEvent("sarp_licensesC:showDocument", true)
addEventHandler("sarp_licensesC:showDocument", root, showDocument)

addEventHandler("onClientRender", root, function()
    if docVisible and docType and docData then
        if Documents[docType] then
            Documents[docType](docData)
        end
    end
end)

