local screenX, screenY = guiGetScreenSize()
local screenX2, screenY2 = screenX / 2, screenY / 2

local snowShaders = {}
local snowTextures = {}
local snowFlakes = {}

local winterModeState = false
local snowGroundShader, snowTreesShader, snowNaughtyTreesShader
local nextCheckTime = 0

local snowFlakeTexture
local flakeBoxWidth, flakeBoxDepth, flakeBoxHeight, flakeBoxWidthDoubled, flakeBoxDepthDoubled = 4, 4, 4, 8, 8
local worldFlakePosition = {0, 0, 0}
local removeFlakes = nil
local snowCount = 1

local availableTextures = {
	{"craproad3_LAe", "snow.dds"},
	{"ws_traingravel", "snow.dds"},
	{"plaintarmac1", "snow.dds"},
	{"trainground3", "snow.dds"},
	{"trainground1", "snow.dds"},
	{"brick", "snow.dds"},
	{"Heliconcrete", "snow.dds"},
	{"alleygroundb256", "snow.dds"},
	{"grasspatch_64HV", "snow.dds"},
	{"dirtKB_64HV", "snow.dds"},
	{"pavetilealley256128", "snow.dds"},
	{"backalley3_LAe", "snow.dds"},
	{"backalley1_LAe", "snow.dds"},
	{"comptwall15", "snow.dds"},
	{"rufwaldock1", "snow.dds"},
	{"yardgrass1", "snow.dds"},
	{"yardgrass2", "snow.dds"},
	{"sidewgrass4", "snow.dds"},
	{"sidewgrass_fuked", "snow.dds"},
	{"tarmcplaing_bank", "snow.dds"},
	{"cos_hiwayout_256", "snow.dds"},
	{"pavemiddirt_law", "snow.dds"},
	{"golf_heavygrass", "snow.dds"},
	{"grassdry_128HV", "snow.dds"},
	{"sjmscorclawn", "snow.dds"},
	{"newgrnd1brn_128", "snow.dds"},
	{"ws_rooftarmac1", "snow.dds"},
	{"brickred", "snow.dds"},
	{"brickred2", "snow.dds"},
	{"indund_64", "snow.dds"},
	{"concretemanky", "snow.dds"},
	{"dirt64b2", "snow.dds"},
	{"dirtgaz64b", "snow.dds"},
	{"grassdirtblend", "snow.dds"},
	{"grasstype7", "snow.dds"},
	{"alley256", "snow.dds"},
	{"Grass", "snow.dds"},
	{"boardwalk_la", "snow.dds"},
	{"LAroad_centre1", "snow.dds"},
	{"concretedust2_256128", "snow.dds"},
	{"GB_nastybar08", "snow.dds"},
	{"sw_sand", "snow.dds"},
	{"luxorwall02_128sandblend", "snow.dds"},
	{"greyground256sand", "snow.dds"},
	{"sjmcargr", "snow.dds"},
	{"GB_nastybar07", "snow.dds"},
	{"Bow_Abpave_Gen", "snow.dds"},
	{"grassdeep2", "snow.dds"},
	{"concretenewb256", "snow.dds"},
	{"backstagefloor1_256", "snow.dds"},
	{"snpdwargrn1", "snow.dds"},
	{"smjlahus28", "snow.dds"},
	{"lasjmslumwall", "snow.dds"},
	{"sjmlahus28", "snow.dds"},
	{"greyground256128", "snow.dds"},
	{"ws_carparknew2a", "snow.dds"},
	{"sjmndukwal3", "snow.dds"},
	{"sandnew_law", "snow.dds"},
	{"sandstonemixb", "snow.dds"},
	{"Grass_128HV", "snow.dds"},
	{"greyground256", "snow.dds"},
	{"bathtile01_int", "snow.dds"},
	{"ws_carpark2", "snow.dds"},
	{"ws_carpark1", "snow.dds"},
	{"stones256", "snow.dds"},
	{"grifnewtex1x_LAS", "snow.dds"},
	{"sjmscorclawn3", "snow.dds"},
	{"Grass_dirt_64HV", "snow.dds"},
	{"carlot1", "snow.dds"},
	{"crazypave", "snow.dds"},
	{"concretenewgery256", "snow.dds"},
	{"concretebigc256128", "snow.dds"},
	{"trainground2", "snow.dds"},
	{"concretebig4256128", "snow.dds"},
	{"stormdrain7", "snow.dds"},
	{"sl_sfngrssdrt01", "snow.dds"},
	{"sl_sfngrass01", "snow.dds"},
	{"dirty256", "snow.dds"},
	{"grassdeep1", "snow.dds"},
	{"man_cellarfloor128", "snow.dds"},
	{"ws_carparknew2", "snow.dds"},
	{"ws_carparknew1", "snow.dds"},
	{"redbrickground256", "snow.dds"},
	{"sjmhoodlawn9s", "snow.dds"},
	{"conc_slabgrey_256128", "snow.dds"},
	{"mudyforest256", "snow.dds"},
	{"grasslong256", "snow.dds"},
	{"grassdead1", "snow.dds"},
	{"concretebig4256", "snow.dds"},
	{"sl_plazatile01", "snow.dds"},
	{"desmuddesgrsblend_sw", "snow.dds"},
	{"desertgravelgrass256", "snow.dds"},
	{"degreengrass", "snow.dds"},
	{"desmud", "snow.dds"},
	{"grassdeadbrn256", "snow.dds"},
	{"brngrss2stones", "snow.dds"},
	{"desgrassbrn", "snow.dds"},
	{"desgreengrass", "snow.dds"},
	{"grasspave256", "snow.dds"},
	{"grasstype4", "snow.dds"},
	{"Grass_dry_64HV", "snow.dds"},
	{"forestfloorbranch256", "snow.dds"},
	{"desgreengrassmix", "snow.dds"},
	{"desertgryard256", "snow.dds"},
	{"desertgravelgrassroad", "snow.dds"},
	{"sw_sandgrass", "snow.dds"},
	{"sw_grass01", "snow.dds"},
	{"sw_grass01a", "snow.dds"},
	{"desertgryard256grs2", "snow.dds"},
	{"grassgrnbrn256", "snow.dds"},
	{"sw_crops", "snow.dds"},
	{"sw_grassB01", "snow.dds"},
	{"Bow_church_dirt_to_grass_side_t", "snow.dds"},
	{"Bow_church_grass_gen", "snow.dds"},
	{"sl_plazatile02", "snow.dds"},
	{"greytile_LA", "snow.dds"},
	{"Bow_church_grass_alt", "snow.dds"},
	{"ws_hextile", "snow.dds"},
	{"sl_LAbedingsoil", "snow.dds"},
	{"sl_flagstone1", "snow.dds"},
	{"badmarb1_LAn", "snow.dds"},
	{"mono2_sfe", "snow.dds"},
	{"mono1_sfe", "snow.dds"},
	{"grassgrn256", "snow.dds"},
	{"fancy_slab128", "snow.dds"},
	{"law_gazwhitefloor", "snow.dds"},
	{"backstageceiling1_128", "snow.dds"},
	{"grasstype10", "snow.dds"},
	{"rooftiles2", "snow.dds"},
	{"boardwalk2_la", "snow.dds"},
	{"pierplanks_128", "snow.dds"},
	{"grasstype3", "snow.dds"},
	{"redcliffroof_LA", "snow.dds"},
	{"grassdeep256", "snow.dds"},
	{"tenniscourt1_256", "snow.dds"},
	{"Grass_lawn_128HV", "snow.dds"},
	{"forestfloor256", "snow.dds"},
	{"forestfloorgrass", "snow.dds"},
	{"grassdead1blnd", "snow.dds"},
	{"desegravelgrassroadLA", "snow.dds"},
	{"vegaspavement2_256", "pave2.dds"},
	{"desgreengrasstrckend", "snow.dds"},
	{"cw2_mountdirt2grass", "snow.dds"},
	{"des_dirt2grass", "snow.dds"},
	{"des_dirt2track", "snow.dds"},
	{"des_dirt2", "snow.dds"},
	{"cw2_mountdirt", "snow.dds"},
	{"sw_copgrass01", "snow.dds"},
	{"des_dirt1Grass", "snow.dds"},
	{"des_dirt1", "snow.dds"},
	{"desgrassbrn_grn", "snow.dds"},
	{"grasstype4", "snow.dds"},
	{"sw_dirt01", "snow.dds"},
	{"des_dirt2", "snow.dds"},
	{"easykerb", "snow.dds"},
	{"bow_church_dirt", "snow.dds"},
	{"bow_church_dirt_lod", "snow.dds"},
	{"ws_rotten_concrete1", "snow.dds"},
	{"ws_rotten_concrete1lod", "snow.dds"},
	{"ws_tunnelwall2", "snow.dds"},
	{"grasslod", "snow.dds"},
	{"des_dirtgrassmix_grass4", "snow.dds"},
	{"grass4dirty", "snow.dds"},
	{"grass4dirtyb", "snow.dds"},
	{"dt_road2grasstype4", "snow.dds"},
	{"golf_fairway1", "snow.dds"},
	{"golf_fairway2", "snow.dds"},
	{"golf_greengrass", "snow.dds"},
	{"golf_gravelpath", "snow.dds"},
	{"ws_drysand", "snow.dds"},
	{"ws_drysand2grass", "snow.dds"},
	{"ws_wetdryblendsand", "snow.dds"},
	{"ws_wetsand", "snow.dds"},
	{"lodsfsbeach1", "snow.dds"},
	{"lodsfsbeach2", "snow.dds"},
	{"lodsfsbeach3", "snow.dds"},
	{"lodsfsbeach4", "snow.dds"},
	{"lodsfsbeach5", "snow.dds"},
	{"grass_128hv", "snow.dds"},
	{"sf_junction3", "snow.dds"},
	{"cobbles_kb_edge_128", "snow.dds"},
	{"gm_lacarpark1", "snow.dds"},
	{"gm_lacarpark2", "snow.dds"},
	{"laroad_offroad1", "snow.dds"},
	{"kbpavement_test", "snow.dds"},
	{"tarmacplain2_bank", "snow.dds"},
	{"stormdrain5_nt", "snow.dds"},
	{"bow_smear_cement", "snow.dds"},
	{"golf_hedge1", "snow.dds"},
	{"newhedgea", "snow.dds"},
	{"ws_airpt_concrete", "snow.dds"},
	{"ws_runwaytarmac", "snow.dds"},
	{"des_scrub1", "snow.dds"},
	{"des_scrub1_lod", "snow.dds"},
	{"des_scrub1_dirt1", "snow.dds"},
	{"des_dirt1", "snow.dds"},
	{"des_dirt1_lod", "snow.dds"},
	{"desstones_dirt1", "snow.dds"},
	{"des_dirt2dedgrass", "snow.dds"},
	{"des_dirt2blend", "snow.dds"},
	{"des_dirtgravel", "snow.dds"},
	{"des_ripplsand", "snow.dds"},
	{"grasstype5_desdirt", "snow.dds"},
	{"grasstype5_dirt", "snow.dds"},
	{"grasstype5_4", "snow.dds"},
	{"grasstype5", "snow.dds"},
	{"desertstones256", "snow.dds"},
	{"sandgrnd128", "snow.dds"},
	{"des_roadedge1", "snow.dds"},
	{"des_oldrunway", "snow.dds"},
	{"des_oldrunwayblend", "snow.dds"},
	{"tarmacplain_bank", "snow.dds"},
	{"snpedtest1", "pave2.dds"},
	{"snpedtest1BLND", "pave2.dds"},
	{"dt_road", "pave2.dds"},
	{"ws_freeway3", "pave2.dds"},
	{"cos_hiwaymid_256", "pave2.dds"},
	{"craproad7_LAe7", "pave2.dds"},
	{"craproad1_LAe", "pave2.dds"},
	{"hiwaymidlle_256", "pave2.dds"},
	{"dirttracksgrass256", "pave.dds"},
	{"dt_roadblend", "pave2.dds"},
	{"desmudtrail", "pave.dds"},
	{"desmudgrass", "snow.dds"},
	{"ws_carpark3", "pave2.dds"},
	{"desmudtrail2", "pave2.dds"},
	{"roadnew4blend_256", "pave2.dds"},
	{"sl_freew2road1", "pave2.dds"},
	{"sf_road5", "pave2.dds"},
	{"sfroad2_lod", "pave2.dds"},
	{"sjmloda991", "pave2.dds"},
	{"cuntroad01_law", "pave2.dds"},
	{"hiwayend_256", "pave2.dds"},
	{"vegasroad1_256", "pave2.dds"},
	{"vegasroad3_256", "pave2.dds"},
	{"vegasroad2_256", "pave2.dds"},
	{"tar_1line256hv", "junction.dds"},
	{"tar_1line256hvblend", "junction.dds"},
	{"roaddgrassblnd", "junction.dds"},
	{"tar_1line256hv_lod", "junction.dds"},
	{"tar_1line256hvblenddrt", "junction.dds"},
	{"tar_1line256hvblenddrtdot", "junction.dds"},
	{"des_dam_conc", "snow.dds"},
	{"grasstype4_mudblend", "snow.dds"},
	{"grasstype4_forestblend", "snow.dds"},
	{"sw_sandgrass4", "snow.dds"},
	{"desert_1line256", "junction.dds"},
	{"desert_1linetar", "junction.dds"},
	{"des_1line256", "junction.dds"},
	{"des_1lineend", "junction.dds"},
	{"crossing_law", "junction.dds"},
	{"dt_road_stoplinea", "junction.dds"},
	{"craproad2_LAe", "junction.dds"},
	{"lasunion994", "snow.dds"},
	{"aarprt8LAS", "junction.dds"},
	{"road_junction", "junction.dds"},
	{"sf_junction5", "junction.dds"},
	{"sjmhoodlawn4", "junction.dds"},
	{"macpath_lae", "junction.dds"},
	{"newpavement", "junction.dds"},
	{"dockpave_256", "junction.dds"},
	{"bow_abattoir_conc2", "pave.dds"},
	{"ws_alley_conc3", "pave.dds"},
	{"sjmhoodlawn41", "pave.dds"},
	{"sjmhoodlawn42", "pave.dds"},
	{"sf_pave6", "pave.dds"},
	{"sidewgrass2", "pave.dds"},
	{"sidewgrass3", "pave.dds"},
	{"sidewgrass1", "pave.dds"},
	{"sidewgrass5", "pave.dds"},
	{"scumtiles3_lae", "pave.dds"},
	{"sidewalk4_lae", "pave.dds"},
	{"starpave_law", "pave.dds"},
	{"starpaveb_law", "pave.dds"},
	{"sidelatino1_lae", "pave.dds"},
	{"pavebsand256", "pave2.dds"},
	{"roadnew4_256", "pave2.dds"},
	{"roadnew4_512", "pave2.dds"},
	{"ws_nicepave", "pave2.dds"},
	{"hiwayinside5_256", "pave2.dds"},
	{"des_dirttrack1", "dirttrack1.dds"},
	{"des_dirttrack1r", "dirttrack1.dds"},
	{"des_dirt2track", "dirttrack1.dds"},
	{"des_dirt2trackr", "dirttrack1.dds"},
	{"des_dirttrackl", "dirttrack1.dds"},
	{"des_dirttrackx", "dirttrack_xcross.dds"},
	{"crackedgroundb", "shadow.dds"},
	{"ws_traintrax1", "train.dds"},
	{"sf_tramline2", "tram.dds"},
	{"rocktq128_grass4blend", "rock.dds"},
	{"rocktq128", "rock.dds"},
	{"rocktq128_dirt", "rock.dds"},
	{"rocktq128blender", "rock.dds"},
	{"cw2_mountrock", "rock.dds"},
	{"rock_country128", "rock.dds"},
	{"golf_grassrock", "rock.dds"},
	{"redclifftop256", "rock.dds"},
	{"des_rocky1", "rock.dds"},
	{"des_rocky1_dirt1", "rock.dds"},
	{"des_redrockmid", "rock.dds"},
	{"des_redrockmidlod", "rock.dds"},
	{"des_redrock1", "rock.dds"},
	{"des_redrock2", "rock.dds"},
	{"des_redrockbot", "rock.dds"},
	{"sm_rock2_desert", "rock.dds"},
	{"des_yelrock", "rock.dds"},
	{"ws_tunnelwall1", "wall1.dds"},
	{"mountainskree_stones256", "snow.dds"},
	{"roucghstonebrtb", "shadow.dds"},
	{"grass_path_128hv", "snow.dds"},
	{"craproad6_lae", "pave2.dds"},
	{"craproad5_lae", "pave2.dds"},
	{"hiwayoutside_256", "snow.dds"},
	{"hiwayinside2_256", "snow.dds"},
	{"hiwayinside3_256", "snow.dds"},
	{"hiwayinside4_256", "snow.dds"},
	{"hiwayinside5_256", "snow.dds"},
	{"hiwayblend1_256", "snow.dds"},
	{"brngrss2stonesb", "snow.dds"},
	{"hiwayinsideblend1_256", "snow.dds"},
	{"hiwayinsideblend2_256", "snow.dds"},
	{"hiwaygravel1_256", "snow.dds"},
	{"hiwaygravel1_lod", "snow.dds"},
	{"blendpavement2b_256", "pave2.dds"},
	{"dustyconcrete", "snow.dds"},
	{"gravelground128", "snow.dds"},
	{"desgrasandblend", "snow.dds"},
	{"desgrasandblend_lod", "snow.dds"},
	{"sw_stonesgrass", "snow.dds"},
	{"sw_stones", "snow.dds"},
	{"des_dirt2 trackl", "dirttrack1.dds"},
	{"des_dirt2stones", "snow.dds"},
	{"des_quarryrdr", "snow.dds"},
	{"des_quarryrd", "dirttrack1.dds"},
	{"desgrns256", "rock.dds"},
	{"des_quarryrdl", "dirttrack1.dds"},
	{"tar_lineslipway", "junction.dds"},
	{"tar_1linefreewy", "junction.dds"},
	{"des_roadedge2", "snow.dds"},
	{"cs_rockdetail2", "rock.dds"},
	{"rocktbrn128", "rock.dds"},
	{"rocktbrn128", "rock.dds"},
	{"grassbrn2rockbrng", "rock.dds"},
	{"rocktbrn128blnd", "rock.dds"},
	{"desclifftypebsmix", "rock.dds"},
	{"desclifftypebsmixlod", "rock.dds"},
	{"sw_rockgrassb2", "rock.dds"},
	{"sw_rockgrassb2lod", "rock.dds"},
	{"sw_rockgrassb1", "rock.dds"},
	{"sw_rockgrassb1lod", "rock.dds"},
	{"dirtblendlit", "snow.dds"},
	{"dirtblendlitlod", "snow.dds"},
	{"sw_rockgrass1", "rock.dds"},
	{"sw_rockgrass1lod", "rock.dds"},
	{"retainwall1", "snow.dds"},
	{"rocktq128_forestblend", "rock.dds"},
	{"rocktq128_forestblend2", "rock.dds"},
	{"forest_rocks", "snow.dds"},
	{"cw2_mounttrailblank", "snow.dds"},
	{"cw2_mounttrail", "snow.dds"},
	{"tar_freewyleft", "junction.dds"},
	{"cw2_weeroad1", "pave.dds"},
	{"forestfloorblendded", "snow.dds"},
	{"forestfloor_sones256", "snow.dds"},
	{"ws_patchygravel", "snow.dds"},
	{"tar_freewyright", "snowroad2.dds"},
}

