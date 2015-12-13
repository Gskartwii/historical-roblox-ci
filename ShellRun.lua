local Bypass = {};
local function Raw(String)
	local Dummy = newproxy(false);
	Bypass[Dummy] = String;
	return Dummy;
end

local function Escape(String)
	if Bypass[String] then 
		return Bypass[String];
	end
	return "'" .. String:gsub("'", "\\'") .. "'";
end

local function Run(Command, ...)
	local Args = {...};
	for i = 1, #Args do
		Args[i] = Escape(Args[i]);
	end
	local Handle = io.popen(Command .. " " .. table.concat(Args, " ") .. " 2>&1", "r");
	local Result, Err = Handle:read("*a");
	Handle:close();
	return "$ " .. Command .. " " .. table.concat(Args, " ") .. "\n" .. Result;
end

return {Run, Raw};
