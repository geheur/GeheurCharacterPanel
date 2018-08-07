--[[
/script printTable(GENERAL_CHAT_DOCK.primary)
/script print(GENERAL_CHAT_DOCK.primary:GetName())
/script GENERAL_CHAT_DOCK.primary:StartSizing("BOTTOMRIGHT")
/script GENERAL_CHAT_DOCK.primary:StopMovingOrSizing()
/script printTable({GENERAL_CHAT_DOCK.primary:GetMaxResize()})
/script GENERAL_CHAT_DOCK.primary:SetMaxResize(5000, 5000)

/script CreateFrame("Frame", "name", nil, "PlayerTalentRowTemplate")
--]]

-- TODO consider putting the talent frame in directly, instead of putting it into MyFrame.
-- TODO is it better to move the existing talent frames, or create new ones?

function printTable(t)
	for i,v in pairs(t) do
		if type(v) == "table" then
			print(i, v:GetName())
		else
			print(i,v)
		end
	end
end

local function PrintAnchor(frame)
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
	--bg:Hide()

	local width = 120
	row:SetWidth(width)
	row.TopLine:SetWidth(width)
	row.BottomLine:SetWidth(width)
	-- /script PlayerTalentFrameTalentsTalentRow1:SetWidth(150)

	--row.TopLine:SetSize(0,0)
	--row.BottomLine:SetSize(0,0)

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

	--[[
	if (UnitLevel("player") >= SHOW_SPEC_LEVEL) then
		return;
	end
	--]]

	TalentFrame_LoadUI();
	--[[
	if ( PlayerTalentFrame_Toggle ) then
		PlayerTalentFrame_Toggle(suggestedTab);
	end
	]]--

	local _, name, description, icon = GetSpecializationInfo(1, false, self.isPet, nil, sex);
	MyButton1:SetNormalTexture(icon) -- TODO needs to be moved to enter world event.
	_, name, description, icon = GetSpecializationInfo(2, false, self.isPet, nil, sex);
	MyButton2:SetNormalTexture(icon) -- TODO needs to be moved to enter world event.
	_, name, description, icon = GetSpecializationInfo(3, false, self.isPet, nil, sex);
	MyButton3:SetNormalTexture(icon) -- TODO needs to be moved to enter world event.
	_, name, description, icon = GetSpecializationInfo(4, false, self.isPet, nil, sex);
	MyButton4:SetNormalTexture(icon) -- TODO needs to be moved to enter world event.

end
do
	local addonIsLoaded = false
	function events:ADDON_LOADED(...)
		if addonIsLoaded then return end
		addonIsLoaded = true

		--PrintAnchor(CharacterFrameInsetRight)
		CharacterFrameInsetRight:SetPoint("TOPLEFT", MyFrame, "TOPRIGHT", 0, 0)
		CHARACTERFRAME_EXPANDED_WIDTH = 790
		CharacterFrame:SetWidth(CHARACTERFRAME_EXPANDED_WIDTH)


		TalentFrame_LoadUI()

		--PrintAnchor(PlayerTalentFrameTalents)

		PlayerTalentFrameTalents:SetParent(MyFrame)
		PlayerTalentFrameTalents:SetPoint("TOPLEFT", MyFrame, nil, 0, 0)
		PlayerTalentFrameTalents:SetPoint("BOTTOMRIGHT", MyFrame, nil, 0, 0)

		PlayerTalentFrameTalents:DisableDrawLayer("BORDER")

		PlayerTalentFrameTalents.unspentText:SetPoint("BOTTOM", PlayerTalentFrameTalents, "TOP", 0, -340)

		--PlayerTalentFrameTalentsTutorialButton:Hide() -- Doesn't work.

		for i=1,7 do
			processRow(i)
		end

		PlayerTalentFrameTalentsPvpTalentButton:Click()
		PlayerTalentFrameTalentsPvpTalentButton:SetPoint("RIGHT")
		PlayerTalentFrameTalentsPvpTalentButton:SetPoint("BOTTOMRIGHT", PlayerTalentFrameTalents, "TOPRIGHT", -10, -10)

		PlayerTalentFrameTalentsPvpTalentFrame:SetPoint("TOPRIGHT", PlayerTalentFrameTalents)
		PlayerTalentFrameTalentsPvpTalentFrame:SetPoint("BOTTOMRIGHT", PlayerTalentFrameTalents)

		--PlayerTalentFrameTalentsPvpTalentFrame:DisableDrawLayer("ARTWORK")
		PlayerTalentFrameTalentsPvpTalentFrame:DisableDrawLayer("BACKGROUND")
		PlayerTalentFrameTalentsPvpTalentFrame:DisableDrawLayer("OVERLAY")
		--PlayerTalentFrameTalentsPvpTalentFrame:DisableDrawLayer("BORDER")

		-- TODO currently not using MySpecButtonsBar to position buttons, I should figure out why that didn't work.
		MySpecButtonsBar:SetPoint("TOPLEFT", PlayerTalentFrameTalents, "BOTTOMLEFT", 3, 0)
		MySpecButtonsBar:SetParent(PlayerTalentFrameTalents)
		MyButton1:SetPoint("TOPLEFT", PlayerTalentFrameTalents, "BOTTOMLEFT", 3, 0)
		MyButton1:SetPoint("BOTTOMLEFT")
		if not (select(2, UnitClass("player")) == "DRUID") then
			MyButton4:Hide()
		end

		--[[
		print("Regions:")
		printTable(PlayerTalentFrameTalentsPvpTalentFrame:GetRegions())
		for _,v in pairs(PlayerTalentFrameTalentsPvpTalentFrame:GetRegions()) do
			print(v)
			if v:GetNumPoints() == 1 then
				local anchor = {frame:GetPoint(1)}
				if anchor[1] == "TOPRIGHT" and anchor[4] == 0 and anchor[5] == 0 then
					v:Hide()
				end
			end
		end
		--]]

		PrintAnchor(PlayerTalentFrameTalentsPvpTalentFrame)
		--PlayerTalentFrameTab2:Click()

		PlayerTalentFrameTalents.talentGroup = PlayerTalentFrame.talentGroup
		TalentFrame_Update(PlayerTalentFrameTalents, "player")

		--PaperDollEquipmentManagerFrame
		PaperDollEquipmentManagerPane:SetPoint("TOPLEFT", MyFrame, "TOPRIGHT", 0, 0)
		--PaperDollEquipmentManagerPane:SetPoint("TOPLEFT", MyFrame, "TOPRIGHT", 0, 0)

		GENERAL_CHAT_DOCK.primary:SetMaxResize(5000, 5000) -- TODO move to a personal addon.
	end
end
function events:PLAYER_SPECIALIZATION_CHANGED(...)
	TalentFrame_LoadUI()
	PlayerTalentFrame_Refresh()
	ToggleTalentFrame(2)
	ToggleTalentFrame(2)

	--[[ Doesn't work
	for i=1,4 do
		local spec = GetSpecialization()
		if spec == i then
			_G["MyButton" .. i]:EnableDrawLayer("BORDER")
		else
			_G["MyButton" .. i]:DisableDrawLayer("BORDER")
		end
	end
	--]]

	--local _, name, description, icon = GetSpecializationInfo(1, false, self.isPet, nil, sex);
	--MyButton1:SetNormalTexture(icon)
end

registerEventHandlers(events)
