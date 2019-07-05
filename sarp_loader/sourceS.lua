function showTheLoadScreen(elementToShow, timeToExecute, loadingTexts, event, eventArgs)
    triggerClientEvent(elementToShow, "showTheLoadScreen", elementToShow, timeToExecute, loadingTexts, event, eventArgs)
end