Rectangle = {}

function Rectangle.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Widget.create(properties)

	function widget:draw(animValue)
		if animValue then
			local r, g, b, a = toRGBA(self.color)
			Drawing.setColor(tocolor(r, g, b, a * animValue))
		end

		if self.rounded then
			Drawing.roundedRectangle(self.x, self.y, self.width, self.height)
		else
			Drawing.rectangle(self.x, self.y, self.width, self.height)
		end
	end
	
	return widget
end