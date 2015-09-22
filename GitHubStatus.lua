local LapisHTTP = require "lapis.nginx.http";
local JSONModule = require "cjson";

return function(SHA, RepoID, State, Description, LogURL)
     print("GitHub status", ({LapisHTTP.simple{
        url     = "https://api.github.com/repos/" .. RepoID .. "/statuses/" .. SHA;
        method  = "POST";
        body    = JSONModule.encode{state = State; context = "continuous-integration/valkyrie", description = Description, target_url = LogURL};
        headers = {
            ["Content-Type"] = "application/json";
            ["Authorization"] = "token " .. io.lines("GitHubToken.txt")();
            ["User-Agent"] = "nginx/Lapis server";
        };
    }})[1]);
end;
