Widget = {}

function Widget.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = {}

	widget.x = properties.x or 0
	widget.y = properties.y or 0
	widget.width = properties.width or 0
	widget.height = properties.height or 0
	widget.parent = nil
	widget.children = {}
	widget.color = properties.color or tocolor(255, 255, 255)
	widget.visible = properties.visible or true
	widget.text = properties.text or ""

	return widget
end

function Widget.getChildIndex(widget, child)
	if not widget or not child then
		return false
	end

	for i, c in ipairs(widget.children) do
		if c == child then
			return i
		end
	end

	return false
end

function Widget.addChild(widget, child)
	if not widget or not child then
		return false
	end

	if child.parent then
		return false
	end

	if Widget.getChildIndex(widget, child) then
		return false
	end

	table.insert(widget.children, child)
	child.parent = widget

	return true
end

function Widget.removeChild(widget, child)
	if not widget or not child then
		return false
	end

	local index = Widget.getChildIndex(widget, child)
	if not index then
		return false
	end

	if not widget.children[index].enableAnimation then
		table.remove(widget.children, index)
		child.parent = nil
	else
		widget.children[index].animStart = false
		widget.children[index].animEnd = getTickCount()
		widget.children[index].removeChildData = {widget, index, child}
	end

	return true
end

function Widget.draw(widget, mouseX, mouseY, cursorX, cursorY)
	if not widget then
		return
	end

	if not widget.visible then
		return
	end

	mouseX = mouseX - widget.x
	mouseY = mouseY - widget.y

	widget.mouseX = mouseX
	widget.mouseY = mouseY

	if isCursorShowing() and widget.dragging and getKeyState("mouse1") then
		widget.x = cursorX - widget.dragging[1]
		widget.y = cursorY - widget.dragging[2]
	elseif widget.dragging then
		widget.dragging = false
	end

	if isCursorWithinArea(0, 0, widget.width, widget.height, mouseX, mouseY) then
		widget.mouseHover = true

		if Render.mouseClick then
			Render.clickedWidget = widget

			if widget.moveable and isCursorWithinArea(widget.moveable.x, widget.moveable.y, widget.moveable.width, widget.moveable.height, mouseX, mouseY) then
				widget.dragging = {cursorX - widget.x, cursorY - widget.y}
			else
				widget.dragging = false
			end
		end
	else
		widget.mouseHover = false
	end

	if widget.draw then
		if widget.enableAnimation then
			local currentTick = getTickCount()

			if widget.animStart and currentTick >= widget.animStart then
				local progress = (currentTick - widget.animStart) / 300
				widget.animValue = interpolateBetween(widget.animValue, 0, 0, 1, 0, 0, progress, "InQuad")

				if progress > 1 then
					widget.animValue = 1
					widget.animStart = false
				end
			elseif widget.animEnd and currentTick >= widget.animEnd then
				local progress = (currentTick - widget.animEnd) / 300
				widget.animValue = interpolateBetween(widget.animValue, 0, 0, 0, 0, 0, progress, "OutQuad")

				if progress > 1 then
					widget.animValue = 0
					widget.animEnd = false

					if widget.removeChildData then
						table.remove(widget.removeChildData[1]["children"], widget.removeChildData[2])
						widget.removeChildData[3]["parent"] = nil
					end
				end
			end
		end

		local color = widget.color
		if type(color) == "table" then	
			Drawing.setColor(tocolor(unpack(color)))
		else
			Drawing.setColor(color)
		end

		Drawing.setFont(widget.font)
		Drawing.setFontScale(widget.fontScale)
		
		widget:draw(widget.animValue or (widget.parent and widget.parent.animValue))
	end

	Drawing.translate(widget.x, widget.y)
	for i, child in ipairs(widget.children) do
		Widget.draw(child, mouseX, mouseY, cursorX, cursorY)
	end
	Drawing.translate(-widget.x, -widget.y)
end