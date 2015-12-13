local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, GetCSRF = unpack(require("HTTPFunctions"));
local EncodeQuery = require("lapis.util").encode_query_string;

local SetStatus;
SetStatus = function(NewStatus, SessionCookie, CSRFToken, Force, CSRFForce)
    local Result = HTTPRequest("/home/updatestatus", EncodeQuery({
        status = NewStatus,
        sendToFacebook = "false" -- lolno.
        -- Also if you pass a boolean LuaSocket dies, lol
    }):gsub("%%20", "+"):gsub("%%3a", "%%3A"), "Cookie: " .. SessionCookie .. "Content-Type: application/x-www-form-urlencoded; charset=UTF-8\nX-CSRF-TOKEN: " .. CSRFToken .. "\nReferer: http://www.roblox.com/home\n");
    if Result:match("Server Error") or Result:match("Error Occurred") then -- Roblox error messages at their finest
        if CSRFForce then
            error("ROBLOX CSRF TOKEN SCRAPING FAILED! Please concact gskw. Remember to include the time this happened at.");
        end
        return SetStatus(NewStatus, SessionCookie, GetCSRF(), Force, true);
    end
    if Result:match("/RobloxDefaultErrorPage") then
		if Force then
			error("ROBLOX LOGIN FAILED! Please contact gskw. Remember to include the time this happened at.");
		end
		return SetStatus(NewStatus, Login(), true, CSRFForce);
    end
end;

return function(NewStatus)
	SetStatus(NewStatus, io.open("session.cookie", "r"):read("*all"), io.open("csrf.token", "r"):read("*all"));
end
