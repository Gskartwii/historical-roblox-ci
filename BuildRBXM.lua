local BuildRBXM			= {};
local EnumInstances 	= {};
local Constants 		= dofile "Constants.lua";
local EncodedTypes 		= dofile "EncodedTypes.lua";

local function EnumerateInstances(Table)
	for i = 1, #Table do
		EnumInstances[Table[i]] = i;
	end
end

local function FindInstanceReferents(Table, Type)
	local Referents 	= {};
	local LastReferent 	= 0;
	for i = 1, #Table do
		if Table[i].Type == Type then
			local NewReferent = EnumInstances[Table[i]] - 1;
			table.insert(Referents, EncodedTypes.IntTransform(NewReferent - LastReferent));
			LastReferent = NewReferent;
		end
	end

	return Referents;
end

local function GetInstancesOfType(Table, Type)
	local Instances 	= {};
	for i = 1, #Table do
		if Table[i].Type == Type then
			table.insert(Instances, Table[i]);
		end
	end

	return Instances;
end

local function GenerateINSTHeader(Table)
	local Return 			= "";
	local UncompressedBuf	;
	for i = 0, Table.UniqueTypes - 1 do
		local Type 			= Table.Types[i + 1];
		UncompressedBuf 	= EncodedTypes.EncodeInt32LE(i); -- Type ID
		UncompressedBuf		= UncompressedBuf .. EncodedTypes.EncodeInt32LE(Type:len()) .. Type;
		UncompressedBuf 	= UncompressedBuf .. "\0"; -- No extra data

		local Referents 	= FindInstanceReferents(Table.Instances, Type);

		UncompressedBuf 	= UncompressedBuf .. EncodedTypes.EncodeInt32LE(#Referents); -- Array length
		UncompressedBuf		= UncompressedBuf .. EncodedTypes.EncodeInterleavedInt32BE(Referents); -- Referent array

		Return 				= Return .. "INST" .. EncodedTypes.CompressLZ4(UncompressedBuf);
	end

	return Return;
end

local function EncodePropertyData(InstancesOfType, PropertyName)
	local Return 			= "";
	local Log			= "";
	local function print(...) Log = Log .. table.concat({...}, "\t") .. "\1\n" end; -- 0x1 = Failure indicator

	local PropertyData		= InstancesOfType[1].Properties[PropertyName]
	local Type 				= PropertyData[1];

	if Type == 0x1 then -- String
		for i = 1, #InstancesOfType do
			Return 			= Return .. EncodedTypes.EncodeInt32LE(InstancesOfType[i].Properties[PropertyName][2]:len()) .. InstancesOfType[i].Properties[PropertyName][2];
		end
	elseif Type == 0x2 then -- Boolean
		for i = 1, #InstancesOfType do
			Return 			= Return .. string.char(InstancesOfType[i].Properties[PropertyName][2] and 1 or 0);
		end
	elseif Type == 0x3 or Type == 0xB or Type == 0x12 then -- Int, BrickColor, Enum
		local IntArray 		= {};
		for i = 1, #InstancesOfType do
			table.insert(IntArray, InstancesOfType[i].Properties[PropertyName][2]);
		end

		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(IntArray);
	elseif Type == 0x4 then -- Float
		local FloatArray 	= {};
		for i = 1, #InstancesOfType do
			table.insert(FloatArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2]));
		end

		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(FloatArray);
	elseif Type == 0x5 then
		print("WARNING: Double " .. PropertyName .. " STUB!");
	elseif Type == 0x7 then -- UDim2
		local OffsetXArray 	= {};
		local OffsetYArray 	= {};
		local ScaleXArray 	= {};
		local ScaleYArray 	= {};

		for i = 1, #InstancesOfType do
			table.insert(OffsetXArray, EncodedTypes.IntTransform(InstancesOfType[i].Properties[PropertyName][2].OffsetX));
			table.insert(OffsetYArray, EncodedTypes.IntTransform(InstancesOfType[i].Properties[PropertyName][2].OffsetY));
			table.insert(ScaleXArray,  EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].ScaleX));
			table.insert(ScaleYArray,  EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].ScaleY));
		end

		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(ScaleXArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(ScaleYArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(OffsetXArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(OffsetYArray);
	elseif Type == 0x8 then
		print("WARNING: Ray " .. PropertyName .. " STUB!");
	elseif Type == 0x9 then
		print("WARNING: Faces " .. PropertyName .. " STUB!");
	elseif Type == 0xA then
		print("WARNING: Axis " .. PropertyName .. " STUB!");
	elseif Type == 0xC then -- Color3
		local RArray 		= {};
		local GArray 		= {};
		local BArray 		= {};

		for i = 1, #InstancesOfType do
			table.insert(RArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].R / 255));
			table.insert(GArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].G / 255));
			table.insert(BArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].B / 255));
		end

		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(RArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(GArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(BArray);
	elseif Type == 0xD then -- Vector2
		local XArray 		= {};
		local YArray 		= {};

		for i = 1, #InstancesOfType do
			table.insert(XArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].X));
			table.insert(YArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].Y));
		end

		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(XArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(YArray);
	elseif Type == 0xE then -- Vector3
		local XArray 		= {};
		local YArray 		= {};
		local ZArray 		= {};

		for i = 1, #InstancesOfType do
			table.insert(XArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].X));
			table.insert(YArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].Y));
			table.insert(ZArray, EncodedTypes.FloatTransform(InstancesOfType[i].Properties[PropertyName][2].Z));
		end

		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(XArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(YArray);
		Return 				= Return .. EncodedTypes.EncodeInterleavedInt32BE(ZArray);
	elseif Type == 0x10 then
		print("WARNING: CFrame " .. PropertyName .. " STUB!");
	elseif Type == 0x13 then
		print("WARNING: Referent " .. PropertyName .. " STUB!");
	end

	return Return, Log;
end

local function GeneratePROPSection(Table)
	local Return 			= "";
	local Log			= "";
	local NewLog;
	local UncompressedBuf 	;

	for i = 1, Table.UniqueTypes do
		local Type 				= Table.Types[i];
		local InstancesOfType 	= GetInstancesOfType(Table.Instances, Type);
		for PropertyName, PropertyData in next, InstancesOfType[1].Properties do
			UncompressedBuf 	= EncodedTypes.EncodeInt32LE(i - 1); -- Type ID
			UncompressedBuf		= UncompressedBuf .. EncodedTypes.EncodeInt32LE(PropertyName:len()) .. PropertyName; -- Property name
			local EncodedData, NewLog = EncodePropertyData(InstancesOfType, PropertyName); 
			UncompressedBuf		= UncompressedBuf .. string.char(PropertyData[1]) .. EncodedData; 
			Log 			= Log .. NewLog;
			Return 				= Return .. "PROP" .. EncodedTypes.CompressLZ4(UncompressedBuf);
		end
	end

	return Return, Log;
end

local function GeneratePRNTSection(Table)
	local Return 			= "PRNT";
	local UncompressedBuf 	= "\0" .. EncodedTypes.EncodeInt32LE(Table.UniqueInstances);

	local ReferentArr 		= {};
	local ParentArr 		= {};

	local LastReferent 		= 0;
	local LastParent 		= 0;

	for i = 1, Table.UniqueInstances do
		local NewReferent 	= EnumInstances[Table.Instances[i]] - 1;
		table.insert(ReferentArr, EncodedTypes.IntTransform(NewReferent - LastReferent));
		LastReferent 		= NewReferent;

		local NewParent   	= Table.Instances[i].Parent and EnumInstances[Table.Instances[i].Parent] - 1 or -1;
		table.insert(ParentArr, EncodedTypes.IntTransform(NewParent - LastParent));
		LastParent 		  	= NewParent;
	end

	UncompressedBuf 		= UncompressedBuf .. EncodedTypes.EncodeInterleavedInt32BE(ReferentArr) .. EncodedTypes.EncodeInterleavedInt32BE(ParentArr);

	Return 					= Return .. EncodedTypes.CompressLZ4(UncompressedBuf);

	return Return;
end

function BuildRBXM.BuildFromTable(Table)
	EnumerateInstances(Table.Instances);
	local Return 		= Constants.Header;
	local Log;
	Return 				= Return .. EncodedTypes.EncodeInt32LE(Table.UniqueTypes);
	Return 				= Return .. EncodedTypes.EncodeInt32LE(Table.UniqueInstances);
	Return 				= Return .. "\0\0\0\0\0\0\0\0";
	Return 				= Return .. GenerateINSTHeader(Table);
	local PROPSection, Log		= GeneratePROPSection(Table);
	Return	 			= Return .. PROPSection;
	Return				= Return .. GeneratePRNTSection(Table);
	Return 				= Return .. Constants.Footer;

	return Return, Log;
end

return BuildRBXM;
