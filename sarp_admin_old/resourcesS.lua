addEventHandler("onResourceStop", root, function(res)
	exports.sarp_core:sendMessageToAdmins("Resource sikeresen leállítva. #ff4646(" .. getResourceName(res) .. ")", 8)
end)

addEventHandler("onResourceStart", root, function(res)
	exports.sarp_core:sendMessageToAdmins("Resource sikeresen elindítva. #7cc576(" .. getResourceName(res) .. ")", 8)
end)