CustomLabel = {}

function CustomLabel.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end
	
	local widget = TextField.create(properties)

	widget.font = properties.font or "default"
	widget.fontScale = properties.fontScale or 1
	widget.color = properties.color or tocolor(255, 255, 255)
	
	return widget
end