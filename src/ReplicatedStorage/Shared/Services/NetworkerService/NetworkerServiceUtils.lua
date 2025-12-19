--[[
	Service Name: Networker (utilities)
	Author: imbouttaheadoutboi (ArtificialF on discord)
	Description: This service provides a way to both create remote events programatically
				 and also obfuscates remote event names with a GUID. It forces clients to know
				 the real name of the remote event in order to fire it with the Networker.
				 Additionally each remote event is organized into a "namespace" for organization.
				 
	Features:
	- Programatically create remote events, reliable or unreliable
	- Organize remote events into "namespaces", ex. "BuildService"
	- Thwart script kiddies by encoding remote event instance names
	
	- Example Usage:
	
	
	Date Created: November 24th, 2025
	Version: 1.0.0
--]]

local NetworkerServiceUtils = {}

-- Register an event into a registry
-- @param registryTable A table that holds a registry of namespaces and their events
-- @param namespace The name of the namespace to register the event under
-- @param eventName The name of the event
-- @param encodedEventName The encoded name of the event
-- @param isEventReliable If the event is a RemoteEvent, reliable, or an UnreliableRemoteEvent
function NetworkerServiceUtils.RegisterEvent(
	registryTable,
	namespace: string,
	eventName: string,
	encodedEventName: string,
	isEventReliable: boolean
)
	-- Missing parameter guard clauses
	assert(registryTable ~= nil, "Event not registered: No registry table")
	assert((namespace ~= "") and (namespace ~= nil), "Event not registered: No namespace provided")
	assert((eventName ~= "") and (eventName ~= nil), "Event not registered: No event name provided")
	assert(
		(encodedEventName ~= "") and (encodedEventName ~= nil),
		"Event not registered: No encoded event name provided"
	)
	assert(isEventReliable ~= nil, "Event not registered: No event type provided")
	-- Validation guard clauses
	assert(
		NetworkerServiceUtils.NamespaceExists(registryTable, namespace),
		"Event not created: Namespace does not exist"
	)
	assert(
		not NetworkerServiceUtils.EventExists(registryTable, namespace, eventName),
		"Event not created: There is already an event with that name"
	)

	-- Register event
	registryTable[namespace][eventName] =
		{ encodedName = encodedEventName, isReliable = isEventReliable, instance = nil }
end

-- Set the event instance in an event entry inside a registry
-- @param registryTable A table that holds a registry of namespaces and their events
-- @param namespace The namespace of the event
-- @param eventName The name of the event
-- @param instance The instance of the remote event to attach to the event in registry
function NetworkerServiceUtils.AttachInstance(registryTable, namespace: string, eventName: string, instance: Instance)
	-- Missing parameter guard clauses
	assert(registryTable ~= nil, "Event not registered: No registry table")
	assert((namespace ~= "") and (namespace ~= nil), "Instance not attached: No namespace provided")
	assert((eventName ~= "") and (eventName ~= nil), "Instance not attached: No event name provided")
	assert(instance ~= nil, "Instance not attached: No instance provided")
	-- Validation guard clauses
	assert(
		NetworkerServiceUtils.NamespaceExists(registryTable, namespace),
		"Instance not attached: Namespace does not exist"
	)
	assert(
		NetworkerServiceUtils.EventExists(registryTable, namespace, eventName),
		"Instance not attached: Event does not exist"
	)

	-- Attach the instance to the event entry
	registryTable[namespace][eventName].instance = instance
end

-- Register a namespace from the serverside into the client registry
-- @param registryTable A table that holds a registry of namespaces and their events
-- @param namespaceName The name of the namespace
function NetworkerServiceUtils.RegisterNamespace(registryTable, namespaceName: string)
	assert(registryTable ~= nil, "Namespace not registered: No registry table")
	assert(
		not NetworkerServiceUtils.NamespaceExists(registryTable, namespaceName),
		"Namespace not registered: Namespace already exists"
	)

	-- Create the namespace
	registryTable[namespaceName] = {}
end

-- Given an event name and a namesapce, check if the event exists
-- @param registryTable A table that holds a registry of namespaces and their events
-- @param namespace The name of the namespace where the event lives under
-- @param eventName The name of the event
-- @returns boolean True if the event exists, false if it doesn't exist
function NetworkerServiceUtils.EventExists(registryTable, namespace: string, eventName: string)
	local ns = registryTable[namespace]
	return ns and ns[eventName] ~= nil
end

-- Given the name of a namespace, check if it's registered
-- @param registryTable A table that holds a registry of namespaces and their events
-- @param namespace The name of the namespace
-- @returns boolean True if the namespace exists, false if it doesn't
function NetworkerServiceUtils.NamespaceExists(registryTable, namespace: string)
	return registryTable[namespace] ~= nil
end

return NetworkerServiceUtils
