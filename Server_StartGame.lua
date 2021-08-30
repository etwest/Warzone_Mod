
function Server_StartGame(game, standing)
	print("Initializing Game!")
	local publicGameData = Mod.PublicGameData
	publicGameData.KillInfo = {}
	for player in pairs(game.ServerGame.Game.Players) do 
		publicGameData.KillInfo[player] = 0;
	end
	Mod.PublicGameData = publicGameData
end