local snowGroundRemoveList = {
	"", "vehicle*", "?emap*", "?hite*", "*92*", "*wheel*", "*interior*", "*handle*", "*body*", "*decal*", "*8bit*",
	"*logos*", "*badge*", "*plate*", "*sign*", "headlight", "headlight1", "shad*", "coronastar", "tx*", "lod*",
	"cj_w_grad", "*cloud*", "*smoke*", "sphere_cj", "particle*", "*water*", "sw_sand", "coral", "unnamed", "chromelip", "chromelip2",
	"tirelowr1",
}

local snowTreesList = {
	"sm_des_bush*", "*tree*", "*ivy*", "*pine*", "veg_*", "*largefur*", "hazelbr*", "weeelm",
	"*branch*", "cypress*", "*bark*", "gen_log", "trunk5", "bchamae", "vegaspalm01_128", "iron",
	"hedgealphad1", "ahoodfence2", "oakleaf1", "oakleaf2", "cedar1", "cedar2", "bthuja1", "berrybush1",
	"stormdrain1_nt", "stormdrain2_nt", "stormdrain_lod", "lasrmd2_sjm", "lasrmd3_sjm", "dead_agave",
	"kbplanter_plants1", "dead_fuzzy", "sm_quarry_conv_belt", "sm_quarry_crusher1", "sm_quarry_crusher2",
	"hedge2", "hedge2lod", "aamanbev96x", "aamanbev96xlod"
}

