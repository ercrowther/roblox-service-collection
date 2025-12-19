--[[
	Service Name: AssetPreloader
	Author: imbouttaheadoutboi (ArtificialF on discord)
	Description: A simple service that takes a configured set of directories and preloads
				 all assets within those directories using ContentProvider:PreloadAsync().
				 The service will dig into sub directories to preload the assets in the case
				 that sub directories are used for organization.
				 
	Features:
	- Preload assets from a list of directories
	
	- Example Usage:
	AssetPreloaderService:init()
	AssetPreloaderService:run()
	
	Date Created: November 20th, 2025
	Version: 1.0.0
--]]

local AssetPreloaderServiceServer = {}

-- Services
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize the service. Run once
function AssetPreloaderServiceServer.init(self: AssetPreloaderServiceServer)
	-- The main directory the assets reside in
	self.mainDirectory = ReplicatedStorage:WaitForChild("Assets")
	-- The directories in which the service will preload assets from
	self.directories = {
		SFX = self.mainDirectory:WaitForChild("SFX"),
		Animations = self.mainDirectory:WaitForChild("Animations"),
		VFX = self.mainDirectory:WaitForChild("VFX"),
	}
end

-- Get all assets from a folder
-- @param folder The folder to gather assets from
-- @returns A table of assets
function getAssets(folder: Instance)
	local assets = {}

	for _, descendant in pairs(folder:GetDescendants()) do
		-- Only add instances (aka assets)
		if descendant:IsA("Instance") then
			table.insert(assets, descendant)
		end
	end

	return assets
end

-- Preload game assets. Run once
function AssetPreloaderServiceServer.run(self: AssetPreloaderServiceServer)
	-- Enforce initilization
	assert(self.directories, "You must initialize the service before running it!")

	print("Preloading assets...")
	local startTime = os.clock()
	local assets = {}

	-- For every main asset directory
	for _, folder in pairs(self.directories) do
		-- Get all assets within it (including subdirectories)
		for _, asset in pairs(getAssets(folder)) do
			table.insert(assets, asset)
		end
	end

	-- Preload the assets
	ContentProvider:PreloadAsync(assets)

	local deltaTime = os.clock() - startTime
	print(("Preloading finished. Time taken: %.2f seconds"):format(deltaTime))
end

-- Define the type of AssetPreloaderServiceServer
type AssetPreloaderServiceServer = typeof(AssetPreloaderServiceServer)

return AssetPreloaderServiceServer :: AssetPreloaderServiceServer
