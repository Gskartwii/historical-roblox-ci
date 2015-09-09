local Lapis = require("lapis")
local Application = Lapis.Application()
local ShellRun = require("ShellRun");
local ModelListParser = require("ModelListParser");
local ModelBuilder = loadfile("Test.lua");

Application:get("/", function()
	return "Welcome to Lapis " .. require("lapis.version")
end)

Application:get("/build/:User/:Branch", function(Arguments)
	if Arguments.params.User:find("%.") or Arguments.params.Branch:find("%.") then
		return "Not enjoying this at all."
	end
	
	local ModelList = ModelListParser("models.list");
	local BranchID = Arguments.params.User .. "/" .. Arguments.params.Branch;
	local PotentialID = ModelList[BranchID];
	if not PotentialID then
		PotentialID = 0;
	
		ShellRun("mkdir -p", "branches/" .. BranchID, "builds/" .. Arguments.params.User);
		ShellRun("git clone", "https://github.com/" .. BranchID, "branches/" .. BranchID); 
	end
	ModelBuilder(BranchID);

	
end);

return Application;
