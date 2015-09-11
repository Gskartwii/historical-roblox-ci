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
		DecoderLog = DecoderLog .. "WARNING: Failed to decode " .. Name .. ": " .. Error .. "\n";
	end

	return Return or {}, DecoderLog;
end

RecursiveScanDir = function(InstanceTree, Name, UnderscoreTable)
	local Log, NewLog = "";
	for File in FileSystemLib.dir(Name) do
		if File:sub(1, 1) ~= "." then -- Avoid ., .. and .git!
			if IsDir(Name .. "/" .. File) then
				local Children 				= {};
				local TableToFill 			= {};
				TableToFill.Properties 		= {Name = {0x1, GetName(File)}};
				TableToFill.Name 			= GetName(File);
				TableToFill.Children 		= Children;
				if GetFullExtension(File) == ".mod.lua" then
					TableToFill.Type 		= "ModuleScript";
					Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				elseif GetFullExtension(File) == ".loc.lua" then
					TableToFill.Type 		= "LocalScript";
					Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				elseif GetFullExtension(File) == ".lua" then
					TableToFill.Type 		= "Script";
					Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				elseif GetFullExtension(File) ~= nil then
					TableToFill.Type 		= GetFullExtension(File):sub(2);
					Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				else
					TableToFill.Type = "Folder";
					Log = Log .. RecursiveScanDir(Children, Name .. "/" .. File);
				end

				table.insert(InstanceTree, TableToFill);
			else
				local FileContent 	= io.open(Name .. "/" .. File, "r"):read("*all");
				if UnderscoreTable and GetName(File) == "_" then
					if GetFullExtension(File):find("%.lua") then
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
					if GetFullExtension(File) == ".mod.lua" then
						table.insert(InstanceTree, {Type = "ModuleScript", Name = GetName(File), Children = {}, Properties = {Name = {0x1, GetName(File)}, Source = {0x1, FileContent}}});
					elseif GetFullExtension(File) == ".loc.lua" then
						table.insert(InstanceTree, {Type = "LocalScript", Name = GetName(File), Children = {}, Properties = {Name = {0x1, GetName(File)}, Source = {0x1, FileContent}}});
					elseif GetFullExtension(File) == ".lua" then
						table.insert(InstanceTree, {Type = "Script", Name = GetName(File), Children = {}, Properties = {Name = {0x1, GetName(File)}, Source = {0x1, FileContent}}});
					else
						local Properties, NewLog;
						if FileContent ~= "" then
							Properties, NewLog	= SafeDecode(Name .. "/" .. File, FileContent);
						else
							Properties, NewLog	= {Name = {0x1, GetName(File)}}, "";
						end
						Log 				= Log .. NewLog;
						Properties.Name  		= {0x1, GetName(File)};
						table.insert(InstanceTree, {Type = GetFullExtension(File):sub(2), Name = GetName(File), Children = {}, Properties = Properties});
					end
				end
			end
		end
	end
	return Log;
end

function DirScanner.ScanDirectory(Name)
	local InstanceTree 	= {};
	local Log = RecursiveScanDir(InstanceTree, Name);
	return InstanceTree, Log;
end

return DirScanner;
