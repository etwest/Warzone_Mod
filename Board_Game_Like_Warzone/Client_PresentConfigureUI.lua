function Client_PresentConfigureUI(rootParent)
	-- Set the default values
	NumTurns        = Mod.Settings.NumTurns;
	DisplayRelative = Mod.Settings.DisplayRelative;
	DisplayOrder    = Mod.Settings.DisplayOrder;
	if (NumTurns == nil) then
		NumTurns = 10;
	end
	if (DisplayRelative == nil) then
		DisplayRelative = true;
	end
	if (DisplayOrder == nil) then
		DisplayOrder = false;
	end

	vrt = UI.CreateVerticalLayoutGroup(rootParent)

	-- Ask user to configure the number of turns
	row = UI.CreateHorizontalLayoutGroup(vrt)
	UI.CreateLabel(row).SetText('Turn Limit: ')
	inputNumTurns = UI.CreateNumberInputField(row).SetSliderMinValue(5).SetSliderMaxValue(30).SetValue(NumTurns)

	-- Ask user to configure the amount of available information
	UI.CreateLabel(vrt).SetText('Should the Following Be Displayed In Game?')
	inputDisplayRelative = UI.CreateCheckBox(vrt).SetIsChecked(DisplayRelative).SetText("Individual player's score and relative ranking");
	inputDisplayOrder = UI.CreateCheckBox(vrt).SetIsChecked(DisplayOrder).SetText('Ordering of all players by total score');
end
