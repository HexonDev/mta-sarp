function showAlert(element, type, msg, msg2, imgPath, color)
	if isElement(element) then
		triggerClientEvent(element, "showAlertClient", element, type, msg, msg2, imgPath, color)
	end
end