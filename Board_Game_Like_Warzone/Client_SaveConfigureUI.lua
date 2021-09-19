function Client_SaveConfigureUI(alert)
	Mod.Settings.NumTurns = inputNumTurns.GetValue();
	Mod.Settings.DisplayScore = inputDisplayScore.GetIsChecked();
	Mod.Settings.DisplayOrder = inputDisplayScore.GetIsChecked();

	if Mod.Settings.NumTurns < 2 then
		alert("The number of turns must be greater than or equal to 2")
	end
	if Mod.Settings.NumTurns > 1000 then
		alert("The number of turns must be less than 1000")
	end
end
