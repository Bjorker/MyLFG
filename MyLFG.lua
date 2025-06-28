MyLFG = {}

--[[
  TurtleWoW does not always include the standard UIDropDownMenu
  helper function.  Add a small fallback to avoid a nil error when
  the dropdowns are initialised.
]]
if UIDropDownMenu_CreateInfo == nil then
  function UIDropDownMenu_CreateInfo()
    return {}
  end
end

function MyLFG_OnLoad()
  MyLFG.prefix = "-->"
  MyLFG.suffix = "<--"
  MyLFG.interval = 5
  MyLFG.channel = "world"
  MyLFG.selectedChannel = MyLFG.channel
  MyLFG.isActive = false
  MyLFG.timer = 0

  -- ensure the frame has a backdrop in case the template fails
  if MyLFGFrame.SetBackdrop then
    MyLFGFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    MyLFGFrame:SetBackdropColor(0, 0, 0, 0.75)
    MyLFGFrame:SetBackdropBorderColor(1, 1, 1, 1)
  end

  MyLFGMessageBox:SetText("DM:W")

  -- anchor dropdowns below the input box
  MyLFGChannelDropdown:ClearAllPoints()
  MyLFGChannelDropdown:SetPoint("TOP", MyLFGMessageBox, "BOTTOM", 0, -10)
  MyLFGPrefixDropdown:ClearAllPoints()
  MyLFGPrefixDropdown:SetPoint("TOP", MyLFGChannelDropdown, "BOTTOM", 0, -10)
  MyLFGSuffixDropdown:ClearAllPoints()
  MyLFGSuffixDropdown:SetPoint("TOP", MyLFGPrefixDropdown, "BOTTOM", 0, -10)

  -- center main buttons
  MyLFGStartButton:ClearAllPoints()
  MyLFGStartButton:SetPoint("BOTTOM", MyLFGFrame, "BOTTOM", -60, 20)
  MyLFGAnnounceButton:ClearAllPoints()
  MyLFGAnnounceButton:SetPoint("BOTTOM", MyLFGFrame, "BOTTOM", 60, 20)

  MyLFGIntervalSlider:SetMinMaxValues(1, 30)
  MyLFGIntervalSlider:SetValueStep(1)
  MyLFGIntervalSlider:SetValue(MyLFG.interval)
  MyLFGIntervalSlider:SetScript("OnValueChanged", function(self, value)
    MyLFG.interval = value
    MyLFGIntervalText:SetText("Interval: "..value.." min")
  end)

  UIDropDownMenu_Initialize(MyLFGChannelDropdown, MyLFG_ChannelDropdown_Initialize)
  UIDropDownMenu_SetSelectedName(MyLFGChannelDropdown, MyLFG.selectedChannel)
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(MyLFGChannelDropdown, MyLFG.selectedChannel)
  end

  UIDropDownMenu_Initialize(MyLFGPrefixDropdown, MyLFG_PrefixDropdown_Initialize)
  UIDropDownMenu_SetSelectedID(MyLFGPrefixDropdown, 1)
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(MyLFGPrefixDropdown, MyLFG.prefix)
  end

  UIDropDownMenu_Initialize(MyLFGSuffixDropdown, MyLFG_SuffixDropdown_Initialize)
  UIDropDownMenu_SetSelectedID(MyLFGSuffixDropdown, 1)
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(MyLFGSuffixDropdown, MyLFG.suffix)
  end

  -- initialise role checkboxes as unchecked
  MyLFGTankCheck:SetChecked(false)
  MyLFGHealerCheck:SetChecked(false)
  MyLFGDps1Check:SetChecked(false)
  MyLFGDps2Check:SetChecked(false)
  MyLFGDps3Check:SetChecked(false)

  -- label the role checkboxes
  if MyLFGTankCheckText then MyLFGTankCheckText:SetText("Tank") end
  if MyLFGHealerCheckText then MyLFGHealerCheckText:SetText("Healer") end
  if MyLFGDps1CheckText then MyLFGDps1CheckText:SetText("DPS 1") end
  if MyLFGDps2CheckText then MyLFGDps2CheckText:SetText("DPS 2") end
  if MyLFGDps3CheckText then MyLFGDps3CheckText:SetText("DPS 3") end

  MyLFGStartButton:SetScript("OnClick", MyLFG_Toggle)
  MyLFGAnnounceButton:SetScript("OnClick", MyLFG_SendAnnouncement)

  -- hide unused buttons if present
  if MyLFGLeftButton then MyLFGLeftButton:Hide() end
  if MyLFGRightButton then MyLFGRightButton:Hide() end

  SLASH_MYLFG1 = "/mylfg"
  SlashCmdList["MYLFG"] = function()
    if MyLFGFrame:IsShown() then
      MyLFGFrame:Hide()
    else
      MyLFGFrame:Show()
    end
  end

  -- cleanup dynamic frames on show
  MyLFGFrame:SetScript("OnShow", function()
    if MyLFG.dynamicFrames then
      for _, f in ipairs(MyLFG.dynamicFrames) do
        if f and f.Hide then f:Hide() end
      end
      MyLFG.dynamicFrames = {}
    end
  end)
