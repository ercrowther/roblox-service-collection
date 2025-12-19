local ServerServices = game:GetService("ServerScriptService"):WaitForChild("Services")

-- Require services to initialize
local AssetPreloaderServiceServer = require(ServerServices:WaitForChild("AssetPreloaderServiceServer"))
local NetworkerServiceServer = require(ServerServices.NetworkerService:WaitForChild("NetworkerServiceServer"))

-- Initialize services
AssetPreloaderServiceServer:init()
NetworkerServiceServer:init()

-- Function call followups after initialization
AssetPreloaderServiceServer:run()
