local Lapis = require("lapis")
local Application = Lapis.Application()
local ShellRun, ShellRaw = unpack(require("ShellRun"));
local ModelListParser = require("ModelListParser");
local ModelBuilder = loadfile("EasyBuilder.lua");
local ModelUploader = require("Uploader");
local JSONModule = require("cjson");
local GitHubStatus = require("GitHubStatus");
local RobloxStatus = require("RobloxStatus");
local ApplyGitInformation = require("GitInfo");

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
    end
    Log = Log .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "reset --hard");
    Log = Log .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "pull");
    Log = Log .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "reset --hard");
    Log = Log .. ModelBuilder("branches/" .. BranchID, "builds/" .. BranchID .. ".rbxm");

    return Log;
end;

local function AttemptUpload(BranchID)
    local ModelList = ModelListParser("models.list");
    local PotentialID = ModelList[BranchID];

    local ModelID = ModelUploader(PotentialID or 0, BranchID);

    if not PotentialID then
        local File = io.open("models.list", "a");
    	File:write(BranchID .. "\t" .. ModelID .. "\n");
        File:close();
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

local function ReactToWebhook(RepoID, BranchID, BranchName, CommitID, CommitMessage, CommitPusher)
    local BuildResult;
    if io.open("locks/" .. CommitID, "r") then
        return "This commit is currently being built!";
    end
    io.open("locks/" .. CommitID, "w"):close();
    GitHubStatus(CommitID, RepoID, "pending", "Currently building and upload your model");

    if BranchID:find("%.") or CommitID:find("%.") then
        return "Nice try. Very nice.";
    end

    local Success, Error = pcall(function() BuildResult = AttemptBuild(RepoID, BranchID, BranchName); end);

    ApplyGitInformation(BranchID, CommitID, CommitMessage, CommitPusher);

    if not Success then
        GitHubStatus(CommitID, RepoID, "error", "The build failed due to an error in the CI", "https://rbxvalkyrie.dy.fi:444/build_log/" .. CommitID);
        local File = io.open("build_logs/" .. CommitID .. ".log", "w");
        File:write(Error);
        File:close();
        return {layout = false; render = "empty", content_type = "text/plain"; "ERROR: " .. Error};
    elseif BuildResult:find("\1") then
        local File = io.open("build_logs/" .. CommitID .. ".log", "w");
        File:write(BuildResult);
        File:close();
        GitHubStatus(CommitID, RepoID, "failure", "The build failed due to an error in the repository", "https://rbxvalkyrie.dy.fi:444/build_log/" .. CommitID);
    else
        local File = io.open("build_logs/" .. CommitID .. ".log", "w");
        File:write(BuildResult);
        File:close();
        local ModelID = AttemptUpload(BranchID);
        GitHubStatus(CommitID, RepoID, "success", "The build succeeded", "https://rbxvalkyrie.dy.fi:444/build_log/" .. CommitID);
    end

    return {layout = false; render = "empty"; content_type = "text/plain"; BuildResult};
end

Application:post("/push_hook", function(Arguments)
    ngx.req.read_body();
    local Body = ngx.req.get_body_data();

    local ParsedBody    = JSONModule.decode(Body);
    local BranchID      = RepoID .. ParsedBody.ref:sub(11);

    if ParsedBody.deleted then
        -- Branch deleted. Might make it copylock the model on Roblox later, or upload an empty model.
        local ModelList = ModelListParser("models.list");
        local ID        = ModelList[BranchID];
        CopyLock(ID);
        return {layout  = false; render = "empty"; content_type = "text/plain"; "Thanks."};
    end

    local RepoID        = ParsedBody.repository.full_name;
    local BranchName    = ParsedBody.ref:sub(12);
    local CommitID      = ParsedBody.head_commit.id;
    local CommitMessage = ParsedBody.head_commit.message;
    local CommitPusher  = ParsedBody.pusher.name;

    return ReactToWebhook(RepoID, BranchID, BranchName, CommitID, CommitMessage, CommitPusher);
end);

Application:post("/pull_hook", function(Arguments)
    ngx.req.read_body();
    local Body = ngx.req.get_body_data();

    local ParsedBody    = JSONModule.decode(Body).pull_request;
    local RepoID        = ParsedBody.head.repo.full_name;
    local BranchName    = ParsedBody.head.ref;
    local BranchID      = RepoID .. "/" .. BranchName;
    local CommitID      = ParsedBody.head.sha;
    local CommitMessage = "[PR description] " .. ParsedBody.body;
    local CommitPusher  = ParsedBody.user.login;

    return ReactToWebhook(RepoID, BranchID, BranchName, CommitID, CommitMessage, CommitPusher);
end);


Application:get("/build_log/:CommitID", function(Arguments)
    if Arguments.params.CommitID:find("%.") then
        return "That still doesn't work.";
    end

    return "<pre>" .. io.open("build_logs/" .. Arguments.params.CommitID .. ".log", "r"):read("*all") .. "</pre>";
end);

Application:get("/models", function()
    return "<pre>" .. io.open("models.list"):read("*all"):gsub("\t(%d+)", "\t<a href='http://roblox.com/redirect-item?id=%1'>%1</a>") .. "</pre>";
end);

return Application;
