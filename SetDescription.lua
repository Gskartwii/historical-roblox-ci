local BuildRequest, HTTPRequestSSL, HTTPRequest, StripHeaders, Login, DataRequest, RunPostBack, FindPostState = unpack(require("HTTPFunctions"));

local function SetDescription(ID, Name, Description, SessionCookie)
    local CurrentState  = FindPostState("https://www.roblox.com/My/Item.aspx?ID=" .. ID, SessionCookie);
    local Result        = RunPostBack("https://www.roblox.com/My/Item.aspx?ID=" .. ID,
                                      CurrentState,
                                      "ctl00$cphRoblox$SubmitButtonBottom", {
                                        ["ctl00$cphRoblox$NameTextBox"]             = Name,
                                        ["ctl00$cphRoblox$DescriptionTextBox"]      = Description,
                                        ["ctl00$cphRoblox$EnableCommentsCheckBox"]  = "on",
                                        ["ctl00$cphRoblox$PublicDomainCheckBox"]    = "on";
                                        ["GenreButtons2"]                           = 1,
                                        ["ctl00$cphRoblox$actualGenreSelection"]    = 1,
                                        ["comments"]                                = "",
                                        ["rdoNotifications"]                        = "on",
                                      }, SessionCookie);
end

return SetDescription;
