local DirScanner    	= {};
local FileSystemLib 	= require "lfs";
local JSONLib		= require "cjson";

local function IsDir(Path)
	return FileSystemLib.attributes(Path).mode == "directory";
end

local function StripPath(Path)
	return Path:sub(select(1, Path:find("/")) or 1);
end

-- Gotta love these hax
local function GetFullExtension(Path)
	local PathLess		= StripPath(Path);

	local ExtensionPos 	= ({PathLess:find("%.")})[1];
	return ExtensionPos and PathLess:sub(ExtensionPos) or nil;
end

local function GetName(Path)
	local PathLess		= StripPath(Path);

	return PathLess:sub(1, PathLess:find("%.") and select(2, PathLess:find("%.")) - 1 or -1);
end

local RecursiveScanDir;

local function SafeDecode(Name, Content)
	local Return = nil;
	local Success, Error = pcall(function() Return = JSONLib.decode(Content) end);
	local DecoderLog = "";

	if not Success then
		DecoderLog = DecoderLog .. "\1WARNING: Failed to decode " .. Name .. ": " .. Error .. "\n"; -- 0x1 = Warning indicator
	end

	return Return or {}, DecoderLog;
end

local IgnoreRules = {};

local function ParseIgnoreRules(Name)
    local File, Err = io.open(Name, "r");
    if not File then
        return {Extensions = {}, Files = {}};
    end

    return JSONLib.decode(File:read "*a");
end

RecursiveScanDir = function(InstanceTree, Name, UnderscoreTable)
    local Log, NewLog = "";
    for File in FileSystemLib.dir(Name) do
        local CurrentFileExtension = GetFullExtension(File);
        if IsDir(Name .. "/" .. File) then
            local Children 				= {};
            local TableToFill 			= {};
            TableToFill.Properties 		= {Name = {0x1, GetName(File)}};
            TableToFill.Name 			= GetName(File);
            TableToFill.Children 		= Children;
            if CurrentFileExtension == ".mod.lua" then
                TableToFill.Type 		= "ModuleScript";
                Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
                elseif CurrentFileExtension == ".loc.lua" then
                    TableToFill.Type 		= "LocalScript";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
                elseif CurrentFileExtension == ".lua" then
                    TableToFill.Type 		= "Script";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
                elseif CurrentFileExtension ~= nil then
                    TableToFill.Type 		= CurrentFileExtension:sub(2);
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
                else
                    TableToFill.Type = "Folder";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File);
                end

                table.insert(InstanceTree, TableToFill);
            else
                local FileContent 	= io.open(Name .. "/" .. File, "r"):read("*all");
                if UnderscoreTable and GetName(File) == "_" then
                    if CurrentFileExtension:find("%.lua") then
                        UnderscoreTable.Properties.Source = {0x1, FileContent};
                    else
                        local Properties, NewLog;
                        if FileContent ~= "" then
                            Properties, NewLog	= SafeDecode(Name .. "/" .. File, FileContent);
                        else
                            Properties, NewLog	= {Name = {0x1, GetName(File)}}, "";
                        end
                        Log 				= Log .. NewLog;
                        Properties.Name 		= UnderscoreTable.Properties.Name;
                        UnderscoreTable.Properties = Properties;
                    end
                else
                    if CurrentFileExtension == nil then
                        Log = Log .. "\1WARNING: No file extension: " .. Name .. "/" .. File;
                    elseif CurrentFileExtension == ".mod.lua" then
                        table.insert(InstanceTree, {Type = "ModuleScript", Name = GetName(File), Children = {}, Properties = {Name = {0x1, GetName(File)}, Source = {0x1, FileContent}}});
                    elseif CurrentFileExtension == ".loc.lua" then
                        table.insert(InstanceTree, {Type = "LocalScript", Name = GetName(File), Children = {}, Properties = {Name = {0x1, GetName(File)}, Source = {0x1, FileContent}}});
                    elseif CurrentFileExtension == ".lua" then
                        table.insert(InstanceTree, {Type = "Script", Name = GetName(File), Children = {}, Properties = {Name = {0x1, GetName(File)}, Source = {0x1, FileContent}}});
                    elseif not IgnoreRules.Extensions[CurrentFileExtension] and not IgnoreRules.Files[Name .. "/" .. File] then
                        local Properties, NewLog;
                        if FileContent ~= "" then
                            Properties, NewLog	= SafeDecode(Name .. "/" .. File, FileContent);
                        else
                            Properties, NewLog	= {Name = {0x1, GetName(File)}}, "";
                        end
                        Log 		    		= Log .. NewLog;
                        Properties.Name  		= {0x1, GetName(File)};
                        table.insert(InstanceTree, {Type = CurrentFileExtension:sub(2), Name = GetName(File), Children = {}, Properties = Properties});
                    end
                end
            end
        end
    return Log;
end

function DirScanner.ScanDirectory(Name)
	local InstanceTree 	= {};
    IgnoreRules = ParseIgnoreRules(Name .. "/.valkyrie.conf");
	local Log = RecursiveScanDir(InstanceTree, Name);
	return InstanceTree, Log;
end

return DirScanner;
