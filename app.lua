local Lapis = require("lapis")
local Application = Lapis.Application()
local ShellRun, ShellRaw = unpack(require("ShellRun"));
local ModelListParser = require("ModelListParser");
local ModelBuilder = loadfile("Test.lua");
local ModelUploader = require("Uploader");

Application:enable "etlua";

Application:get("/", function()
	return "Welcome to Lapis " .. require("lapis.version")
end)

Application:get("/build/:User/:Repo/:Branch", function(Arguments)
	if Arguments.params.User:find("%.") or Arguments.params.Repo:find("%.") or Arguments.params.Branch:find("%.") then
		return "Not enjoying this at all."
	end
	
	local ModelList = ModelListParser("models.list");
	local RepoID = Arguments.params.User .. "/" .. Arguments.params.Repo;
	local BranchID = RepoID .. "/" .. Arguments.params.Branch;
	local PotentialID = ModelList[BranchID];
	table.foreach(ModelList, print);
	local Log = "";
	if not PotentialID then
		PotentialID = 0;
	
		Log = Log .. ShellRun("mkdir -p", "branches/" .. BranchID .. "/MainModule.mod.lua", "builds/" .. RepoID);
		Log = Log .. ShellRun("git clone", "https://github.com/" .. RepoID, "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "-b", Arguments.params.Branch); 
	else
		Log = Log .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "pull");
	end
	Log = Log .. ModelBuilder(BranchID);

	local ModelID = ModelUploader(PotentialID, BranchID);

	if PotentialID == 0 then
		io.open("models.list", "a"):write(BranchID .. "\t" .. ModelID .. "\n");
	end

	return {layout = false; render = "empty", content_type = "text/plain"; Log .. "\nID: " .. ModelID};
end);

return Application;

