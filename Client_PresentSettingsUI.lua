
function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel(rootParent).SetText('The winner of this game will be decided by the number of points earned by each player. Points are earned by killing armies and by your income at the end of the game.');

	row = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(row).SetText('The game will last for ');
	UI.CreateLabel(row).SetText(Mod.Settings.NumTurns .. ' turns.').SetColor('#FF2200');
end
