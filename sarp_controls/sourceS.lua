function toggleControl(player, controls, enabled)
	triggerClientEvent(player, "toggleControl", player, controls, enabled, getResourceName(sourceResource))
end