function Client_SaveConfigureUI(alert)
	Mod.Settings.NumTurns = inputNumTurns.GetValue();

	if Mod.Settings.NumTurns < 2 then
		alert("The number of turns must be greater than 2")
	end
	if Mod.Settings.NumTurns > 1000 then
		alert("The number of turns must be less than 1000")
	end
end
