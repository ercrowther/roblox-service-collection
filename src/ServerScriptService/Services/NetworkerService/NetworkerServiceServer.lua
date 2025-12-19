--[[
	Service Name: Networker (server side)
	Author: imbouttaheadoutboi (ArtificialF on discord)
	Description: This service provides a way to both create remote events programatically
				 and also obfuscates remote event names with a GUID. It forces clients to know
				 the real name of the remote event in order to fire it with the Networker.
				 Additionally each remote event is organized into a "namespace" for organization.
				 
	Features:
	- Programatically create remote events, reliable or unreliable
	- Organize remote events into "namespaces", ex. "BuildService"
	- Thwart script kiddies by encoding remote event instance names
	- Give events a client and server ratelimit, limiting how many times the event can be fired per second
	- Allow/disallow clients from firing an event
	- Fire to all clients except the ones in a list
	
	- Example Usage:
	NetworkerServiceServer:init()
    NetworkerServiceServer:CreateNamespace("BuildService")
    NetworkerServiceServer:CreateEvent("BuildService", "Place", true, 3)
    NetworkerServiceServer:OnServerEvent("BuildService", "Place", function(player) end)
	
	Date Created: November 24th, 2025
	Version: 1.0.0
--]]

local NetworkerServiceServer = {}

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local NetworkerUtils =
	require(game.ReplicatedStorage.Shared.Services.NetworkerService:WaitForChild("NetworkerServiceUtils"))
-- Remotes
local RegisterEvent = game.ReplicatedStorage.Shared.Services.NetworkerService:WaitForChild("STCRegisterEvent")
-- Constants
local eventFolderPath = game.ReplicatedStorage
local eventFolderName = "NetworkerEvents"
local defaultClientRateLimit = 50

-- Initialize the service. Run once
function NetworkerServiceServer.init(self: NetworkerServiceServer)
	-- Create the main folder to store all created remote events
	local folder = Instance.new("Folder")
	folder.Parent = eventFolderPath
	folder.Name = eventFolderName

	-- Hold a registry of all namespaces and their events
	self.__registry = {}

	-- For each event, remove the player key (if it exists) for firing log and allowed players
	Players.PlayerRemoving:Connect(function(player)
		for _, namespace in pairs(self.__registry) do
			for _, event in pairs(namespace) do
				local fireLog = event.playerFireLog
				local allowedLog = event.allowedPlayers
				local foundPlayerIdx = fireLog[player]

				if foundPlayerIdx then
					print("Removed player from firelog")
					fireLog[player] = nil
				end

				foundPlayerIdx = allowedLog[player]
				if foundPlayerIdx then
					print("Removed player from allowedlog")
					allowedLog[player] = nil
				end
			end
		end
	end)
end

-- Fire an event to a client
-- @param namespace The namespace the event lives under
-- @param eventName The name of the event
-- @param player The client to fire to
function NetworkerServiceServer.FireClient(
	self: NetworkerServiceServer,
	namespace: string,
	eventName: string,
	player: Player,
	...
)
	if not NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		warn("Server to client not fired: Event does not exist!")
		return
	end

	self.__registry[namespace][eventName].instance:FireClient(player, ...)
end

-- Fire an event to all clients
-- @param namespace The namespace the event lives under
-- @param eventName The name of the event
function NetworkerServiceServer.FireAllClients(self: NetworkerServiceServer, namespace: string, eventName: string, ...)
	if not NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		warn("Server to all clients not fired: Event does not exist!")
		return
	end

	self.__registry[namespace][eventName].instance:FireAllClients(...)
end

-- Fire an event to all clients excluding a list of clients
-- @param namespace The namespace the event lives under
-- @param eventName The name of the event
-- @param excludedPlayers A table containing players to NOT fire to
function NetworkerServiceServer.FireAllClientsExcept(
	self: NetworkerServiceServer,
	namespace: string,
	eventName: string,
	excludedPlayers,
	...
)
	if not NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		warn("Server to all clients not fired: Event does not exist!")
		return
	end
	excludedPlayers = excludedPlayers or {}

	-- Convert excludedPlayers to a "set" for constant time lookups instead of table.find linear search
	local excluded = {}
	for _, player in ipairs(excludedPlayers) do
		excluded[player] = true
	end

	-- Fire to each player as long as they dont exist in excludedPlayers
	local event = self.__registry[namespace][eventName].instance
	for _, player in ipairs(Players:GetPlayers()) do
		if not excluded[player] then
			event:FireClient(player, ...)
		end
	end
end

