
-- TODO consider putting the talent frame in directly, instead of putting it into MyFrame.
-- TODO is it better to move the existing talent frames, or create new ones?

-- TODO reparent so that playertalentframetalents isn't used.

local debug = false

local function printTable(t)
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

local combatDeferQueue = {}
local function combatDefer(f)
	if InCombatLockdown() then
		combatDeferQueue[#combatDeferQueue] = f
	else
		f()
	end
end

-- ### addon-specific utility

local function isTalentOnCd(row, col)
	local onCd, remainingCd = false, 0

	local _,name,_,selected,_,spellID,_,_,_,_,_ = GetTalentInfo(row, col, GetActiveSpecGroup())
	if spellID ~= nil and selected then -- spellID ~= nil indicates that the talent adds a spell to the spellbook.
		local startTime,duration,_ = GetSpellCooldown(spellID);
		onCd = duration ~= 0
		if onCd then
			remainingCd = duration - (GetTime() - startTime)
		end
	end
	return onCd, remainingCd
end

-- ### Talent interface move, resize, and modify.

local function processTalent(rowN, talentN)
	local talentName = "PlayerTalentFrameTalentsTalentRow" .. rowN .. "Talent" .. talentN
	local talent = _G[talentName]
	local selection = _G[talentName .. "Selection"]
	local name = _G[talentName .. "Name"]
	local iconTexture = _G[talentName .. "IconTexture"]

	talent:SetWidth(40)

	for i=1,4 do
		local bla = talent:CreateTexture(nil, "ARTWORK", "MySelectedTalentBorder"..i)
		talent["MyBorder"..i] = bla
	end

	talent.Cover:SetAlpha(0.65)

	talent:CreateFontString(nil, "ARTWORK", "TalentCooldownString")
	talent.Text:SetTextColor(1, 0, 0, 1)
	TomeButton:HookScript("OnUpdate", function()
		local onCd, remainingCd = isTalentOnCd(rowN, talentN) 
		if onCd then
			talent.Text:Show()
			talent.Text:SetText(string.format("%.0f", remainingCd))
		else
			talent.Text:Hide()
		end
	end)

	-- selection:SetAlpha(1) -- For ElvUI. -- Doesn't accomplish my goals, at least not entirely.

	if talentN == 1 then
		local leftAnchor = _G["PlayerTalentFrameTalentsTalentRow" .. rowN]
		talent:SetPoint("LEFT", leftAnchor, nil, 0, 0)
	else
		local leftAnchor = _G["PlayerTalentFrameTalentsTalentRow" .. rowN .. "Talent" .. (talentN - 1)]
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

-- ### Tome button

local buffs = {"Tome of the Tranquil Mind", "Codex of the Tranquil Mind", "Feint"} -- TODO remove "Feint".
-- Priority order - item ids with lower indices will be used first.
local items = {143785, 141446}
--local items = {12692, 140192} -- Test values.

local function anyTalentOnCd()
	local longestDuration = 0
	for row=1,7 do
		for col=1,3 do
			local _,remainingCd = isTalentOnCd(row, col)
			if remainingCd > longestDuration then
				longestDuration = remainingCd
			end
		end
	end
	return longestDuration ~= 0, longestDuration
end

local function getNumTomes()
	local total = 0
	for i,v in pairs(items) do
		total = total + GetItemCount(v)
	end
	return total
end

-- NOTE: Assumes there's only one talent switching buff up at a time.
local function getTomeDurationRemaining()
	for i=1,1000 do
		local name,_,_,_,_,expirationTime,_,_,_,spellId = UnitBuff("player", i)
		if name == nil then
			return 0
		else
			for i,v in pairs(buffs) do
				if name == v then
					return expirationTime - GetTime()
				end
			end
		end
	end
end

local function tomeButtonUpdate()
	-- TODO add logic for rest area.
	TomeButton.CombatIndicator:Hide()
	TomeButton.Text:Hide()

	-- Highlight.
	if InCombatLockdown() then
		TomeButton.CombatIndicator:Show()
	end

	-- Text.
	if IsResting() then
		TomeButton.Text:SetText("Zzz")
		TomeButton.Text:SetTextColor(0, 1, 0, 1)
		TomeButton.Text:Show()
		--TomeButtonIcon:SetTexture()
	elseif anyTalentOnCd() then
		local _,duration = anyTalentOnCd()
		TomeButton.Text:SetText(string.format("%.0f", duration))
		TomeButton.Text:SetTextColor(1, 0, 0, 1)
		TomeButton.Text:Show()
	else
		local tomeDurationRemaining = getTomeDurationRemaining()
		if tomeDurationRemaining ~= 0 then
			TomeButton.Text:SetText(string.format("%.0f", tomeDurationRemaining))
			TomeButton.Text:SetTextColor(1, 1, 1, 1)
			TomeButton.Text:Show()
		end
	end
	
	TomeButton.TomeCountText:SetText(getNumTomes())
end

local function canChangeTalents()
	return not InCombatLockdown() and (IsResting() or getTomeDurationRemaining() > 0)
end

local function tomeButtonItemUpdate()
	for i,v in pairs(items) do
		local count = GetItemCount(v)
		if count > 0 then
			combatDefer(function() TomeButton:SetAttribute("macrotext", "/use item:"..v) end)
			return
		end
	end
end

local function tomeButtonActiveUpdate()
	-- No need to defer execution; once combat is left this function will be called again.
	if InCombatLockdown() then
		if debug then print("Could not (de)activate tome button, am in combat") end
		return
	end

	if canChangeTalents() then
		if debug then print("deactivating tome button") end
		TomeButton:SetAttribute("type", nil)
	else
		if debug then print("activating tome button") end
		TomeButton:SetAttribute("type", "macro")
	end
end

--[[
CombatHide and CombatShow are used to remove the tome button from the character panel at all possible times. The reason for this is that the tome button is an action button and is therefore protected from being moved/hidden whatever in combat. This causes an odd interaction with DejaCharacterStats which prevents the DejaCharacterStatus panel from showing up when you open the character panel in combat. Both changing the button's parent, and anchor, are necessary.
--]]
function TomeButton:CombatHide()
	self:SetParent(UIParent)
	self:ClearAllPoints()
	self:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT")
	self:Hide()
end

function TomeButton:CombatShow()
	TomeButton:SetParent(GeheurTalentFrame)
	self:ClearAllPoints()
	TomeButton:SetPoint("BOTTOMLEFT")
	TomeButton:Show()
end

local function initTomeButton()
	TomeButtonIcon:SetTexture(GetItemIcon(143785))

	tomeButtonItemUpdate()
	tomeButtonActiveUpdate()

	TomeButton:SetScript("OnUpdate", tomeButtonUpdate)
	TomeButton:SetScript("OnShow", tomeButtonActiveUpdate)

	--CharacterFrame:HookScript("OnShow", function()
		--if not InCombatLockdown() then
			--TomeButton:CombatShow();
		--end
	--end)
	TomeButton:CombatHide()
end

local function updateSpecButtons()
	local spec = GetSpecialization()
	for i=1,GetNumSpecializations() do
		_G["SpecChange"..i]:GetNormalTexture():SetDesaturated(i ~= spec)
	end
	if select(2, UnitClass("player")) == "HUNTER" then
		local petSpec = GetSpecialization(false, true)
		for i=1,GetNumSpecializations(false, true) do
			_G["PetSpecChange"..i]:GetNormalTexture():SetDesaturated(i ~= petSpec)
		end
	end
end

local function AddPetSpecButtons()
	local previousFrame = nil
	local PET = true
	for i=1,GetNumSpecializations(false, PET) do
		local frame = CreateFrame("BUTTON", "PetSpecChange"..i, SpecButtonsBar, "MyPetSpecButton")
		local _,_,_,icon = GetSpecializationInfo(i, false, PET, nil, sex);
		frame:SetNormalTexture(icon)
		if i == 1 then
			frame:SetPoint("TOPLEFT", SpecChange1, "BOTTOMLEFT")
		else
			frame:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT")
		end
		previousFrame = frame
		frame:SetScript("OnClick", function() if GetSpecialization(false, PET) ~= i then SetSpecialization(i, true) end end)
	end
end

local function AddSpecButtons()
	SpecButtonsBar:SetParent(PlayerTalentFrameTalents)
	local previousFrame = nil
	for i=1,GetNumSpecializations() do
		local frame = CreateFrame("BUTTON", "SpecChange"..i, SpecButtonsBar, "MySpecButton")
		local _,_,_,icon = GetSpecializationInfo(i, false, false, nil, sex);
		frame:SetNormalTexture(icon)
		if i == 1 then
			frame:SetPoint("TOPLEFT", PlayerTalentFrameTalents, "BOTTOMLEFT", 3, 0)
		else
			frame:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT")
		end
		previousFrame = frame
		frame:SetScript("OnClick", function() if GetSpecialization() ~= i then SetSpecialization(i) end end)
	end
	if select(2, UnitClass("player")) == "HUNTER" then
		AddPetSpecButtons()
	end
	updateSpecButtons()
end

local CharacterPanelOnShow do
	local characterPanelSetUp = false
	function CharacterPanelOnShow()
		if not characterPanelSetUp then
			-- TODO apparently this does nothing at the moment, lol. Maybe I should move SetupCharacterPanel here?
			characterPanelSetUp = true
		end
		PlayerTalentFrameTalents:Show()
		PaperDollEquipmentManagerPane:Show()
		if not InCombatLockdown() then
			TomeButton:CombatShow()
		end
	end
end
function CharacterPanelOnHide()
	if not InCombatLockdown() then
		TomeButton:CombatHide()
	end
end

local function SetupCharacterPanel()
	CharacterFrame:HookScript("OnShow", function()
		CharacterPanelOnShow()
	end)
	CharacterFrame:HookScript("OnHide", function()
		CharacterPanelOnHide()
	end)

--[[
PaperDollItemsFrame:SetScript("OnDragStart", function(self)
	self:SetMovable(true)
	self:StartMoving()
end)
PaperDollItemsFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	self:SetMovable(false)

	if VWQL then
		VWQL.AnchorQCBLeft = self:GetLeft()
		VWQL.AnchorQCBTop = self:GetTop() 
	end
end)
--]]

	PlayerTalentFrameTalentsTutorialButton:HookScript("OnShow", function(self) self:Hide() end)

	PlayerTalentFrameTalents:SetParent(GeheurTalentFrame)
	PlayerTalentFrameTalents:SetPoint("TOPLEFT", GeheurTalentFrame, nil, 0, 0)
	PlayerTalentFrameTalents:SetPoint("BOTTOMRIGHT", GeheurTalentFrame, nil, 0, 0)

	PlayerTalentFrameTalents:DisableDrawLayer("BORDER")

	PlayerTalentFrameTalents.unspentText:SetPoint("BOTTOM", PlayerTalentFrameTalents, "TOP", 0, -340)

	--PlayerTalentFrameTalentsTutorialButton:Hide() -- Doesn't work.

	for i=1,7 do
		processRow(i)
	end

	PlayerTalentFrameTalentsPvpTalentButton:Click()
	PlayerTalentFrameTalentsPvpTalentButton:Click()
	PlayerTalentFrameTalentsPvpTalentButton:SetPoint("RIGHT")
	PlayerTalentFrameTalentsPvpTalentButton:SetPoint("BOTTOMRIGHT", PlayerTalentFrameTalents, "TOPRIGHT", -10, -10)

	PlayerTalentFrameTalentsPvpTalentFrame:SetPoint("TOPRIGHT", PlayerTalentFrameTalents)
	PlayerTalentFrameTalentsPvpTalentFrame:SetPoint("BOTTOMRIGHT", PlayerTalentFrameTalents)
	PlayerTalentFrameTalentsPvpTalentFrame:SetPoint("LEFT", PlayerTalentFrameTalents, "RIGHT", -80, 0)
	--PlayerTalentFrameTalentsPvpTalentFrameTalentList:SetPoint("BOTTOMLEFT", PaperDollEquipmentManagerPaneScrollBarScrollDownButton, "BOTTOMRIGHT", 0, 0)
	PlayerTalentFrameTalentsPvpTalentFrameTalentList:SetPoint("BOTTOMLEFT", GeheurTalentFrame, "BOTTOMRIGHT", 0, 0)
	PlayerTalentFrameTalentsPvpTalentFrameTalentList:SetPoint("TOPLEFT", GeheurTalentFrame, "TOPRIGHT", 0, 0)
	PlayerTalentFrameTalentsPvpTalentFrameTalentList:HookScript("OnShow", function() PaperDollEquipmentManagerPane:Hide() end)
	PlayerTalentFrameTalentsPvpTalentFrameTalentList:HookScript("OnHide", function() PaperDollEquipmentManagerPane:Show() end)

	PlayerTalentFrameTalentsPvpTalentFrame:DisableDrawLayer("BACKGROUND")
	PlayerTalentFrameTalentsPvpTalentFrame:DisableDrawLayer("OVERLAY")

	AddSpecButtons()

	PaperDollEquipmentManagerPane:ClearAllPoints()
	PaperDollEquipmentManagerPane:SetPoint("BOTTOMLEFT", PlayerTalentFrameTalents, "BOTTOMRIGHT")
	PaperDollEquipmentManagerPane:SetPoint("TOP", CharacterFrame, "TOP")
	PaperDollSidebarTab3:SetScript("OnClick", function() end)
	PaperDollSidebarTab3:Hide()

