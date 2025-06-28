MyLFG = {}

--[[ 
  TurtleWoW (WoW 1.12) non include alcune funzioni moderne.
  Aggiungiamo fallback per evitare errori.
]]
if not UIDropDownMenu_CreateInfo then
  function UIDropDownMenu_CreateInfo()
    return {}
  end
end

function MyLFG_OnLoad()
  MyLFGFrame:RegisterEvent("PLAYER_LOGIN")
  MyLFGFrame:SetScript("OnEvent", MyLFG_OnEvent)
end

function MyLFG_OnEvent(self, event, ...)
  if event == "PLAYER_LOGIN" then
    MyLFGFrame:UnregisterEvent("PLAYER_LOGIN")
    MyLFG_InitUI()
  end
end

function MyLFG_InitUI()
  MyLFG.prefix = "-->"
  MyLFG.suffix = "<--"
  MyLFG.interval = 5
  MyLFG.channel = "world"
  MyLFG.selectedChannel = MyLFG.channel
  MyLFG.isActive = false
  MyLFG.timer = 0

  -- Set testo iniziale
  MyLFGMessageBox:SetText("DM:W")

  -- Posizionamento dropdown
  MyLFGChannelDropdown:ClearAllPoints()
  MyLFGChannelDropdown:SetPoint("TOP", MyLFGMessageBox, "BOTTOM", 0, -10)
  MyLFGPrefixDropdown:ClearAllPoints()
  MyLFGPrefixDropdown:SetPoint("TOP", MyLFGChannelDropdown, "BOTTOM", 0, -10)
  MyLFGSuffixDropdown:ClearAllPoints()
  MyLFGSuffixDropdown:SetPoint("TOP", MyLFGPrefixDropdown, "BOTTOM", 0, -10)

  -- Slider
  MyLFGIntervalSlider:SetMinMaxValues(1, 30)
  MyLFGIntervalSlider:SetValueStep(1)
  MyLFGIntervalSlider:SetValue(MyLFG.interval)
  MyLFGIntervalSlider:SetScript("OnValueChanged", function(self, value)
    MyLFG.interval = value
    MyLFGIntervalText:SetText("Interval: " .. value .. " min")
  end)

  -- Dropdown init
  UIDropDownMenu_Initialize(MyLFGChannelDropdown, MyLFG_ChannelDropdown_Initialize)
  UIDropDownMenu_Initialize(MyLFGPrefixDropdown, MyLFG_PrefixDropdown_Initialize)
  UIDropDownMenu_Initialize(MyLFGSuffixDropdown, MyLFG_SuffixDropdown_Initialize)

  -- Checkbox
  MyLFGTankCheck:SetChecked(false)
  MyLFGHealerCheck:SetChecked(false)
  MyLFGDps1Check:SetChecked(false)
  MyLFGDps2Check:SetChecked(false)
  MyLFGDps3Check:SetChecked(false)

  if MyLFGTankCheckText then MyLFGTankCheckText:SetText("Tank") end
  if MyLFGHealerCheckText then MyLFGHealerCheckText:SetText("Healer") end
  if MyLFGDps1CheckText then MyLFGDps1CheckText:SetText("DPS 1") end
  if MyLFGDps2CheckText then MyLFGDps2CheckText:SetText("DPS 2") end
  if MyLFGDps3CheckText then MyLFGDps3CheckText:SetText("DPS 3") end

  -- Pulsanti
  MyLFGStartButton:SetScript("OnClick", MyLFG_Toggle)
  MyLFGAnnounceButton:SetScript("OnClick", MyLFG_SendAnnouncement)

  -- Slash command
  SLASH_MYLFG1 = "/mylfg"
  SlashCmdList["MYLFG"] = function()
    if MyLFGFrame:IsShown() then
      MyLFGFrame:Hide()
    else
      MyLFGFrame:Show()
    end
  end
end

function MyLFG_ChannelDropdown_Initialize()
  local channels = {}
  for i = 1, 10 do
    local id, name = GetChannelName(i)
    if id and id > 0 and name then
      table.insert(channels, { text = name, value = name })
    end
  end

  for _, channel in ipairs(channels) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = channel.text
    info.value = channel.value
    info.func = function()
      MyLFG.channel = channel.value
      MyLFG.selectedChannel = channel.value
    end
    UIDropDownMenu_AddButton(info)
  end
end

function MyLFG_PrefixDropdown_Initialize()
  local options = {
    { text = "-->", value = "-->" },
    { text = ">>>", value = ">>>" },
    { text = "==>", value = "==>" },
    { text = "[[", value = "[[" },
    { text = "«", value = "«" }
  }

  for _, option in ipairs(options) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = option.text
    info.value = option.value
    info.func = function()
      MyLFG.prefix = option.value
    end
    UIDropDownMenu_AddButton(info)
  end
end

function MyLFG_SuffixDropdown_Initialize()
  local options = {
    { text = "<--", value = "<--" },
    { text = "<<<", value = "<<<" },
    { text = "<==", value = "<==" },
    { text = "]]", value = "]]" },
    { text = "»", value = "»" }
  }

  for _, option in ipairs(options) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = option.text
    info.value = option.value
    info.func = function()
      MyLFG.suffix = option.value
    end
    UIDropDownMenu_AddButton(info)
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

local function GetNeeds()
  local needs = {}
  local dpsNeeded = 0

  if MyLFGTankCheck:GetChecked() then table.insert(needs, "need TANK") end
  if MyLFGHealerCheck:GetChecked() then table.insert(needs, "need HEALER") end
  if MyLFGDps1Check:GetChecked() then dpsNeeded = dpsNeeded + 1 end
  if MyLFGDps2Check:GetChecked() then dpsNeeded = dpsNeeded + 1 end
  if MyLFGDps3Check:GetChecked() then dpsNeeded = dpsNeeded + 1 end
  if dpsNeeded > 0 then table.insert(needs, "need " .. dpsNeeded .. " DPS") end

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
  if members == 4 then lf = "LF1M"
  elseif members >= 2 then lf = "LF3M" end

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
