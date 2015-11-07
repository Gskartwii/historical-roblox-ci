local Lapis = require("lapis")
local Application = Lapis.Application()
local ShellRun, ShellRaw = unpack(require("ShellRun"));
local ModelListParser = require("ModelListParser");
local ModelBuilder = loadfile("Test.lua");
local ModelUploader = require("Uploader");
local JSONModule = require("cjson");
local GitHubStatus = require("GitHubStatus");
local RobloxStatus = require("RobloxStatus");

Application:enable "etlua";

Application:get("/", function()
    return "Welcome to Lapis " .. require("lapis.version")
end);

local function AttemptBuild(RepoID, BranchID, BranchName)
    local ModelList = ModelListParser("models.list");
    local PotentialID = ModelList[BranchID];
    local Log = "";
    if not PotentialID then
    	PotentialID = 0;

    	Log = Log .. ShellRun("mkdir -p", "branches/" .. BranchID .. "/MainModule.mod.lua", "builds/" .. RepoID, "build_logs/" .. BranchID);
    	Log = Log .. ShellRun("git clone", "https://github.com/" .. RepoID, "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "-b", BranchName);
    else
    	Log = Log .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "pull");
    end
    Log = Log .. ModelBuilder(BranchID);

    return Log;
end;

local function AttemptUpload(BranchID)
    local ModelList = ModelListParser("models.list");
    local PotentialID = ModelList[BranchID];

    local ModelID = ModelUploader(PotentialID or 0, BranchID);

    if not PotentialID then
    	io.open("models.list", "a"):write(BranchID .. "\t" .. ModelID .. "\n");
    end

    return ModelID;
end

Application:get("/build/:User/:Repo/:Branch", function(Arguments)
    if Arguments.params.User:find("%.") or Arguments.params.Repo:find("%.") or Arguments.params.Branch:find("%.") then
    	return "Not enjoying this at all."
    end

    local RepoID = Arguments.params.User .. "/" .. Arguments.params.Repo;
    local BranchID = RepoID .. "/" .. Arguments.params.Branch;

    return AttemptBuild(RepoID, BranchID, Arguments.params.Branch);
end);

Application:post("/push_hook", function(Arguments)
    ngx.req.read_body();
    local Body = ngx.req.get_body_data();

    local ParsedBody = JSONModule.decode(Body);

    local BuildResult;
    GitHubStatus(ParsedBody.head_commit.id, ParsedBody.repository.full_name, "pending", "Currently building and upload your model");

    local RepoID = ParsedBody.repository.full_name;
    local BranchID = ParsedBody.repository.full_name .. ParsedBody.ref:sub(11);
    local BranchName = ParsedBody.ref:sub(12);
    local CommitID = ParsedBody.head_commit.id;

    if BranchID:find("%.") or CommitID:find("%.") then
        return "Nice try. Very nice.";
    end

    local Success, Error = pcall(function() BuildResult = AttemptBuild(RepoID, BranchID, BranchName); end);

    if not Success then
        GitHubStatus(ParsedBody.head_commit.id, ParsedBody.repository.full_name, "error", "The build failed due to an error in the CI");
        return {layout = false; render = "empty", content_type = "text/plain"; "ERROR: " .. Error};
    elseif BuildResult:find("\1") then
        io.open("build_logs/" .. CommitID .. ".log", "w"):write(BuildResult);
        GitHubStatus(ParsedBody.head_commit.id, ParsedBody.repository.full_name, "failure", "The build failed due to an error in the repository", "http://gskw.noip.me:9999/build_log/" .. CommitID);
    else
        io.open("build_logs/" .. CommitID .. ".log", "w"):write(BuildResult);
        GitHubStatus(ParsedBody.head_commit.id, ParsedBody.repository.full_name, "success", "The build succeeded", "http://gskw.noip.me:9999/build_log/" .. CommitID);
    end

    local ModelID = AttemptUpload(BranchID);

    RobloxStatus("CI status update: " .. ParsedBody.pusher.name .. " pushed " .. #ParsedBody.commits .. " commits to " .. BranchName);

    return {layout = false; render = "empty"; content_type = "text/plain"; BuildResult};
end);

Application:get("/build_log/:CommitID", function(Arguments)
    if Arguments.params.CommitID:find("%.") then
        return "That still doesn't work.";
    end

    return "<pre>" .. io.open("build_logs/" .. Arguments.params.CommitID .. ".log", "r"):read("*all") .. "</pre>";
end);

Application:get("/models", function()
    return "<pre>" .. io.open("models.list"):read("*all") .. "</pre>";
end);

return Application;
