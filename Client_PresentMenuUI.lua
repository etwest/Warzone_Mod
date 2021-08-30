require('Utilities');

function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game)
	SubmitBtn = nil;

	setMaxSize(450, 280);

	vert = UI.CreateVerticalLayoutGroup(rootParent);
	local row = UI.CreateHorizontalLayoutGroup(vert);
	UI.CreateLabel(row).SetText("Players ordered by their current scores:")

	-- get the players, ordered by points
	local player_by_points = get_player_order(game);

	-- display the current order of players
	-- We might want to think about what the actual best information to display is
	-- Ideas:
	--   Display the current position of player and appoximate score (factor in incomes or no?)
	-- Main problem is I don't want to give away information about income too much or really at all.
	-- Keeping that a mystery is part of the fun I think.
	-- I think its part of the skill of the game to determine relative incomes and part of the diplo
	for position, player in ipairs(player_by_points) do
		local row = UI.CreateHorizontalLayoutGroup(vert);
		local player_obj = game.Game.Players[player];
		UI.CreateLabel(row).SetText(position .. ". " .. player_obj.DisplayName(nil, false))
	end

	-- if (game.Us == nil) then
	-- 	local row = UI.CreateHorizontalLayoutGroup(vert);
	-- 	UI.CreateLabel(row).SetText("You cannot gift armies since you're not in the game");
	-- 	return;
	-- end
end

function get_player_order(game)
	local sorted_players = {}
	local kill_info = Mod.PublicGameData.KillInfo;
	for player in pairs(game.Game.Players) do
		table.insert(sorted_players, player)
	end

	table.sort(sorted_players, function(a, b)
		return kill_info[a] < kill_info[b]
	end)

	return sorted_players
end