end

--- ### events
local function registerEventHandlers(events)
	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", function(self, event, ...)
	 events[event](self, ...); -- call one of the functions above
	end);
	for k, v in pairs(events) do
	 frame:RegisterEvent(k); -- Register all events for which handlers have been defined
	end
end

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

	initTomeButton()
	SetupCharacterPanel()

	PlayerTalentFrameTalents.talentGroup = PlayerTalentFrame.talentGroup
	TalentFrame_Update(PlayerTalentFrameTalents, "player")
end

do
local addonIsLoaded = false
function events:ADDON_LOADED(...)
	if addonIsLoaded then return end
	addonIsLoaded = true

	hooksecurefunc("TalentFrame_Update", function()
		for i=1,MAX_TALENT_TIERS do
			for j=1,NUM_TALENT_COLUMNS do
				local talentButton = _G["PlayerTalentFrameTalentsTalentRow"..i.."Talent"..j]
				local talentButtonIconTexture = _G["PlayerTalentFrameTalentsTalentRow"..i.."Talent"..j.."IconTexture"]
				if talentButton.knownSelection and talentButton.MyBorder1 then
					if talentButton.knownSelection:IsShown() then
						talentButton.MyBorder1:Show()
						talentButton.MyBorder2:Show()
						talentButton.MyBorder3:Show()
						talentButton.MyBorder4:Show()
						talentButton.Cover:Hide()
					else
						talentButton.MyBorder1:Hide()
						talentButton.MyBorder2:Hide()
						talentButton.MyBorder3:Hide()
						talentButton.MyBorder4:Hide()
						talentButton.Cover:Show()
						talentButtonIconTexture:SetDesaturated(false)
					end
				end
			end
		end
	end)

	hooksecurefunc("PaperDollFrame_SetSidebar", function()
		PaperDollEquipmentManagerPane:Show()
	end)


