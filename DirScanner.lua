local DirScanner    	= {};
local FileSystemLib 	= require "lfs";

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

RecursiveScanDir = function(InstanceTree, Name, UnderscoreTable)
	for File in FileSystemLib.dir(Name) do
		if File:sub(1, 1) ~= "." then -- Avoid ., .. and .git!
			if IsDir(Name .. "/" .. File) then
				local Children 		= {};
				local TableToFill 	= {};
				if GetFullExtension(File) == ".mod.lua" then
					TableToFill.Name = GetName(File);
					TableToFill.Type = "ModuleScript";
					TableToFill.Children = Children;
					RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				elseif GetFullExtension(File) == ".loc.lua" then
					TableToFill.Name = GetName(File);
					TableToFill.Type = "LocalScript";
					TableToFill.Children = Children;
					RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				elseif GetFullExtension(File) == ".lua" then
					TableToFill.Name = GetName(File);
					TableToFill.Type = "Script";
					TableToFill.Children = Children;
					RecursiveScanDir(Children, Name .. "/" .. File, TableToFill);
				elseif GetFullExtension(File) == nil then
					TableToFill.Name = GetName(File);
					TableToFill.Type = "Folder";
					TableToFill.Children = Children;
					RecursiveScanDir(Children, Name .. "/" .. File);
				end

				table.insert(InstanceTree, TableToFill);
			else
				local FileContent 	= io.open(Name .. "/" .. File, "r"):read("*all");
				if UnderscoreTable and GetName(File) == "_" then
					UnderscoreTable.Script = FileContent;
				else
					if GetFullExtension(File) == ".mod.lua" then
						table.insert(InstanceTree, {Type = "ModuleScript", Name = GetName(File), Children = {}, Script = FileContent});
					elseif GetFullExtension(File) == ".loc.lua" then
						table.insert(InstanceTree, {Type = "LocalScript", Name = GetName(File), Children = {}, Script = FileContent});
					elseif GetFullExtension(File) == ".lua" then
						table.insert(InstanceTree, {Type = "Script", Name = GetName(File), Children = {}, Script = FileContent});
					elseif GetFullExtension(File) == ".RemoteEvent" then
						table.insert(InstanceTree, {Type = "RemoteEvent", Name = GetName(File), Children = {}});
					elseif GetFullExtension(File) == ".IntValue" then
						table.insert(InstanceTree, {Type = "IntValue", Name = GetName(File), Children = {}});
					elseif GetFullExtension(File) == ".ObjectValue" then
						table.insert(InstanceTree, {Type = "InstanceTree", Name = GetName(File), Children = {}});
					else
						print("WARNING: Unknown Extension", GetFullExtension(File), " in ", File);
					end
				end
			end
		end
	end
end

function DirScanner.ScanDirectory(Name)
	local InstanceTree 	= {};
	RecursiveScanDir(InstanceTree, Name);
	return InstanceTree;
end

return DirScanner;
