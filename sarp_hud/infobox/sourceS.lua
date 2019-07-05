function showInfobox(element, type, msg, msg2, imgPath, color)
	if isElement(element) then
		triggerClientEvent(element, "showInfobox", element, type, msg, msg2, imgPath, color)
	end
end