local platebackTexture = dxCreateTexture("files/plateback.png", "dxt3")

local texturesTable = {
	bloodpool_64 = dxCreateTexture("files/bloodpool_64.png", "dxt3"),
	bubbles = dxCreateTexture("files/bubbles.png", "dxt3"),
	--coronastar = dxCreateTexture("files/coronastar.png", "dxt3"),
	fireball6 = dxCreateTexture("files/fireball6.png", "dxt3"),
	smoke = dxCreateTexture("files/smoke.png", "dxt3"),
	smokeII_3 = dxCreateTexture("files/smokeII_3.png", "dxt3"),
	vehiclelights128 = dxCreateTexture("files/vehiclelights128.png", "dxt3"),
	vehiclelightson128 = dxCreateTexture("files/vehiclelightson128.png", "dxt3"),
	vehicleshatter128 = dxCreateTexture("files/vehicleshatter128.png", "dxt3"),
	lamp_shad_64 = dxCreateTexture("files/lamp_shad_64.png", "dxt3"),
	headlight = dxCreateTexture("files/headlight.png", "dxt3"),
	headlight1 = dxCreateTexture("files/headlight1.png", "dxt3"),
	collisionsmoke = dxCreateTexture("files/collisionsmoke.png", "dxt3"),
	particleskid = dxCreateTexture("files/particleskid.png", "dxt3"),
	plateback = platebackTexture,
	plateback1 = platebackTexture,
	plateback2 = platebackTexture,
	plateback3 = platebackTexture,
	hospwin1_LAe = dxCreateTexture("files/hospwin1_LAe.png", "dxt3"),
	hospwin2_LAe = dxCreateTexture("files/hospwin2_LAe.png", "dxt3"),
	hospwin3_LAe = dxCreateTexture("files/hospwin3_LAe.png", "dxt3"),
	carparkwall1_256 = dxCreateTexture("files/carparkwall1_256.png", "dxt3"),
	hospwall1 = dxCreateTexture("files/hospwall1.png", "dxt3"),
	--marinadoor1_256 = dxCreateTexture("files/marinadoor1_256.png", "dxt3"),
}

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		for k, v in pairs(texturesTable) do
			local shader = dxCreateShader("files/texturechanger.fx")
			if shader then
				dxSetShaderValue(shader, "gTexture", v)
				engineApplyShaderToWorldTexture(shader, k)
			end
		end
	end
)