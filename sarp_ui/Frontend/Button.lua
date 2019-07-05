Button = {}

local interpolationDuration = 250

function Button.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Widget.create(properties)

	widget.text = properties.text or ""
	widget.alignX = properties.alignX or "center"
	widget.alignY = properties.alignY or "center"

	if not properties.colors then
		properties.colors = {}
	end

	widget.colors = {
		normal = properties.colors.normal or tocolor(0, 0, 0),
		hover = properties.colors.hover or tocolor(150, 150, 150),
		down = properties.colors.down or tocolor(255, 255, 255),
	}
	widget.textColor = properties.textColor or tocolor(255, 255, 255)

	function widget:draw(animValue)
		if isCursorWithinArea(0, 0, self.width, self.height, self.mouseX, self.mouseY) then
			if getKeyState("mouse1") then
				self.color = self.colors.down
			else
				self.color = self.colors.hover
			end
		else
			self.color = self.colors.normal
		end

		if type(self.color) == "table" then
			self.color = tocolor(self.color[1], self.color[2], self.color[3], self.color[4])
		end

		if animValue then
			local r, g, b, a = toRGBA(self.color)
			Drawing.setColor(tocolor(r, g, b, a * animValue))
		else
			Drawing.setColor(self.color)
		end
		
		if self.rounded then
			Drawing.roundedRectangle(self.x, self.y, self.width, self.height)
		else
			Drawing.rectangle(self.x, self.y, self.width, self.height)
		end

		if animValue then
			local r, g, b, a = toRGBA(self.textColor)
			Drawing.setColor(tocolor(r, g, b, a * animValue))
		else
			Drawing.setColor(self.textColor)
		end

		Drawing.text(self.x, self.y, self.width, self.height, self.text, self.alignX, self.alignY, true, false)		
	end

	return widget
end