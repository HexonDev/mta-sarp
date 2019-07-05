CustomList = {}

local hoveredList = false
local hoveredListRow = false

function CustomList.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Widget.create(properties)

	widget.columns = properties.columns or {}
	widget.items = properties.items or {}

	widget.itemHeight = properties.itemHeight or 35

	widget.columnFont = properties.columnFont or "default-bold"
	widget.itemFont = properties.itemFont or widget.columnFont

	widget.columnFontScale = properties.columnFontScale or 1
	widget.itemFontScale = properties.itemFontScale or widget.columnFontScale

	widget.activeColor = properties.activeColor or tocolor(50, 179, 239, 125)
	widget.evenColor = properties.evenColor or tocolor(52, 50, 51)
	widget.oddColor = properties.oddColor or tocolor(42, 40, 41)
	widget.rowHoverColor = properties.rowHoverColor or tocolor(105, 105, 105, 105)

	widget.columnColor = properties.columnColor or tocolor(255, 255, 255)
	widget.itemColor = properties.itemColor or tocolor(152, 150, 151)
	widget.itemActiveColor = properties.itemActiveColor or tocolor(255, 255, 255)

	widget.visibleItems = properties.visibleItems or 10
	widget.currentOffset = properties.currentOffset or 0
	widget.scrollOffset = properties.scrollOffset or 1

	widget.enableScrollbar = properties.enableScrollbar or false
	widget.scrollBgColor = properties.scrollBgColor or tocolor(75, 75, 75, 200)
	widget.scrollGripColor = properties.scrollGripColor or tocolor(50, 179, 239)

	widget.activeItem = properties.activeItem or false
	widget.hoveredItem = false

	local totalSize = 0
	for i = 1, #widget.columns do
		totalSize = totalSize + widget.columns[i].size
	end
	widget.columnsSize = totalSize

	function widget:draw(animValue)
		local x = self.x
		local h = self.itemHeight * math.min(#self.items, self.visibleItems)

		if isCursorWithinArea(x, self.y, self.width, h, self.mouseX, self.mouseY) then
			hoveredList = self
		elseif hoveredList then
			hoveredList = false
		end

		self.hoveredItem = false

		local y = self.y
		local itemY = 0

		for i = 1, self.visibleItems do
			local offset = i + self.currentOffset
			local item = self.items[offset]
			local isHover = isCursorWithinArea(0, itemY, self.width, self.itemHeight, self.mouseX, self.mouseY)
			
			if self.activeItem == offset then
				if animValue then
					local r, g, b, a = toRGBA(self.activeColor)
					Drawing.setColor(tocolor(r, g, b, a * animValue))
				else
					Drawing.setColor(self.activeColor)
				end
			elseif isHover and item then
				self.hoveredItem = offset

				if animValue then
					local r, g, b, a = toRGBA(self.rowHoverColor)
					Drawing.setColor(tocolor(r, g, b, a * animValue))
				else
					Drawing.setColor(self.rowHoverColor)
				end
			else
				if i % 2 == 0 then
					if animValue then
						local r, g, b, a = toRGBA(self.evenColor)
						Drawing.setColor(tocolor(r, g, b, a * animValue))
					else
						Drawing.setColor(self.evenColor)
					end
				else
					if animValue then
						local r, g, b, a = toRGBA(self.oddColor)
						Drawing.setColor(tocolor(r, g, b, a * animValue))
					else
						Drawing.setColor(self.oddColor)
					end
				end
			end
			Drawing.rectangle(self.x, y, self.width, self.itemHeight)

			local x = self.x

			for j = 1, #self.columns do
				local column = self.columns[j]
				if column then
					local columnWidth = column.size / self.columnsSize * self.width

					if i == 1 and column.text then
						local y = self.y - self.itemHeight

						Drawing.setFont(self.columnFont)
						Drawing.setFontScale(self.columnFontScale)
						if animValue then
							local r, g, b, a = toRGBA(self.columnColor)
							Drawing.setColor(tocolor(r, g, b, a * animValue))
						else
							Drawing.setColor(self.columnColor)
						end

						if column.columnAlign ~= "center" then
							Drawing.text(x + 5, y, columnWidth - 10, self.itemHeight, tostring(column.text), column.columnAlign or "center", "center", true)
						else
							Drawing.text(x, y, columnWidth, self.itemHeight, tostring(column.text), column.columnAlign or "center", "center", true)
						end
					end

					if item and item[j] then
						Drawing.setFont(self.itemFont)
						Drawing.setFontScale(self.itemFontScale)

						if self.activeItem == offset then
							if animValue then
								local r, g, b, a = toRGBA(self.itemActiveColor)
								Drawing.setColor(tocolor(r, g, b, a * animValue))
							else
								Drawing.setColor(self.itemActiveColor)
							end
						else
							if animValue then
								local r, g, b, a = toRGBA(self.itemColor)
								Drawing.setColor(tocolor(r, g, b, a * animValue))
							else
								Drawing.setColor(self.itemColor)
							end
						end

						if column.itemAlign ~= "center" then
							Drawing.text(x + 5, y, columnWidth - 10, self.itemHeight, tostring(item[j]), column.itemAlign or "center", "center", true)
						else
							Drawing.text(x, y, columnWidth, self.itemHeight, tostring(item[j]), column.itemAlign or "center", "center", true)
						end
					end

					x = x + columnWidth
				end
			end

			y = y + self.itemHeight
			itemY = itemY + self.itemHeight
		end

		if self.enableScrollbar and #self.items > self.visibleItems then
			if animValue then
				local r, g, b, a = toRGBA(self.scrollBgColor)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.scrollBgColor)
			end
			Drawing.rectangle(self.x + self.width - 5, self.y, 5, h)

			if animValue then
				local r, g, b, a = toRGBA(self.scrollGripColor)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.scrollGripColor)
			end
			Drawing.rectangle(self.x + self.width - 5, self.y + (h / #self.items) * math.min(self.currentOffset, #self.items - self.visibleItems), 5, (h / #self.items) * self.visibleItems)
		end
	end

	return widget
end

addEventHandler("onClientKey", root, function (key, state)
	if not hoveredList then
		return
	end

	if key == "mouse_wheel_down" then
		hoveredList.currentOffset = hoveredList.currentOffset + hoveredList.scrollOffset

		if hoveredList.currentOffset > #hoveredList.items - hoveredList.visibleItems then
			hoveredList.currentOffset = #hoveredList.items - hoveredList.visibleItems
		end
	elseif key == "mouse_wheel_up" then
		hoveredList.currentOffset = hoveredList.currentOffset - hoveredList.scrollOffset

		if hoveredList.currentOffset < 0 then
			hoveredList.currentOffset = 0
		end
	end
end)