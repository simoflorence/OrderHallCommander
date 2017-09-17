local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file, must be 1
--@debug@
print('Loaded',__FILE__)
--@end-debug@
local function pp(...) print(GetTime(),"|cff009900",__FILE__:sub(-15),strjoin(",",tostringall(...)),"|r") end
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Auto Generated
local me,ns=...
if ns.die then return end
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Missionlist',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetMissionlistModule() return module end
-- Template
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=addon:Wrap("NewTable")
local del=addon:Wrap("DelTable")
local kpairs=addon:Wrap("Kpairs")
local empty=addon:Wrap("Empty")

local todefault=addon:Wrap("todefault")

local tonumber=tonumber
local type=type
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
local OHFCompleteDialog=OrderHallMissionFrameMissions.CompleteDialog
local OHFMissionScroll=OrderHallMissionFrameMissionsListScrollFrame
local OHFMissionScrollChild=OrderHallMissionFrameMissionsListScrollFrameScrollChild
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local garrisonType=LE_GARRISON_TYPE_7_0
local FAKE_FOLLOWERID="0x0000000000000000"
local MAX_LEVEL=110

local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT

local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")

if LibDebug then LibDebug() dprint=print end
local safeG=addon.safeG

--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
local LE_FOLLOWER_TYPE_GARRISON_7_0=LE_FOLLOWER_TYPE_GARRISON_7_0
local LE_GARRISON_TYPE_7_0=LE_GARRISON_TYPE_7_0
local GARRISON_FOLLOWER_COMBAT_ALLY=GARRISON_FOLLOWER_COMBAT_ALLY
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE
local ViragDevTool_AddData=_G.ViragDevTool_AddData
if not ViragDevTool_AddData then ViragDevTool_AddData=function() end end
local KEY_BUTTON1 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283\124t" -- left mouse button
local KEY_BUTTON2 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385\124t" -- right mouse button
local CTRL_KEY_TEXT,SHIFT_KEY_TEXT=CTRL_KEY_TEXT,SHIFT_KEY_TEXT


-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN
local UNCAPPED_PERC=PERCENTAGE_STRING
local CAPPED_PERC=PERCENTAGE_STRING .. "**"
local Dialog = LibStub("LibDialog-1.0")
local missionNonFilled=true
local wipe=wipe
local GetTime=GetTime
local ENCOUNTER_JOURNAL_SECTION_FLAG4=ENCOUNTER_JOURNAL_SECTION_FLAG4
local RESURRECT=RESURRECT
local LOOT=LOOT
local IGNORED=IGNORED
local UNUSED=UNUSED
local GARRISON_FOLLOWER_COMBAT_ALLY=GARRISON_FOLLOWER_COMBAT_ALLY
local nobonusloot=G.GetFollowerAbilityDescription(471)
local increasedcost=G.GetFollowerAbilityDescription(472)
local increasedduration=G.GetFollowerAbilityDescription(428)
local killtroops=G.GetFollowerAbilityDescription(437)
local killtroopsnodie=killtroops:gsub('%.',' ') ..  L['but using troops with just one durability left']
local GARRISON_MISSION_AVAILABILITY2=GARRISON_MISSION_AVAILABILITY .. " %s"
local GARRISON_MISSION_ID="MissionID: %d"
local weak={__mode="v"}
local missionstats=setmetatable({},weak)
local missionmembers=setmetatable({},weak)
local missionthreats=setmetatable({},weak)
local spinners=setmetatable({},weak)
local missionIDS=setmetatable({},weak)
local missionKEYS=setmetatable({},weak)
local function nop() return 0 end
local Current_Sorter
local sortKeys={}
local MAX=math.huge
local OHFButtons=OHFMissions.listScroll.buttons
local clean
local displayClean
local function GetPerc(mission,realvalue)
	local p=addon:GetSelectedParty(mission.missionID,missionKEYS[mission.missionID])
	local perc=-p.perc or 0
	if realvalue then
		return perc
	else
		return addon:GetBoolean("IGNORELOW") and perc or 1
	end
end
local function IsLow(mission)
	return
		(addon:GetBoolean("ELITEMODE") and not mission.elite) or
		(GetPerc(mission) == 0) or
		(addon:IsBlacklisted(mission.missionID))
end
local function IsIgnored(mission)
	--return addon:GetBoolean("ELITEMODE") and mission.class=="0"
	return addon:GetBoolean("ELITEMODE") and not addon:GetMissionData(mission.missionID,'elite')
end
local sorters={
		Garrison_SortMissions_Original=nop,
		Garrison_SortMissions_Chance=function(mission)
			return GetPerc(mission,true)
		end,
		Garrison_SortMissions_Level=function(mission)
			if IsLow(mission) then return MAX end
			return -mission.level * 1000 - (mission.iLevel or 0)
		end,
		Garrison_SortMissions_Age=function(mission)
			if IsLow(mission) then return MAX end
			return mission.offerEndTime
		end,
		Garrison_SortMissions_Xp=function(mission)
			if IsLow(mission) then return MAX end
			local p=addon:GetSelectedParty(mission.missionID,missionKEYS[mission.missionID])
			return -p.totalXP or 0
		end,
		Garrison_SortMissions_HourlyXp=function(mission)
			if IsLow(mission) then return MAX end
			local p=addon:GetSelectedParty(mission.missionID,missionKEYS[mission.missionID])
			return (-p.totalXP or 0) * 60 /  (p.timeseconds or  mission.durationSeconds or 36000)
		end,
		Garrison_SortMissions_Duration=function(mission)
			if IsLow(mission) then return MAX end
			local p=addon:GetSelectedParty(mission.missionID,missionKEYS[mission.missionID])
			return p.timeseconds or  mission.durationSeconds or 0
		end,
		Garrison_SortMissions_Class=function(mission)
			if IsLow(mission) then return MAX end
			local factor=100000
			return tonumber(format("%7d.%07d",todefault(mission.classOrder,factor), factor - math.min(factor,todefault(mission.classValue,0))))
		end,
}
local function InProgress(mission,frame)
	return (mission and mission.inProgress) or OHFMissions.showInProgress or (frame and frame.IsCustom)
