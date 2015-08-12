local EncodedTypes 		= {};
local BitLibrary 		= require "bit32";
local LZ4Library 		= dofile "lz4.lua";
local PackLibrary 		= require "vstruct";

function EncodedTypes.EncodeInt32LE(Integer)
	return string.char(
					 	  BitLibrary.band(Integer, 0xFF),
		BitLibrary.rshift(BitLibrary.band(Integer, 0xFF00), 	8),
		BitLibrary.rshift(BitLibrary.band(Integer, 0xFF0000), 	16),
		BitLibrary.rshift(BitLibrary.band(Integer, 0xFF000000), 24));
end

function EncodedTypes.EncodeInt32BE(Integer)
	return EncodedTypes.EncodeInt32LE(Integer):reverse();
end

function EncodedTypes.CompressLZ4(String)
	local Compressed 	= LZ4Library.compress(String);

	return EncodedTypes.EncodeInt32LE(Compressed:len() - 8) .. EncodedTypes.EncodeInt32LE(String:len()) .. "\0\0\0\0" .. -- Header
	Compressed:sub(9);
end

function EncodedTypes.EncodeInterleavedInt32LE(Table)
	local Pieces 		= {"", "", "", ""};

	for i = 1, #Table do
		Pieces[1]		= Pieces[1] .. string.char(BitLibrary.band(Table[i], 0xFF));
		Pieces[2]		= Pieces[2] .. string.char(BitLibrary.rshift(BitLibrary.band(Table[i], 0xFF00), 8));
		Pieces[3] 		= Pieces[3] .. string.char(BitLibrary.rshift(BitLibrary.band(Table[i], 0xFF0000), 16));
		Pieces[4] 		= Pieces[4] .. string.char(BitLibrary.rshift(BitLibrary.band(Table[i], 0xFF000000), 24));
	end

	return table.concat(Pieces, "");
end

function EncodedTypes.EncodeInterleavedInt32BE(Table)
	local Pieces 		= {"", "", "", ""};

	for i = 1, #Table do
		Pieces[1] 		= Pieces[1] .. string.char(BitLibrary.rshift(BitLibrary.band(Table[i], 0xFF000000), 24));
		Pieces[2] 		= Pieces[2] .. string.char(BitLibrary.rshift(BitLibrary.band(Table[i], 0xFF0000), 16));
		Pieces[3]		= Pieces[3] .. string.char(BitLibrary.rshift(BitLibrary.band(Table[i], 0xFF00), 8));
		Pieces[4]		= Pieces[4] .. string.char(BitLibrary.band(Table[i], 0xFF));
	end

	return table.concat(Pieces, "");
end

function EncodedTypes.IntTransform(Integer)
	return Integer >= 0 and 2 * Integer or -2 * Integer - 1;
end

local function FloatToBinary(n)
    local Packed 		= PackLibrary.write("> f4", "", {n});
	return BitLibrary.lshift(Packed:byte(1), 24) + BitLibrary.lshift(Packed:byte(2), 16) + BitLibrary.lshift(Packed:byte(3), 8) + Packed:byte(4);
end

function EncodedTypes.FloatTransform(Float)
	local Binary 			= FloatToBinary(Float);

	return BitLibrary.lshift(Binary, 1) + BitLibrary.rshift(Binary, 31);
end

return EncodedTypes;
