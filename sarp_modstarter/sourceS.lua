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
	--"sarp_dog",
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

local failedToLoad = false

addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		local tickCount = getTickCount()

		for i = 1, #resources do
			local resname = getResourceFromName(resources[i])
			local state = startResource(resname)

			if resname == "sarp_database" and not state then
				failedToLoad = true
				break
			end
		end

		if failedToLoad then
			print("[SARP]: Nincs kapcsolat az adatbázissal ezért a resourcek nem indultak el.")
		else
			print("[SARP]: Mod started in " .. getTickCount() - tickCount .. " ms.")
		end
	end
)

addEventHandler("onResourceStop", getResourceRootElement(),
	function ()
		for i = #resources, 1, -1 do
			stopResource(getResourceFromName(resources[i]))
		end
	end
)

function getResourceList()
	return resources
end