end
function module:OnInitialized()
-- Dunno why but every attempt of changing sort starts a memory leak
	local sorters={
		Garrison_SortMissions_Original=L["Original method"],
		Garrison_SortMissions_Chance=L["Success Chance"],
		Garrison_SortMissions_Level=L["Level"],
		Garrison_SortMissions_Age=L["Expiration Time"],
		Garrison_SortMissions_Xp=L["Global approx. xp reward"],
		Garrison_SortMissions_HourlyXp=L["Global approx. xp reward per hour"],
		Garrison_SortMissions_Duration=L["Duration Time"],
		Garrison_SortMissions_Class=L["Reward type"],
	}
	
--@debug@
	addon:AddBoolean("ELITEMODE",false,L["Elites mission mode"],L["Only consider elite missions"])
--@end-debug@	
	addon:AddSelect("SORTMISSION","Garrison_SortMissions_Original",sorters,	L["Sort missions by:"],L["Changes the sort order of missions in Mission panel"])
	addon:AddBoolean("IGNORELOW",false,L["Empty missions sorted as last"],L["Empty or 0% success mission are sorted as last. Does not apply to \"original\" method"])
	addon:AddBoolean("NOWARN",false,L["Remove no champions warning"],L["Disables warning: "] .. GARRISON_PARTY_NOT_ENOUGH_CHAMPIONS)
	addon:RegisterForMenu("mission",
--@debug@
		"ELITEMODE",
--@end-debug@	
		"SORTMISSION",
		"IGNORELOW",
		"NOWARN")
	self:LoadButtons()
	Current_Sorter=addon:GetString("SORTMISSION")
	self:SecureHookScript(OHF--[[MissionTab--]],"OnShow","InitialSetup")
	--@debug@
	--@end-debug@
	--hooksecurefunc("Garrison_SortMissions",Garrison_SortMissions_PostHook)--function(missions) module:SortMissions(missions) end)
	--self:SecureHook("Garrison_SortMissions",function(missionlist) print("Sorting",#missionlist,"missions") end)
	--function(missions) module:SortMissions(missions) end)
	--self:SecureHookScript(OrderHallMissionFrameMissionsTab1,"OnClick","CheckShadow")
	--self:SecureHookScript(OrderHallMissionFrameMissionsTab2,"OnClick","CheckShadow")
	--self:SecureHook("GarrisonMissionController_OnClickTab","CheckShadow")
	--self:SecureHook("GarrisonMissionListTab_OnClick","CheckShadow")

		Dialog:Register("OHCUrlCopy", {
			text = L["URL Copy"],
			width = 500,
			editboxes = {
				{ width = 484,
					on_escape_pressed = function(self, data) self:GetParent():Hide() end,
				},
			},
			on_show = function(self, data)
				self.editboxes[1]:SetText(data.url)
				self.editboxes[1]:HighlightText()
				self.editboxes[1]:SetFocus()
			end,
			buttons = {
				{ text = CLOSE, },
			},
			show_while_dead = true,
			hide_on_escape = true,
		})
end
function module:Print(...)
	print(...)
end
function module:Events()
	addon:RegisterEvent("GARRISON_MISSION_LIST_UPDATE")
	addon:RegisterEvent("GARRISON_MISSION_STARTED")
	addon:RegisterEvent("GARRISON_FOLLOWER_CATEGORIES_UPDATED")
	addon:RegisterEvent("GARRISON_FOLLOWER_ADDED")
	addon:RegisterEvent("GARRISON_FOLLOWER_REMOVED")
	addon:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATED")
	addon:RegisterEvent("GARRISON_LANDINGPAGE_SHIPMENTS")
	addon:RegisterEvent("GARRISON_UPDATE")
	addon:RegisterEvent("GARRISON_UPGRADEABLE_RESULT")
	addon:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
	addon:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED")
	addon:RegisterEvent("GARRISON_FOLLOWER_UPGRADED")
	addon:RegisterEvent("GARRISON_FOLLOWER_DURABILITY_CHANGED")
	addon:RegisterEvent("SHIPMENT_CRAFTER_CLOSED")
end
function module:LoadButtons(...)
	local buttonlist=OHFMissions.listScroll.buttons
	for i=1,#buttonlist do
		local b=buttonlist[i]
		self:SecureHookScript(b,"OnEnter","AdjustMissionTooltip")
		self:RawHookScript(b,"OnClick","RawMissionClick")
		b:RegisterForClicks("AnyDown")
		local scale=0.8
		local f,h,s=b.Title:GetFont()
		b.Title:SetFont(f,h*scale,s)
		local f,h,s=b.Summary:GetFont()
		b.Summary:SetFont(f,h*scale,s)
		self:SecureHookScript(b.Rewards[1],"OnMouseUp","printLink")
		self:SecureHookScript(b.Rewards[1],"OnEnter","rwWarning")
	end
end
local currentFollowerString=""
local function makedirty(self,event,missionType,missionID,...)
	if event=="GARRISON_MISSION_LIST_UPDATE" or
		event=="GARRISON_MISSION_STARTED" then
		if missionType ~= LE_FOLLOWER_TYPE_GARRISON_7_0 then return end
	end
	if event=="GARRISON_FOLLOWER_CATEGORIES_UPDATED"
		or event=="GARRISON_FOLLOWER_ADDED"
		or event=="GARRISON_FOLLOWER_REMOVED"
		or event=="GARRISON_FOLLOWER_LIST_UPDATED"
		or event=="GARRISON_FOLLOWER_XP_CHANGED"
		or event=="GARRISON_FOLLOWER_UPGRADED"
		or event=="GARRISON_FOLLOWER_DURABILITY_CHANGED"
	then
		clean=false
	end
	displayClean=false			
--@debug@
	print("Set Dirty state",event,clean,displayClean)
--@end-debug@
end
function addon:GARRISON_MISSION_LIST_UPDATE(...) makedirty(self,...) end
function addon:GARRISON_MISSION_STARTED(...) makedirty(self,...)  end
function addon:GARRISON_FOLLOWER_CATEGORIES_UPDATED(...) makedirty(self,...) end
function addon:GARRISON_FOLLOWER_ADDED(...) makedirty(self,...) end
function addon:GARRISON_FOLLOWER_REMOVED(...) makedirty(self,...) end
function addon:GARRISON_FOLLOWER_LIST_UPDATED(...) makedirty(self,...) end
function addon:GARRISON_LANDINGPAGE_SHIPMENTS(...) makedirty(self,...) end
function addon:GARRISON_UPDATE(...) makedirty(self,...) end
function addon:GARRISON_UPGRADEABLE_RESULT(...) makedirty(self,...) end
function addon:GARRISON_MISSION_COMPLETE_RESPONSE(...) makedirty(self,...) end
function addon:GARRISON_FOLLOWER_XP_CHANGED(...) makedirty(self,...) end
function addon:GARRISON_FOLLOWER_UPGRADED(...) makedirty(self,...) end
function addon:GARRISON_FOLLOWER_DURABILITY_CHANGED(...) makedirty(self,...) end
function addon:SHIPMENT_CRAFTER_CLOSED(...) makedirty(self,...) end
local tb={url=""}
local artinfo='*' .. L["Artifact shown value is the base value without considering knowledge multiplier"]

function module:rwWarning(this)
	if this.itemID  then
		local tip=GameTooltip
		if addon.allArtifactPower[tostring(this.itemID)] then
			tip:AddLine(artinfo,C.Artifact())
		end
		tip:AddLine("Shift-Click for a wowhead link popup")
		tip:Show()
	end
end
function module:printLink(this,button)
	if button=="RightButton" then
		local missionID=this:GetParent().info.missionID
		addon:Print("Mission",missionID,addon:GetMissionData(missionID,'class'))
	elseif this.itemID and IsShiftKeyDown() then
		if Dialog:ActiveDialog("OHCUrlCopy") then
			Dialog:Dismiss("OHCUrlCopy")
		end
		tb.url="http://www.wowhead.com/item=" ..this.itemID
		Dialog:Spawn("OHCUrlCopy", tb)
	end
end

--- Full mission panel refresh.
-- Reloads cached mission inProgressMissions and availableMissions.
-- Updates combat ally data
-- Sorts missions
-- Updates top tabs (available/in progress)
-- calls Update
-- 
function module:OnUpdateMissions(frame)
--@debug@
	print("Called OnUpdateMissions with ",clean,displayClean)
--@end-debug@	
	if not clean or not displayClean then
--@debug@
		local start=debugprofilestop()
--@end-debug@	
		missionNonFilled=false
		wipe(missionKEYS)
		wipe(missionIDS)
		if not clean then
			addon:GetFullPermutations(true)
			local rc=addon:RefillParties()
--@debug@
			print(format("Refilled %d parties in %.3f",rc,(debugprofilestop()-start)/1000))
--@end-debug@	
		end
		clean=true
		displayClean=true
	end
	return 
end
function module:RefreshButtons()
	wipe(missionKEYS)
	wipe(missionIDS)
	for _,frame in pairs(OHFButtons) do
		self:OnSingleUpdate(frame)
	end
	return self:CheckShadow()
end
function module:OnUpdate(frame)
	self:RefreshButtons()
end
function module:CheckShadow()
	if not addon:GetBoolean("NOWARN") and not OHFMissions.showInProgress and not OHFCompleteDialog:IsVisible() and missionNonFilled then
		local totChamps,maxChamps=addon:GetTotFollowers('CHAMP_' .. AVAILABLE),addon:GetNumber("MAXCHAMP")
		--@debug@
		print("Checking shadows for ",maxChamps,totChamps)
		--@end-debug@
		if totChamps==0 then
			self:NoMartiniNoParty(GARRISON_PARTY_NOT_ENOUGH_CHAMPIONS)
		elseif maxChamps  < 3 then
			self:NoMartiniNoParty(L["Unable to fill missions, raise maximum champions' number"])
		else
			self:NoMartiniNoParty(L["Unable to fill missions. Check your switches"])
		end
	else
		self:NoMartiniNoParty()
	end
end
function addon:ClearMissionsCache()
		wipe(missionKEYS)
		wipe(missionIDS)
end
function addon:Redraw()
	self:ApplySORTMISSION(Current_Sorter)
end
function module:OnSingleUpdate(frame)
	if OHFMissions:IsVisible() and not OHFCompleteDialog:IsVisible() and frame.info then
		self:AdjustPosition(frame)
		--if frame.info.missionID ~= missionIDS[frame] then
		local full= not missionIDS[frame] or missionIDS[frame]~=frame.info.missionID
		local blacklisted=addon:IsBlacklisted(frame.info.missionID)
		if full and not blacklisted  then
			self:AdjustMissionButton(frame)
		end
		missionIDS[frame]=frame.info.missionID
		local mission=addon:GetMissionData(frame.info.missionID)
		if blacklisted then
			self:Dim(frame)
		else
		local rw=frame.Rewards[1]
			rw.Icon:SetDesaturated(false)
			rw.IconBorder:SetDesaturated(false)
		if mission.class and mission.class=="Artifact" then
			rw.Quantity:SetText(mission.classValue .. "*")
			rw.Quantity:Show()
			end
		end
	end
end
local pcall=pcall
local sort=table.sort
local strcmputf8i=strcmputf8i
local function sortfuncProgress(a,b)
	--return a.timeLeftSeconds < b.timeLeftSeconds
		return strcmputf8i(a.name, b.name) < 0
end
local function sortfuncAvailable(a,b)
	if sortKeys[a.missionID] ~= sortKeys[b.missionID] then
		return todefault(sortKeys[a.missionID],MAX) < todefault(sortKeys[b.missionID],MAX)
	else
		return strcmputf8i(a.name, b.name) < 0
	end
end
function module:SortMissions()
	sort(OHFMissions.inProgressMissions,sortfuncProgress)
	if Current_Sorter=="Garrison_SortMissions_Original" then return end
	local f=sorters[Current_Sorter]
	for k=#OHFMissions.availableMissions,1,-1 do
		local missionID=OHFMissions.availableMissions[k].missionID
		local mission=addon:GetMissionData(missionID) -- we need the enriched version
--@debug@
		if IsIgnored(mission) then
			tremove(OHFMissions.availableMissions,k)
		else
--@end-debug@			
			local rc,result =pcall(f,mission)
			sortKeys[missionID]=rc and result or 0
--@debug@
		end
--@end-debug@			
	end
	sort(OHFMissions.availableMissions,sortfuncAvailable)
end
local timer
function addon:Apply(flag,value)
	missionNonFilled=false
	if not timer then timer=addon:NewDelayableTimer(function() addon:RefreshMissions() end) end
	timer:Start(0.01)
end
function addon:ApplySORTMISSION(value)
	Current_Sorter=value
	OHFMissions:UpdateMissions()
	
end
function addon:ApplyELITEMODE(value)
	OHFMissions:UpdateMissions()
end
function addon:ApplyMAXIMIZEXP(value)
	OHFMissions:UpdateMissions()
end
function addon:RefreshMissions()
	module:RefreshButtons()
	if OHF.MissionTab.MissionPage:IsVisible() then
		module:RawMissionClick(OHF.MissionTab.MissionPage,"missionpage")
	end
end
local function ToggleSet(this,value)
	return addon:ToggleSet(this.flag,this.tipo,value)
end
local function ToggleGet(this)
	return addon:ToggleGet(this.flag,this.tipo)

end
local function PreToggleSet(this)
	return ToggleSet(this,this:GetChecked())
end
local pin
local close
local menu
local button
local function OpenMenu()
	addon.db.profile.showmenu=true
	button:Hide()
	menu:Show()
end
local function CloseMenu()
	addon.db.profile.showmenu=false
	button:Show()
	menu:Hide()
end
local warner
function module:NoMartiniNoParty(text)
	if not warner then
		warner=CreateFrame("Frame","OHCWarner",OHFMissions)
		warner.label=warner:CreateFontString(nil,"OVERLAY","GameFontNormalHuge3Outline")
		warner.label:SetTextColor(C:Orange())
		warner:SetAllPoints()
		warner.label:SetHeight(100)
		warner.label:SetPoint("CENTER")
		warner:SetFrameStrata("TOOLTIP")
		addon:SetBackdrop(warner,0,0,0,0.7)
	end
	local label=warner.label
	if text then
		label:SetText(text)
		warner:Show()
	else
		warner:Hide()
	end
end

function module:Menu()
	local previous
	local factory=addon:GetFactory()
	for _,v in pairs(addon:GetRegisteredForMenu("mission")) do
		local flag,icon=strsplit(',',v)
		local f=factory:Option(addon,menu,flag,200)
		if type(f)=="table" and f.GetObjectType then
			if previous then
				f:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,0)
			else
				f:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-30)
			end
			local w=f:GetWidth()+30
			if w >menu:GetWidth() then menu:SetWidth(w) end
			previous=f
		end
	end
	self.Menu=function() addon:Print("Should not call this again") end
