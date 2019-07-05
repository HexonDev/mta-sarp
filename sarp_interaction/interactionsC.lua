Interaction.Interactions = {}

--{"Bezárás", ":sarp_assets/images/sarplogo_big.png", "function"},

function addInteraction(type, model, name, image, executeFunction)
	if not Interaction.Interactions[type][model] then
		Interaction.Interactions[type][model] = {} 
		print("Tábla nem létezik, létrehozás...")        
	end
 
	table.insert(Interaction.Interactions[type][model], {name, image, executeFunction})
	print(name .. " interakció beszúrva")
end

addEventHandler("onClientResourceStart", resourceRoot, function()

end)

function getInteractions(element)
	local interactions = {}
	local type = getElementType(element)
	local model = getElementModel(element)

	table.insert(interactions, {"Bezárás", ":sarp_assets/images/cross_x.png",
		function ()
			Interaction.Close()
		end
	})

	if type == "player" then
		if exports.sarp_groups:isPlayerHavePermission(localPlayer, "cuff") then
			if getElementData(element, "player.Cuffed") then
				if getElementData(element, "player.Grabbed") then
					table.insert(interactions, {"Vezetőszár levétele", "icons/uncuff.png",
						function (player, target)
							triggerServerEvent("grabPlayerOff", localPlayer, target)
						end
					})
				else
					table.insert(interactions, {"Vezetőszár rátétele", "icons/cuff.png",
						function (player, target)
							triggerServerEvent("grabPlayer", localPlayer, target)
						end
					})

					table.insert(interactions, {"Bilincs levétele", "icons/uncuff.png",
						function (player, target)
							triggerServerEvent("cuffPlayer", localPlayer, target)
						end
					})
				end
			else
				table.insert(interactions, {"Megbilincselés", "icons/cuff.png",
					function (player, target)
						triggerServerEvent("cuffPlayer", localPlayer, target)
					end
				})
			end
		end

		table.insert(interactions, {"Ruházat átvizsgálása", "icons/detector.png",
			function (player, target)
				triggerServerEvent("friskPlayer", localPlayer, target)
			end
		})

		if exports.sarp_groups:isPlayerHavePermission(localPlayer, "heal") then
			table.insert(interactions, {"Megvizsgálás", "icons/heart.png",
				function (player, target)
					triggerEvent("examinePlayerBody", localPlayer, target)
				end
			})

			if not isPedHeadless(element) then
				if getElementHealth(element) <= 20 and getElementHealth(element) > 0 then -- ha menthető állapotban van (ájult vagy elő-halál, össz. 10 perc)
					table.insert(interactions, {"Felsegítés", "icons/heart.png",
						function (player, target)
							triggerEvent("tryToHelpUpPerson", localPlayer, target)
						end
					})
				else -- ha nem ájult, ellehessen látni a sérültet
					table.insert(interactions, {"Gyógyítás", "icons/heart.png",
						function (player, target)
							triggerEvent("tryToHealPerson", localPlayer, target)
						end
					})
				end
			end
		end

		if getElementData(element, "player.Cuffed") or getElementData(element, "player.Grabbed") then
			table.insert(interactions, {"Berakás a járműbe", "icons/heart.png",
				function (player, target)
					triggerEvent("sarp_detainC:detainMode", localPlayer, element)
				end
			})
		end
	elseif type == "vehicle" then
		table.insert(interactions, {"Csomagtartó", "icons/trunk.png",
			function (player, target)
				if getPedOccupiedVehicle(localPlayer) then
					exports.sarp_hud:showInfobox("error", "Járműben ülve nem nézhetsz bele a csomagtartóba!")
				else
					if getVehicleType(element) == "Automobile" then
						if not exports.sarp_inventory:bootCheck(element) then
							exports.sarp_hud:showInfobox("error", "Csak a jármű csomagtartójánál állva nézhetsz bele a csomagtérbe!")
							return
						end
					end

					triggerServerEvent("requestItems", localPlayer, element, tonumber(getElementData(element, "vehicle.dbID")), "vehicle", getElementsByType("player", getRootElement(), true))
				end
			end
		})

		if getElementData(element, "vehicle.locked") then
			table.insert(interactions, {"Jármű kinyitása", "icons/unlock.png",
				function (player, target)
					triggerServerEvent("toggleVehicleLock", localPlayer, element, getElementsByType("player", getRootElement(), true), {getPedTask(localPlayer, "primary", 3)})
				end
			})
		else
			table.insert(interactions, {"Jármű bezárása", "icons/lock.png",
				function (player, target)
					triggerServerEvent("toggleVehicleLock", localPlayer, element, getElementsByType("player", getRootElement(), true), {getPedTask(localPlayer, "primary", 3)})
				end
			})
		end

		if exports.sarp_groups:isPlayerHavePermission(localPlayer, "wheelClamp") then
			if getElementData(element, "vehicle.wheelClamp") then
				table.insert(interactions, {"Kerékbilincs leszedése", "icons/wheelclamp.png",
					function (player, target)
						local cX, cY, cZ = getVehicleComponentPosition(target, "wheel_lf_dummy", "world")
						if getDistanceBetweenPoints3D(cX, cY, cZ, getElementPosition(localPlayer)) <= 1.5 then
							setElementData(target, "vehicle.wheelClamp", false)
							exports.sarp_groupscripting:startWheelClampingAnimation(getElementData(element, "vehicle.wheelClamp"))
						else
							exports.sarp_hud:showAlert("error", "Túl messze vagy a bal első keréktől")
						end
					end
				})
			else
				table.insert(interactions, {"Kerékbilincs felrakása", "icons/wheelclamp.png",
					function (player, target)
						local cX, cY, cZ = getVehicleComponentPosition(target, "wheel_lf_dummy", "world")
						if getDistanceBetweenPoints3D(cX, cY, cZ, getElementPosition(localPlayer)) <= 1.5 then
							setElementData(target, "vehicle.wheelClamp", true)
							exports.sarp_groupscripting:startWheelClampingAnimation(getElementData(element, "vehicle.wheelClamp"))
						else
							exports.sarp_hud:showAlert("error", "Túl messze vagy a bal első keréktől")
						end
					end
				})
			end
		end

		if model == 407 or model == 544 then
			--if exports.sarp_groups:isPlayerHavePermission(localPlayer, "wheelClamp") then
				if not getElementData(localPlayer, "player.hasCutter") then
					table.insert(interactions, {"Hidraulikus vágó kivétele", "icons/wheelclamp.png",
						function (player, target)
							triggerServerEvent("sarp_cutterS:giveCutter", localPlayer)
						end
					})
				else
					table.insert(interactions, {"Hidraulikus vágó visszarakása", "icons/wheelclamp.png",
						function (player, target)
							triggerServerEvent("sarp_cutterS:takeCutter", localPlayer)
						end
					})
				end

			--end
		end

		if exports.sarp_service:isElementInServiceZone(element) then
			table.insert(interactions, {"Jármű megszerelése", "icons/icon.png",
				function (player, target)
					triggerEvent("sarp_serviceC:showService", element, element)
				end
			})
		end
	
	elseif type == "object" then
		if getElementData(element, "isFactoryObject") then
			local tempActions = exports.sarp_job_storekeeper:getCurrentInteractionList(model)

			for k,v in pairs(tempActions) do
				table.insert(interactions, v)
			end

			tempActions = nil
		elseif getElementData(element, "isFuelPump") then
			local tempActions = exports.sarp_fuel:getCurrentInteractionList(model)

			for k,v in pairs(tempActions) do
				table.insert(interactions, v)
			end

			tempActions = nil
		elseif model == exports.sarp_job_windowcleaner:getElevatorID() then
			table.insert(interactions, {"Beszállás", "icons/lock.png",
				function (player, target)
					triggerEvent("enterElevator", localPlayer)
				end
			})
		elseif getElementData(element, "poolTableId") then
			local tempActions = exports.sarp_billiard:getCurrentInteractionList()

			for k,v in pairs(tempActions) do
				table.insert(interactions, v)
			end

			tempActions = nil
		end
	end
	
	return interactions
end