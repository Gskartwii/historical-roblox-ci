local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest, RunPostBack, FindPostState = unpack(require("HTTPFunctions"));

local function CopyLockModel(ID, SessionCookie)
    local CurrentState  = FindPostState("http://www.roblox.com/My/Item.aspx?ID=" .. ID, SessionCookie);
    local Result        = RunPostBack("http://www.roblox.com/My/Item.aspx?ID=" .. ID,
                                      CurrentState,
                                      "ctl00$cphRoblox$SubmitButtonBottom", {
                                        ["ctl00$cphRoblox$NameTextBox"]             = "[DELETED]" .. CurrentState:match "name=\"ctl00$cphRoblox$NameTextBox\" type=\"text\" value=\"(.-)\"",
                                        ["ctl00$cphRoblox$DescriptionTextBox"]      = "Deleted Valkyrie CI upload",
                                        ["ctl00$cphRoblox$EnableCommentsCheckBox"]  = "on",
                                        ["GenreButtons2"]                           = 1,
                                        ["ctl00$cphRoblox$actualGenreSelection"]    = 1,
                                        ["comments"]                                = "",
                                        ["rdoNotifications"]                        = "on",
                                      }, SessionCookie);
end

local function DisownModel(ID, SessionCookie)
    local RealURL       = HTTPRequest("http://www.roblox.com/redirect-item?id=" .. ID, "", "Cookie: " .. SessionCookie .. "\n"):match "Location: (.-)\r\n";
    local CurrentState  = FindPostState(RealURL, SessionCookie);
    local Result        = RunPostBack(RealURL, CurrentState, "ctl00$cphRoblox$btnDelete", {
        ["ctl00$cphRoblox$CommentsPane$NewCommentTextBox"]  = "Write a comment!",
        ["ctl00$cphRoblox$CreateSetPanel1$Name"]            = "",
        ["ctl00$cphRoblox$CreateSetPanel1$Description"]     = "",
        ["ctl00$cphRoblox$CreateSetPanel1$Uploader"]        = ""
    }, SessionCookie);
end

local ModelListParser = require "ModelListParser";

return function(ID)
    CopyLockModel(ID, io.open "session.cookie":read "*a");
    DisownModel(ID, io.open "session.cookie":read "*a");
    local Models = ModelListParser "models.list";
    local ModelsList = io.open("models.list", "w");
    for BranchName, BranchID in next, Models do
        if BranchID ~= ID then
            ModelListParser:write(("%s\t%d\n"):format(BranchName, BranchID));
        end
    end
end;