end
local stopper=addon:NewModule("stopper","AceHook-3.0")
function addon:UpdateStop(n)
	stopper:UnhookAll()
	stopper:RawHookScript(OrderHallMissionFrameMissions,"OnUpdate",GarrisonMissionListMixin.OnUpdate)
end
function module:InitialSetup(this)
	if type(addon.db.global.warn01_seen)~="number" then	addon.db.global.warn01_seen =0 end
	if type(addon.db.global.warn02_seen)~="number" then	addon.db.global.warn02_seen =0 end
	if GetAddOnEnableState(UnitName("player"),"GarrisonCommander") > 0 then
		if addon.db.global.warn02_seen  < 3 then
			addon.db.global.warn02_seen=addon.db.global.warn02_seen+1
			addon:Popup(L["OrderHallCommander overrides GarrisonCommander for Order Hall Management.\n You can revert to GarrisonCommander simply disabling OrderhallCommander.\nIf instead you like OrderHallCommander remember to add it to Curse client and keep it updated"],20)
		end
	end
	menu=CreateFrame("Frame",nil,OHFMissionTab,"OHCMenu")
	menu.Title:SetText(me .. ' ' .. addon.version)
	menu.Title:SetTextColor(C:Yellow())
	local obj=addon:GetCacheModule():GetTroopsFrame()
	local _,minor=LibStub("LibInit")
	local LL=LibStub("AceLocale-3.0"):GetLocale("LibInit" .. minor,true)
	addon:MarkAsNew(obj,addon:NumericVersion(),LL["Release notes"] .. ' ' .. addon.version,"Help")
	close=menu.CloseButton
	button=CreateFrame("Button",nil,OHFMissionTab,"OHCPin")
	button.tooltip=L["Show/hide OrderHallCommander mission menu"]
	close:SetScript("OnClick",CloseMenu)
	button:SetScript("OnClick",OpenMenu)
	button:GetNormalTexture():SetRotation(math.rad(270))
	button:GetHighlightTexture():SetRotation(math.rad(270))
	self:Menu()
	if addon.db.profile.showmenu then OpenMenu() else CloseMenu() end
	self:Unhook(this,"OnShow")
	self:SecureHookScript(this,"OnShow","MainOnShow")
	self:SecureHookScript(this,"OnHide","MainOnHide")
	OHF.ChampionsStatusInfo=OHF:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	OHF.ChampionsStatusInfo:SetPoint("TOPRIGHT",-45,-5)
	OHF.ChampionsStatusInfo:SetText("")
	OHF.TroopsStatusInfo=OHF:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	OHF.TroopsStatusInfo:SetPoint("TOPLEFT",80,-5)
	OHF.TroopsStatusInfo:SetText("")
	local option1=addon:GetFactory():Button(OHFMissionScroll,
	L["Quick start first mission"],
	L["Launch the first filled mission with at least one locked follower.\nKeep SHIFT pressed to actually launch, a simple click will only print mission name with its followers list"],200)
	option1:SetPoint("BOTTOMLEFT",200,-25)
	option1.obj=module
	option1:SetOnChange("RunMission")
	local option2=addon:GetFactory():Button(OHFMissionScroll,L["Unlock all"],L["Unlocks all follower at once"])
	option2:SetPoint("BOTTOMRIGHT",-200,-25)
	option2:SetOnChange(function() addon:UnReserve() addon:RefreshMissions() end)
	button.tooltip=L["Show/hide OrderHallCommander mission menu"]
	for _,mission in pairs(addon:GetMissionData()) do
		addon:GetSelectedParty(mission.missionID)
	end
	self:EvOn()
	self:MainOnShow()
	-- For some strange reason, we need this to avoid leaking memory
	addon:UpdateStop()
