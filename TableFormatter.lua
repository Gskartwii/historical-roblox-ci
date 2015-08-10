local TableFormatter 			= {};

local GetInstances;
GetInstances = function(Table, TableToFill, LastParent)
	if not TableToFill then
		TableToFill 			= {};
	end
	for i = 1, #Table do
		Table[i].Parent 		= LastParent;
		table.insert(TableToFill, Table[i]);
		GetInstances(Table.Children, TableToFill, Table);
	end

	return TableToFill;
end

function TableFormatter.FormatTable(Table)
	local Formatted 			= {};
	Formatted.Instances 		= GetInstances(Table);
	Formatted.Types 			= GetTypes(Formatted.Instances);
	Formatted.UniqueTypes		= #Formatted.UniqueTypes;
	Formatted.UniqueInstance	= #Formatted.Instances;
end

return TableFormatter;
