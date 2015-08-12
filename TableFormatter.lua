local TableFormatter 			= {};

local GetInstances;
GetInstances = function(Table, TableToFill, LastParent)
	if not TableToFill then
		TableToFill 			= {};
	end
	for i = 1, #Table do
		Table[i].Parent 		= LastParent;
		table.insert(TableToFill, Table[i]);
		if Table[i].Children then
			GetInstances(Table[i].Children, TableToFill, Table[i]);
		end
	end

	return TableToFill;
end

local function GetTypes(Table)
	local Occurrences 			= {};
	local Return 				= {};

	for i = 1, #Table do
		local Type 				= Table[i].Type;
		if not Occurrences[Type] then
			table.insert(Return, Type);
			Occurrences[Type] 	= true;
		end
	end

	return Return;
end

function TableFormatter.FormatTable(Table)
	local Formatted 			= {};
	Formatted.Instances 		= GetInstances(Table);
	Formatted.Types 			= GetTypes(Formatted.Instances);
	Formatted.UniqueTypes		= #Formatted.Types;
	Formatted.UniqueInstances	= #Formatted.Instances;

	return Formatted;
end

return TableFormatter;