local snowNaughtyTreesList = {
	"planta256", "plantb256", "sm_josh_leaf", "kbtree4_test", "trunk3", "newtreeleaves128", "ashbrnch", "pinelo128", "tree19mi",
	"lod_largefurs07", "veg_largefurs05","veg_largefurs06", "fuzzyplant256", "foliage256", "cypress1", "cypress2",
	"sm_agave_1", "sm_agave_2", "sm_agave_bloom", "sm_des_bush1", "sm_minipalm1", "kbtree3_test",
}

local snowballModel = 5630

local txd = engineLoadTXD("files/snowball.txd")
engineImportTXD(txd, snowballModel)

local dff = engineLoadDFF("files/snowball.dff")
engineReplaceModel(dff, snowballModel)

local playerBalls = {}
local throwedBalls = {}
local playerBallState = {}
local playerBallPower = {}

local throwStartTick = 0
local maxPower = 0.4
local maxPowerTime = 1000

function createSnowBall()
	if getElementDimension(localPlayer) ~= 0 then
		exports.sarp_hud:showInfobox("error", "Interiorban nem tudsz hógolyót gyúrni!")
	else
		setElementData(localPlayer, "snowballData", {0, 0})
	end
end
addCommandHandler("hogolyo", createSnowBall)
addCommandHandler("hógolyó", createSnowBall)

