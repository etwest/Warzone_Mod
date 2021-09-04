require('Utilities');

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == 'GameOrderAttackTransfer') then
		local terr_map = game.ServerGame.LatestTurnStanding.Territories;
		
		-- Don't get points for fighting neutral or transfers
		if (terr_map[order.To].IsNeutral or not result.IsAttack) then
			return;
		end

		-- some variables
		local attackerID = terr_map[order.From].OwnerPlayerID;
		local defenderID = terr_map[order.To].OwnerPlayerID;
		local publicGameData = Mod.PublicGameData;
		
		-- write the number of armies lost through this attack to LostArmiesFrom and TotalLosses
		publicGameData.TotalLosses[attackerID] = publicGameData.TotalLosses[attackerID] + result.DefendingArmiesKilled.NumArmies;
		publicGameData.TotalLosses[defenderID] = publicGameData.TotalLosses[defenderID] + result.AttackingArmiesKilled.NumArmies;
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
	local min_kills      = 10; -- minimum kills needed to be counted for combat

	for id, player in pairs(game.Game.Players) do
		incomes[id] = player.Income(0, game.ServerGame.PreviousTurnStanding, false, true).Total;
	end

	for player, total_loss in pairs(totalLosses) do
		-- calculate the total income that fought this player
		-- TODO: currently all this does is assign points based on attacks
		-- another idea would be to try to figure out the income on both sides of a 'war'
		-- then we probably need to define what a 'war' is
		local total_income = 0;
		for oth_player, kills in pairs(lostArmiesFrom[player]) do
			if kills > min_kills then
				total_income = total_income + incomes[oth_player];
			else
				totalLosses[oth_player] = totalLosses[oth_player] - kills; -- don't count these kills for points
			end
		end
		-- assign points to each player that dealt damage to this player
		for oth_player, kills in pairs(lostArmiesFrom[player]) do
			if kills > min_kills then 
				-- temporary code for calculating points. Just use number of kills
				publicGameData.KillPoints[oth_player] = publicGameData.KillPoints[oth_player] + kills
				print("kills by player " .. oth_player .. ": " .. publicGameData.KillPoints[oth_player])
			end
		end
	end

	-- assign points for armies killed
	-- local attacker_points, defender_points = GetPoints(result.DefendingArmiesKilled.NumArmies, result.AttackingArmiesKilled.NumArmies, attacker_income, defender_income)

	empty_lost_info(publicGameData); -- reset TotalLosses and LostArmiesFrom
	Mod.PublicGameData = publicGameData; -- write to PublicGameData

	-- check if we should end the game
	print(game.ServerGame.Game.NumberOfLogicalTurns)
	if game.ServerGame.Game.NumberOfLogicalTurns >= Mod.Settings.NumTurns then
		end_game(game, addNewOrder)
	end
end

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
	local standing      = game.ServerGame.LatestTurnStanding

	print("ENDING game and assigning winner")

	-- We need to recalculate the current incomes because that may
	-- have changed dramatically in this last turn
	for id, player in pairs(game.Game.Players) do
		local player_income = player.Income(0, standing, false, true).Total;
		incomes[id]         = player_income;
		income_points[id]   = player_income * Mod.Settings.NumTurns / 4;
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
		msg_string = msg_string .. "Total Points = " .. total_points[player] .. "\n"
		msg_string = msg_string .. "End of Game Income = " .. incomes[player] .. "\n"
		msg_string = msg_string .. "Got " .. killPoints[player] .. " points from combat and " 
		msg_string = msg_string .. income_points[player] .. " from end of game income."
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
