local StudioManager 		= {};
local JsonLibrary 			= require "cjson";

function StudioManager.StartClient()
	io.popen(("start /b " .. os.getenv("LOCALAPPDATA") .. "\\Roblox\\Versions\\version-536a65c8f5284f3f\\RobloxStudioBeta.exe -testMode -avatar -script \"%s\" &"):format(io.open("Studio_Client.lua", "r"):read("*all"):gsub("\"", "\\\"")):gsub("&", "^&"), "r"):close();
end

function StudioManager.StartServer()
	io.popen((os.getenv("LOCALAPPDATA") .. "\\Roblox\\Versions\\version-536a65c8f5284f3f\\RobloxStudioBeta.exe -testMode -fileLocation F:/Valkyrie_CI/RunFile.rbxl -script \"%s\""):format(io.open("Studio_Server.lua", "r"):read("*all"):gsub("\"", "\\\"")):gsub("&", "^&"), "r"):close();
end

function StudioManager.GetOutput()
	local File 				= io.open(os.getenv("LOCALAPPDATA") .. "\\Roblox\\InstalledPlugins\\0\\settings.json");
	return JsonLibrary.decode(File:read("*all"));
end

return StudioManager;
