--[[
	Service Name: Networker (client side)
	Author: imbouttaheadoutboi (ArtificialF on discord)
	Description: This service provides a way to both create remote events programatically
				 and also encodes remote event names with a GUID. It forces clients to know
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
	NetworkerServiceClient:init()
    NetworkerServiceClient:FireServer("BuildService", "Place")
	
	Date Created: November 24th, 2025
	Version: 1.0.0
--]]

local NetworkerServiceClient = {}

-- Services
local NetworkerUtils =
	require(game.ReplicatedStorage.Shared.Services.NetworkerService:WaitForChild("NetworkerServiceUtils"))
-- Remotes
local RegisterEvent = game.ReplicatedStorage.Shared.Services.NetworkerService:WaitForChild("STCRegisterEvent")

-- Initialize the service. Run once
function NetworkerServiceClient.init(self: NetworkerServiceClient)
	-- Hold a registry of all namespaces and their events. Populated by the server side of the service
	self.__registry = {}

	-- Register events and namespaces on server request
	-- The format of register data is as follows
	-- type, namespace, eventName, eventEncodedName, isReliable, instance
	-- Register data will only contain type and namespace if type = "Namespace"
	RegisterEvent.OnClientEvent:Connect(function(registerData)
		if registerData.type == "Event" then
			self:RegisterEvent(
				registerData.namespace,
				registerData.eventName,
				registerData.eventEncodedName,
				registerData.isReliable,
				registerData.instance
			)
		elseif registerData.type == "Namespace" then
			self:RegisterNamespace(registerData.namespace)
		end
	end)
end

-- Call a callback function when server fires a specified event
-- @param namespace The namespace where the event lives
-- @param eventName The name of the event
-- @param callback A function to call when client recieves an event from the server
function NetworkerServiceClient.OnClientEvent(
	self: NetworkerServiceClient,
	namespace: string,
	eventName: string,
	callback
)
	if NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		-- Create connection with callback if event exists
		local remote = self.__registry[namespace][eventName].instance
		return remote.OnClientEvent:Connect(callback)
	else
		warn("Server to client listening failed: Event does not exist!")
		return
	end
end

-- Fire an event to the server. Add any arguments after namespace and event name
-- @param namespace The namespace where the event lives
-- @param eventName The name of the event
function NetworkerServiceClient.FireServer(self: NetworkerServiceClient, namespace: string, eventName: string, ...)
	if NetworkerUtils.EventExists(self.__registry, namespace, eventName) then
		-- Fire event to the server if it exists
		local remote = self.__registry[namespace][eventName].instance
		return remote:FireServer(...)
	else
		warn("Client to server firing failed: Event does not exist!")
		return
	end
end

-- Register an event into the client registry
-- @param namespace The name of the namespace to register the event under
-- @param eventName The name of the event
-- @param encodedEventName The encoded name of the event
-- @param isEventReliable If the event is a RemoteEvent, reliable, or an UnreliableRemoteEvent
-- @param instance The instance of the event
function NetworkerServiceClient.RegisterEvent(
	self: NetworkerServiceClient,
	namespace: string,
	eventName: string,
	encodedEventName: string,
	isEventReliable: boolean,
	instance: Instance
)
	NetworkerUtils.RegisterEvent(self.__registry, namespace, eventName, encodedEventName, isEventReliable)
	NetworkerUtils.AttachInstance(self.__registry, namespace, eventName, instance)
end

-- Register a namespace from the serverside into the client registry
-- @param namespaceName The name of the namespace
function NetworkerServiceClient.RegisterNamespace(self: NetworkerServiceClient, namespaceName: string)
	NetworkerUtils.RegisterNamespace(self.__registry, namespaceName)
end

-- Define the type of NetworkerServiceClient
type NetworkerServiceClient = typeof(NetworkerServiceClient)

return NetworkerServiceClient :: NetworkerServiceClient