--@alpha@
	local frame=CreateFrame("Frame",nil,OHF,"TooltipBorderedFrameTemplate")
	frame.label=frame:CreateFontString(nil,"OVERLAY","GameFontNormalHuge")
	frame.label:SetAllPoints(frame)
	frame:SetPoint("BOTTOM",OHF,"TOP",0,30)
	frame.label:SetWidth(OHF:GetWidth()-10)
	frame.label:SetText("You are using an\r|cffff0000ALPHA VERSION|r.\nThings can and will break.")
	frame.label:SetJustifyV("CENTER")
	frame.label:SetJustifyH("CENTER")
	frame:SetHeight(frame.label:GetStringHeight()+15)
	frame:SetWidth(OHF:GetWidth())
	frame.label:SetPoint("CENTER")
	if true then return end
--@end-alpha@
	local frame=CreateFrame("Frame",nil,OHF,"TooltipBorderedFrameTemplate")
	frame.label=frame:CreateFontString(nil,"OVERLAY","GameFontNormalHuge")
	frame.label:SetAllPoints(frame)
	frame:SetPoint("BOTTOM",OHF,"TOP",0,30)
	frame.label:SetWidth(OHF:GetWidth()-10)
	frame.label:SetText("You are using an\r|cffff0000BETA VERSION|r.\nIf something doesnt work usually typing /reload will fix it.")
	frame.label:SetJustifyV("CENTER")
	frame.label:SetJustifyH("CENTER")
	frame:SetHeight(frame.label:GetStringHeight()+15)
	frame:SetWidth(OHF:GetWidth())
	frame.label:SetPoint("CENTER")
	
