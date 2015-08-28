(function(...)
	--rbxsig%mzAwBWILOXqhKxGNtnAK02+e4FUsxn5wdF0GNqWuVZO1xo7odT816udMeDBtnGQ49Vt1q2RafPLkowIc7uOb5iu9gkKybQwN+7WNU29h9WxaxQxjxh9+YGcJFBTO8VK5ra1P9ue0iI6m1/NDdnfsMI2omih4fZrrL9Z5X7aEPTQ=%
	-- Start Game Script Arguments
	local placeId, port, gameId, sleeptime, access, url, timeout, machineAddress, gsmInterval, baseUrl, maxPlayers, maxGameInstances, injectScriptAssetID, apiKey, libraryRegistrationScriptAssetID, pingTimesReportInterval, gameCode, universeId, preferredPlayerCapacity, matchmakingContextId, placeVisitAccessKey = ...

	-----------------------------------"CUSTOM" SHARED CODE----------------------------------

	pcall(function() settings().Network.UseInstancePacketCache = true end)
	pcall(function() settings().Network.UsePhysicsPacketCache = true end)
	pcall(function() settings()["Task Scheduler"].PriorityMethod = Enum.PriorityMethod.AccumulatedError end)


	settings().Network.PhysicsSend = Enum.PhysicsSendMethod.TopNErrors
	settings().Network.ExperimentalPhysicsEnabled = true
	settings().Network.WaitingForCharacterLogRate = 100
	pcall(function() settings().Diagnostics:LegacyScriptMode() end)

	-----------------------------------START GAME SHARED SCRIPT------------------------------

	local assetId = placeId -- might be able to remove this now

	local scriptContext = game:GetService('ScriptContext')
	pcall(function() scriptContext:AddStarterScript(libraryRegistrationScriptAssetID) end)
	scriptContext.ScriptsDisabled = true

	game:SetPlaceID(assetId, false)
	pcall(function () if universeId ~= nil then game:SetUniverseId(universeId) end end)
	game:GetService("ChangeHistoryService"):SetEnabled(false)

	-- establish this peer as the Server
	local ns = game:GetService("NetworkServer")

	local badgeUrlFlagExists, badgeUrlFlagValue = pcall(function () return settings():GetFFlag("NewBadgeServiceUrlEnabled") end)
	local newBadgeUrlEnabled = badgeUrlFlagExists and badgeUrlFlagValue
	if url~=nil then
		local apiProxyUrl = string.gsub(url, "http://www", "https://api")    -- hack - passing domain (ie "sitetest1.robloxlabs.com") and appending "https://api." to it would be better

		pcall(function() game:GetService("Players"):SetAbuseReportUrl(url .. "/AbuseReport/InGameChatHandler.ashx") end)
		pcall(function() game:GetService("ScriptInformationProvider"):SetAssetUrl(url .. "/Asset/") end)
		pcall(function() game:GetService("ContentProvider"):SetBaseUrl(url .. "/") end)
		pcall(function() game:GetService("Players"):SetChatFilterUrl(url .. "/Game/ChatFilter.ashx") end)

		if gameCode then
			game:SetVIPServerId(tostring(gameCode))
		end

		game:GetService("BadgeService"):SetPlaceId(placeId)

		if newBadgeUrlEnabled then
			game:GetService("BadgeService"):SetAwardBadgeUrl(apiProxyUrl .. "/assets/award-badge?userId=%d&badgeId=%d&placeId=%d")
		end

		if access ~= nil then
			if not newBadgeUrlEnabled then
				game:GetService("BadgeService"):SetAwardBadgeUrl(url .. "/Game/Badge/AwardBadge.ashx?UserID=%d&BadgeID=%d&PlaceID=%d")
			end

			game:GetService("BadgeService"):SetHasBadgeUrl(url .. "/Game/Badge/HasBadge.ashx?UserID=%d&BadgeID=%d")
			game:GetService("BadgeService"):SetIsBadgeDisabledUrl(url .. "/Game/Badge/IsBadgeDisabled.ashx?BadgeID=%d&PlaceID=%d")

			game:GetService("FriendService"):SetMakeFriendUrl(url .. "/Game/CreateFriend?firstUserId=%d&secondUserId=%d")
			game:GetService("FriendService"):SetBreakFriendUrl(url .. "/Game/BreakFriend?firstUserId=%d&secondUserId=%d")
			game:GetService("FriendService"):SetGetFriendsUrl(url .. "/Game/AreFriends?userId=%d")
		end
		game:GetService("BadgeService"):SetIsBadgeLegalUrl("")
		game:GetService("InsertService"):SetBaseSetsUrl(url .. "/Game/Tools/InsertAsset.ashx?nsets=10&type=base")
		game:GetService("InsertService"):SetUserSetsUrl(url .. "/Game/Tools/InsertAsset.ashx?nsets=20&type=user&userid=%d")
		game:GetService("InsertService"):SetCollectionUrl(url .. "/Game/Tools/InsertAsset.ashx?sid=%d")
		game:GetService("InsertService"):SetAssetUrl(url .. "/Asset/?id=%d")
		game:GetService("InsertService"):SetAssetVersionUrl(url .. "/Asset/?assetversionid=%d")

		if gameCode then
			pcall(function() loadfile(url .. "/Game/LoadPlaceInfo.ashx?PlaceId=" .. placeId .. "&gameCode=" .. tostring(gameCode))() end)
		else
			pcall(function() loadfile(url .. "/Game/LoadPlaceInfo.ashx?PlaceId=" .. placeId)() end)
		end

		pcall(function()
					if access then
						loadfile(url .. "/Game/PlaceSpecificScript.ashx?PlaceId=" .. placeId)()
					end
				end)
	end

	pcall(function() game:GetService("NetworkServer"):SetIsPlayerAuthenticationRequired(true) end)
	settings().Diagnostics.LuaRamLimit = 0

	game:GetService("Players").PlayerAdded:connect(function(player)
		print("Player " .. player.userId .. " added")

		if url and access and placeId and player and player.userId then
			game:HttpGet(url .. "/Game/ClientPresence.ashx?action=connect&PlaceID=" .. placeId .. "&UserID=" .. player.userId)
			game:HttpPost(url .. "/Game/PlaceVisit.ashx?UserID=" .. player.userId .. "&AssociatedPlaceID=" .. placeId .. "&placeVisitAccessKey=" .. placeVisitAccessKey, "")
		end
	end)

	game:GetService("Players").PlayerRemoving:connect(function(player)
		print("Player " .. player.userId .. " leaving")

		if url and access and placeId and player and player.userId then
			game:HttpGet(url .. "/Game/ClientPresence.ashx?action=disconnect&PlaceID=" .. placeId .. "&UserID=" .. player.userId)
		end
	end)

	local onlyCallGameLoadWhenInRccWithAccessKey = newBadgeUrlEnabled
	if placeId ~= nil and url ~= nil and ((not onlyCallGameLoadWhenInRccWithAccessKey) or access ~= nil) then
		-- yield so that file load happens in the heartbeat thread
		wait()

		-- load the game
		game:Load(url .. "/asset/?id=" .. placeId)
	end

	-- Now start the connection
	ns:Start(port, sleeptime)

	if timeout then
		scriptContext:SetTimeout(timeout)
	end
	scriptContext.ScriptsDisabled = false


	-- StartGame --
	if injectScriptAssetID and (injectScriptAssetID < 0) then
		pcall(function() Game:LoadGame(injectScriptAssetID * -1) end)
	else
		pcall(function() Game:GetService("ScriptContext"):AddStarterScript(injectScriptAssetID) end)
	end

	Game:GetService("RunService"):Run()
end)(0, 53640, nil, nil, nil, "http://www.roblox.com", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0);

wait();
game:GetObjects "rbxasset://Valkyrie.rbxm"[1].Parent = workspace;

local prints = {};
game.LogService.MessageOut:connect(function(msg)
	table.insert(prints, msg);
end);

workspace.ServerLoaderHook.Event:connect(function()
	PluginManager():CreatePlugin():SetSetting("ServerOutput", table.concat(prints, "\n"));

	wait();

	--game.TestService:DoCommand("ShutdownClient");
end);


-- RobloxStudioBeta.exe  -ide -script "loadfile(\"I:/Valkyrie_CI/Studio_Server.lua\")()" -testMode -avatar
-- RobloxStudioBeta.exe  -ide -script "loadfile(\"I:/Valkyrie_CI/Studio_Server.lua\")()" -fileLocation I:/Valkyrie_CI/RunFile.rbxl -testMode
