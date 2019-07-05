local connection = false

addEventHandler("onResourceStart", getRootElement(),
    function (startedResource)
        if getResourceName(startedResource) == "sarp_database" then
            connection = exports.sarp_database:getConnection()
        elseif source == getResourceRootElement() then
            if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
                connection = exports.sarp_database:getConnection()
            end
        end
    end
)

local registerEvent = function(eventName, element, func)
    addEvent(eventName, true)
    addEventHandler(eventName, element, func)
end

function setPlayerBankMoney(player, value)
    if not player then
        player = source
    end

    dbQuery( -- PÉNZZEL NEM SZÓRAKOZUNK, EGYBŐL MENTÜNK ADATBÁZISBA HA PL. CRASHELNE A SZERVER NE VESSZEN EL A JÁTÉKOSTÓL
        function (qh, sourcePlayer)
            setElementData(sourcePlayer, "char.bankMoney", value)
            triggerClientEvent(sourcePlayer, "sarp_bankC:updateBalance", sourcePlayer)

            dbFree(qh)
        end, {player}, connection, "UPDATE characters SET bankMoney = ? WHERE charID = ?", value, getElementData(player, "char.ID")
    )
end
registerEvent("sarp_bankS:setPlayerBankMoney", root, setPlayerBankMoney)

function givePlayerBankMoney(player, value)
    if not player then
        player = source
    end

    if (getElementData(player, "char.Money") or 0) - value >= 0 then
        local finalValue = getElementData(player, "char.bankMoney") + value

        dbQuery( -- PÉNZZEL NEM SZÓRAKOZUNK, EGYBŐL MENTÜNK ADATBÁZISBA HA PL. CRASHELNE A SZERVER NE VESSZEN EL A JÁTÉKOSTÓL
            function (qh, sourcePlayer)
                setElementData(sourcePlayer, "char.bankMoney", finalValue)
                exports.sarp_core:takeMoney(sourcePlayer, value)
                triggerClientEvent(sourcePlayer, "sarp_bankC:updateBalance", sourcePlayer)

                dbFree(qh)
            end, {player}, connection, "UPDATE characters SET bankMoney = ?, money = ? WHERE charID = ?", finalValue, getElementData(player, "char.Money") - value, getElementData(player, "char.ID")
        )
    else
        exports["sarp_alert"]:showAlert(player, "error", "Sikeretelen tranzakció!", "Nincs ennyi pénz a kezedben")
    end
end
registerEvent("sarp_bankS:givePlayerBankMoney", root, givePlayerBankMoney)

function takePlayerBankMoney(player, value)
    if not player then
        player = source
    end

    if getElementData(player, "char.bankMoney") > 0 and getElementData(player, "char.bankMoney") >= value then 
        local finalValue = getElementData(player, "char.bankMoney") - value

        dbQuery( -- PÉNZZEL NEM SZÓRAKOZUNK, EGYBŐL MENTÜNK ADATBÁZISBA HA PL. CRASHELNE A SZERVER NE VESSZEN EL A JÁTÉKOSTÓL
            function (qh, sourcePlayer)
                setElementData(sourcePlayer, "char.bankMoney", finalValue)
                exports.sarp_core:giveMoney(sourcePlayer, value)
                triggerClientEvent(sourcePlayer, "sarp_bankC:updateBalance", sourcePlayer)

                dbFree(qh)
            end, {player}, connection, "UPDATE characters SET bankMoney = ?, money = ? WHERE charID = ?", finalValue, getElementData(player, "char.Money") + value, getElementData(player, "char.ID")
        )
    else
        exports["sarp_alert"]:showAlert(player, "error", "Sikeretelen tranzakció!", "Nincs ennyi pénz a számládon")
    end
end
registerEvent("sarp_bankS:takePlayerBankMoney", root, takePlayerBankMoney)