end

function MyLFG_UpdateButton()
  if MyLFG.isActive then
    MyLFGStartButton:SetText("Stop")
  else
    MyLFGStartButton:SetText("Start")
  end
end

local function MyLFG_OnUpdate(self, elapsed)
  MyLFG.timer = MyLFG.timer + elapsed
  if MyLFG.timer >= (MyLFG.interval * 60) then
    MyLFG_SendAnnouncement()
    MyLFG.timer = 0
  end
end

function MyLFG_Start()
  if MyLFG.isActive then return end
  MyLFG.timer = 0
  MyLFGFrame:SetScript("OnUpdate", MyLFG_OnUpdate)
  MyLFG.isActive = true
  MyLFG_UpdateButton()
  DEFAULT_CHAT_FRAME:AddMessage("MyLFG: Started")
end

function MyLFG_Stop()
  if not MyLFG.isActive then return end
  MyLFGFrame:SetScript("OnUpdate", nil)
  MyLFG.isActive = false
  MyLFG_UpdateButton()
  DEFAULT_CHAT_FRAME:AddMessage("MyLFG: Stopped")
end

function MyLFG_Toggle()
  if MyLFG.isActive then
    MyLFG_Stop()
  else
    MyLFG_Start()
  end
end

function MyLFG_ChannelDropdown_OnClick(self)
  if not self then return end
  UIDropDownMenu_SetSelectedName(MyLFGChannelDropdown, self.value)
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(MyLFGChannelDropdown, self.value)
  end
  MyLFG.channel = self.value
  MyLFG.selectedChannel = self.value
end

function MyLFG_ChannelDropdown_Initialize()
  for i = 1, 10 do
    local id, name = GetChannelName(i)
    if id and id > 0 and name then
      local info = UIDropDownMenu_CreateInfo()
      info.text = name
      info.value = name
      info.func = MyLFG_ChannelDropdown_OnClick
      UIDropDownMenu_AddButton(info)
    end
  end
end

function MyLFG_PrefixDropdown_OnClick(self)
  if not self then return end
  UIDropDownMenu_SetSelectedName(MyLFGPrefixDropdown, self.value)
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(MyLFGPrefixDropdown, self.value)
  end
  MyLFG.prefix = self.value
end

function MyLFG_PrefixDropdown_Initialize()
  local options = {"-->", ">>>", "==>", "[[", "«"}
  for i, opt in ipairs(options) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = opt
    info.value = opt
    info.func = MyLFG_PrefixDropdown_OnClick
    UIDropDownMenu_AddButton(info)
  end
end

function MyLFG_SuffixDropdown_OnClick(self)
  if not self then return end
  UIDropDownMenu_SetSelectedName(MyLFGSuffixDropdown, self.value)
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(MyLFGSuffixDropdown, self.value)
  end
  MyLFG.suffix = self.value
end

function MyLFG_SuffixDropdown_Initialize()
  local options = {"<--", "<<<", "<==", "]]", "»"}
  for i, opt in ipairs(options) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = opt
    info.value = opt
    info.func = MyLFG_SuffixDropdown_OnClick
    UIDropDownMenu_AddButton(info)
  end
end

local function GetNeeds()
  local needs = {}
  local dpsNeeded = 0

  if MyLFGTankCheck:GetChecked() then
    table.insert(needs, "need TANK")
  end

  if MyLFGHealerCheck:GetChecked() then
    table.insert(needs, "need HEALER")
  end

  if MyLFGDps1Check:GetChecked() then dpsNeeded = dpsNeeded + 1 end
  if MyLFGDps2Check:GetChecked() then dpsNeeded = dpsNeeded + 1 end
  if MyLFGDps3Check:GetChecked() then dpsNeeded = dpsNeeded + 1 end

  if dpsNeeded > 0 then
    table.insert(needs, "need " .. dpsNeeded .. " DPS")
  end

  return table.concat(needs, " ")
end

function MyLFG_SendAnnouncement()
  local base = MyLFGMessageBox:GetText() or ""
  local members = GetNumPartyMembers() + 1

  if members >= 5 then
    DEFAULT_CHAT_FRAME:AddMessage("MyLFG: Group FULL")
    MyLFG_Stop()
    return
  end

  local lf = "LFM"
  if members == 4 then
    lf = "LF1M"
  elseif members >= 2 and members <= 3 then
    lf = "LF3M"
  end

  local needs = GetNeeds()
  local finalMsg = MyLFG.prefix.." "..lf.." "..base.." "..needs.." "..MyLFG.suffix

  local channelId = GetChannelName(MyLFG.channel)
  if channelId and channelId > 0 then
    SendChatMessage(finalMsg, "CHANNEL", nil, channelId)
    DEFAULT_CHAT_FRAME:AddMessage("MyLFG: Message sent to "..MyLFG.channel)
  else
    DEFAULT_CHAT_FRAME:AddMessage("MyLFG: Channel not found")
  end
end