end
function addon:GetMissionKey(missionID)
	return missionID and missionKEYS[missionID] or missionKEYS
end
function addon:GetMembersFrame(frame)
	return missionmembers[frame]
end
function module:RunMission()
	return addon:GetAutopilotModule():RunMission()
end
function module:EvOn()
	for _,m in addon:IterateModules() do
		if m.Events then m:Events() end
	end
	--self:RawHook(OHFMissions,"Update","OnUpdate",true)
	self:SecureHook("Garrison_SortMissions","SortMissions")	
	self:Hook(OHFMissions,"UpdateMissions","OnUpdateMissions",true)
	self:SecureHook(OHFMissions,"Update","OnUpdate")	--self:RawHook(OHFMissions,"Update","OnUpdate",true)
end
function module:EvOff()
	for _,m in addon:IterateModules() do
		if m.EventsOff then
			m:EventsOff()
		elseif m.UnregisterAllEvents then
			m:UnregisterAllEvents()
		end
	end
	self:Unhook("Garrison_SortMissions")	
	self:Unhook(OHFMissions,"UpdateMissions")
	self:Unhook(OHFMissions,"Update")
end
function module:MainOnShow()
	addon:GetResources(true)
	print(OHF.selectedTab)
	--self:Unhook(OHFMissions,"Update")
	addon:RefreshFollowerStatus()
	addon:GetCacheModule():GARRISON_LANDINGPAGE_SHIPMENTS()
	addon:ParseFollowers()
	addon.lastChange=GetTime()
	addon:ApplySORTMISSION(addon:GetString("SORTMISSION"))
	OHF:SelectTab(OHF.selectedTab)
end
function module:MainOnHide()
	collectgarbage()
	addon:GetAutocompleteModule():AutoClose()
end
function module:AdjustPosition(frame)
	local mission=frame.info
	frame.Title:ClearAllPoints()
	if  mission.isResult then
		frame.Title:SetPoint("TOPLEFT",165,15)
	elseif  mission.inProgress then
		frame.Title:SetPoint("TOPLEFT",165,-10)
	else
		frame.Title:SetPoint("TOPLEFT",165,-7)
	end
	if mission.isRare then
		frame.Title:SetTextColor(frame.RareText:GetTextColor())
	else
		frame.Title:SetTextColor(C:White())
	end
	frame.RareText:Hide()
	-- Compacting mission time and level
	frame.RareText:Hide()
	frame.Level:ClearAllPoints()
	frame.MissionType:ClearAllPoints()
	frame.ItemLevel:Hide()
	frame.Level:SetPoint("LEFT",5,0)
	frame.MissionType:SetPoint("LEFT",5,0)
	if mission.isMaxLevel then
		frame.Level:SetText(mission.iLevel)
	else
		frame.Level:SetText(mission.level)
	end
	local missionID=mission.missionID
end

function module:AdjustMissionButton(frame)
	if not OHF:IsVisible() then return end
	local mission=frame.info
	local missionID=mission and mission.missionID
	if not missionID then return end
	missionIDS[frame]=missionID
	-- Adding stats frame (expiration date and chance)
	if not missionstats[frame] then
		missionstats[frame]=CreateFrame("Frame",nil,frame,"OHCStats")
--@debug@
		self:RawHookScript(missionstats[frame],"OnEnter","MissionTip")
--@end-debug@
	end
	local stats=missionstats[frame]
	local aLevel,aIlevel=addon:GetAverageLevels()
	if mission.isMaxLevel then
		frame.Level:SetText(mission.iLevel)
		frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor((aIlevel-750)/(mission.iLevel-750)*100)))
	else
		frame.Level:SetText(mission.level)
		frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor(aLevel/mission.level*100)))
	end
	if mission.inProgress then
		stats:SetPoint("LEFT",48,14)
		stats.Expire:Hide()
	else
		stats.Expire:SetFormattedText("%s\n%s",GARRISON_MISSION_AVAILABILITY,mission.offerTimeRemaining)
		stats.Expire:SetTextColor(addon:GetAgeColor(mission.offerEndTime))
		stats:SetPoint("LEFT",48,0)
		stats.Expire:Show()
	end
	stats.Chance:Show()
	if not missionmembers[frame] then
		missionmembers[frame]=CreateFrame("Frame",nil,frame,"OHCMembers")
	end
	if not missionthreats[frame] then
		missionthreats[frame]=CreateFrame("Frame",nil,frame,"OHCThreats")
	end
	if addon:IsBlacklisted(missionID) then
		return
	end
	self:AddMembers(frame)
