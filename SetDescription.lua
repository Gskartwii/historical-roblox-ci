local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest, RunPostBack, FindPostState = unpack(require("HTTPFunctions"));

local function SetDescription(ID, Description, SessionCookie)
    local CurrentState  = FindPostState("http://www.roblox.com/My/Item.aspx?ID=" .. ID, SessionCookie);
    local Result        = RunPostBack("http://www.roblox.com/My/Item.aspx?ID=" .. ID,
                                      CurrentState,
                                      "ctl00$cphRoblox$SubmitButtonBottom", {
                                        ["ctl00$cphRoblox$NameTextBox"]             = CurrentState:match "name=\"ctl00$cphRoblox$NameTextBox\" type=\"text\" value=\"(.-)\"",
                                        ["ctl00$cphRoblox$DescriptionTextBox"]      = Description,
                                        ["ctl00$cphRoblox$EnableCommentsCheckBox"]  = "on",
                                        ["GenreButtons2"]                           = 1,
                                        ["ctl00$cphRoblox$actualGenreSelection"]    = 1,
                                        ["comments"]                                = "",
                                        ["rdoNotifications"]                        = "on",
                                      }, SessionCookie);
end

return SetDescription;
