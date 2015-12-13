#!/usr/bin/env lua
local Input, Output = ...;
local DirScanner = dofile "DirScanner.lua";
local TableFormatter = dofile "TableFormatter.lua";
local BuildRBXM	= dofile "BuildRBXM.lua";
local Result, Log = DirScanner.ScanDirectory(Input);
local StudioManager = dofile "StudioManager.lua";

local Handle, Err = io.open(Output, "w");
local Build, BuilderLog = BuildRBXM.BuildFromTable(TableFormatter.FormatTable(Result));
Handle:write(Build);
Handle:close(); -- Allow Studio to access the file
return Log .. BuilderLog;
