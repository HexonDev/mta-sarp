CustomDropDown = {}

local hoveredElement = false

function CustomDropDown.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Widget.create(properties)

	widget.font = properties.font or "default"
	widget.fontScale = properties.fontScale or 1

	widget.items = properties.items or {}
	widget.itemHeight = properties.itemHeight or 35
	
	widget.bgColor = properties.bgColor or tocolor(42, 40, 41)
	widget.bgHoverColor = properties.bgHoverColor or tocolor(52, 50, 51)

	widget.activeItemColor = properties.activeItemColor or tocolor(255, 255, 255)
	widget.activeItemHoverColor = properties.activeItemHoverColor or tocolor(255, 255, 255)

	widget.itemColor = properties.itemColor or tocolor(255, 255, 255)
	widget.itemHoverColor = properties.itemHoverColor or tocolor(105, 105, 105, 105)

	widget.visibleItems = properties.visibleItems or 10
	widget.currentOffset = properties.currentOffset or 0
	widget.scrollOffset = properties.scrollOffset or 1

	widget.enableScrollbar = properties.enableScrollbar or false
	widget.scrollBgColor = properties.scrollBgColor or tocolor(75, 75, 75, 200)
	widget.scrollGripColor = properties.scrollGripColor or tocolor(50, 179, 239)

	widget.activeItem = properties.activeItem or 1
	widget.hoveredItem = false

	widget.listDropped = false

	function widget:draw(animValue)
		hoveredElement = false

		local isHover = isCursorWithinArea(0, 0, self.width, self.height, self.mouseX, self.mouseY)
		if isHover then
			if animValue then
				local r, g, b, a = toRGBA(self.bgHoverColor)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.bgHoverColor)
			end

			hoveredElement = self
		else
			if animValue then
				local r, g, b, a = toRGBA(self.bgColor)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.bgColor)
			end
		end

		Drawing.rectangle(self.x, self.y, self.width, self.height)
		
		if isHover then
			if animValue then
				local r, g, b, a = toRGBA(self.activeItemHoverColor)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.activeItemHoverColor)
			end
		else
			if animValue then
				local r, g, b, a = toRGBA(self.activeItemColor)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.activeItemColor)
			end
		end

		local iconSize = self.height * 0.75

		if not self.listDropped then
			Drawing.image(self.x, self.y + (self.height - iconSize) / 2, iconSize, iconSize, ":sarp_assets/images/arrow.png", true, 0)
		else
			Drawing.image(self.x, self.y + (self.height - iconSize) / 2, iconSize, iconSize, ":sarp_assets/images/arrow.png", true, 90)
		end

		Drawing.setFont(self.font)
		Drawing.setFontScale(self.fontScale)
		Drawing.text(self.x + iconSize + 2, self.y, self.width, self.height, self.items[self.activeItem][1], "left", "center", true)

	end

	return widget
end

addEventHandler("onClientClick", root, function (button, state)

end)