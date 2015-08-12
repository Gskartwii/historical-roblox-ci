local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result = DirScanner.ScanDirectory "i:/Valkyrie Git";

io.open("t.rbxm", "wb"):write(BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result)));