addEventHandler("onClientKey", getRootElement(),
	function (key, state)
		if key == "mouse1" and playerBallState[localPlayer] == 0 then
			if state then
				throwStartTick = getTickCount()
			else
				local power = getTickCount() - throwStartTick

				if power > maxPowerTime then
					power = maxPowerTime
				end

				power = power / maxPowerTime

				if power > maxPower then
					power = maxPower
				end

				setElementData(localPlayer, "snowballData", {1, power})
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		for k, v in pairs(throwedBalls) do
			if playerBallState[k] == 2 then
				local distance = 1
				local height = 0.05
				local radius = v.ballRadius

				if playerBallPower[k] == 1 then
					distance = 12
					height = 1
				elseif playerBallPower[k] > 0.8 then
					distance = 8
					height = 0.8
				elseif playerBallPower[k] > 0.6 then
					distance = 6
					height = 0.5
				elseif playerBallPower[k] > 0.4 then
					distance = 3
					height = 0.3
				elseif playerBallPower[k] > 0.2 then
					distance = 1
					height = 0.1
				end

				local power = distance * playerBallPower[k]
				local angle = math.rad(v.playerRotZ + 90)

				local x = v.playerPosX + math.cos(angle) * radius
				local y = v.playerPosY + math.sin(angle) * radius
				local z = v.playerPosZ + 9 * height + (-0.01 * (radius / power - 30) ^ 2) * height

				local ground = getGroundPosition(v.ballPosX, v.ballPosY, v.ballPosZ + 1)
				local diff = v.ballPosZ - ground

				if diff > 0 then
					v.ballPosX = x
					v.ballPosY = y
					v.ballPosZ = z
					v.ballRadius = v.ballRadius + 0.75 * power + (1 - height) * 0.75

					setElementPosition(playerBalls[k], x, y, z)
				else
					setElementPosition(playerBalls[k], v.ballPosX, v.ballPosY, ground + 0.1)

					playerBallState[k] = nil
					throwedBalls[k] = nil
					playerBallPower[k] = nil
				end
			end
		end
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		for k, v in pairs(playerBalls) do
			if playerBallState[k] and (playerBallState[k] == 0 or playerBallState[k] == 1) then
				local bonePosX, bonePosY, bonePosZ = getPedBonePosition(k, 26)

				setElementPosition(v, bonePosX, bonePosY, bonePosZ + 0.02)
			end
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue, newValue)
		if dataName == "snowballData" then
			if not newValue then
				if isElement(playerBalls[source]) then
					destroyElement(playerBalls[source])
				end

				playerBalls[source] = nil
				playerBallState[source] = nil
			else
				local state, power = unpack(newValue)

				playerBallState[source] = state
				playerBallPower[source] = power

				if state == 0 then
					local snowballObject = createObject(snowballModel, 0, 0, 0)

					if isElement(snowballObject) then
						setObjectScale(snowballObject, 0.1)
						setElementCollisionsEnabled(snowballObject, false)

						playerBalls[source] = snowballObject

						if source == localPlayer then
							exports.sarp_controls:toggleControl({"fire"}, false)
						end
					end
				elseif state == 1 then
					setPedAnimation(source, "GRENADE", "WEAPON_throw", -1, false)

					setTimer(
						function(player)
							if player == localPlayer then
								setElementData(localPlayer, "snowballData", {2, power})

								exports.sarp_controls:toggleControl({"fire"}, true)
							end

							setTimer(
								function(player)
									setPedAnimation(player)
								end,
							300, 1, player)
						end,
					300, 1, source)
				elseif state == 2 then
					if playerBalls[source] then
						local ballPosX, ballPosY, ballPosZ = getElementPosition(playerBalls[source])
						local playerPosX, playerPosY, playerPosZ = getElementPosition(source)
						local playerRotX, playerRotY, playerRotZ = getElementRotation(source)

						throwedBalls[source] = {
							playerPosX = playerPosX,
							playerPosY = playerPosY,
							playerPosZ = playerPosZ,
							playerRotZ = playerRotZ,
							ballPosX = ballPosX,
							ballPosY = ballPosY,
							ballPosZ = ballPosZ,
							ballRadius = 1
						}
					end
				end
			end
		end
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		toggleWinter(false)
		winterModeState = false
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		toggleWinter(true)
		winterModeState = true
	end
)

