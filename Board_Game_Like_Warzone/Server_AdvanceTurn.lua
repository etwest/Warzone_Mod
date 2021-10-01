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
		
		-- write the number of armies lost through this attack to LostArmiesFrom
		publicGameData.LostArmiesFrom[defenderID][attackerID] = publicGameData.LostArmiesFrom[defenderID][attackerID] + result.DefendingArmiesKilled.NumArmies;
		publicGameData.LostArmiesFrom[attackerID][defenderID] = publicGameData.LostArmiesFrom[attackerID][defenderID] + result.AttackingArmiesKilled.NumArmies;
		Mod.PublicGameData = publicGameData;
		-- print('LostArmiesFrom[attacker][defender] = ' .. publicGameData.LostArmiesFrom[attackerID][defenderID])
		-- print('LostArmiesFrom[defender][attacker] = ' .. publicGameData.LostArmiesFrom[defenderID][attackerID])
	end
end

function Server_AdvanceTurn_End(game, addNewOrder)
	-- print("ENDING TURN: " .. game.ServerGame.Game.NumberOfTurns + 1)

	-- local variables
	local publicGameData = Mod.PublicGameData;
	local lostArmiesFrom = publicGameData.LostArmiesFrom;
	local incomes        = {};

	for id, player in pairs(game.Game.Players) do
		incomes[id] = player.Income(0, game.ServerGame.PreviousTurnStanding, false, true).Total;
	end

	-- for each pair of players
	 	-- if at war
		  -- figure out income that attacked player A and income that attacked player B
		  -- weight each of their kills by get_points function.
	for player1, attacked_by in pairs(lostArmiesFrom) do
		for player2, _ in pairs(attacked_by) do
			if not (player1 == player2) and lostArmiesFrom[player1][player2] > 0 then
				local p1_kills = lostArmiesFrom[player2][player1];
				local p2_kills = lostArmiesFrom[player1][player2];

				-- print('checking points for combat between: ' .. player1 .. ' and ' .. player2);
				-- assign points to player1 weighted by the incomes of the player attacking 1 vs 2
				local p1_side_income = 0; -- the incomes of players that attacked p2
				local p2_side_income = 0; -- the incomes of players that attacked p1
				local max_p1_side_kills = 0;
				local max_p2_side_kills = 0;
				for _, kills in pairs(lostArmiesFrom[player2]) do
					if kills > max_p1_side_kills then
						max_p1_side_kills = kills
					end
				end
				for oth_player, kills in pairs(lostArmiesFrom[player2]) do
					-- print('damaged p2: ' .. oth_player .. ': ' .. kills .. '/' .. max_p1_side_kills .. '*' .. incomes[oth_player]);
					p1_side_income = p1_side_income + (kills/max_p1_side_kills) * incomes[oth_player];
				end

				for _, kills in pairs(lostArmiesFrom[player1]) do
					if kills > max_p2_side_kills then
						max_p2_side_kills = kills
					end
				end
				for oth_player, kills in pairs(lostArmiesFrom[player1]) do
					-- print('damaged p1: ' .. oth_player .. ': ' .. kills .. '/' .. max_p2_side_kills .. '*' .. incomes[oth_player]);
					p2_side_income = p2_side_income + (kills/max_p2_side_kills) * incomes[oth_player];
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

	-- print the current points to game history
	-- loop through all players and calculate the number of points they have
	-- this includes kill_points and current income
	-- we will just add these together to determine the winner
	local kill_points   = publicGameData.KillPoints;
	local income_points = publicGameData.IncomePoints;
	local total_points  = {};
	local incomes       = {};
	
	local player_ids    = {};
	local standing      = game.ServerGame.LatestTurnStanding;

	-- We need to recalculate the current incomes because that may
	-- have changed dramatically in this turn
	for id, player in pairs(game.Game.Players) do
		if player.State == 3 or player.Surrendered then -- if player is eliminated or surrendered then their income is 0
			incomes[id] = 0;
		else
			local player_income = player.Income(0, standing, false, false).Total;
			incomes[id]         = player_income;
		end
		income_points[id]   = incomes[id] * Mod.Settings.NumTurns / 4;
		total_points[id]    = kill_points[id] + income_points[id];
		table.insert(player_ids, id);
	end

	-- sort the players by their total points
	-- TODO: account for ties
	table.sort(player_ids, function(a, b)
		return total_points[a] > total_points[b]
	end)

	-- for each player save their total points for referencing later
	local points_data = {}
	for position, player in pairs(player_ids) do
		local msg_string = position .. ". " .. game.Game.Players[player].DisplayName(nil, false) .. "\n";
		msg_string = msg_string .. "Total Points = " .. string.format("%.3f", total_points[player]) .. "\n"
		msg_string = msg_string .. "Has " .. string.format("%.3f", kill_points[player]) .. " points from combat and " 
		msg_string = msg_string .. string.format("%.3f", income_points[player]) .. " from end of turn income."
		points_data[position] = msg_string;
	end
	table.insert(publicGameData.PointsList, points_data);

	empty_lost_info(publicGameData); -- reset TotalLosses and LostArmiesFrom
	publicGameData.IncomePoints = income_points;
	Mod.PublicGameData = publicGameData; -- write to PublicGameData

	if game.ServerGame.Game.NumberOfTurns >= Mod.Settings.NumTurns - 1 then
		-- for each player display their total points publicly
		for position, player in pairs(player_ids) do
			local msg_string = position .. ". " .. game.Game.Players[player].DisplayName(nil, false) .. "\n";
			msg_string = msg_string .. "Total Points = " .. string.format("%.3f", total_points[player]) .. "\n"
			msg_string = msg_string .. "Has " .. string.format("%.3f", kill_points[player]) .. " points from combat and " 
			msg_string = msg_string .. string.format("%.3f", income_points[player]) .. " from end of turn income."
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
	-- print('\n\nNew TURN')
end

function empty_lost_info(publicGameData)
	for player, attacked_by in pairs(publicGameData.LostArmiesFrom) do 
		for oth_player in pairs(attacked_by) do 
			publicGameData.LostArmiesFrom[player][oth_player] = 0;
		end
	end
end

-- Return the amount of points to be assigned to the attacker and defender
function get_points(attacker_killed, defender_killed, attacker_income, defender_income)
	-- this is one approach in which only the one with more income is 'punished'
	-- another approach would be to take the square root
	local income_ratio = defender_income / attacker_income;
	local attacker_ratio = income_ratio;
	local defender_ratio = income_ratio;
	if (attacker_income > defender_income) then
		defender_ratio = 1;
	else
		attacker_ratio = 1;
	end
	
	local attacker_points = attacker_killed * attacker_ratio;
	local defender_points = defender_killed / defender_ratio;
	-- print('attacker_points = ' .. attacker_points);
	return attacker_points, defender_points;
end
