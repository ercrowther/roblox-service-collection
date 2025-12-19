local ClientServices = game:GetService("ReplicatedStorage").Shared:WaitForChild("Services")

-- Require services to initialize
local NetworkerServiceClient = require(ClientServices.NetworkerService:WaitForChild("NetworkerServiceClient"))

-- Initialize services
NetworkerServiceClient:init()
