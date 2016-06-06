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
local CopyLock = require "LockModel";
local Config = require "lapis.config".get();
local json_params = require "lapis.application".json_params;

Application:enable "etlua";

Application:get("/", function()
    return "[CI] Welcome to Lapis " .. require("lapis.version")
end);

local function AttemptBuild(RepoID, BranchID, BranchName, CommitID, CommitMessage, CommitPusher)
    local ModelList = ModelListParser("models.list");
    local PotentialID = ModelList[BranchID];
    local Log = "";
    if not PotentialID then
    	PotentialID = 0;

    	Log = Log .. ShellRun("mkdir -p", "branches/" .. BranchID .. "/MainModule.mod.lua", "builds/" .. RepoID)
            	  .. ShellRun("git clone --recursive", "https://github.com/" .. RepoID, "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "-b", BranchName);
    end
    -- TODO: Avoid writing all this every time
    Log = Log .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "reset --hard")
              .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "pull")
              .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "reset --hard")
              .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "submodule init")
              .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "submodule sync")
              .. ShellRun("git -C", "branches/" .. BranchID .. "/MainModule.mod.lua", ShellRaw "submodule update");
    ApplyGitInformation(BranchID, CommitID, CommitMessage, CommitPusher);
    ShellRun ("moonc", "branches/" .. BranchID);
    ShellRun ("find", "branches/" .. BranchID, ShellRaw "-type f -name *.moon -exec rm {} +");
    Log = Log .. ModelBuilder("branches/" .. BranchID, "builds/" .. BranchID .. ".rbxm");

    return Log;
end;

local function AttemptUpload(BranchID, Payload)
    local ModelList = ModelListParser("models.list");
    local PotentialID = ModelList[BranchID];

    local ModelID = ModelUploader((PotentialID or 0), BranchID, Payload);

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
	if BranchID:find("%.") or CommitID:find("%.") then
        return "Nice try. Very nice.";
    end

    local BuildResult;
    if io.open("locks/" .. CommitID, "r") then
        return "This commit is currently being built!";
    end
    io.open("locks/" .. CommitID, "w"):close();
    GitHubStatus(CommitID, RepoID, "pending", "Currently building and upload your model");

    local Success, Error = pcall(function() BuildResult = AttemptBuild(RepoID, BranchID, BranchName, CommitID, CommitMessage, CommitPusher); end);

    if not Success then
        GitHubStatus(CommitID, RepoID, "error", "The build failed due to an error in the CI", "https://ci.crescentcode.net/build_log/" .. CommitID);
        local File = io.open("build_logs/" .. CommitID .. ".log", "w");
        File:write(Error);
        File:close();
        return {layout = false; render = "empty", content_type = "text/plain"; "ERROR: " .. Error};
    elseif BuildResult:find("\1") then
        local File = io.open("build_logs/" .. CommitID .. ".log", "w");
        File:write(BuildResult);
        File:close();
        GitHubStatus(CommitID, RepoID, "failure", "The build failed due to an error in the repository", "https://ci.crescentcode.net/build_log/" .. CommitID);
    else
        local File = io.open("build_logs/" .. CommitID .. ".log", "w");
        File:write(BuildResult);
        File:close();
        local ModelID = AttemptUpload(BranchID, {RepoID = RepoID, BranchID = BranchID, BranchName = BranchName, CommitID = CommitID, CommitMessage = CommitMessage, CommitPusher = CommitPusher});
        GitHubStatus(CommitID, RepoID, "success", "The build succeeded", "https://ci.crescentcode.net/build_log/" .. CommitID);
    end
    
    ShellRun("rm -rf", "locks/" .. CommitID);

    return {layout = false; render = "empty"; content_type = "text/plain"; BuildResult};
end

