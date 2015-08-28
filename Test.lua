local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result = DirScanner.ScanDirectory "i:/Valkyrie Git";
local StudioManager = dofile "StudioManager.lua";

local Handle, Err = io.open(os.getenv("LOCALAPPDATA") .. "\\Roblox\\Versions\\version-536a65c8f5284f3f\\content\\Valkyrie.rbxm", "wb");
Handle:write(BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result)));
Handle:close(); -- Allow Studio to access the file

--StudioManager.StartClient();
--StudioManager.StartServer();
--local Output = StudioManager.GetOutput();
--print("Client output:", Output.ClientOutput);
--print("Server output:", Output.ServerOutput);
