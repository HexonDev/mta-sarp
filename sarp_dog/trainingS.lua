
addEventHandler("onResourceStart", getResourceRootElement(), function()
    setTimer(function()
        trainerPed = createPed(100, 1578.80859375, -1702.98828125, 5.890625)
        setElementData(trainerPed, "ped.dogtrainer", true)
        setElementData(trainerPed, "ped.inUse", false)
		setElementData(trainerPed, "ped.name", "Kutya_kiképző")
    end, 2000, 1)
end)