Application:post("/push_hook", function(Arguments)
    ngx.req.read_body();
    local Body = ngx.req.get_body_data();

    local ParsedBody    = JSONModule.decode(Body);
    local RepoID        = ParsedBody.repository.full_name;
    local BranchID      = RepoID .. ParsedBody.ref:sub(11);

    if ParsedBody.deleted then
        -- Branch deleted. Might make it copylock the model on Roblox later, or upload an empty model.
        local ModelList = ModelListParser("models.list");
        local ID        = ModelList[BranchID];
        CopyLock(ID);
        return {layout  = false; render = "empty"; content_type = "text/plain"; "Thanks."};
    end

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

Application:post("/test_patch/:Owner/:Branch", function(Arguments)
    ngx.req.read_body();
    local Patch         = ngx.req.get_body_data();
    local Owner         = Arguments.params.Owner;
    local Branch        = Arguments.params.Branch;

    if Owner:find "%." or Branch:find "%." then
        return "Patched this one, too!";
    end

    local Log = "";
    if io.open("locks/patch-" .. Owner) then
        return "A patch for this branch is currently being built!";
    end
    io.open("locks/patch-" .. Owner, "w"):close();
    Log = Log .. ShellRun("mkdir -p", "branches/" .. Owner .. "/ValkyrieFramework/Patch/MainModule.mod.lua", "builds/" .. Owner .. "/ValkyrieFramework");
    Log = Log .. ShellRun("git clone --recursive", "https://github.com/" .. Owner .. "/ValkyrieFramework", "branches/" .. Owner .. "/ValkyrieFramework/Patch/MainModule.mod.lua", ShellRaw "-b", Branch);

    local TempFile      = os.tmpname();
    local PatchFile     = io.open(TempFile, "w");
    PatchFile:write(Patch);
    PatchFile:close();

    Log = Log .. ShellRun("git -C", "branches/" .. Owner .. "/ValkyrieFramework/Patch/MainModule.mod.lua", ShellRaw "apply", TempFile);
    ApplyGitInformation(Owner .. "/ValkyrieFramework/Patch", "patch", "Command line testing patch", "Patchouli Bloxledge");

    Log = Log .. ModelBuilder("branches/" .. Owner .. "/ValkyrieFramework/Patch", "builds/" .. Owner .. "/ValkyrieFramework/Patch.rbxm");
    AttemptUpload(Owner .. "/ValkyrieFramework/Patch", {RepoID = Owner .. "/ValkyrieFramework", BranchID = Owner .. "/ValkyrieFramework/Patch", BranchName = "Patch", CommitID = "patch", CommitMessage = "Command line testing patch", CommitPusher = "Patchouli Bloxledge"});
    ShellRun("rm -rf", "locks/patch-" .. Owner, "branches/" .. Owner .. "/ValkyrieFramework/Patch");

    return {layout = false; render = "empty"; content_type = "text/plain"; Log};
end);

Application:post("/dl_patch/:Owner/:Repo/:Branch", function(Arguments)
    ngx.req.read_body();
    local Patch         = ngx.req.get_body_data();
    local Owner         = Arguments.params.Owner;
    local Repo          = Arguments.params.Repo;
    local Branch        = Arguments.params.Branch;

    if Owner:find "%." or Branch:find "%." then
        return "Patched this one, too!";
    end

    local Log = "";
    if io.open("locks/patch-" .. Owner) then
        return "A patch for this branch is currently being built!";
    end
    io.open("locks/patch-" .. Owner, "w"):close();
    Log = Log .. ShellRun("mkdir -p", "branches/" .. Owner .. "/" .. Repo .. "/Patch/MainModule.mod.lua", "builds/" .. Owner .. "/" .. Repo .. "");
    Log = Log .. ShellRun("git clone --recursive", "https://github.com/" .. Owner .. "/" .. Repo .. "", "branches/" .. Owner .. "/" .. Repo .. "/Patch/MainModule.mod.lua", ShellRaw "-b", Branch);

    local TempFile      = os.tmpname();
    local PatchFile     = io.open(TempFile, "w");
    PatchFile:write(Patch);
    PatchFile:close();

    Log = Log .. ShellRun("git -C", "branches/" .. Owner .. "/" .. Repo .. "/Patch/MainModule.mod.lua", ShellRaw "apply", TempFile); ApplyGitInformation(Owner .. "/" .. Repo .. "/Patch", "patch", "Command line testing patch", "Patchouli Bloxledge"); 
    Log = Log .. ModelBuilder("branches/" .. Owner .. "/" .. Repo .. "/Patch", "builds/" .. Owner .. "/" .. Repo .. "/Patch.rbxm");
    ShellRun("rm -rf", "locks/patch-" .. Owner, "branches/" .. Owner .. "/" .. Repo .. "/Patch");

    return {layout = false; render = "empty"; content_type = "application/roblox-model"; io.open("builds/" .. Owner .. "/" .. Repo .. "/Patch.rbxm"):read "*a"};
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

Application:get("/status/:branch", function(self)
    return io.open("models.list"):read("*all"):match("/"..self.params.branch.."[^%d\n]*(%d*)");
end);


Application:post("/docs_push_hook", json_params(function(Arguments)
    local Remote = Config.remote or "origin";
    local Branch = Config.branch or "master";
    local Repo   = Config.repo;

    if "refs/heads/" .. Branch ~= Arguments.params.ref then
        return {content_type = "text/plain", layout = false, "This is not my branch!"};
    end

    ShellRun("git -C", Repo, ShellRaw "pull", Remote, Branch);
    return {content_type = "text/plain", layout = false, ShellRun("(cd " .. Repo .. "; ./buildsite.sh)")};
end));

return Application;