end
function module:Dim(frame)
		frame.Title:SetTextColor(0,0,0)
		frame.Overlay:Show()
		frame.Overlay:SetFrameLevel(10)
		frame.Level:SetTextColor(C.Grey())
		frame.Summary:SetTextColor(C.Grey())
		local stats=missionstats[frame]
		if stats then 
			stats.Chance:SetTextColor(C.Grey())
		end
		local members=missionmembers[frame]
		if members then 
			for _,champion in pairs(members.Champions) do
				champion:Unlock()
				champion:SetEmpty(UNUSED)
			end
		end
		local rw=frame.Rewards[1]
		if rw then 		
			rw.Icon:SetDesaturated(true)
			rw.IconBorder:SetDesaturated(true)
		end
end
function module:UnDim(frame)
		frame.Overlay:Hide()
		local rw=frame.Rewards[1]
		if rw then 		
			rw.Icon:SetDesaturated(false)
			rw.IconBorder:SetDesaturated(false)
		end
end
function module:AddMembers(frame)
	local start=GetTime()
	local mission=frame.info
	if not mission then return end
	local nrewards=#mission.rewards
	local missionID=mission.missionID
	local followers=mission.followers
	if not missionID then _G.Print(frame:GetName()) return end
	local members=missionmembers[frame]
	local stats=missionstats[frame]
	local threats=missionthreats[frame]
	members:SetNotReady()
	members:SetPoint("RIGHT",frame.Rewards[nrewards],"LEFT",-5,0)
	if InProgress(frame.info,frame) then
		for i,followerID in ipairs(frame.info.followers) do
			members.Champions[i]:SetFollower(followerID,false)
		end
		for i=#frame.info.followers+1,3 do
			members.Champions[i]:Hide()
		end		
		frame.Overlay:SetFrameLevel(20)
		threats:Hide()
		local perc=select(4,G.GetPartyMissionInfo(missionID))
		stats.Chance:SetFormattedText(PERCENTAGE_STRING,perc)
		stats.Chance:SetTextColor(addon:GetDifficultyColors(perc,true))
		return
	end
	local lastkey=missionKEYS[missionID]
	local parties=addon:GetMissionParties(missionID)	
	local party,key=parties:GetSelectedParty(lastkey)
	local ps=UNCAPPED_PERC
	if key ~= parties.xpkey then
		local bestchance,uncappedchance=parties:GetChanceForKey(key),parties:GetChanceForKey(parties.uncappedkey)
		ps=(bestchance==uncappedchance) and UNCAPPED_PERC or CAPPED_PERC
	end
	if party.timeseconds ~= mission.durationSeconds then
		local color=party.timeseconds > mission.durationSeconds and RED_FONT_COLOR_CODE or GREEN_FONT_COLOR_CODE
		frame.Summary:SetFormattedText(PARENS_TEMPLATE,color .. party.timestring .. FONT_COLOR_CODE_CLOSE)
	end
	local perc=party.perc or 0
	local maxChance=addon:GetNumber('MINCHANCE') 
	stats.Chance:SetFormattedText(ps,perc)
	stats.Chance:SetTextColor(addon:GetDifficultyColors(perc,true))
	missionKEYS[missionID]=key
	local emptymarker=UNUSED
	for i=1,mission.numFollowers do
		if party:Follower(i) then
		missionNonFilled=false
			if members.Champions[i]:SetFollower(party:Follower(i),true) then
				stats.Chance:SetTextColor(C.Grey())
			end
		else
			if i==1 then emptymarker = nil end
			members.Champions[i]:SetEmpty(emptymarker)
			if perc < maxChance then
				stats.Chance:SetTextColor(C.Grey())
			end
		end
		members.Champions[i]:Show()
	end
	for i=mission.numFollowers+1,3 do
			members.Champions[i]:Hide()
	end
	return self:AddThreats(frame,threats,party,missionID)
end
local function goodColor(good,bad)
	if type(bad)=="nil" then bad=not good end
	if good then return "green"
	elseif bad then return "red" else
	return "tear" end

