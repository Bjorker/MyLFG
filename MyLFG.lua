local PREFIX_OPTIONS = {"LFM", "LF1M", "LFG"}
local SUFFIX_OPTIONS = {"pst", "/w me", "need all"}

function MyLFG_OnLoad(self)
    print("MyLFG Loaded")
    -- Initialize checkboxes to checked
    self.Tank:SetChecked(true)
    self.Healer:SetChecked(true)
    self.DPS1:SetChecked(true)
    self.DPS2:SetChecked(true)
    self.DPS3:SetChecked(true)

    -- Setup drop-down menus
    MyLFG_SetupPrefixDropDown()
    MyLFG_SetupSuffixDropDown()
    MyLFG_SetupChannelDropDown()
end

local function DropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(self.owner, self:GetID())
end

function MyLFG_SetupPrefixDropDown()
    local dropDown = MyLFGFramePrefixDropDown
    dropDown.owner = dropDown
    UIDropDownMenu_Initialize(dropDown, function()
        for i, option in ipairs(PREFIX_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = DropDown_OnClick
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedID(dropDown, 1)
end

function MyLFG_SetupSuffixDropDown()
    local dropDown = MyLFGFrameSuffixDropDown
    dropDown.owner = dropDown
    UIDropDownMenu_Initialize(dropDown, function()
        for i, option in ipairs(SUFFIX_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = DropDown_OnClick
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedID(dropDown, 1)
end

function MyLFG_SetupChannelDropDown()
    local dropDown = MyLFGFrameChannelDropDown
    dropDown.owner = dropDown
    UIDropDownMenu_Initialize(dropDown, function()
        local list = {GetChannelList()}
        for i = 1, #list, 2 do
            local id = list[i]
            local name = list[i + 1]
            if id and name then
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.arg1 = id
                info.func = function(self, arg1)
                    UIDropDownMenu_SetSelectedValue(dropDown, arg1)
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropDown, 1)
end

local function GetRoleString()
    local parts = {}
    if MyLFGFrameTank:GetChecked() then
        table.insert(parts, "1x Tank")
    end
    if MyLFGFrameHealer:GetChecked() then
        table.insert(parts, "1x Healer")
    end
    local dpsCount = 0
    if MyLFGFrameDPS1:GetChecked() then dpsCount = dpsCount + 1 end
    if MyLFGFrameDPS2:GetChecked() then dpsCount = dpsCount + 1 end
    if MyLFGFrameDPS3:GetChecked() then dpsCount = dpsCount + 1 end
    if dpsCount > 0 then
        table.insert(parts, dpsCount .. "x DPS")
    end
    return table.concat(parts, " ")
end

function MyLFG_Announce()
    local prefix = PREFIX_OPTIONS[UIDropDownMenu_GetSelectedID(MyLFGFramePrefixDropDown)] or ""
    local suffix = SUFFIX_OPTIONS[UIDropDownMenu_GetSelectedID(MyLFGFrameSuffixDropDown)] or ""
    local channel = UIDropDownMenu_GetSelectedValue(MyLFGFrameChannelDropDown)
    if not channel then channel = 1 end
    local message = MyLFGFrameMessageBox:GetText() or ""
    local roleString = GetRoleString()

    local fullMessage = table.concat({prefix, message, roleString, suffix}, " ")
    SendChatMessage(fullMessage, "CHANNEL", nil, channel)
end

