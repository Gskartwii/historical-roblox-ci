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

	local ExtensionPos 	= ({PathLess:find("%.", 2)})[1];
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
		print(Name, " DECODE ERROR !!!! ", Error);
	end

	return Return or {}, DecoderLog;
end

local function ParseRules(Name)
    local File, Err = io.open(Name, "r");
    if not File then
        return {Extensions = {[".md"] = true}, Files = {["."] = true, [".."] = true, [".git"] = true}};
    end
    local Content = File:read "*a";
    File:close();

    return JSONLib.decode(Content);
end

local AlwaysIgnore = {
    Extensions = {};
    Files = {
        ["project.conf"] = true;
        ["."] = true;
        [".."] = true;
        [".git"] = true;
        [".gitignore"] = true;
        [".gitmodules"] = true;
        [".gitattributes"] = true;
    }
};

RecursiveScanDir = function(InstanceTree, Name, UnderscoreTable, Rules)
    local Log, NewLog = "";
    local IsLocalRules = io.open(Name .. "/project.conf");
    local Rules = IsLocalRules and ParseRules(Name .. "/project.conf") or Rules;
    for File in FileSystemLib.dir(Name) do
        local CurrentFileExtension = GetFullExtension(File);
        if not Rules.Extensions[CurrentFileExtension] and not Rules.Files[File] and not AlwaysIgnore.Extensions[CurrentFileExtension] and not AlwaysIgnore.Files[File] then
            if IsDir(Name .. "/" .. File) then
                local Children 				= {};
                local TableToFill 			= {};
                TableToFill.Properties 		= {Name = {0x1, GetName(File)}};
                TableToFill.Name 			= GetName(File);
                TableToFill.Children 		= Children;
                if CurrentFileExtension == ".mod.lua" then
                    TableToFill.Type 		= "ModuleScript";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill, Rules);
                elseif CurrentFileExtension == ".loc.lua" then
                    TableToFill.Type 		= "LocalScript";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill, Rules);
                elseif CurrentFileExtension == ".lua" then
                    TableToFill.Type 		= "Script";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill, Rules);
                elseif CurrentFileExtension ~= nil then
                    TableToFill.Type 		= CurrentFileExtension:sub(2);
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill, Rules);
                else
                    TableToFill.Type = "Folder";
                    Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, nil, Rules);
                end

                table.insert(InstanceTree, TableToFill);
            else
                local Handle        = io.open(Name .. "/" .. File, "r");
                local FileContent 	= Handle:read("*all");
                Handle:close();
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
                    else
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
    end
    return Log;
end

function DirScanner.ScanDirectory(Name)
	local InstanceTree, Log 	= {}, "";
    Rules = ParseRules(Name .. "/MainModule.mod.lua/project.conf");

    if not Rules.RootMode or Rules.RootMode == "Legacy" then
        local RootName = "MainModule";
        local RootType = "ModuleScript";

        if Rules.RootOverride then
            RootName = Rules.RootOverride.Name or RootName;
            RootType = Rules.RootOverride.Type or RootType;
        end
        InstanceTree[1] = {Name = RootName, Type = RootType, Children = {}, Properties = {Name = {0x1, RootName}}};

        Log = RecursiveScanDir(InstanceTree[1].Children, Name .. "/MainModule.mod.lua", InstanceTree[1], Rules);
    elseif Rules.RootMode == "MultiRoot" then
        Log = RecursiveScanDir(InstanceTree, Name .. "/MainModule.mod.lua", nil, Rules);
    end
	return InstanceTree, Log;
end

return DirScanner;
