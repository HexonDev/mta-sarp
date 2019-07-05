CustomPanel = {}

function CustomPanel.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end
	
	local widget = Rectangle.create(properties)

	widget.rounded = properties.rounded

	if properties.color == "transparent" then
		widget.color = tocolor(0, 0, 0, 0)
	else
		widget.color = properties.color or tocolor(29, 29, 29, 240)
	end

	widget.moveable = properties.moveable or false
	widget.dragging = false

	widget.enableAnimation = properties.enableAnimation or false

	if widget.enableAnimation then
		widget.animStart = getTickCount()
		widget.animEnd = false
		widget.animValue = 0
	end

	return widget
end