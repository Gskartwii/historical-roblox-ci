local FileSystemLib = require("lfs");
local StringValueTemplate = [[{
    "Value": [1, "%s"]
}]];

return function(BranchID, HeadCommitID, HeadCommitText, Author)
    local BaseDir = "branches/" .. BranchID .. "/MainModule.mod.lua/GitMeta/";
    lfs.mkdir(BaseDir);
    
    io.open(BaseDir .. "BranchID.StringValue", "w"):write(StringValueTemplate:format(BranchID));
    io.open(BaseDir .. "HeadCommitID.StringValue", "w"):write(StringValueTemplate:format(HeadCommitID));
    io.open(BaseDir .. "HeadCommitText.StringValue", "w"):write(StringValueTemplate:format(HeadCommitText));
    io.open(BaseDir .. "Author.StringValue", "w"):write(StringValueTemplate:format(Author));
end;
