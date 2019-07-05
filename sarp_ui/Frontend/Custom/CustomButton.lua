CustomButton = {}

function CustomButton.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Button.create(properties)

	widget.font = properties.font or "default"
	widget.rounded = properties.rounded

	properties.color = properties.color or {50, 179, 239}

	widget.colors = {
		normal = properties.color,
		hover = colorDarken(properties.color, 15),
		down = colorDarken(properties.color, 5)
	}

	widget.textColor = properties.textColor or tocolor(255, 255, 255)

	return widget
end