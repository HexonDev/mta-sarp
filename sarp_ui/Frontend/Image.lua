Image = {}

function Image.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Widget.create(properties)

	widget.texture = properties.texture
	widget.color = properties.color or tocolor(255, 255, 255)
	widget.floorMode = properties.floorMode or false

	function widget:draw(animValue)
		if self.texture then
			if animValue then
				local r, g, b, a = toRGBA(self.color)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.color)
			end

			Drawing.image(self.x, self.y, self.width, self.height, self.texture, self.floorMode)
		end
	end
	
	return widget
end