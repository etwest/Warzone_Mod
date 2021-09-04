require('Utilities')

function Server_StartGame(game, standing)
	print("Initializing Game!")
	local publicGameData = Mod.PublicGameData
	publicGameData.KillPoints     = {};
	publicGameData.LostArmiesFrom = {};
	publicGameData.TotalLosses    = {};
	for player in pairs(game.ServerGame.Game.Players) do 
		publicGameData.KillPoints[player]     = 0;
		publicGameData.TotalLosses[player]    = 0;
		publicGameData.LostArmiesFrom[player] = {};
		for oth_player in pairs(game.ServerGame.Game.Players) do
			if not (player == oth_player) then
				publicGameData.LostArmiesFrom[player][oth_player] = 0;
			end
		end
	end

	-- print('created lostArmiesFrom')
	-- for player in pairs(publicGameData.LostArmiesFrom) do
	-- 	DumpTable(publicGameData.LostArmiesFrom[player])
	-- end

	Mod.PublicGameData = publicGameData
end
