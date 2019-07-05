
addEventHandler("onClientResourceStart", getResourceRootElement(), function()
	txd = engineLoadTXD ( "dog.txd" )
	engineImportTXD ( txd, 9 )
	dff = engineLoadDFF ( "dog.dff" )
	engineReplaceModel ( dff, 9 )
	
end)

local dogSounds = {
	["barking"] = {"ugat.", "me", "sounds/dogwhof.ogg", 40},
	["whistle"] = {"fütyül.", "me", "sounds/dogwhistle.ogg", 20},
	["attack"] = {"megtámadott valakit.", "me", "sounds/attack.ogg", 15},
	["stroking"] = {"megsimagtatja a kutyát.", "me", "sounds/stroking.ogg", 10},
}

local activeSounds = {}

function dogPlaySound(action)
	executor = source
	if not isElement(executor) then
		return
	end

	if not action then
		return
	end

	if dogSounds[action] then
		local exeX, exeY, exeZ = getElementPosition(executor)
		dogSound = playSound3D(dogSounds[action][3], exeX, exeY, exeZ)
		--attachElements(dogSound, exec)
		setSoundMaxDistance(dogSound, dogSounds[action][4])
		triggerServerEvent("sendLocalDogAction", executor, executor, dogSounds[action][2], dogSounds[action][1])
	end
end
addEvent("dogPlaySound", true)
addEventHandler("dogPlaySound", root, dogPlaySound)