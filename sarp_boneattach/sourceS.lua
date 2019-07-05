local attachmentsData = {}
isFromServerSide = true

addEvent("requestAttachmentData", true)
addEventHandler("requestAttachmentData", getRootElement(),
	function ()
		if attachmentsData[client] then
			return
		end
		
		triggerClientEvent(client, "receiveAttachmentData", root, attached_ped, attached_bone, attached_x, attached_y, attached_z, attached_rx, attached_ry, attached_rz)
		attachmentsData[client] = true
	end
)

addEventHandler("onPlayerQuit", getRootElement(),
	function ()
		attachmentsData[source] = nil
	end
)