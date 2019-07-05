local screenX, screenY = guiGetScreenSize()

local currentPage = 0
local jobsVisible = 3
local scrollbarPosition = 0
local scrollbarInterpolationTick = false

local showJobPanel = false
local selectedJob = nil

local reponsiveMultipler = exports.sarp_hud:getResponsiveMultipler()

function resp(x)
    return x * reponsiveMultipler
end

function respc(x)
    return math.ceil(x * reponsiveMultipler)
end

local bebas15 = dxCreateFont(":sarp_assets/fonts/BebasNeue.otf", resp(15))
local bebas20 = dxCreateFont(":sarp_assets/fonts/BebasNeue.otf", resp(20))
local century13 = dxCreateFont(":sarp_assets/fonts/CenturyGothicRegular.ttf", resp(13))
local century16 = dxCreateFont(":sarp_assets/fonts/CenturyGothicRegular.ttf", resp(16))

addEventHandler("onClientRender", root, function()
    if showJobPanel then
        local lBlockW, lBlockH = resp(600), resp(650)
        local lBlockX, lBlockY = (screenX / 2) + resp(10), (screenY / 2) - (lBlockH / 2)
        dxDrawRectangle(lBlockX, lBlockY, lBlockW, lBlockH, tocolor(0, 0, 0, 190)) 

        local jobNameTextW, jobNameTextH
        local jobNameTextX, jobNameTextY
        if selectedJob == nil then
            jobNameTextW, jobNameTextH = lBlockW, lBlockH
            jobNameTextX, jobNameTextY = lBlockX, lBlockY
            dxDrawText("Nincs kiválasztott munka\nHúzd a kurzorod a képre", jobNameTextX, jobNameTextY, jobNameTextX + jobNameTextW, jobNameTextY + jobNameTextH, tocolor(255, 255, 255, 255), 1, bebas15, "center", "center")
        else
            jobNameTextW, jobNameTextH = lBlockW, lBlockH
            jobNameTextX, jobNameTextY = lBlockX, lBlockY
            if not getElementData(localPlayer, "adminDuty") then 
                dxDrawText(jobs[selectedJob][1], jobNameTextX, jobNameTextY + resp(20) , jobNameTextX + jobNameTextW, jobNameTextY + jobNameTextH, tocolor(255, 255, 255, 255), 1, bebas20, "center")
            else
                dxDrawText(jobs[selectedJob][1] .. " (ID: " .. selectedJob .. ")", jobNameTextX, jobNameTextY + resp(20) , jobNameTextX + jobNameTextW, jobNameTextY + jobNameTextH, tocolor(255, 255, 255, 255), 1, bebas20, "center")
            end

            local jobDescriptionTextW, jobDescriptionTextH = lBlockW, lBlockH
            local jobDescriptionTextX, jobDescriptionTextY = lBlockX, lBlockY
            dxDrawText("Munkaköri leírás:", jobDescriptionTextX, jobDescriptionTextY + resp(100), jobDescriptionTextX + jobDescriptionTextW, jobDescriptionTextY + jobDescriptionTextH, tocolor(255, 255, 255, 255), 1, century16, "center")
            dxDrawText(jobs[selectedJob][3], jobDescriptionTextX + resp(20), jobDescriptionTextY + resp(130), jobDescriptionTextX + jobDescriptionTextW - resp(20), jobDescriptionTextY + jobDescriptionTextH, tocolor(255, 255, 255, 255), 1, century13, "center", "top", false, true)
        end

        local eButtonW, eButtonH = resp(140), resp(30)
        local eButtonX, eButtonY = lBlockX + lBlockW - eButtonW - resp(10), lBlockY + lBlockH - eButtonH - resp(10)

        local exitTextW, exitTextH = eButtonW, eButtonH
        local exitTextX, exitTextY = eButtonX, eButtonY 
        dxDrawRectangle(eButtonX, eButtonY, eButtonW, eButtonH, tocolor(50, 179, 239, 230))
        dxDrawText("Bezárás", exitTextX, exitTextY, exitTextX + exitTextW, exitTextY + exitTextH, tocolor(255, 255, 255, 255), 1, century13, "center", "center")
            

        local rBlockW, rBlockH = resp(500), resp(200)
        local rBlockX, rBlockY = (screenX / 2) - rBlockW - resp(10), (screenY / 2) - (lBlockH / 2)

        local scrollW, scrollH = resp(15), lBlockH
        local scrollX, scrollY = rBlockX - scrollW - resp(5), lBlockY 
        dxDrawRectangle(scrollX, scrollY, scrollW, scrollH, tocolor(0, 0, 0, 190))

        local scrollBarW, scrollBarH = resp(11), resp(10)
        local scrollBarX, scrollBarY = scrollX + resp(2), scrollY + resp(3) 
       
        if #jobs > jobsVisible then
            local currentTick = getTickCount()
            local scrollbarCalculatedHeight = scrollH / #jobs
            
            if scrollbarInterpolationTick and currentTick >= scrollbarInterpolationTick then
                local scrollbarMoveAnimation = interpolateBetween(scrollbarPosition, 0, 0, scrollbarCalculatedHeight * math.min(currentPage, #jobs - jobsVisible), 0, 0, (currentTick - scrollbarInterpolationTick) / 500, "OutQuad")
                scrollbarPosition = scrollbarMoveAnimation
            end
            
            dxDrawRectangle(scrollBarX, scrollBarY, scrollBarW, scrollBarH, tocolor(0, 0, 0, 190))
            dxDrawRectangle(scrollBarX, scrollBarY + scrollbarPosition, scrollBarW, (scrollbarCalculatedHeight * jobsVisible) - scrollBarH * 0.5, tocolor(50, 179, 239, 230))
        end
        
        local c = 0
        for i = 1, jobsVisible do
            local v = jobs[i + currentPage]
            if v then
                print(c, i, i+currentPage)
                local blockX, blockY = rBlockX, rBlockY + ((rBlockH + resp(25)) * c)
                dxDrawRectangle(blockX, blockY, rBlockW, rBlockH, tocolor(0, 0, 0, 190)) 
                
                local imageW, imageH = rBlockW - resp(10), rBlockH - resp(10)
                local imageX, imageY = blockX + resp(5), blockY + resp(5)
                dxDrawImage(imageX, imageY, imageW, imageH, v[2])

                local buttonW, buttonH = imageW, rBlockH - resp(170)
                local buttonX, buttonY = blockX + resp(5), blockY + rBlockH - buttonH - resp(5)
                
                local buttonTextX, buttonTextY = buttonX, buttonY
                local buttonTextW, buttonTextH = buttonW, buttonH

                if cursorInBox(imageX, imageY, imageW, imageH) then
                    selectedJob = i + currentPage
                    if tonumber(getElementData(localPlayer, "char.Job") or 0) == tonumber(selectedJob) then
                        dxDrawRectangle(buttonX, buttonY, buttonW, buttonH, tocolor(143, 67, 67, 230)) -- 143, 67, 67
                        dxDrawText("Munkaviszony felmondása", buttonTextX, buttonTextY, buttonTextX + buttonTextW, buttonTextY + buttonTextH, tocolor(255, 255, 255, 255), 1, century13, "center", "center")
                    else
                        dxDrawRectangle(buttonX, buttonY, buttonW, buttonH, tocolor(50, 179, 239, 230)) -- 143, 67, 67
                        dxDrawText("Munka felvétele", buttonTextX, buttonTextY, buttonTextX + buttonTextW, buttonTextY + buttonTextH, tocolor(255, 255, 255, 255), 1, century13, "center", "center")
                    end
                end

                local nameTextX, nameTextY = imageX, imageY
                local nameTextW, nameTextH = imageW, imageH
                dxDrawBorderedText(v[1], nameTextX, nameTextY, nameTextX + nameTextW, nameTextY + nameTextH, tocolor(255, 255, 255, 255), 1, bebas15, "center", "center")
                c = c + 1
            end
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if showJobPanel then
        if press then
            if #jobs > jobsVisible then
                if key == "mouse_wheel_down" and currentPage < #jobs - jobsVisible then
                    scrollbarInterpolationTick = getTickCount()
                    currentPage = currentPage + jobsVisible
                elseif key == "mouse_wheel_up" and currentPage > 0 then
                    scrollbarInterpolationTick = getTickCount()
                    currentPage = currentPage - jobsVisible
                end
            end
        end
    end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if showJobPanel then
        if button == "left" then
            if state == "down" then

                local lBlockW, lBlockH = resp(600), resp(650)
                local lBlockX, lBlockY = (screenX / 2) + resp(10), (screenY / 2) - (lBlockH / 2)

                local rBlockW, rBlockH = resp(500), resp(200)
                local rBlockX, rBlockY = (screenX / 2) - rBlockW - resp(10), (screenY / 2) - (lBlockH / 2)

                for i = 1, jobsVisible do
                    local v = jobs[i + currentPage]
                    if v then
                        local blockX, blockY = rBlockX, rBlockY + ((rBlockH + resp(25)) * (i - 1))
                        --dxDrawRectangle(blockX, blockY, rBlockW, rBlockH, tocolor(0, 0, 0, 190)) 
                        
                        local imageW, imageH = rBlockW - resp(10), rBlockH - resp(10)
                        local imageX, imageY = blockX + resp(5), blockY + resp(5)
                        --dxDrawImage(imageX, imageY, imageW, imageH, v[2])
        

                        local buttonW, buttonH = imageW, rBlockH - resp(170)
                        local buttonX, buttonY = blockX + resp(5), blockY + rBlockH - buttonH - resp(5)
                        if cursorInBox(buttonX, buttonY, buttonW, buttonH) then
                            if tonumber(getElementData(localPlayer, "char.Job") or 0) == tonumber(selectedJob) then
                                triggerServerEvent( "applyPlayerJob", localPlayer, localPlayer, 0, jobs[selectedJob][1])
                            else
                                if tonumber(getElementData(localPlayer, "char.playedMinutes")) >= jobs[selectedJob][4] then
                                    triggerServerEvent( "applyPlayerJob", localPlayer, localPlayer, selectedJob, jobs[selectedJob][1])
                                else
                                    exports.sarp_hud:showAlert("error", "A " .. jobs[selectedJob][1] .. " felvételéhez", "minimum " .. jobs[selectedJob][4] .. " játszott perc szükséges")
								
								end
                            end
                        end
                    end
                end       

                local eButtonW, eButtonH = resp(140), resp(30)
                local eButtonX, eButtonY = lBlockX + lBlockW - eButtonW - resp(10), lBlockY + lBlockH - eButtonH - resp(10)
                if cursorInBox(eButtonX, eButtonY, eButtonW, eButtonH) then
                    selectedJob = nil
                    showJobPanel = false
                end
            end
        end
    else
        if button == "left" and state == "down" then
            if clickedElement and isElement(clickedElement) then
                if getElementData(clickedElement, "ped.type") == 1 then
                    if exports.sarp_core:inDistance3D(getLocalPlayer(), clickedElement, 2) then
                        showJobPanel = true
                    end
                end
            end
        end
    end
end)

function dxDrawBorderedText(text, x, y, w, h, color, ...)
	local textWithoutHEX = text:gsub("#%x%x%x%x%x%x", "")
	dxDrawText(textWithoutHEX, x - 1, y - 1, w - 1, h - 1, tocolor(0, 0, 0, 255), ...)
	dxDrawText(textWithoutHEX, x - 1, y + 1, w - 1, h + 1, tocolor(0, 0, 0, 255), ...)
	dxDrawText(textWithoutHEX, x + 1, y - 1, w + 1, h - 1, tocolor(0, 0, 0, 255), ...)
	dxDrawText(textWithoutHEX, x + 1, y + 1, w + 1, h + 1, tocolor(0, 0, 0, 255), ...)
	dxDrawText(text, x, y, w, h, color, ...)
end

function cursorInBox(x, y, w, h)
	if x and y and w and h then
		if isCursorShowing() then
			if not isMTAWindowActive() then
				local cursorX, cursorY = getCursorPosition()
				
				cursorX, cursorY = cursorX * screenX, cursorY * screenY
				
				if cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h then
					return true
				end
			end
		end
	end
	
	return false
end
