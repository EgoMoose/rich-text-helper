--!strict

local DEBUGGING = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

if DEBUGGING then
	ServerScriptService.Debug.Disabled = false
	return
end

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

TestEZ.TestBootstrap:run({
	ReplicatedStorage.Packages.RichTextHelper,
})
