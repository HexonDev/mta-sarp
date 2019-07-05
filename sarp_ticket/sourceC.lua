

local activeTicket = false
local selectedTicket = "Traffic"

local ticketData = nil
local ticketEdit = false

local ticketItemDatabaseId = false

buttons = {}
activeButton = false
activeInput = false
inputValues = {}

local currentInputCaretState = false
local lastInputCaretTick = 0

function clearInputs()
	for k, v in pairs(inputValues) do
		inputValues[k] = ""
	end
end

function drawInput(k, x, y, sx, sy, font, fontScale, color, extra)
	if not inputValues[k] then
		inputValues[k] = ""
	end

	if extra then
		dxDrawText(inputValues[k] .. extra, x + respc(3), y + respc(15), x + sx - respc(12), y + sy, color, fontScale, font, "left", "center", true)
	else
		dxDrawText(inputValues[k], x + respc(3), y + respc(15), x + sx - respc(12), y + sy, color, fontScale, font, "left", "center", true)
	end

	if activeInput == k then
		local textWidth = dxGetTextWidth(inputValues[k], fontScale, font) + 2
		local r, g, b = bitExtract(color, 16, 8), bitExtract(color, 8, 8), bitExtract(color, 0, 8)
		local a = currentInputCaretState and 255 or 0

		local caretPosX = x + respc(3) + textWidth

		if caretPosX > x + sx - respc(12) then
			caretPosX = x + sx - respc(12)
		end

		dxDrawRectangle(caretPosX, y + respc(15), 2, sy - respc(20), tocolor(r, g, b, a))

		if getTickCount() - lastInputCaretTick >= 375 then
			lastInputCaretTick = getTickCount()
			currentInputCaretState = not currentInputCaretState
		end
	end

	buttons["setInput:" .. k] = {x, y, sx, sy}
end

addEventHandler("onClientCharacter", root,
	function (character)
		if ticketItemDatabaseId and activeInput then
			local selected = split(activeInput, "|")

			if selected[3] then
				local maxCharacter = tonumber(selected[3])

				if utf8.len(inputValues[activeInput]) >= maxCharacter then
					return
				end
			end

			if selected[2] == "num-only" then
				if tonumber(character) then
					cancelEvent()

					inputValues[activeInput] = inputValues[activeInput] .. character
				end
			else
				cancelEvent()

				inputValues[activeInput] = inputValues[activeInput] .. character
			end
		end
	end
)

addEventHandler("onClientKey", root,
	function (key, press)
		if ticketItemDatabaseId and activeInput and inputValues[activeInput] then
			if press then
				cancelEvent()

				if key == "backspace" then
					if utf8.len(inputValues[activeInput]) > 0 then
						inputValues[activeInput] = utf8.sub(inputValues[activeInput], 1, -2)
					end
				end
			end
		end
	end
)

addEventHandler("onClientClick", root,
	function (button, state)
		if ticketItemDatabaseId and button == "left" then
			if state == "down" then
				activeInput = false

				if activeButton then
					local selected = split(activeButton, ":")

					if selected[1] == "setInput" then
						activeInput = selected[2]
					end
				end
			end
		end
	end)

Tickets = {}

addEventHandler("onClientRender", root, function()
	if activeTicket then
		buttons = {}
		--print("activeTicket", selectedTicket, Tickets[selectedTicket]["Render"])
		if Tickets[selectedTicket] then
			Tickets[selectedTicket]["Render"](ticketData, ticketEdit);
		end

		local cx, cy = getCursorPosition()

		activeButton = false

		if cx and cy then
			cx, cy = screenX * cx, screenY * cy

			for k, v in pairs(buttons) do
				if cx >= v[1] and cx <= v[1] + v[3] and cy >= v[2] and cy <= v[2] + v[4] then
					activeButton = k
					break
				end
			end
		end
	end
end)


addCommandHandler("ticket", function()
	showTicket("Traffic", nil)
end)

addCommandHandler("ticket2", function()
	showTicket("Traffic", nil, true)
end)


function showTicket(itemDbId, state, ticket, data, edit)	
	activeTicket = state
	activeInput = false

	clearInputs()

	if activeTicket then
		if Tickets[ticket] then
			for k, v in pairs(Tickets[ticket]["Event"]) do
				--print(k, v)
				addEventHandler(k, root, v)
			end
		end
	else
		if Tickets[selectedTicket] then
			for k, v in pairs(Tickets[selectedTicket]["Event"]) do
				--print(k, v)
				removeEventHandler(k, root, v)
			end
		end

		if ticketItemDatabaseId then
			exports.sarp_inventory:unuseItem(ticketItemDatabaseId)
		end
	end
	
	selectedTicket = ticket
	ticketData = data
	ticketEdit = edit

	if state then
		ticketItemDatabaseId = itemDbId
	else
		ticketItemDatabaseId = false
	end
end
registerEvent("sarp_ticketC:showTicket", root, showTicket)

payPed = nil

addEventHandler("onClientResourceStart", resourceRoot, function()
	payPed = createPed(17, 1484.5911865234, -1742.2227783203, 13.546875, 270)
	setElementFrozen(payPed, true)
	setElementData(payPed, "invulnerable", true)
	setElementData(payPed, "visibleName", "John Alvarez")
	setElementData(payPed, "pedNameType", "Büntetés kifizetés")
	setElementData(payPed, "ped.type", "FINEPAY")
    setPedAnimation(payPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
end)