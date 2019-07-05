
addCommandHandler("anim", function(player, cmd, animName)
	if not animName then
		outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Anim Név]", player, 0, 0, 0, true)
		outputChatBox(exports.sarp_core:getServerTag("info") .. "Animációk listája: /animlist", player, 0, 0, 0, true)
	else
		if not animations[animName] then
			outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs ilyen animáció", player, 0, 0, 0, true)
			return
		end

		playAnimation(player, animName)
	end
end)

function playAnimation(player, animName)
	setPedAnimation(player, unpack(animations[animName]))
	outputChatBox(exports.sarp_core:getServerTag("info") .. "Animáció befejezése: /stopanim", player, 0, 0, 0, true)
end
addEvent("sarp_animationS:playAnimation", true)
addEventHandler("sarp_animationS:playAnimation", root, playAnimation)

addCommandHandler("stopanim", function(player, cmd)
	setPedAnimation(player)
end)

