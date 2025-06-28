MyLFG = {}

function MyLFG_OnLoad()
  MyLFG.prefix = "-->"
  MyLFG.suffix = "<--"
  MyLFG.interval = 5
  MyLFG.channel = "world"
  MyLFG.isActive = false
  MyLFG.timer = 0

  MyLFGMessageBox:SetText("DM:W")

  MyLFGIntervalSlider:SetMinMaxValues(1, 30)
  MyLFGIntervalSlider:SetValueStep(1)
  MyLFGIntervalSlider:SetValue(MyLFG.interval)
  MyLFGIntervalSlider:SetScript("OnValueChanged", function(self, value)
    MyLFG.interval = value
    MyLFGIntervalText:SetText("Interval: "..value.." min")
  end)

  UIDropDownMenu_Initialize(MyLFGChannelDropdown, MyLFG_ChannelDropdown_Initialize)
  UIDropDownMenu_SetSelectedID(MyLFGChannelDropdown, 1)

  UIDropDownMenu_Initialize(MyLFGPrefixDropdown, MyLFG_PrefixDropdown_Initialize)
  UIDropDownMenu_SetSelectedID(MyLFGPrefixDropdown, 1)

  UIDropDownMenu_Initialize(MyLFGSuffixDropdown, MyLFG_SuffixDropdown_Initialize)
  UIDropDownMenu_SetSelectedID(MyLFGSuffixDropdown, 1)

  MyLFGStartButton:SetScript("OnClick", MyLFG_Toggle)
  MyLFGAnnounceButton:SetScript("OnClick", MyLFG_SendAnnouncement)

  SLASH_MYLFG1 = "/mylfg"
  SlashCmdList["MYLFG"] = function()
    if MyLFGFrame:IsShown() then
      MyLFGFrame:Hide()
    else
      MyLFGFrame:Show()
    end
  end
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
  UIDropDownMenu_SetSelectedID(MyLFGChannelDropdown, self:GetID())
  MyLFG.channel = self.value
end

function MyLFG_ChannelDropdown_Initialize()
  local info = UIDropDownMenu_CreateInfo()
  info.func = MyLFG_ChannelDropdown_OnClick

  info.text = "world"; info.value = "world"; UIDropDownMenu_AddButton(info)
  info = UIDropDownMenu_CreateInfo(); info.func = MyLFG_ChannelDropdown_OnClick
  info.text = "LookingForGroup"; info.value = "LookingForGroup"; UIDropDownMenu_AddButton(info)
  info = UIDropDownMenu_CreateInfo(); info.func = MyLFG_ChannelDropdown_OnClick
  info.text = "Custom"; info.value = "Custom"; UIDropDownMenu_AddButton(info)
end

function MyLFG_PrefixDropdown_OnClick(self)
  UIDropDownMenu_SetSelectedID(MyLFGPrefixDropdown, self:GetID())
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
  UIDropDownMenu_SetSelectedID(MyLFGSuffixDropdown, self:GetID())
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
  local hasWarrior = false
  local hasHealer = false
  local dps = 0

  local function check(unit)
    if not UnitExists(unit) then return end
    local class = UnitClass(unit)
    if class == "Warrior" then
      hasWarrior = true
      dps = dps + 1
    elseif class == "Priest" or class == "Druid" or class == "Paladin" then
      hasHealer = true
      dps = dps + 1
    else
      dps = dps + 1
    end
  end

  check("player")
  for i=1, GetNumPartyMembers() do
    check("party"..i)
  end

  local needs = {}
  if not hasWarrior then table.insert(needs, "need TANK") end
  if not hasHealer then table.insert(needs, "need HEALER") end
  if dps < 3 then table.insert(needs, "need DPS") end

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
