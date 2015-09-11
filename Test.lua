#!/usr/bin/env luajit
local BranchName = ...;
local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result, Log = DirScanner.ScanDirectory("branches/" .. BranchName);
local StudioManager = dofile "StudioManager.lua";

local Handle, Err = io.open("builds/" .. BranchName .. ".rbxm", "w");
local Build, BuilderLog = BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result));
print("LOG", Log);
Handle:write(Build);
Handle:close(); -- Allow Studio to access the file
return Log .. BuilderLog;
