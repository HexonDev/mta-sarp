Input = {}

local activeInput

local repeatTimer
local repeatStartTimer

local repeatWait = 500
local repeatDelay = 50

local maskedChar = "●"

function Input.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Rectangle.create(properties)

	widget._type = "Input"
	widget.text = properties.text or ""
	widget.placeholder = properties.placeholder or ""
	widget.forceRegister = properties.forceRegister or false
	widget.masked = properties.masked or false
	widget.font = properties.font or "default"
	widget.fontScale = properties.fontScale or 1
	widget.regexp = properties.regexp or false
	widget.textColor = properties.textColor or tocolor(255, 255, 255)
	widget.placeholderColor = properties.placeholderColor or tocolor(230, 230, 230)
	widget.maxLength = properties.maxLength or math.huge

	function widget:draw(animValue)
		if activeInput == self then
			self.color = self.colors.active
		else
			if isCursorWithinArea(0, 0, self.width, self.height, self.mouseX, self.mouseY) then
				if getKeyState("mouse1") then
					self.color = self.colors.active
				else
					self.color = self.colors.hover
				end
			else
				self.color = self.colors.normal
			end
		end

		if animValue then
			if type(self.color) == "table" then
				self.color = tocolor(self.color[1], self.color[2], self.color[3], self.color[4])
			end

			local r, g, b, a = toRGBA(self.color)
			self.color = tocolor(r, g, b, a * animValue)

			r, g, b, a = toRGBA(self.placeholderColor)
			self.placeholderColor = tocolor(r, g, b, a * animValue)

			r, g, b, a = toRGBA(self.textColor)
			self.textColor = tocolor(r, g, b, a * animValue)
		end

		if self.rounded then
			Drawing.roundedRectangle(self.x, self.y, self.width, self.height)
		else
			Drawing.rectangle(self.x, self.y, self.width, self.height)
		end
		Drawing.setColor(self.placeholderColor)

		local text = self.placeholder

		if utf8.len(self.text) > 0 then
			text = self.text

			if self.masked then
				text = string.rep(maskedChar, utf8.len(self.text))
			end
		elseif activeInput == self then
			text = ""
		end

		if activeInput == self then
			Drawing.setColor(self.textColor)

			if self.selectedAll then
				local w = dxGetTextWidth(text, self.fontScale, self.font) + 4
				local h = dxGetFontHeight(self.fontScale, self.font) + 4

				Drawing.rectangle(self.x + 10 - 2, self.y + (self.height - h) / 2, w, h, tocolor(255, 255, 255, 75))
			end

			local interpolation = interpolateBetween(0, 0, 0, 1, 0, 0, getTickCount() / 750, "SineCurve")
			if interpolation > 0.5 then
				if self.caretIndex then
					text = utf8.insert(text, self.caretIndex, "|")
				else
					text = utf8.insert(text, "|")
				end
			end
		end

		Drawing.text(self.x + 10, self.y, self.width - 20, self.height, text, "left", "center", true, false)
	end

	return widget
end

addEvent("_sarpUI.clickInternal", false)
addEventHandler("_sarpUI.clickInternal", resourceRoot, function ()
	if activeInput then
		activeInput.selectedAll = false
	end

	if Render.clickedWidget and Render.clickedWidget._type == "Input" then
		activeInput = Render.clickedWidget
	else
		activeInput = nil
	end

	guiSetInputMode("no_binds")
	guiSetInputEnabled(not not activeInput)
end)

addEventHandler("onClientCharacter", root, function (character)
	if activeInput then
		if activeInput.selectedAll then
			activeInput.text = ""
			activeInput.selectedAll = false
			activeInput.caretIndex = false
		end

		if utf8.len(activeInput.text) < activeInput.maxLength then
			if activeInput.forceRegister == "lower" then
				character = utf8.lower(character)
			elseif activeInput.forceRegister == "upper" then
				character = utf8.upper(character)
			end

			if activeInput.regexp then
				if not pregFind(character, activeInput.regexp) then
					return
				end
			end

			if activeInput.caretIndex then
				activeInput.text = utf8.insert(activeInput.text, activeInput.caretIndex, tostring(character))
				activeInput.caretIndex = activeInput.caretIndex + 1
			else
				activeInput.text = utf8.insert(activeInput.text, tostring(character))
			end
			triggerEvent("sarpUI.inputChange", activeInput.resourceRoot, activeInput.id)
		end
	end
end)

local function handleKey(key, repeatKey)
	if not activeInput then
		return
	end

	if key == "backspace" and utf8.len(activeInput.text) > 0 and ((activeInput.caretIndex and activeInput.caretIndex - 1 > 0) or not activeInput.caretIndex) then
		if activeInput.selectedAll then
			activeInput.text = ""
			activeInput.selectedAll = false
			activeInput.caretIndex = false
		else
			if activeInput.caretIndex then
				local index = activeInput.caretIndex - 1
				activeInput.text = utf8.sub(activeInput.text, 0, index - 1) .. utf8.sub(activeInput.text, index + 1, utf8.len(activeInput.text))
				activeInput.caretIndex = activeInput.caretIndex - 1
			else
				activeInput.text = utf8.sub(activeInput.text, 1, -2)
			end
		end

		triggerEvent("sarpUI.inputChange", activeInput.resourceRoot, activeInput.id)
	elseif not repeatKey then
		if key == "tab" then
			local inputs = {}
			local currentIndex = 0
			local index = 0

			for i, v in ipairs(activeInput.parent.children) do
				if v._type == "Input" then
					index = index + 1
					table.insert(inputs, v)

					if v == activeInput then
						currentIndex = index
					end
				end
			end

			if #inputs > 1 then
				currentIndex = currentIndex + 1
				if currentIndex > #inputs then
					currentIndex = 1
				end
				activeInput.selectedAll = false
				activeInput = inputs[currentIndex]
			end
		elseif key == "enter" then
			triggerEvent("sarpUI.inputEnter", activeInput.resourceRoot, activeInput.id)
			activeInput = nil
		elseif key == "c" and (getKeyState("lctrl") or getKeyState("rctrl")) and activeInput.selectedAll then
			local text = activeInput.text

			if activeInput.masked then
				text = string.rep(maskedChar, utf8.len(activeInput.text))
			end

			setClipboard(text)
		elseif key == "a" and (getKeyState("lctrl") or getKeyState("rctrl")) then
			activeInput.selectedAll = true
			activeInput.caretIndex = false
		elseif key == "arrow_l" and (activeInput.caretIndex or utf8.len(activeInput.text)) > 1 then
			activeInput.caretIndex = (activeInput.caretIndex or utf8.len(activeInput.text) + 1) - 1
			activeInput.selectedAll = false
		elseif key == "arrow_r" and (activeInput.caretIndex or utf8.len(activeInput.text)) <= utf8.len(activeInput.text) then
			activeInput.caretIndex = (activeInput.caretIndex or utf8.len(activeInput.text)) + 1
			activeInput.selectedAll = false
		else
			return
		end
	end

	if repeatKey and getKeyState(key) then
		repeatTimer = setTimer(handleKey, repeatDelay, 1, key, true)
	end
end

addEventHandler("onClientKey", root, function (key, state)
	if not activeInput then
		return
	end

	if not state then
		if isTimer(repeatStartTimer) then
			killTimer(repeatStartTimer)
		end

		if isTimer(repeatTimer) then
			killTimer(repeatTimer)
		end

		return
	end

	handleKey(key, false)
	repeatStartTimer = setTimer(handleKey, repeatWait, 1, key, true)
end)