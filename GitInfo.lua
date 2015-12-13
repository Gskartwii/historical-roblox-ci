local FileSystemLib = require("lfs");
local StringValueTemplate = [[{
    "Value": [1, "%s"]
}]];

local function Write(Name, Content)
    local File = assert(io.open(Name, "w"));
    File:write(Content);
    File:close();
end

return function(BranchID, HeadCommitID, HeadCommitText, Author)
    local BaseDir = "branches/" .. BranchID .. "/MainModule.mod.lua/GitMeta/";
    lfs.mkdir(BaseDir);
    
    Write(BaseDir .. "BranchID.StringValue", StringValueTemplate:format(BranchID));
    Write(BaseDir .. "HeadCommitID.StringValue", StringValueTemplate:format(HeadCommitID));
    Write(BaseDir .. "HeadCommitText.StringValue", StringValueTemplate:format(HeadCommitText));
    Write(BaseDir .. "Author.StringValue", StringValueTemplate:format(Author));
end;