addCommandHandler("wintermode",
	function ()
		winterModeState = not winterModeState

		toggleWinter(winterModeState)
		
		if not winterModeState then
			destroySnowTextures()
			destroySnowGround()
			destroySnowFlakes()
			
			if isElement(snowFlakeTexture) then
				destroyElement(snowFlakeTexture)
			end
			
			snowFlakeTexture = nil
		end
	end
)

addEventHandler("onClientPlayerVehicleEnter", getRootElement(),
	function ()
		if winterModeState then
			removeVehicleSnowTexturesSoon()
		end
	end
)

function toggleWinter(state)
	if state then
		snowFlakeTexture = dxCreateTexture("files/textures/snowflake.dds")
		
		applySnowGround()
		
		for k = 1, #availableTextures do
			local v = availableTextures[k]

			applySnowTexture(v[1], "files/textures/" .. v[2])
		end
		
		applySnowFlakes()
	end
end

function applySnowGround()
	snowGroundShader = dxCreateShader("files/shaders/ground.fx", 0, 250)
	snowTreesShader = dxCreateShader("files/shaders/trees.fx")
	snowNaughtyTreesShader = dxCreateShader("files/shaders/naughtytrees.fx")
	noiseTexture = dxCreateTexture("files/textures/smallnoise.dds")
	
	if not snowGroundShader or not snowTreesShader or not snowNaughtyTreesShader or not noiseTexture then
		return nil
	end
	
	dxSetShaderValue(snowTreesShader, "noiseTexture", noiseTexture)
	dxSetShaderValue(snowNaughtyTreesShader, "noiseTexture", noiseTexture)
	dxSetShaderValue(snowGroundShader, "noiseTexture", noiseTexture)
	dxSetShaderValue(snowGroundShader, "snowFadeEnd", 250)
	dxSetShaderValue(snowGroundShader, "snowFadeStart", 250 / 2)
	
	engineApplyShaderToWorldTexture(snowGroundShader, "*")

	for _, removeMatch in ipairs(snowGroundRemoveList) do
		engineRemoveShaderFromWorldTexture(snowGroundShader, removeMatch)
	end

	for _, applyMatch in ipairs(snowTreesList) do
		engineApplyShaderToWorldTexture(snowTreesShader, applyMatch)
	end

	for _, applyMatch in ipairs(snowNaughtyTreesList) do
		engineApplyShaderToWorldTexture(snowNaughtyTreesShader, applyMatch)
	end
	
	removedVehicleTexture = {}
	vehTimer = setTimer(checkCurrentVehicle, 100, 0)
	removeVehicleSnowTextures()
