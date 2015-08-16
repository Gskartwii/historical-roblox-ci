local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result = DirScanner.ScanDirectory "i:/Valkyrie Git";
local StudioManager = dofile "StudioManager.lua";

local Handle = io.open("C:\\Users\\GSKW\\AppData\\Local\\Roblox\\Versions\\version-a15ad0329eab4912\\content\\Valkyrie.rbxm", "wb");
Handle:write(BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result)));
Handle:close(); -- Allow Studio to access the file

StudioManager.StartClient();
StudioManager.StartServer();
local Output = StudioManager.GetOutput();
print("Client output:", Output.ClientOutput);
print("Server output:", Output.ServerOutput);
