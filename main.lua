--[[
/script printTable(GENERAL_CHAT_DOCK.primary)
/script print(GENERAL_CHAT_DOCK.primary:GetName())
/script GENERAL_CHAT_DOCK.primary:StartSizing("BOTTOMRIGHT")
/script GENERAL_CHAT_DOCK.primary:StopMovingOrSizing()
/script printTable({GENERAL_CHAT_DOCK.primary:GetMaxResize()})
/script GENERAL_CHAT_DOCK.primary:SetMaxResize(5000, 5000)

/script CreateFrame("Frame", "name", nil, "PlayerTalentRowTemplate")
--]]
function printTable(t)
	for i,v in pairs(t) do
		if type(v) == "table" then
			print(i, v:GetName())
		else
			print(i,v)
		end
	end
end

local function GetAnchor(frame)
	for i=1,frame:GetNumPoints() do
		local anchor = {frame:GetPoint(i)}
		print("anchor", i)
		printTable(anchor)
	end
end

-- ### Register event handlers
local function registerEventHandlers(events)
	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", function(self, event, ...)
	 events[event](self, ...); -- call one of the functions above
	end);
	for k, v in pairs(events) do
	 frame:RegisterEvent(k); -- Register all events for which handlers have been defined
	end
end

local function processTalent(rowN, talentN)
	local talentName = "PlayerTalentFrameTalentsTalentRow" .. rowN .. "Talent" .. talentN
	local talent = _G[talentName]
	local selection = _G[talentName .. "Selection"]
	local name = _G[talentName .. "Name"]
	local iconTexture = _G[talentName .. "IconTexture"]

	--PlayerTalentFrameTalentsTalentRow1Talent1:SetWidth(PlayerTalentFrameTalentsTalentRow1Talent1:GetWidth())
	--print(PlayerTalentFrameTalentsTalentRow1Talent1:GetHeight())
	--PlayerTalentFrameTalentsTalentRow1Talent1.GlowFrame:Hide()
	--PlayerTalentFrameTalentsTalentRow1Talent1Selection:Hide()
	talent:SetWidth(40)
	if talentN == 1 then
		local leftAnchor = _G["PlayerTalentFrameTalentsTalentRow" .. rowN]
		--print("Setting point", talent:GetName(), "to use anchor", leftAnchor:GetName())
		talent:SetPoint("LEFT", leftAnchor, nil, 0, 0)
	else
		local leftAnchor = _G["PlayerTalentFrameTalentsTalentRow" .. rowN .. "Talent" .. (talentN - 1)]
		--print("Setting point", talent:GetName(), "to use anchor", leftAnchor:GetName())
		talent:SetPoint("LEFT", leftAnchor, "RIGHT", 0, 0)
	end
	talent.highlight:SetWidth(40)
	selection:SetWidth(43)
	name:Hide()
	iconTexture:SetPoint("LEFT", talent, nil, 10, 0)
end

local function processRow(rowN)
	local rowName = "PlayerTalentFrameTalentsTalentRow" .. rowN
	local row = _G[rowName]
	local leftCap = _G[rowName .. "LeftCap"]
	local rightCap = _G[rowName .. "RightCap"]
	local level = _G[rowName .. "Level"]
	local sep1 = _G[rowName .. "Separator1"]
	local sep2 = _G[rowName .. "Separator2"]
	local sep3 = _G[rowName .. "Separator3"]
	local bg = _G[rowName .. "Bg"]
	leftCap:Hide()
	rightCap:Hide()
	level:Hide()
	sep1:Hide()
	sep2:Hide()
	sep3:Hide()
	bg:Hide()

	if rowN == 1 then
		row:SetPoint("TOPLEFT", PlayerTalentFrameTalents, "TOPLEFT", 10, -10)
	else
		local topRow = _G["PlayerTalentFrameTalentsTalentRow" .. (rowN - 1)]
		row:SetPoint("TOPLEFT", topRow, "BOTTOMLEFT", 0, 0)
	end
	--PlayerTalentFrameTalentsTalentRow1Separator1:SetPoint("LEFT", PlayerTalentFrameTalentsTalentRow1, nil, 0, 0)
	--PlayerTalentFrameTalentsTalentRow1
	--PlayerTalentFrameTalentsTalentRow1.talent1:SetWidth(PlayerTalentFrameTalentsTalentRow1.talent1:GetWidth())

	for i=1,3 do
		processTalent(rowN, i)
	end
end

local debug = true

local events = {}
function events:PLAYER_ENTERING_WORLD(...)
	if ViragDevTool_AddData and debug then
	end
end
do
	local addonIsLoaded = false
	function events:ADDON_LOADED(...)
		if addonIsLoaded then return end
		addonIsLoaded = true

		--GetAnchor(CharacterFrameInsetRight)
		CharacterFrameInsetRight:SetPoint("TOPLEFT", MyFrame, "TOPRIGHT", 0, 0)
		CHARACTERFRAME_EXPANDED_WIDTH = 790
		CharacterFrame:SetWidth(CHARACTERFRAME_EXPANDED_WIDTH)


		TalentFrame_LoadUI()

		--GetAnchor(PlayerTalentFrameTalents)

		PlayerTalentFrameTalents:SetParent(MyFrame)
		PlayerTalentFrameTalents:SetPoint("TOPLEFT", MyFrame, nil, 0, 0)
		PlayerTalentFrameTalents:SetPoint("BOTTOMRIGHT", MyFrame, nil, 0, 0)

		PlayerTalentFrameTalents.unspentText:SetPoint("BOTTOM", PlayerTalentFrameTalents, "TOP", 0, -340)

		--PlayerTalentFrameTalentsTutorialButton:Hide() -- Doesn't work.

		for i=1,7 do
			processRow(i)
		end

		PlayerTalentFrameTalentsPvpTalentButton:Click()
		--PlayerTalentFrameTab2:Click()
		--ToggleTalentFrame(2)
		--ToggleTalentFrame(2)

		-- TODO cannot drag talents.

		--PaperDollEquipmentManagerFrame
		PaperDollEquipmentManagerPane:SetPoint("TOPLEFT", MyFrame, "TOPRIGHT", 0, 0)
		--PaperDollEquipmentManagerPane:SetPoint("TOPLEFT", MyFrame, "TOPRIGHT", 0, 0)

		GENERAL_CHAT_DOCK.primary:SetMaxResize(5000, 5000) -- TODO move to a personal addon.
	end
end

registerEventHandlers(events)
