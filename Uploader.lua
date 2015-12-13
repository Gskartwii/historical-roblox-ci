local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest = unpack(require("HTTPFunctions"));

local Upload;
Upload = function(Data, ID, Name, SessionCookie, Force)
	local Result = DataRequest("/Data/Upload.ashx?assetid=" .. ID .. "&type=Model&name=" .. Name  .. "&description=Valkyrie%20CI%20upload&genreTypeId=1&ispublic=True&allowComments=True",
		Data, "Cookie: " .. SessionCookie .. "\nContent-Type: text/xml\n");
	if Result:match("/RobloxDefaultErrorPage") then
		if Force then
			error("ROBLOX LOGIN FAILED! Please contact gskw. Remember to include the time this happened at.");
		end
		return Upload(Data, ID, Name, Login(), true);
	end
	return StripHeaders(Result);
end

return function(ID, BranchName)
	local ModelID = Upload(io.open("builds/" .. BranchName .. ".rbxm"):read("*all"), ID, BranchName, io.open("session.cookie", "r"):read("*all"));
	return ModelID;
end;
