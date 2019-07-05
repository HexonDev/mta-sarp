CustomImageButton = {}

function CustomImageButton.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end
	
	local widget = Image.create(properties)
	
	widget.color = properties.color or tocolor(255, 255, 255)
	widget.hoverColor = properties.hoverColor or false
	widget.hoverSize = properties.hoverSize or false

	function widget:draw(animValue)
		if self.texture then
			if animValue then
				local r, g, b, a = toRGBA(self.color)
				Drawing.setColor(tocolor(r, g, b, a * animValue))
			else
				Drawing.setColor(self.color)
			end
			
			if self.mouseHover then
				if self.hoverColor then
					if animValue then
						local r, g, b, a = toRGBA(self.hoverColor)
						Drawing.setColor(tocolor(r, g, b, a * animValue))
					else
						Drawing.setColor(self.hoverColor)
					end
				else
					Drawing.setColor(self.color)
				end

				if self.hoverSize then
					Drawing.image(self.x - self.hoverSize / 2, self.y - self.hoverSize / 2, self.width + self.hoverSize, self.height + self.hoverSize, self.texture)
				else
					Drawing.image(self.x, self.y, self.width, self.height, self.texture)
				end
			else
				Drawing.image(self.x, self.y, self.width, self.height, self.texture)
			end
		end
	end

	return widget
end