CustomCheckbox = {}

function CustomCheckbox.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Widget.create(properties)
	widget._type = "Checkbox"
	widget.state = false
	widget.rounded = properties.rounded

	properties.color = properties.color or {50, 179, 239}

	widget.colors = {
		normal = tocolor(unpack(properties.color)),
		hover = colorLighten(properties.color, 15)
	}

	function widget:draw(animValue)
		if isCursorWithinArea(0, 0, self.width, self.height, self.mouseX, self.mouseY) then
			self.color = self.colors.hover
		else
			self.color = self.colors.normal
		end

		if animValue then
			if type(self.color) == "table" then
				self.color = tocolor(self.color[1], self.color[2], self.color[3], self.color[4])
			end

			local r, g, b, a = toRGBA(self.color)
			self.color = tocolor(r, g, b, a * animValue)
		end

		if self.state then
			Drawing.setColor(self.color)
		else
			Drawing.setColor(tocolor(44, 42, 43, 255 * (animValue or 1)))
		end

		if self.rounded then
			Drawing.roundedRectangle(self.x, self.y, self.width, self.height)
		else
			Drawing.rectangle(self.x, self.y, self.width, self.height)
		end

		if self.state then
			local tickWidth = self.width * 0.75
			local tickHeight = self.height * 0.75

			Drawing.setColor(tocolor(255, 255, 255, 255 * (animValue or 1)))
			Drawing.image(math.floor(self.x + (self.width - tickWidth) / 2), math.floor(self.y + (self.height - tickHeight) / 2), tickWidth, tickHeight, ":sarp_assets/images/tick.png")
		end
	end

	return widget
end

addEvent("_sarpUI.clickInternal", false)
addEventHandler("_sarpUI.clickInternal", resourceRoot, function ()
	if Render.clickedWidget and Render.clickedWidget._type == "Checkbox" then
 		Render.clickedWidget.state = not Render.clickedWidget.state
 	end
end)