end
local timeIcon="Interface/ICONS/INV_Misc_PocketWatch_01"
local killIcon="Interface/TARGETINGFRAME/UI-RaidTargetingIcon_8"
local lootIcon="Interface/TARGETINGFRAME/UI-RaidTargetingIcon_7"
local resurrectIcon="Interface/ICONS/Spell_Holy_GuardianSpirit"
local lockIcon="Interface/CHATFRAME/UI-ChatFrame-LockIcon"
function module:AddThreats(frame,threats,party,missionID)
	threats:SetPoint("TOPLEFT",frame.Title,"BOTTOMLEFT",0,-5)
	local enemies=addon:GetMissionData(missionID,'enemies')
	if type(enemies)~="table" then
		enemies=select(8,G.GetMissionInfo(missionID))
	end
	local mechanics=new()
	local counters=new()
	local biases=new()
	for _,enemy in pairs(enemies) do
		if type(enemy.mechanics)=="table" then
			for mechanicID,mechanic in pairs(enemy.mechanics) do
			-- icon=enemy.mechanics[id].icon
				mechanic.id=mechanicID
				mechanic.bias=-1
				tinsert(mechanics,mechanic)
			end
		end
	end
	for _,followerID in party:IterateFollowers() do
		if not G.GetFollowerIsTroop(followerID) then
			local followerBias = G.GetFollowerBiasForMission(missionID,followerID)
			tinsert(counters,("%04d,%s,%s,%f"):format(1000-(followerBias*100),followerID,G.GetFollowerName(followerID),followerBias))
		end
	end
	table.sort(counters)
	for _,data in pairs(counters) do
		local _,followerID,_,bias=strsplit(",",data)
			local abilities=G.GetFollowerAbilities(followerID)
			for _,ability in pairs(abilities) do
				for counter,info in pairs(ability.counters) do
					for _,mechanic in pairs(mechanics) do
						if mechanic.id==counter and not biases[mechanic] then
							biases[mechanic]=todefault(bias,0)
							break
						end
					end
				end
		end
	end
	tinsert(mechanics,false) -- separator
	local r,n,i=addon:GetResources()
	local baseCost, cost = party.baseCost or 0 ,party.cost or 0
	-- nobonusloot
	-- increasedcost
	-- increasedduration
	-- killtroops
	if cost>baseCost then
		tinsert(mechanics,new({icon=i,color="red",name=n,description=increasedcost}))
	end
	if cost<baseCost then
		tinsert(mechanics,new({icon=i,color="green",name=n,description=L["Cost reduced"]}))
	end
	if party.timeImproved then
		tinsert(mechanics,new({icon=timeIcon,color="green",name="Time",description=L["Mission duration reduced"]}))
		end
		if party.hasMissionTimeNegativeEffect then
		tinsert(mechanics,new({icon=timeIcon,color="red",name="Time",description=increasedduration}))
	end
	if party.hasKillTroopsEffect then
			if addon:CanKillTroops(party) then
			tinsert(mechanics,new({icon=killIcon,color="red",name=ENCOUNTER_JOURNAL_SECTION_FLAG4,description=killtroops}))
		else
			tinsert(mechanics,new({icon=killIcon,color="green",name=ENCOUNTER_JOURNAL_SECTION_FLAG4,description=killtroopsnodie}))
		end
	end
	if party.hasResurrectTroopsEffect then
		tinsert(mechanics,new({icon=resurrectIcon,color="green",name=RESURRECT,description=L["Resurrect troops effect"]}))
	end
	if party.hasBonusLootNegativeEffect then
		tinsert(mechanics,new({icon=lootIcon,color="red",name=LOOT,description=nobonusloot}))
	end
	threats:AddIcons(mechanics,biases)
	threats.Cost:Show()
	threats.Cost:SetWidth(0)
	threats.Cost:SetFormattedText(addon.resourceFormat,cost)
	local color=goodColor(cost>=r)
	if cost>r then
		threats.Cost:SetTextColor(C:Red())
	else
		threats.Cost:SetTextColor(C:Green())
	end
	threats.Cost:ClearAllPoints()
	threats.Cost:SetPoint("LEFT",frame.Summary,"RIGHT",5,0)
	if party.totalXP and party.totalXP > 0 then
		threats.XP:SetFormattedText(XP_GAIN,party.totalXP or 0)
		threats.XP:ClearAllPoints()
		threats.XP:SetPoint("LEFT",threats.Cost,"RIGHT",5,0)
		threats.XP:Show()
	else
		threats.XP:Hide()
	end
	del(mechanics)
	del(counters)
	del(biases)
end
function module:MissionTip(this)
	local tip=GameTooltip
	local info=this:GetParent().info
	local missionID=info.missionID
	tip:SetOwner(this,"ANCHOR_CURSOR")
	tip:AddLine(me)
	tip:AddDoubleLine(addon:GetAverageLevels())
	OrderHallCommanderMixin.DumpData(tip,info)
	tip:AddLine("Followers")
	for i,id in ipairs(info.followers) do
		local rc,name = pcall(G.GetFollowerName,id)
		tip:AddDoubleLine(id,name)
	end
	local party=addon:GetMissionParties(missionID)
	local key=missionKEYS[missionID]
	local candidate =party:GetSelectedParty(key)
	local dataclass=addon:GetData('Troops')
	for i,id in ipairs(candidate) do
		local rc,name = pcall(G.GetFollowerName,id)
		tip:AddDoubleLine(id,name)
	end
	tip:AddLine("Rewards")
	for i,d in pairs(info.rewards) do
		tip:AddLine('['..i..']')
		OrderHallCommanderMixin.DumpData(tip,info.rewards[i])
	end
	tip:AddLine("OverRewards")
	for i,d in pairs(info.overmaxRewards) do
		tip:AddLine('['..i..']')
		OrderHallCommanderMixin.DumpData(tip,info.overmaxRewards[i])
	end
	tip:AddDoubleLine("MissionID",info.missionID)
	local mission=addon:GetMissionData(info.missionID)
	tip:AddDoubleLine("MissionClass",mission.missionClass)
	tip:AddDoubleLine("MissionValue",mission.missionValue)
	tip:AddDoubleLine("MissionSort",mission.missionSort)
	tip:Show()
end
local bestTimes={}
local bestTimesIndex={}
local emptyTable={}
function module:AdjustMissionTooltip(this,...)
	local tip=GameTooltip
	local missionID=this.info.missionID
--@debug@
	tip:AddDoubleLine("MissionID",missionID)
--@end-debug@
	if this.info.inProgress or this.info.completed then tip:Show() return end
	local party=addon:GetMissionParties(missionID)
	local candidate,key=emptyTable,missionKEYS[missionID]
	if not this.info.isRare then
		tip:AddLine(GARRISON_MISSION_AVAILABILITY);
		tip:AddLine(this.info.offerTimeRemaining, 1, 1, 1);
	end
	tip:AddLine(me .. ' additions',C:Silver())
	if key ~= party.xpkey then
		local bestchance,uncappedchance=party:GetChanceForKey(key),party:GetChanceForKey(party.uncappedkey)
		if (not addon:GetMissionData(missionID,"elite",false) and bestchance < uncappedchance) then
			tip:AddDoubleLine(L["Mission was capped due to total chance less than"],addon:GetNumber("BONUSCHANCE"))
			tip:AddDoubleLine("Maximum chance was",uncappedchance,nil,nil,nil,addon:GetDifficultyColors(uncappedchance,true))
		end
	end
	if party then
		candidate,key =party:GetSelectedParty(key)
		if candidate then
--@debug@
			tip:AddDoubleLine("Base time",this.info.durationSeconds)
			tip:AddDoubleLine("Party time",candidate.timeseconds)
			tip:AddDoubleLine("Best Key",party.bestkey)
			tip:AddDoubleLine("Xp Key",party.xpkey)
			tip:AddDoubleLine("Uncapped Key",party.uncappedkey)
			tip:AddDoubleLine("Selected Key",key)
