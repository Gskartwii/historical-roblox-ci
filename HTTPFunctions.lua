local SSLWrapper = require "ssl";
local Sockets = require "socket";

local function BuildRequest(URL, FormData, ExtraHeaders, Host)
	local Request = "POST " .. URL .. " HTTP/1.1\n";
	Request = Request .. "Host: " .. (Host or "www.roblox.com") .. "\n";
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

local function HTTPGet(URL, ExtraHead)
    local Socket = Sockets.tcp();
    Socket:connect("www.roblox.com", 80);
    Socket:send(BuildRequest(URL, "", ExtraHead):gsub("POST", "GET")); -- lol
    local Response = Socket:receive("*a");
    Socket:close();
    return Response;
end

local function DataRequest(URL, FormData, ExtraHeaders)
	local Socket = Sockets.tcp();
	Socket:connect("data.roblox.com", 80);
	Socket:send(BuildRequest(URL, FormData, ExtraHeaders, "data.roblox.com"));
	local Response = Socket:receive("*a");
    print(Response);
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

local function GetCSRF()
    local Result = HTTPGet("/home", "Cookie: " .. io.open("session.cookie"):read("*a") .. "\n");

    io.open("roblox.home", "w"):write(Result);
    local CSRFToken = Result:match("Roblox.XsrfToken.setToken%('(%w-)'%)"); -- Too lazy to use "%."

    local CSRFFile, Error = io.open("csrf.token", "w");
    if not CSRFFile then error(Error); end
    CSRFFile:write(CSRFToken);

    return CSRFToken;
end

return {BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest};
