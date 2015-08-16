local StudioManager 		= {};
local JsonLibrary 			= require "cjson";

function StudioManager.StartClient()
	io.popen(("start /b C:\\Users\\GSKW\\AppData\\Local\\Roblox\\Versions\\version-a15ad0329eab4912\\RobloxStudioBeta.exe -testMode -avatar -script \"%s\" &"):format(io.open("Studio_Client.lua", "r"):read("*all"):gsub("\"", "\\\"")):gsub("&", "^&"), "r"):close();
end

function StudioManager.StartServer()
	io.popen(("C:\\Users\\GSKW\\AppData\\Local\\Roblox\\Versions\\version-a15ad0329eab4912\\RobloxStudioBeta.exe -testMode -fileLocation I:/Valkyrie_CI/RunFile.rbxl -script \"%s\""):format(io.open("Studio_Server.lua", "r"):read("*all"):gsub("\"", "\\\"")):gsub("&", "^&"), "r"):close();
end

function StudioManager.GetOutput()
	local File 				= io.open("C:\\Users\\GSKW\\AppData\\Local\\Roblox\\InstalledPlugins\\0\\settings.json");
	return JsonLibrary.decode(File:read("*all"));
end

return StudioManager;
