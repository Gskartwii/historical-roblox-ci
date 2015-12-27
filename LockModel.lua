local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest, RunPostBack, FindPostState = unpack(require("HTTPFunctions"));

local CopyLockModel;
CopyLockModel = function(ID, SessionCookie)
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
    
    print(Result);
end;

return function(ID)
    CopyLockModel(ID, io.open "session.cookie":read "*a");
end;
