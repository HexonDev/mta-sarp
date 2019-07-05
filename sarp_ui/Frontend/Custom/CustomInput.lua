CustomInput = {}

function CustomInput.create(properties)
	if type(properties) ~= "table" then
		properties = {}
	end

	local widget = Input.create(properties)

	widget.font = properties.font or "default"
	widget.rounded = properties.rounded

	properties.color = properties.color or {54, 52, 53}
	properties.textColor = properties.textColor or tocolor(255, 255, 255)
	properties.placeholderColor = properties.placeholderColor or tocolor(230, 230, 230)

	widget.colors = {
		normal = properties.color,
		hover = colorLighten(properties.color, 15),
		active = colorLighten(properties.color, 20)
	}

	widget.textColor = properties.textColor
	widget.placeholderColor = properties.placeholderColor

	return widget
end

--[[
createCustomInput({
	x = int,
	y = int,
	width = int,
	height = int,
	font = betűtípus, -- alap: default
	fontScale = betűméret, -- alap: 1
	color = {r, g, b}, -- alap: {54, 52, 53}
	textColor = {r, g, b}, -- alap: {255, 255, 255}
	placeholderColor = {r, g, b}, -- alap: {230, 230, 230}
	rounded = boolean, -- lekerített legyen-e; alapból: false
	placeholder = string, -- ha üres az input, legyen-e kiírva bele valami infó
	forceRegister = string, -- típusok: "lower", "upper"; alapból: false | a karaktereket alakítja át nagy/kis betűre
	masked = boolean, -- jelszavakhoz "kicsillagozás", alapból: false
	regexp = string, -- reguláris kifejezés, pl. hogy csak számokat lehessen megadni: ^[0-9], vagy csak betűket: ^[a-zA-Z], esetleg számok és betűk: ^[a-zA-Z0-9] vagy ^[A-Za-z0-9_]$ (bővebb infó googleba)
	maxLength = num -- maximum beírható karakter
})
]]