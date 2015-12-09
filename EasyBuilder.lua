#!/usr/bin/env lua
local Input, Output = ...;
print(Input, Output);
local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result, Log = DirScanner.ScanDirectory(Input);
local StudioManager = dofile "StudioManager.lua";

local Handle, Err = io.open(Output, "w");
print(Err);
local Build, BuilderLog = BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result));
print("LOG", Log);
Handle:write(Build);
Handle:close(); -- Allow Studio to access the file
return Log .. BuilderLog;
