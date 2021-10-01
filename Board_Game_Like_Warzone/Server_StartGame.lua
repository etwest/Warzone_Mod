require('Utilities')

function Server_StartGame(game, standing)
	print("Initializing Game!")
	local publicGameData = Mod.PublicGameData
	publicGameData.KillPoints     = {};
	publicGameData.IncomePoints   = {};
	publicGameData.LostArmiesFrom = {};
	for player in pairs(game.ServerGame.Game.Players) do 
		publicGameData.KillPoints[player]     = 0;
		publicGameData.IncomePoints[player]   = 0;
		publicGameData.LostArmiesFrom[player] = {};
		for oth_player in pairs(game.ServerGame.Game.Players) do
			if not (player == oth_player) then
				publicGameData.LostArmiesFrom[player][oth_player] = 0;
			end
		end
	end

	-- Track the history of points using this variable
	publicGameData.PointsList     = {};
	-- print('created lostArmiesFrom')
	-- for player in pairs(publicGameData.LostArmiesFrom) do
	-- 	DumpTable(publicGameData.LostArmiesFrom[player])
	-- end

	Mod.PublicGameData = publicGameData
end