end
end

-- Bypasses the need for talent page to be selected in the talents window.
local function My_PlayerTalentFrame_Refresh()
	ButtonFrameTemplate_ShowAttic(PlayerTalentFrame);
	PlayerTalentFrame_HideSpecsTab();
	PlayerTalentFrameTalents.talentGroup = PlayerTalentFrame.talentGroup;
	TalentFrame_Update(PlayerTalentFrameTalents, "player");
	PlayerTalentFrame_ShowTalentTab();
	PlayerTalentFrame_HidePetSpecTab();
	PlayerTalentFrameTalentsPvpTalentButton:Update();

	updateSpecButtons()

	if CharacterFrame:IsShown() then PlayerTalentFrameTalents:Show() end
end

function events:UNIT_PET(...)
	if (...) == "player" then
		updateSpecButtons()
	end
end
function events:PLAYER_SPECIALIZATION_CHANGED(...)
	if (...) == "player" then
		ToggleTalentFrame(2)
		ToggleTalentFrame(2)
		My_PlayerTalentFrame_Refresh()
	end

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
function events:BAG_UPDATE(...)
	tomeButtonItemUpdate()
end
function events:PLAYER_REGEN_DISABLED(...)
	if CharacterFrame:IsVisible() then TomeButton:CombatHide() end
end
function events:PLAYER_REGEN_ENABLED(...)
	for _,f in pairs(combatDeferQueue) do
		f()
	end

	tomeButtonActiveUpdate()
	tomeButtonUpdate()

	if CharacterFrame:IsVisible() then TomeButton:CombatShow() end
end
function events:PLAYER_UPDATE_RESTING(...)
	tomeButtonActiveUpdate()
	tomeButtonUpdate()
end
function events:UNIT_AURA(unit)
	if not TomeButton:IsVisible() then return end
	tomeButtonActiveUpdate()
	tomeButtonUpdate()
end
--[[
function events:PLAYER_REGEN_DISABLED()
	TomeButton:Hide()
	TomeButton:SetParent(UIParent)
end
function events:PLAYER_REGEN_ENABLED()
	TomeButton:Show()
	TomeButton:SetParent(GeheurTalentFrame)
end
--]]

registerEventHandlers(events)