--@end-debug@
			if candidate.hasBonusLootNegativeEffect then
				tip:AddLine(nobonusloot,C:Red())
			end
			if candidate.hasKillTroopsEffect then
				if addon:CanKillTroops(candidate) then
					tip:AddLine(killtroops,C:Red())
				else
					tip:AddLine(killtroopsnodie,C:Green())
				end
			end
			if candidate.hasResurrectTroopsEffect then
				tip:AddLine(L["Resurrect troops effect"],C:Green())
			end
			if candidate.cost > candidate.baseCost then
				tip:AddLine(increasedcost,C:Red())
			end
			if candidate.hasMissionTimeNegativeEffect then
				tip:AddLine(increasedduration,C:Red())
			end
			if candidate.timeImproved then
				tip:AddLine(L["Duration reduced"],C:Green())
			end
			local r,n,i=addon:GetResources()
			if candidate.cost > r then
				tip:AddLine(GARRISON_NOT_ENOUGH_MATERIALS_TOOLTIP,C:Red())
			end
			-- Not important enough to be specifically shown
			-- hasSuccessChanceNegativeEffect
			-- hasUncounterableSuccessChanceNegativeEffect
		end
	end
	if addon:IsBlacklisted(this.info.missionID) then
		tip:AddDoubleLine(L["Blacklisted"],L["Right-Click to remove from blacklist"],1,0.125,0.125,C:Green())
		--GameTooltip:AddLine(L["Blacklisted missions are ignored in Mission Control"])
	else
		tip:AddDoubleLine(L["Not blacklisted"],L["Right-Click to blacklist"],0.125,1.0,0.125,C:Red())
	end
	-- Mostrare per ogni tempo di attesa solo la percentuale migliore
	wipe(bestTimes)
	wipe(bestTimesIndex)
	key=key or "999999999999999999999"
	addon:BusyFor() -- with no parames resets cache
	for _,otherkey in party:IterateIndex() do
		if otherkey < key then
			local candidate=party:GetSelectedParty(otherkey)
			local duration=addon:BusyFor(candidate)
			if duration > 0 then
				local busy=false
				if addon:GetBoolean("USEALLY") then
					for _,c in candidate:IterateFollowers() do
						local rc,status = pcall(G.GetFollowerStatus,c)
						if rc and status and status==GARRISON_FOLLOWER_COMBAT_ALLY then
							busy=true
							break
						end
					end
				end
				if not busy then
					if not bestTimes[duration] or not bestTimes[duration].perc or bestTimes[duration].perc < candidate.perc then
						bestTimes[duration]=candidate
					end
				end
			end
		else
			break
		end
	end
	for t,p in pairs(bestTimes) do
		tinsert(bestTimesIndex,t)
	end
	if #bestTimesIndex > 0 then
		tip:AddLine(L["Better parties available in next future"],C:Green())
		table.sort(bestTimesIndex)
		local bestChance=0
		for i=1,#bestTimesIndex do
			local key=bestTimesIndex[i]
			local candidate=bestTimes[key]
			if candidate.perc > bestChance then
				bestChance=candidate.perc
				tip:AddDoubleLine(SecondsToTime(key),GARRISON_MISSION_PERCENT_CHANCE:format(bestChance),C.Orange.r,C.Orange.g,C.Orange.b,addon:GetDifficultyColors(bestChance))
				for _,c in candidate:IterateFollowers() do
					local busy=G.GetFollowerMissionTimeLeftSeconds(c) or 0
					tip:AddDoubleLine(G.GetFollowerLink(c),SecondsToTime(busy),1,1,1,addon:GetDifficultyColors(busy/10))
				end
			end
		end
	end
--@debug@
	tip:AddLine("Mission Data")
	for k,v in kpairs(party) do
		local color="Silver"
		if type(v)=="number" then color="Cyan"
		elseif type(v)=="string" then color="Yellow" v=v:sub(1,30)
		elseif type(v)=="boolean" then v=v and 'True' or 'False' color="White"
		elseif type(v)=="table" then color="Green" if v.GetObjectType then v=v:GetObjectType() else v=tostring(v) end
		else v=type(v) color="Blue"
		end
		if k=="description" then v =v:sub(1,10) end
		tip:AddDoubleLine(k,v,addon.colors("Orange",color))
	end
	tip:AddLine("Candidate Data")
	for k,v in kpairs(candidate) do
		local color="Silver"
		if type(v)=="number" then color="Cyan"
		elseif type(v)=="string" then color="Yellow" v=v:sub(1,30)
		elseif type(v)=="boolean" then v=v and 'True' or 'False' color="White"
		elseif type(v)=="table" then color="Green" if v.GetObjectType then v=v:GetObjectType() else v=tostring(v) end
		else v=type(v) color="Blue"
		end
		if k=="description" then v =v:sub(1,10) end
		tip:AddDoubleLine(k,v,addon.colors("Orange",color))
	end
--@end-debug@	
	tip:Show()
end
function module:RawMissionClick(this,button)
	local mission=this.info or this.missionInfo -- callable also from mission page
	local key=missionKEYS[mission.missionID]
	if button=="LeftButton" or button=="missionpage" then
		if button ~= "missionpage" then self.hooks[this].OnClick(this,button) end
		if( IsControlKeyDown()) then
			self:Print("Ctrl key, ignoring mission prefill")
		else
			addon:GetMissionpageModule():FillMissionPage(mission,key)
		end
	elseif button=="RightButton" then
		addon.db.profile.blacklist[mission.missionID]= not addon.db.profile.blacklist[mission.missionID]
		GameTooltip:Hide()
		missionIDS[this]=nil
		addon:RefreshMissions()
		if addon:IsBlacklisted(mission.missionID) then
			self:Dim(this)
		else
			self:UnDim(this)
		end
--@debug@
		print("Calling OHF:UpdateMissions")  
--@end-debug@
		OHF:UpdateMissions()
		this:GetScript("OnEnter")(this)
--@debug@
	elseif button=="MiddleButton" then
		if (IsShiftKeyDown()) then
			DevTools_Dump(this.info)
		else
			addon:TestParty(mission.missionID)
		end

		return
--@end-debug@
	end
end


