return function(Filename)
	local Ret = {};
	if not io.open(Filename) then return Ret; end
	for Line in io.lines(Filename) do
		Ret[Line:sub(1, Line:find("\t") - 1)] = Line:sub(Line:find("\t") + 1);
	end
	return Ret;
end;
