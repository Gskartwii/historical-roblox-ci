local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest = unpack(require("HTTPFunctions"));
local SetDescription = require "SetDescription";

local function MakeDescription(BranchName, Payload)
    local Owner = Payload.RepoID:match "^([a-zA-Z0-9%-]+)";
    local Description =
        "Valkyrie CI upload\n"
     .. (Owner == "CrescentCode" and "Official Crescent Code model" or "UNOFFICIAL 3rd-party model") .. "\n"
     .. "Owner: " .. Owner .. "\n"
     .. "Branch: " .. Payload.BranchName .. "\n"
     .. "Repository: " .. Payload.RepoID:match "([a-zA-Z0-9%-]-)$" .. "\n"
     .. "Commit SHA: " .. Payload.CommitID .. "\n"
     .. "Commit message: " .. Payload.CommitMessage .. "\n"
     .. "Last updated by: " .. Payload.CommitPusher .. "\n";

     return Description;
end

local Upload;
Upload = function(Data, ID, Name, SessionCookie, Force)
	local Result = DataRequest("/Data/Upload.ashx?assetid=" .. ID .. "&type=Model&name=" .. Name  .. "&description=" .. "Temporary%20description%2E%2E%2E" .. "&genreTypeId=1&ispublic=True&allowComments=True",
		Data, "Cookie: " .. SessionCookie .. "\nContent-Type: text/xml\n");
	if Result:match("/RobloxDefaultErrorPage") then
		if Force then
			error("ROBLOX LOGIN FAILED! Please contact gskw. Remember to include the time this happened at.");
		end
		return Upload(Data, ID, Name, Description, Login(), true);
	end
	return StripHeaders(Result);
end

return function(ID, BranchName, Payload)
    local ModelName = "";
    local Description = MakeDescription(BranchName, Payload);
    if BranchName:find "CrescentCode/ValkyrieFramework/" then
        ModelName = BranchName:gsub("CrescentCode/ValkyrieFramework/", "");
    else
        ModelName = BranchName:gsub("/ValkyrieFramework/", "/");
    end
	local ModelID = Upload(io.open("builds/" .. BranchName .. ".rbxm"):read("*all"), ID, ModelName, io.open("session.cookie", "r"):read("*all"));

    SetDescription(ID, ModelName, Description, io.open("session.cookie", "r"):read("*all"));

	return ModelID;
end;
