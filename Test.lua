local DirScanner = dofile "DirScanner.lua";
local Result = DirScanner.ScanDirectory "i:/gv";


local RecFunction;
RecFunction = function(Table, Function)
	for i, v in next, Table do
		Function(i,v);
		if v.Children then
			RecFunction(v.Children, Function)
		end
	end
end;

RecFunction(Result, function(i,v)
	print("Name", v.Name);
	print("Type", v.Type);
	print("Children", #v.Children);
	print();
end);
