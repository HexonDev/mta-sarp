local controlsName = {
	"fire", "next_weapon", "previous_weapon", "forwards", "backwards", "left", "right", "zoom_in", "zoom_out",
	"change_camera", "jump", "sprint", "look_behind", "crouch", "action", "walk", "aim_weapon",
	"enter_exit", "vehicle_fire", "vehicle_secondary_fire", "vehicle_left", "vehicle_right",
	"steer_forward", "steer_back", "accelerate", "brake_reverse", "radio_next", "radio_previous", "radio_user_track_skip", "horn",
	"handbrake", "vehicle_look_left", "vehicle_look_right", "vehicle_look_behind", "vehicle_mouse_look", "special_control_left", "special_control_right",
	"special_control_down", "special_control_up", "enter_passenger"
}
local controlStates = {}
local controlNumbers = {}
local controlsUsedByRes = {}

local _toggleControl = toggleControl
_toggleControl("radar", false)

addEventHandler("onClientResourceStop", getRootElement(),
	function (stoppedResource)
		local resourceName = getResourceName(stoppedResource)

		if controlsUsedByRes[resourceName] then
			controlsUsedByRes[resourceName] = nil
			toggleControl("all", true, true, resourceName)
		end
	end
)

addEventHandler("onClientKey", getRootElement(),
	function (key)
		if controlNumbers[key] then
			if controlNumbers[key] > 0 then
				_toggleControl(key, false)
				controlStates[key] = true
			elseif controlStates[key] then
				_toggleControl(key, true)
				controlStates[key] = false
			end
		end
	end, true, "high+9999999"
)

addEvent("toggleControl", true)
addEventHandler("toggleControl", getRootElement(),
	function (controls, enabled, byResource)
		toggleControl(controls, enabled, false, byResource)
	end
)

function toggleControl(controls, enabled, important, byResource)
	if controls then
		if sourceResource then
			byResource = getResourceName(sourceResource)
		end

		if controls == "all" or controls[1] == "all" then
			for i = 1, #controlsName do
				local control = controlsName[i]
				if control then
					if not controlNumbers[control] then
						controlNumbers[control] = 0
					end
					
					if important then
						controlNumbers[control] = 0
					elseif not enabled then
						controlNumbers[control] = controlNumbers[control] + 1
					elseif controlNumbers[control] - 1 >= 0 then
						controlNumbers[control] = controlNumbers[control] - 1
					else
						controlNumbers[control] = 0
					end
					
					if controlNumbers[control] > 0 then
						setPedControlState(control, false)
						_toggleControl(control, false)
						controlStates[control] = true
						controlsUsedByRes[byResource] = true
					elseif controlStates[control] then
						_toggleControl(control, true)
						controlStates[control] = false
						controlsUsedByRes[byResource] = nil
					end
				end
			end
		else
			for k,v in ipairs(controls) do
				if not controlNumbers[v] then
					controlNumbers[v] = 0
				end

				if not enabled then
					controlNumbers[v] = controlNumbers[v] + 1
				elseif controlNumbers[v] - 1 >= 0 then
					controlNumbers[v] = controlNumbers[v] - 1
				else
					controlNumbers[v] = 0
				end
				
				if controlNumbers[v] > 0 then
					setPedControlState(v, false)
					_toggleControl(v, false)
					controlStates[v] = true
					controlsUsedByRes[byResource] = true
				elseif controlStates[v] then
					_toggleControl(v, true)
					controlStates[v] = false
					controlsUsedByRes[byResource] = nil
				end
			end
		end
	end
end