end

function destroySnowGround()
	destroyElement(noiseTexture)
	destroyElement(snowTreesShader)
	destroyElement(snowNaughtyTreesShader)
	destroyElement(snowGroundShader)
	killTimer(vehTimer)
end

function applySnowTexture(texture, path)
	if texture and path then
		if not snowShaders[texture] then
			snowShaders[texture] = dxCreateShader("files/shaders/texturechanger.fx", 0, 500)
		end

		if not snowTextures[path] then
			snowTextures[path] = dxCreateTexture(path, "dxt3")
		end

		if snowShaders[texture] and snowTextures[path] then
			dxSetShaderValue(snowShaders[texture], "TEXTURE", snowTextures[path])
			engineApplyShaderToWorldTexture(snowShaders[texture], texture)
		end
	end
end

function destroySnowTextures()
	for k, v in pairs(snowShaders) do
		if isElement(snowShaders[k]) then
			destroyElement(snowShaders[k])
		end
	end

	for k, v in pairs(snowTextures) do
		if isElement(snowTextures[k]) then
			destroyElement(snowTextures[k])
		end
	end

	snowShaders = {}
	snowTextures = {}
end

function applySnowFlakes()
	snowFlakes = {}
	
	local worldX, worldY, worldZ = getWorldFromScreenPosition(0, 0, 1)
	local worldX2, worldY2, worldZ2 = getWorldFromScreenPosition(screenX, 0, 1)
	
	flakeBoxWidth = getDistanceBetweenPoints3D(worldX, worldY, worldZ, worldX2, worldY2, worldZ2) + 3.0
	flakeBoxDepth = flakeBoxWidth
	
	flakeBoxWidthDoubled = flakeBoxWidth * 2
	flakeBoxDepthDoubled = flakeBoxDepth * 2

	worldX, worldY, worldZ = getWorldFromScreenPosition(screenX2, screenY2, flakeBoxDepth)
	worldFlakePosition = {worldX, worldY, worldZ}		
	
	for i = 1, 75 do
		local flakeX, flakeY, flakeZ = random(0, flakeBoxWidth * 2), random(0, flakeBoxDepth * 2), random(0, flakeBoxHeight * 2)
		
		createSnowFlake(flakeX - flakeBoxWidth, flakeY - flakeBoxDepth, flakeZ - flakeBoxHeight, 0)
	end
	
	addEventHandler("onClientRender", getRootElement(), drawSnowFlakes)
