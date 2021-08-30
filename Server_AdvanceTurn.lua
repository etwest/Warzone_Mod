require('Utilities');

-- This part is for adjusting the number of points
-- Thoughts: I think we want to implement the tally it up and assign points at the end
--           method
--           Basically, because of the Matthew vs Alicia war with Yitzhar attacking in the background.
--           Yitzhar shouldn't get a ton of points for doing that even though he's weaker than Matthew because
--           Matthew was at the time fighting an opponent of equivalent strength (Alicia)
function GetPoints(attacker_killed, defender_killed, attacker_income, defender_income)
	local income_ratio    = (defender_income / attacker_income);
	local attacker_points = attacker_killed * income_ratio;
	local defender_points = defender_killed / income_ratio;

	return attacker_points, defender_points;
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if (order.proxyType == 'GameOrderAttackTransfer') then
		local terr_map = game.ServerGame.LatestTurnStanding.Territories;
		local attackerID = terr_map[order.From].OwnerPlayerID;
		local defenderID = terr_map[order.To].OwnerPlayerID;
		local publicGameData = Mod.PublicGameData;
		
		if (not terr_map[order.To].IsNeutral) then
			local attacker = game.Game.Players[attackerID];
			local defender = game.Game.Players[defenderID];

			-- So here we are ignoring the effects of santion cards. It may be prudent to change this later
			local attacker_income = attacker.Income(0, game.ServerGame.LatestTurnStanding, false, true).Total
			local defender_income = defender.Income(0, game.ServerGame.LatestTurnStanding, false, true).Total
			local attacker_points, defender_points = GetPoints(result.DefendingArmiesKilled.NumArmies, result.AttackingArmiesKilled.NumArmies, attacker_income, defender_income)

			publicGameData.KillInfo[attackerID] = publicGameData.KillInfo[attackerID] + attacker_points;
			publicGameData.KillInfo[defenderID] = publicGameData.KillInfo[defenderID] + defender_points;
			print("attacker kills total =", publicGameData.KillInfo[attackerID])
			print("defender kills total =", publicGameData.KillInfo[defenderID])
		end

		-- write any changes we've made back to the PublicGameData
		Mod.PublicGameData = publicGameData;
	end
end
