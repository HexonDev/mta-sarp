addEvent("onTazerShoot", true)
addEventHandler("onTazerShoot", getRootElement(),
	function (targetPlayer)
		if isElement(source) and isElement(targetPlayer) then
			if not getElementData(targetPlayer, "player.Tazed") then
				setElementData(targetPlayer, "player.Tazed", true)

				exports.sarp_controls:toggleControl(targetPlayer, {"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, false)
				setPedAnimation(targetPlayer, "ped", "FLOOR_hit_f", -1, false, false, true)

				setTimer(
					function(player)
						if isElement(player) then
							setPedAnimation(player, "FAT", "idle_tired", -1, true, false, false)

							setTimer(
								function(player)
									if isElement(player) then
										exports.sarp_controls:toggleControl(player, {"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, true)
										setPedAnimation(player, false)

										setElementData(player, "player.Tazed", false)
									end
								end,
							10000, 1, player)
						end
					end,
				20000, 1, targetPlayer)

				exports.sarp_chat:sendLocalMeAction(source, "lesokkolt valakit. ((" .. getElementData(targetPlayer, "visibleName"):gsub("_", " ") .. "))")
			end
		end
	end
)