end

function destroySnowFlakes()
	removeEventHandler("onClientRender", getRootElement(), drawSnowFlakes)
	
	for flake in pairs(snowFlakes) do
		snowFlakes[flake] = nil
	end
	
	snowFlakes = nil
	removeFlakes = nil
end

function createSnowFlake(x, y, z, alpha, flake)
	if removeFlakes then
		if removeFlakes[2] % removeFlakes[3] == 0 then
			removeFlakes[1] = removeFlakes[1] - 1
			
			if removeFlakes[1] == 0 then
				removeFlakes = nil
			end
			
			table.remove(snowFlakes, i)
			
			return
		else
			removeFlakes[2] = removeFlakes[2] + 1
		end
	end
	
	snowCount = snowCount % 4 + 1
	
	local getRandomRotation = math.random(0, 180)
	
	if flake then
		snowFlakes[flake] = {
			x = x,
			y = y,
			z = z,
			speed = math.random(1, 3) / 100,
			size = 2 ^ math.random(1, 3),
			section = {(snowCount % 2 == 1) and 0 or 32, (snowCount < 3) and 0 or 32},
			rot = getRandomRotation,
			alpha = alpha,
			jitter_direction = {math.cos(math.rad(getRandomRotation * 2)), -math.sin(math.rad(math.random(0, 360)))},
			jitter_cycle = getRandomRotation * 2,
			jitter_speed = 8
		}
	else
		table.insert(snowFlakes, {
			x = x,
			y = y,
			z = z,
			speed = math.random(1, 3) / 100,
			size = 2 ^ math.random(1, 3),
			section = {(snowCount % 2 == 1) and 0 or 32, (snowCount < 3) and 0 or 32},
			rot = getRandomRotation,
			alpha = alpha,
			jitter_direction = {math.cos(math.rad(getRandomRotation * 2)), -math.sin(math.rad(math.random(0, 360)))},
			jitter_cycle = getRandomRotation * 2,
			jitter_speed = 8
		})
	end
end

