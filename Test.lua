#!/usr/bin/env luajit
local BranchName = ...;
local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result = DirScanner.ScanDirectory("branches/" .. BranchName);
local StudioManager = dofile "StudioManager.lua";

local Handle, Err = io.open("builds/" .. BranchName .. ".rbxm", "w");
print(Err);
Handle:write(BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result)));
Handle:close(); -- Allow Studio to access the file
