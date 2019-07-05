Render = {}
Render.resources = {}
Render.clickedWidget = false
Render.mouseClick = false

local screenWidth, screenHeight = guiGetScreenSize()
local oldMouseState = false

local function draw()
	Drawing.setColor()
	Drawing.origin()

	Render.clickedWidget = false

	local newMouseState = getKeyState("mouse1") or getKeyState("mouse2")
	if not Render.mouseClick and newMouseState and not oldMouseState then
		Render.mouseClick = true
	end
	oldMouseState = newMouseState

	local mouseX, mouseY = getMousePosition()
	
	for resourceRoot, resourceInfo in pairs(Render.resources) do
		Widget.draw(resourceInfo.rootWidget, mouseX, mouseY, mouseX, mouseY)
	end

	if Render.mouseClick then
		triggerEvent("_sarpUI.clickInternal", resourceRoot)
	end

	if Render.clickedWidget then
		triggerEvent("sarpUI.click", Render.clickedWidget.resourceRoot, Render.clickedWidget.id, getKeyState("mouse1") and "left" or "right")

		if type(Render.clickedWidget.click) == "function" then
			Render.clickedWidget:onClick(mouseX, mouseY)
		end
	end

	Render.mouseClick = false
end

local function update(deltaTime)

end

function Render.start()
	addEventHandler("onClientRender", root, draw)
	--addEventHandler("onClientPreRender", root, update)
	triggerEvent("onInterfaceStarted", localPlayer)
end

function Render.setupResource(resourceRoot)
	if Render.resources[resourceRoot] then
		return false
	end

	Render.resources[resourceRoot] = {
		widgets = {},
		rootWidget = Widget.create()
	}

	table.insert(Render.resources[resourceRoot].widgets, Render.resources[resourceRoot].rootWidget)
	Render.resources[resourceRoot].rootWidget.id = 1
end

function Render.exportWidget(widget, resourceRoot)
	Render.setupResource(resourceRoot)

	table.insert(Render.resources[resourceRoot].widgets, widget)

	widget.id = #Render.resources[resourceRoot].widgets
	widget.resourceRoot = resourceRoot

	return widget.id
end

function Render.getWidgetById(resourceRoot, id)
	if not resourceRoot or not id then
		return false
	end

	if not Render.resources[resourceRoot] then
		return false
	end

	return Render.resources[resourceRoot].widgets[id]
end

function Render.destroyWidget(resourceRoot, id)
	if not resourceRoot or not id then
		return false
	end

	if not Render.resources[resourceRoot] then
		return false
	end

	Render.resources[resourceRoot].widgets[id] = nil

	return true
end

addEventHandler("onClientResourceStop", root, function ()
	Render.resources[source] = nil
end)