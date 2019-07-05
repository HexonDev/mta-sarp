local screenX, screenY = guiGetScreenSize()

local inJobZone = false
local jobStarted = false

local waterTexture = dxCreateTexture("files/water.png")
local sewageTexture = dxCreateTexture("files/sewage.png")

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		jobData.innerColShape.element = createColPolygon(unpack(jobData.innerColShape.details))

		for i = 1, #jobData.containers do
			local container = jobData.containers[i]

			if container then
				container.colShapeElement = createColSphere(unpack(container.colShapeDetails))
			end
		end
	end
)

addEventHandler("onClientElementColShapeHit", getLocalPlayer(),
	function (theShape, matchingDimension)
		if theShape == jobData.innerColShape.element and matchingDimension then
			inJobZone = true
		end
	end
)

addEventHandler("onClientElementColShapeLeave", getLocalPlayer(),
	function (theShape, matchingDimension)
		if theShape == jobData.innerColShape.element and matchingDimension then
			inJobZone = false
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
    function ()
    	if inJobZone then
    		for i = 1, #jobData.containers do
    			local container = jobData.containers[i]

    			if container then
    				if container.type == "water" then
    					dxDrawMaterialLine3D(container.materialPosition[1], container.materialPosition[2], container.materialPosition[3] + 0.21, container.materialPosition[1], container.materialPosition[2], container.materialPosition[3] - 0.21, waterTexture, 0.42, tocolor(50, 179, 239))
    				else
    					dxDrawMaterialLine3D(container.materialPosition[1], container.materialPosition[2], container.materialPosition[3] + 0.21, container.materialPosition[1], container.materialPosition[2], container.materialPosition[3] - 0.21, sewageTexture, 0.42, tocolor(87, 183, 137))
    				end
    			end
    		end
    	end
    end
)