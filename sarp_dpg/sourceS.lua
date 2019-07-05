local resources = {
	"sarp_whitelist",

	"sarp_anticheat",
	"sarp_database",
	"sarp_core",

	"sarp_assets",
	"sarp_ui",

	"sarp_logs",

	"sarp_hud",
	"sarp_admin",
	
	"sarp_removelv",
	"sarp_water",
	"sarp_maps",

	"sarp_mods_veh",
	"sarp_mods_skin",
	"sarp_mods_obj",

	"sarp_textures",
	"sarp_workaround",
	"sarp_controls",
	"sarp_alert",
	"sarp_3dview",
	"sarp_boneattach",
	"sarp_weather",

	"sarp_inventory",
	"sarp_interiors",
	"sarp_vehicles",

	"sarp_nametag",
	"sarp_jobs",
	"sarp_dog",
	"sarp_chat",
	"sarp_billiard",
	"sarp_achievements",
	"sarp_dashboard",
	"sarp_damage",
	"sarp_carshop",
	"sarp_licenses",
	"sarp_bank",
	"sarp_loader",
	"sarp_npcs",
	"sarp_shop",
	"sarp_groups",
	"sarp_groupscripting",
	"sarp_crosshair",
	"sarp_weapons",
	"sarp_newdebug",
	"sarp_performance",
	"sarp_interaction",
	"sarp_fuel",
	"sarp_minigames",
	"sarp_death",
	"sarp_tempomat",
	"sarp_paintjobs",
	"sarp_remove",

	"sarp_job_icecream",
	"sarp_job_windowcleaner",
	"sarp_job_storekeeper",
	"sarp_job_server",
	"sarp_job_miner",

	"sarp_accounts",

	"sarp_tipps",
	"sarp_ticket",
	"sarp_animation",
	"sarp_skinshop"
}

addEventHandler("onResourceStart", getResourceRootElement(),
	function()
		for i = 1, #resources do
			local resName = resources[i]
			local res = getResourceFromName(resName)
			if res then
				setTimer(
					function()
						local meta = xmlLoadFile(":" .. resName .. "/meta.xml")
						if meta then
							local dpg = xmlFindChild(meta, "download_priority_group", 0)
							local download_priority_group = 0 - i
							if dpg then
								xmlNodeSetValue(dpg, tostring(download_priority_group))
							else
								dpg = xmlCreateChild(meta, "download_priority_group")
								xmlNodeSetValue(dpg, tostring(download_priority_group))
							end
							print(resName .. " download_priority_group changed to -> " .. tostring(download_priority_group))
							xmlSaveFile(meta)
							xmlUnloadFile(meta)
						end
					end,
				1000, 1)
			end
		end
	end)