-- Listen for an event fired by a client
-- @param namespace The namespace the event lives under
-- @param eventName The name of the event
-- @param callback The callback function when the client fires the event. The first argument is the player who fired the event
function NetworkerServiceServer.OnServerEvent(
	self: NetworkerServiceServer,
	namespace: string,
	eventName: string,
	callback
)
	if not NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		warn("Client to server listening failed: Event does not exist!")
		return
	end

	-- Cache event registry info into easier variables
	local eventData = self.__registry[namespace][eventName]
	local event = eventData.instance
	local rateLimit = eventData.clientRateLimit
	local fireLog = eventData.playerFireLog
	local allowedPlayers = eventData.allowedPlayers

	event.OnServerEvent:Connect(function(player, ...)
		local currentFireTime = os.clock()
		local fireMinTime = currentFireTime - 1
		local log = fireLog[player]
		local timesFired = 0

		-- Guard clause if player is not in the list of allowed players
		if not allowedPlayers[player] then
			warn("Player " .. player.Name .. " tried to fire an event they aren't allowed to!")
			return
		end
		-- Add an entry for the player if they dont have a fire log yet
		if not log then
			fireLog[player] = {}
			log = fireLog[player]
		end

		-- Go through the player's fire log, tallying up fires within 1 second and pruning those outside 1 second
		for i = #log, 1, -1 do
			if log[i] >= fireMinTime and log[i] <= currentFireTime then
				timesFired = timesFired + 1
			else
				table.remove(log, i)
			end
		end

		if timesFired >= rateLimit then
			warn("Player " .. player.Name .. " fired more then a ratelimit")
		else
			table.insert(log, currentFireTime)
			callback(player, ...)
		end
	end)
end

-- Give a player permission to fire a specified event from their client
-- @param namespace The namespace the event lives under
-- @param eventName The name of the event
-- @param player The player to allow for the event
function NetworkerServiceServer.AllowPlayerForEvent(
	self: NetworkerServiceServer,
	namespace: string,
	eventName: string,
	player: Player
)
	if not NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		warn("Allow player to fire event failed: Event does not exist!")
		return
	end

	-- Place the player in the allowedPlayers set if they arent in it yet
	local allowedPlayersSet = self.__registry[namespace][eventName].allowedPlayers
	if not allowedPlayersSet[player] then
		allowedPlayersSet[player] = true
	end
end

-- Revoke a player's permission to fire a specified event from their client
-- @param namespace The namespace the event lives under
-- @param eventName The name of the event
-- @param player The player to disallow for the event
function NetworkerServiceServer.DisallowPlayerForEvent(
	self: NetworkerServiceServer,
	namespace: string,
	eventName: string,
	player: Player
)
	if not NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		warn("Disallow player to fire event failed: Event does not exist!")
		return
	end

	-- Remove the player in the allowedPlayers set if they arent in it yet
	local allowedPlayersSet = self.__registry[namespace][eventName].allowedPlayers
	if allowedPlayersSet[player] then
		allowedPlayersSet[player] = nil
	end
end

-- Create either a reliable or unreliable remote event under a specified namespace
-- @param namespace The name of the namespace the remote event should be registered under
-- @param eventName The name of the remote event
-- @param isReliable If the event should be a RemoteEvent or a UnreliableRemoteEvent
-- @param clientRatelimit How many times per second a single client can fire an event before restrictions. This number is rounded
function NetworkerServiceServer.CreateEvent(
	self: NetworkerServiceServer,
	namespace: string,
	eventName: string,
	isReliable: boolean,
	clientRateLimit: number
)
	local eventEncodedName = HttpService:GenerateGUID(false)
	clientRateLimit = clientRateLimit or defaultClientRateLimit

	-- Register the event (also functions as a guard clause for bad data)
	NetworkerUtils.RegisterEvent(self.__registry, namespace, eventName, eventEncodedName, isReliable)

	-- Create remote event instance
	local event
	if isReliable then
		event = Instance.new("RemoteEvent")
	else
		event = Instance.new("UnreliableRemoteEvent")
	end
	event.Name = eventEncodedName
	event.Parent = eventFolderPath:FindFirstChild(eventFolderName)

	-- Add additional fields post-registry/creation
	NetworkerUtils.AttachInstance(self.__registry, namespace, eventName, event)
	self.__registry[namespace][eventName].clientRateLimit = clientRateLimit
	self.__registry[namespace][eventName].playerFireLog = {}
	self.__registry[namespace][eventName].allowedPlayers = {}

	-- Pass the event to be registered on the client side of the service
	-- An instance can now be passed, as all data is confirmed valid at this point
	RegisterEvent:FireAllClients({
		type = "Event",
		namespace = namespace,
		eventName = eventName,
		eventEncodedName = eventEncodedName,
		isReliable = isReliable,
		instance = event,
	})
end

-- Create a namespace for remote events to be registered under
-- @param namespaceName The name for the namespace
function NetworkerServiceServer.CreateNamespace(self: NetworkerServiceServer, namespaceName: string)
	-- Register on the server side
	NetworkerUtils.RegisterNamespace(self.__registry, namespaceName)
	-- Register on the client side
	RegisterEvent:FireAllClients({
		type = "Namespace",
		namespace = namespaceName,
	})
end

-- Define the type of NetworkerServiceServer
type NetworkerServiceServer = typeof(NetworkerServiceServer)

return NetworkerServiceServer :: NetworkerServiceServer
