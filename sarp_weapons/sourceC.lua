local weaponDatas = {
	[22] = {
		fileName = "colt45",
		model = 346
	},
	[23] = {
		fileName = "silenced",
		model = 347
	},
	[24] = {
		fileName = "desert_eagle",
		model = 348,
		shoot_sound = "deagle_shoot.wav",
		reload_sound = "deagle_reload.wav"
	},
	[33] = {
		fileName = "cuntgun",
		model = 357,
		shoot_sound = "rifle_shoot.wav",
		reload_sound = "rifle_reload.wav"
	},
	[34] = {
		fileName = "sniper",
		model = 358,
		shoot_sound = "rifle_shoot.wav",
		reload_sound = "rifle_reload.wav"
	},
	[6] = {
		fileName = "pickaxe",
		model = 337
	}
}

for k,v in pairs(weaponDatas) do
	engineImportTXD(engineLoadTXD("files/models/" .. v.fileName .. ".txd"), v.model)
	engineReplaceModel(engineLoadDFF("files/models/" .. v.fileName .. ".dff"), v.model)
end

local fireSoundDistance = 75
local explodeSoundDistance = 150

setWorldSoundEnabled(5, 7, false, true)
setWorldSoundEnabled(5, 6, false, true)
setWorldSoundEnabled(5, 52, false, true)
setWorldSoundEnabled(5, 53, false, true)

addEventHandler("onClientPlayerWeaponFire", getRootElement(),
	function (weapon, _, ammoInClip)
		if weaponDatas[weapon] then
			local playerX, playerY, playerZ = getElementPosition(source)
			local playerDimension = getElementDimension(source)
		
			if weaponDatas[weapon].shoot_sound then
				local shootSound = weaponDatas[weapon].shoot_sound
				
				if weapon == 24 and getElementData(source, "tazerState") then
					shootSound = "taser_shoot.wav"
				end

				local soundEffect = playSound3D("files/sounds/" .. shootSound, playerX, playerY, playerZ)
				setSoundMaxDistance(soundEffect, fireSoundDistance)
				setElementDimension(soundEffect, playerDimension)
			end
		end
	end
)

addEventHandler("onClientExplosion", getRootElement(),
	function (x, y, z, explosionType)
		if explosionType == 0 then
			local soundEffect = playSound3D("files/sounds/explosion1.wav", x, y, z)
			setSoundMaxDistance(soundEffect, explodeSoundDistance)
			setElementDimension(soundEffect, getElementDimension(localPlayer))
		elseif explosionType == 4 or explosionType == 5 or explosionType == 6 or explosionType == 7 then
			local soundEffect = playSound3D("files/sounds/explosion2.wav", x, y, z)
			setSoundMaxDistance(soundEffect, explodeSoundDistance)
			setElementDimension(soundEffect, getElementDimension(localPlayer))
		end
	end
)