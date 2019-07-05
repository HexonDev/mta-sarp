local printExports = false
local function printMetaExport(name)
	if printExports then
		outputConsole('\t<export type="client" function="' .. tostring(name) ..'" />')
	end
end

function getRootWidget()
	Render.setupResource(sourceResourceRoot)
	return Render.resources[sourceResourceRoot].rootWidget.id
end
printMetaExport("getRootWidget")

function addChild(parent, child)
	if not child then
		child = Render.getWidgetById(sourceResourceRoot, parent)
		parent = Render.resources[sourceResourceRoot].rootWidget
	else
		parent = Render.getWidgetById(sourceResourceRoot, parent)
		child = Render.getWidgetById(sourceResourceRoot, child)
	end

	if not parent or not child then
		return false
	end

	return Widget.addChild(parent, child)
end
printMetaExport("addChild")

function removeChild(parent, child)
	if not child then
		child = Render.getWidgetById(sourceResourceRoot, parent)
		
		if Render.resources[sourceResourceRoot] then
			parent = Render.resources[sourceResourceRoot].rootWidget
		end
	else
		parent = Render.getWidgetById(sourceResourceRoot, parent)
		child = Render.getWidgetById(sourceResourceRoot, child)
	end

	if not parent or not child then
		return false
	end

	return Widget.removeChild(parent, child)
end
printMetaExport("removeChild")

local widgetsList = {
	"Rectangle",
	"Button",
	"Image",
	"TextField",
	"Input",

	"CustomPanel",
	"CustomButton",
	"CustomInput",
	"CustomCheckbox",
	"CustomImageButton",
	"CustomList",
	"CustomLabel",
	"CustomDropDown"
}

local function createWidgetProxy(name, resourceRoot, ...)
	local WidgetType = _G[name]

	if type(WidgetType) ~= "table" then
		outputDebugString("Widget does not exist: " .. tostring(name), 1)
		return false
	end

	local widget = WidgetType.create(...)
	if not widget then
		outputDebugString("Failed to create widget: " .. tostring(name), 1)
		return false
	end

	return Render.exportWidget(widget, resourceRoot)
end

for i, name in ipairs(widgetsList) do
	_G["create" .. name] = function (...)
		return createWidgetProxy(name, sourceResourceRoot, ...)
	end
	printMetaExport("create" .. name)
end

local publicPropertiesList = {
	-- Base
	"x", "y", "width", "height", "color", "visible", "text",
	-- TextField
	"alignX", "alignY", "clip", "wordBreak", "colorCoded",
	-- SARP
	"colors", "type", "state", "activeItem", "items", "hoveredItem"
}

for i, name in ipairs(publicPropertiesList) do
	local capitalizedName = capitalizeString(name)

	_G["get" .. capitalizedName] = function (widget)
		widget = Render.getWidgetById(sourceResourceRoot, widget)
		if not widget then
			return false
		end
		return widget[name]
	end

	printMetaExport("get" .. capitalizedName)

	_G["set" .. capitalizedName] = function (widget, value)
		widget = Render.getWidgetById(sourceResourceRoot, widget)

		if not widget then
			return false
		end

		if value == nil then
			return false
		end

		if type(widget["set" .. capitalizedName]) == "function" then
			widget[name] = widget["set" .. capitalizedName](widget, value)
		else
			widget[name] = value
		end
		
		return true
	end

	printMetaExport("set" .. capitalizedName)
end