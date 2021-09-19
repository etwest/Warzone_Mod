function Client_PresentConfigureUI(rootParent)
	-- Set the default values
	NumTurns = Mod.Settings.NumTurns;
	DisplayScore = Mod.Settings.DisplayScore;
	DisplayOrder = Mod.Settings.DisplayOrder;
	if (NumTurns == nil) then
		NumTurns = 10;
	end
	if (DisplayScore == nil) then
		DisplayScore = true;
	end
	if (DisplayOrder == nil) then
		DisplayOrder = false;
	end

	-- Ask user to configure the number of turns
	row = UI.CreateHorizontalLayoutGroup(rootParent)
	UI.CreateLabel(row).SetText('Turn Limit: ')
	inputNumTurns = UI.CreateNumberInputField(row).SetSliderMinValue(5).SetSliderMaxValue(30).SetValue(NumTurns)

	-- Ask user to configure the amount of available information
	vrt = UI.CreateVerticalLayoutGroup(rootParent)
	UI.CreateLabel(vrt).SetText('Should the Following Be Displayed In Game?')
	inputDisplayScore = UI.CreateCheckBox(vrt).SetIsChecked(DisplayScore).SetText("Player's approximate score");
	inputDisplayOrder = UI.CreateCheckBox(vrt).SetIsChecked(DisplayOrder).SetText('Ordering of players by combat score');
end
