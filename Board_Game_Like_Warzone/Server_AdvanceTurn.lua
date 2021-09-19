require('Utilities');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == 'GameOrderAttackTransfer') then
		local terr_map = game.ServerGame.LatestTurnStanding.Territories;
		-- printGameOrderAttackTransfer(order, result, terr_map, game.ServerGame.Game.Players)
		
		-- Don't get points for fighting neutral or transfers
		if (terr_map[order.To].IsNeutral or not result.IsAttack) then
			return;
		end

		-- some variables
		local attackerID = terr_map[order.From].OwnerPlayerID;
		local defenderID = terr_map[order.To].OwnerPlayerID;
		local publicGameData = Mod.PublicGameData;
		
		-- write the number of armies lost through this attack to LostArmiesFrom and TotalLosses
		publicGameData.TotalLosses[attackerID] = publicGameData.TotalLosses[attackerID] + result.AttackingArmiesKilled.NumArmies;
		publicGameData.TotalLosses[defenderID] = publicGameData.TotalLosses[defenderID] + result.DefendingArmiesKilled.NumArmies;
		publicGameData.LostArmiesFrom[defenderID][attackerID] = publicGameData.LostArmiesFrom[defenderID][attackerID] + result.DefendingArmiesKilled.NumArmies;
		publicGameData.LostArmiesFrom[attackerID][defenderID] = publicGameData.LostArmiesFrom[attackerID][defenderID] + result.AttackingArmiesKilled.NumArmies;
		Mod.PublicGameData = publicGameData;
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	-- local variables
	local publicGameData = Mod.PublicGameData;
	local totalLosses    = publicGameData.TotalLosses;
	local lostArmiesFrom = publicGameData.LostArmiesFrom;
	local incomes        = {};

	for id, player in pairs(game.Game.Players) do
		incomes[id] = player.Income(0, game.ServerGame.PreviousTurnStanding, false, true).Total;
	end

	for player1, total_loss1 in pairs(totalLosses) do
		for player2, total_loss2 in pairs(totalLosses) do
			if not (player1 == player2) and lostArmiesFrom[player1][player2] > 0 then
				local p1_kills = lostArmiesFrom[player2][player1];
				local p2_kills = lostArmiesFrom[player1][player2];

				-- print('checking points for combat between: ' .. player1 .. ' and ' .. player2);
				-- assign points to player1 weighted by the incomes of the player attacking 1 vs 2
				local p1_side_income = 0; -- the incomes of players that attacked p2
				local p2_side_income = 0; -- the incomes of players that attacked p1
				for oth_player, kills in pairs(lostArmiesFrom[player2]) do
					-- print('damaged p2: ' .. oth_player .. ': ' .. kills .. '/' .. total_loss2 .. '*' .. incomes[oth_player]);
					p1_side_income = p1_side_income + (kills/total_loss2) * incomes[oth_player];
				end
				for oth_player, kills in pairs(lostArmiesFrom[player1]) do
					-- print('damaged p1: ' .. oth_player .. ': ' .. kills .. '/' .. total_loss1 .. '*' .. incomes[oth_player]);
					p2_side_income = p2_side_income + (kills/total_loss1) * incomes[oth_player];
				end

				-- print('p1_side_income: ' .. p1_side_income);
				-- print('p2_side_income: ' .. p2_side_income);

				p1_points, p2_points = get_points(p1_kills, p2_kills, p1_side_income, p2_side_income);
				-- TODO: this could be improved by utilizing the p2_points as well (requires changing second for loop)
				publicGameData.KillPoints[player1] = publicGameData.KillPoints[player1] + p1_points;
				-- print('Total Kill points p1: ' .. publicGameData.KillPoints[player1])
			end
		end
	end

	empty_lost_info(publicGameData); -- reset TotalLosses and LostArmiesFrom
	Mod.PublicGameData = publicGameData; -- write to PublicGameData

	-- check if we should end the game
	if game.ServerGame.Game.NumberOfLogicalTurns >= Mod.Settings.NumTurns - 1 then
		end_game(game, addNewOrder)
	end
end

-- for each pair of players
 	-- if at war
	  -- figure out income that attacked player A and income that attacked player B
	  -- weight each of their kills by get_points function.

function empty_lost_info(publicGameData)
	for player in pairs(publicGameData.TotalLosses) do 
		publicGameData.TotalLosses[player] = 0;
		for oth_player in pairs(publicGameData.LostArmiesFrom[player]) do 
			publicGameData.LostArmiesFrom[player][oth_player] = 0;
		end
	end
end

-- This part is for adjusting the number of points
-- Thoughts: I think we want to implement the tally it up and assign points at the end
--           method
--           Basically, because of the Matthew vs Alicia war with Yitzhar attacking in the background.
--           Yitzhar shouldn't get a ton of points for doing that even though he's weaker than Matthew because
--           Matthew was at the time fighting an opponent of equivalent strength (Alicia)
function get_points(attacker_killed, defender_killed, attacker_income, defender_income)
	local income_ratio    = (defender_income / attacker_income);
	local attacker_points = attacker_killed * income_ratio;
	local defender_points = defender_killed / income_ratio;
	-- print('attacker_points = ' .. attacker_points);
	return attacker_points, defender_points;
end

function end_game(game, addNewOrder)
	-- loop through all players and calculate the number of points they have
	-- this includes kill_points and current income
	-- temporarily we will just add these together to determine the winner
	local killPoints    = Mod.PublicGameData.KillPoints;
	local total_points  = Mod.PublicGameData.KillPoints;
	local incomes       = {};
	local income_points = {};
	local player_ids    = {};
	local standing      = game.ServerGame.LatestTurnStanding;

	print("ENDING game and assigning winner")

	-- We need to recalculate the current incomes because that may
	-- have changed dramatically in this last turn
	for id, player in pairs(game.Game.Players) do
		if player.State == 3 or player.Surrendered then -- if player is eliminated or surrendered then their income is 0
			incomes[id] = 0;
		else
			local player_income = player.Income(0, standing, false, true).Total;
			incomes[id]         = player_income;
		end
		income_points[id]   = incomes[id] * Mod.Settings.NumTurns / 4;
		total_points[id]    = total_points[id] + income_points[id];
		table.insert(player_ids, id);
	end

	-- sort the players by their total points
	-- TODO: account for ties
	table.sort(player_ids, function(a, b)
		return total_points[a] > total_points[b]
	end)

	-- for each player display their total points
	for position, player in pairs(player_ids) do
		local msg_string = position .. ". " .. game.Game.Players[player].DisplayName(nil, false) .. "\n";
		msg_string = msg_string .. "Total Points = " .. string.format("%.3f", total_points[player]) .. "\n"
		msg_string = msg_string .. "Got " .. string.format("%.3f", killPoints[player]) .. " points from combat and " 
		msg_string = msg_string .. string.format("%.3f", income_points[player]) .. " from end of game income."
		addNewOrder(WL.GameOrderEvent.Create(player, msg_string, nil, {}));
	end

	-- declare a winner and assign all territories to them
	-- winner is first id from player_ids
	local winner_takes_all = {}
	for _, territory in pairs(standing.Territories) do
		local territory_mod = WL.TerritoryModification.Create(territory.ID);
		territory_mod.SetOwnerOpt = player_ids[1]; -- lua indexes by 1
		table.insert(winner_takes_all, territory_mod);
	end
	addNewOrder(WL.GameOrderEvent.Create(player_ids[1], "Wins the game!", nil, winner_takes_all));
end