function drawSnowFlakes()
	if winterModeState then
		local cameraX, cameraY, cameraZ = getCameraMatrix()
		local worldX, worldY, worldZ = getWorldFromScreenPosition(screenX2, screenY2, flakeBoxDepth)

		if isLineOfSightClear(cameraX, cameraY, cameraZ, cameraX, cameraY, cameraZ + 20, true, false, false, true, false, true, false, localPlayer) or isLineOfSightClear(worldX, worldY, worldZ, worldX, worldY, worldZ + 20, true, false, false, true, false, true, false, localPlayer) then
			local checkGround = getGroundPosition

			if testLineAgainstWater(cameraX, cameraY, cameraZ, cameraX, cameraY,cameraZ + 20) then
				checkGround = getWaterLevel
			end

			local groundX, groundY, groundZ = worldX + flakeBoxWidth * -1, worldY + flakeBoxDepth * -1, worldZ + 15	
			local groundPositions = {}

			for i = 1, 3 do
				local iterator = flakeBoxWidthDoubled * (i * 0.25)
				
				groundPositions[i] = {
					checkGround(groundX + iterator, groundY + (flakeBoxDepthDoubled * 0.25), groundZ),
					checkGround(groundX + iterator, groundY + (flakeBoxDepthDoubled * 0.5), groundZ),
					checkGround(groundX + iterator, groundY + (flakeBoxDepthDoubled * 0.75), groundZ)
				}
			end	

			local oppositeX, oppositeY, oppositeZ = worldFlakePosition[1] - worldX, worldFlakePosition[2] - worldY, worldFlakePosition[3] - worldZ

			for i, flake in pairs(snowFlakes) do
				if flake then				
					if flake.z < -flakeBoxHeight then
						createSnowFlake(random(0, flakeBoxWidth * 2) - flakeBoxWidth, random(0, flakeBoxDepth * 2) - flakeBoxDepth, flakeBoxHeight, 0, i)
					else
						local groundX, groundY = 2, 2
						
						if flake.x <= flakeBoxWidthDoubled * 0.33 - flakeBoxWidth then
							groundX = 1
						elseif flake.x >= flakeBoxWidthDoubled * 0.66 - flakeBoxWidth then
							groundX = 3
						end

						if flake.y <= flakeBoxDepthDoubled * 0.33 - flakeBoxDepth then
							groundY = 1
						elseif flake.y >= flakeBoxDepthDoubled * 0.66 - flakeBoxDepth then
							groundY = 3
						end

						if groundPositions[groundX][groundY] and (flake.z + worldZ) > groundPositions[groundX][groundY] then
							local drawX, drawY, jitterX, jitterY = nil, nil, 0, 0
							local jitterCycle = math.cos(flake.jitter_cycle) / flake.jitter_speed

							jitterX = (flake.jitter_direction[1] * jitterCycle)
							jitterY = (flake.jitter_direction[2] * jitterCycle)
							drawX, drawY = getScreenFromWorldPosition(flake.x + worldX + jitterX, flake.y + worldY + jitterY ,flake.z + worldZ, 15, false)

							if drawX and drawY then
								dxDrawImageSection(drawX, drawY, flake.size, flake.size, flake.section[1], flake.section[2], 32, 32, snowFlakeTexture, flake.rot, 0, 0, tocolor(222, 235, 255, flake.alpha))

								flake.rot = flake.rot + 1

								if flake.alpha < 255 then
									flake.alpha = flake.alpha + 10
									
									if flake.alpha > 255 then
										flake.alpha = 255
									end
								end	
							end
						end
						
						flake.jitter_cycle = (flake.jitter_cycle % 360) + 0.1
						flake.x = flake.x + (0.01 * 1)
						flake.y = flake.y + (0.01 * 1)
						flake.z = flake.z - flake.speed	
						flake.x = flake.x + oppositeX
						flake.y = flake.y + oppositeY
						flake.z = flake.z + oppositeZ

						if flake.x < -flakeBoxWidth or flake.x > flakeBoxWidth or flake.y < -flakeBoxDepth or flake.y > flakeBoxDepth or flake.z > flakeBoxHeight then
							flake.x = flake.x - oppositeX
							flake.y = flake.y - oppositeY
							
							local flakeX, flakeY, flakeZ = (flake.x > 0 and -flake.x or math.abs(flake.x)), (flake.y > 0 and -flake.y or math.abs(flake.y)), random(0, flakeBoxHeight * 2)

							createSnowFlake(flakeX, flakeY, flakeZ - flakeBoxHeight, 255, i)
						end
					end
				end
			end
		end
		
		worldFlakePosition = {worldX, worldY, worldZ}
	end
end

function checkCurrentVehicle()
	local playerVehicle = getPedOccupiedVehicle(localPlayer)
	local vehicleModel = playerVehicle and getElementModel(playerVehicle)

	if lastCheckedVehicle ~= playerVehicle or lastCheckedVehicleModel ~= vehicleModel then
		lastCheckedVehicle = playerVehicle
		lastCheckedVehicleModel = vehicleModel
		removeVehicleSnowTexturesSoon()
	end

	if nextCheckTime < getTickCount() then
		nextCheckTime = getTickCount() + 5000
		removeVehicleSnowTextures()
	end
end

function removeVehicleSnowTexturesSoon()
	nextCheckTime = getTickCount() + 200
end

function removeVehicleSnowTextures()
	local playerVehicle = getPedOccupiedVehicle(localPlayer)
	
	if playerVehicle then
		local vehicleModel = getElementModel(playerVehicle)
		local vehicleTextures = engineGetVisibleTextureNames("*", vehicleModel)
		
		if vehicleTextures then	
			for _, removeMatch in pairs(vehicleTextures) do
				if not removedVehicleTexture[removeMatch] then
					removedVehicleTexture[removeMatch] = true
					engineRemoveShaderFromWorldTexture(snowGroundShader, removeMatch)
				end
			end
		end
	end
end

_dxCreateShader = dxCreateShader
function dxCreateShader(filepath, priority, maxDistance, bDebug)
	priority = priority or 0
	maxDistance = maxDistance or 0
	bDebug = bDebug or false

	local build = getVersion().sortable:sub(9)
	local fullscreen = not dxGetStatus()["SettingWindowed"]

	if build < "03236" and fullscreen then
		maxDistance = 0
	end

	return _dxCreateShader(filepath, priority, maxDistance, bDebug)
end

function random(lower, upper)
	return lower + (math.random() * (upper - lower))
end