local SSLWrapper = require "ssl";
local Sockets = require "socket";

local function BuildRequest(URL, FormData, ExtraHeaders)
	local Request = "POST " .. URL .. " HTTP/1.1\n";
	Request = Request .. "Host: www.roblox.com\n";
	Request = Request .. "Accept: */*\n";
	Request = Request .. "Connection: close\n"; -- keep-alive will never yield EOF so you can't tell if the server has finished
	Request = Request .. "Content-Length: " .. FormData:len() .. "\n";
	Request = Request .. "User-Agent: Roblox/WinINet\n"; -- Some pages require this I think
	Request = Request .. ExtraHeaders .. "\n";
	Request = Request .. FormData;

	return Request;
end

local function HTTPRequestSSL(URL, FormData, ExtraHeaders)
	local Socket = Sockets.tcp();
	Socket:connect("www.roblox.com", 443);
	Socket = SSLWrapper.wrap(Socket, {mode = "client", protocol = "tlsv1"});
	Socket:dohandshake();
	Socket:send(BuildRequest(URL, FormData, ExtraHeaders));
	local Response = Socket:receive("*a");
	Socket:close();
	return Response;
end

local function HTTPRequest(URL, FormData, ExtraHeaders)
	local Socket = Sockets.tcp();
	Socket:connect("www.roblox.com", 80);
	Socket:send(BuildRequest(URL, FormData, ExtraHeaders));
	local Response = Socket:receive("*a");
	Socket:close();
	return Response;
end

local function StripHeaders(Response)
	return Response:sub(Response:find("\r\n\r\n") + 4);
end

local function Login()
	local LineReader = io.lines("Credientials.txt");
	local Username, Password = LineReader(), LineReader();

	local Result = HTTPRequestSSL("https://www.roblox.com/Services/Secure/LoginService.asmx/ValidateLogin", ('{"userName": "%s","password":"%s","isCaptchaOn":false,"challenge":"","captchaResponse":""}'):format(Username, Password), "X-Requested-With: XMLHttpRequest\nContent-Type: application/json\nAccept-Encoding: gzip\n");

	local SessionCookie = Result:match("(%.ROBLOSECURITY=.-);");

	local SessionFile, Error = io.open("session.cookie", "w");
	if not SessionFile then error(Error); end
	SessionFile:write(SessionCookie);

	return SessionCookie;
end

local Upload;
Upload = function(Data, ID, Name, SessionCookie, Force)
	local Result = HTTPRequest("/Data/Upload.ashx?assetid=" .. ID .. "&type=Model&name=" .. Name  .. "&description=Valkyrie%20CI%20upload&genreTypeId=1&ispublic=True&allowComments=True",
		Data, "Cookie: " .. SessionCookie .. "\nContent-Type: text/xml\n");
	if Result:match("/RobloxDefaultErrorPage") then
		if Force then
			error("ROBLOX LOGIN FAILED! Please contact gskw. Remember to include the time this happened at.");
		end
		print("Update .ROBLOSECURITY");
		return Upload(Data, ID, Name, Login(), true);
	end
	return StripHeaders(Result);
end

return function(ID, BranchName)
	local ModelID = Upload(io.open("builds/" .. BranchName .. ".rbxm"):read("*all"), ID, BranchName, io.open("session.cookie", "r"):read("*all"));
	return ModelID;
end;
