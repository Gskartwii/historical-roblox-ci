local function Escape(String)
	return "'" .. String:gsub("'", "\\'") .. "'";
end

return function(Command, ...)
	local Args = {...};
	for i = 1, #Args do
		Args[i] = Escape(Args[i]);
	end
	local Handle = io.popen(Command .. " " .. table.concat(Args, " "), "r");
	print(Command .. " " .. table.concat(Args, " "));
	local Result = Handle:read("*a");
	Handle:close();
	return Result;
end;
