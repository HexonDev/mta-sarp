adminCMDs = {
	["adminduty"] = {-2, false},
	["goto"] = {1, "/#cmd [Játékos ID]"},
	["gethere"] = {1, "/#cmd [Játékos ID]"},
	["vá"] = {-2, "/#cmd [Játékos ID] [Üzenet]"},
	["asay"] = {1, "/#cmd [Üzenet]"},
	["freconnect"] = {6, "/#cmd [Játékos ID]"},
	["giveitem"] = {6, "/#cmd [Játékos ID] [Item ID] [Item darab] ([data1] [data2] [data3])"},
	--["takeitem"] = {6, "/#cmd [ID]"},
	["kick"] = {1, "/#cmd [Játékos ID] [Indok]"},
	["freeze"] = {1, "/#cmd [Játékos ID]"},
	["unfreeze"] = {1, "/#cmd [Játékos ID]"},
	["fadminduty"] = {7, "/#cmd [Játékos ID]"},
	["vanish"] = {3, false},
    ["setadminnick"] = {6, "/#cmd [Játékos ID] [Becenév]"},
    ["ffly"] = {6, "/#cmd [Játékos ID]"},
    ["fly"] = {1, false},
    ["sethp"] = {4, "/#cmd [Játékos ID] [Érték]"},
    ["makeadmin"] = {-2, "/#cmd [Játékos ID] [Érték]"},
    ["spec"] = {1, "/#cmd [Játékos ID]"},
    ["setarmor"] = {1, "/#cmd [Játékos ID] [Érték]"}, 
    ["setskin"] = {1, "/#cmd [Játékos ID] [SKIN ID]"},
    ["changename"] = {1, "/#cmd [Játékos ID] [új_név]"},
    ["hideadmin"] = {1, false}, --
    ["gotoplace"] = {1, "/#cmd [Hely]"}, 
    ["setmoney"] = {1, "/#cmd [Játékos ID] [Érték]"},
    ["givemoney"] = {1, "/#cmd [Játékos ID] [Érték]"},
    ["takemoney"] = {1, "/#cmd [Játékos ID] [Érték]"},
    ["ajail"] = {1, "/#cmd [Játékos Neve / ID] [Idő (perc)] [Indok]"},
    ["unajail"] = {1, "/#cmd [Játékos Neve/ ID] [Indok]"},
    ["ajailed"] = {1, false},
    ["oajail"] = {1, "/#cmd [Serial / AccountID] [Idő (perc)] [Indok]"},
    ["oaujail"] = {1, "/#cmd [Serial / AccountID] [Indok]"},
    ["createnpc"] = {1, "/#cmd [Skin ID] [Típus] [NPC Altípus] [NPC Név]"},
    ["deletenpc"] = {1, "/#cmd [NPC ID]"},
    ["aban"] = {1, "/#cmd [Játékos ID / névrészlet] [Idő (óra | 0 = örök] [Indok]"},
    ["unaban"] = {1, "/#cmd [AccountID / Serial]"},
    ["oaban"] = {1, "/#cmd [AccountID / Serial] [Idő (óra | 0 = örök)] [Indok]"},
    ["getveh"] = {1, "/#cmd [Jármű ID]"},
    ["gotoveh"] = {1, "/#cmd [Jármű ID]"},
    ["fixveh"] = {1, "/#cmd [Jármű ID]"},
    ["respawnveh"] = {1, "/#cmd [Jármű ID]"},
    ["setvehfuel"] = {1, "/#cmd [Jármú ID] [Üzemanyag szint (0-100)]"},
    ["unflipveh"] = {1, "/#cmd [Jármű ID]"},
    ["delveh"] = {1, "/#cmd [Jármű ID]"},
    ["makeveh"] = {1, "/#cmd [Jármű Model ID] [Játékos ID] [Frakció ID] [R] [G] [B]"},
    ["dl"] = {-2, false},
    ["deleteatm"] = {1, "/#cmd [ATM ID]"},
    ["createatm"] = {1, false},
    ["blowveh"] = {6, "/#cmd [Jármű ID]"},
    ["setvehcolor"] = {6, "/#cmd [Jármű ID] [R] [G] [B]"},
    ["setvehpaintjob"] = {6, "/#cmd [Jármű ID] [Paintjob ID]"},
    ["gotopos"] = {1, "/#cmd [X] [Y] [Z]"},
}

adminCommands = {}

function addCommandToList(command, desc)
	assert(type(command) == "string", "Bad argument @ 'addCommandToList' [expected string at argument 1, got "..type(command).."]")
    assert(type(desc) == "string", "Bad argument @ 'addCommandToList' [expected function at argument 2, got "..type(desc).."]")
	
	adminCommands[command] = desc
end

function addAdminCommand(command, func, description)
    assert(type(command) == "string", "Bad argument @ 'addAdminCommand' [expected string at argument 1, got "..type(command).."]")
    assert(type(func) == "function", "Bad argument @ 'addAdminCommand' [expected function at argument 2, got "..type(command).."]")
    assert(type(description) == "string", "Bad argument @ 'addAdminCommand' [expected string at argument 3, got "..type(command).."]")

    addCommandHandler(command, func) 
    addCommandToList(command, description)
end