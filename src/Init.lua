local ArtUI = {
    Window = nil,
    Theme = nil,
    Creator = require("./modules/Creator"),
    LocalizationModule = require("./modules/Localization"),
    NotificationModule = require("./components/Notification"),
    Themes = nil,
    Transparent = false,
    
    TransparencyValue = .15,
    
    UIScale = 1,
    
    ConfigManager = nil,
    Version = "0.0.0",
    
    Services = require("./utils/services/Init"),
    
    OnThemeChangeFunction = nil,
    
    cloneref = nil,
    UIScaleObj = nil,
}


local cloneref = (cloneref or clonereference or function(instance) return instance end)

ArtUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui= cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
    ArtUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local ServicesModule = ArtUI.Services


local Creator = ArtUI.Creator

local New = Creator.New
local Tween = Creator.Tween


local Acrylic = require("./utils/Acrylic/Init")


local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or (CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui"))

local UIScaleObj = New("UIScale", {
    Scale = ArtUI.Scale,
})

ArtUI.UIScaleObj = UIScaleObj

ArtUI.ScreenGui = New("ScreenGui", {
    Name = "ArtUI",
    Parent = GUIParent,
    IgnoreGuiInset = true,
    ScreenInsets = "None",
}, {
    
    New("Folder", {
        Name = "Window"
    }),
    -- New("Folder", {
    --     Name = "Notifications"
    -- }),
    -- New("Folder", {
    --     Name = "Dropdowns"
    -- }),
    New("Folder", {
        Name = "KeySystem"
    }),
    New("Folder", {
        Name = "Popups"
    }),
    New("Folder", {
        Name = "ToolTips"
    })
})

ArtUI.NotificationGui = New("ScreenGui", {
    Name = "ArtUI/Notifications",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
ArtUI.DropdownGui = New("ScreenGui", {
    Name = "ArtUI/Dropdowns",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
ArtUI.TooltipGui = New("ScreenGui", {
    Name = "ArtUI/Tooltips",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
ProtectGui(ArtUI.ScreenGui)
ProtectGui(ArtUI.NotificationGui)
ProtectGui(ArtUI.DropdownGui)
ProtectGui(ArtUI.TooltipGui)

Creator.Init(ArtUI)


function ArtUI:SetParent(parent)
    ArtUI.ScreenGui.Parent = parent
    ArtUI.NotificationGui.Parent = parent
    ArtUI.DropdownGui.Parent = parent
end
math.clamp(ArtUI.TransparencyValue, 0, 1)

local Holder = ArtUI.NotificationModule.Init(ArtUI.NotificationGui)

function ArtUI:Notify(Config)
    Config.Holder = Holder.Frame
    Config.Window = ArtUI.Window
    --Config.ArtUI = ArtUI
    return ArtUI.NotificationModule.New(Config)
end

function ArtUI:SetNotificationLower(Val)
    Holder.SetLower(Val)
end

function ArtUI:SetFont(FontId)
    Creator.UpdateFont(FontId)
end

function ArtUI:OnThemeChange(func)
    ArtUI.OnThemeChangeFunction = func
end

function ArtUI:AddTheme(LTheme)
    ArtUI.Themes[LTheme.Name] = LTheme
    return LTheme
end

function ArtUI:SetTheme(Value)
    if ArtUI.Themes[Value] then
        ArtUI.Theme = ArtUI.Themes[Value]
        Creator.SetTheme(ArtUI.Themes[Value])
        
        if ArtUI.OnThemeChangeFunction then
            ArtUI.OnThemeChangeFunction(Value)
        end
        --Creator.UpdateTheme()
        
        return ArtUI.Themes[Value]
    end
    return nil
end

function ArtUI:GetThemes()
    return ArtUI.Themes
end
function ArtUI:GetCurrentTheme()
    return ArtUI.Theme.Name
end
function ArtUI:GetTransparency()
    return ArtUI.Transparent or false
end
function ArtUI:GetWindowSize()
    return Window.UIElements.Main.Size
end
function ArtUI:Localization(LocalizationConfig)
    return ArtUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function ArtUI:SetLanguage(Value)
    if Creator.Localization then
        return Creator.SetLanguage(Value)
    end
    return false
end

function ArtUI:ToggleAcrylic(Value)
	if ArtUI.Window and ArtUI.Window.AcrylicPaint and ArtUI.Window.AcrylicPaint.Model then
		ArtUI.Window.Acrylic = Value
		ArtUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end



function ArtUI:Gradient(stops, props)
    local colorSequence = {}
    local transparencySequence = {}

    for posStr, stop in next, stops do
        local position = tonumber(posStr)
        if position then
            position = math.clamp(position / 100, 0, 1)
            table.insert(colorSequence, ColorSequenceKeypoint.new(position, stop.Color))
            table.insert(transparencySequence, NumberSequenceKeypoint.new(position, stop.Transparency or 0))
        end
    end

    table.sort(colorSequence, function(a, b) return a.Time < b.Time end)
    table.sort(transparencySequence, function(a, b) return a.Time < b.Time end)


    if #colorSequence < 2 then
        error("ColorSequence requires at least 2 keypoints")
    end


    local gradientData = {
        Color = ColorSequence.new(colorSequence),
        Transparency = NumberSequence.new(transparencySequence),
    }

    if props then
        for k, v in pairs(props) do
            gradientData[k] = v
        end
    end

    return gradientData
end


function ArtUI:Popup(PopupConfig)
    PopupConfig.ArtUI = ArtUI
    return require("./components/popup/Init").new(PopupConfig)
end


ArtUI.Themes = require("./themes/Init")(ArtUI)

Creator.Themes = ArtUI.Themes


ArtUI:SetTheme("Dark")
ArtUI:SetLanguage(Creator.Language)


function ArtUI:CreateWindow(Config)
    local CreateWindow = require("./components/window/Init")
    
    if not isfolder("ArtUI") then
        makefolder("ArtUI")
    end
    if Config.Folder then
        makefolder(Config.Folder)
    else
        makefolder(Config.Title)
    end
    
    Config.ArtUI = ArtUI
    Config.Parent = ArtUI.ScreenGui.Window
    
    if ArtUI.Window then
        warn("You cannot create more than one window")
        return
    end
    
    local CanLoadWindow = true
    
    local Theme = ArtUI.Themes[Config.Theme or "Dark"]
    
    --ArtUI.Theme = Theme
    Creator.SetTheme(Theme)
    
    
    local hwid = gethwid or function()
        return Players.LocalPlayer.UserId
    end
    
    local Filename = hwid()
    
    if Config.KeySystem then
        CanLoadWindow = false
    
        local function loadKeysystem()
            KeySystem.new(Config, Filename, function(c) CanLoadWindow = c end)
        end
    
        local keyPath = (Config.Folder or "Temp") .. "/" .. Filename .. ".key"
        
        if Config.KeySystem.KeyValidator then
            if Config.KeySystem.SaveKey and isfile(keyPath) then
                local savedKey = readfile(keyPath)
                local isValid = Config.KeySystem.KeyValidator(savedKey)
                
                if isValid then
                    CanLoadWindow = true
                else
                    loadKeysystem()
                end
            else
                loadKeysystem()
            end
        elseif not Config.KeySystem.API then
            if Config.KeySystem.SaveKey and isfile(keyPath) then
                local savedKey = readfile(keyPath)
                local isKey = (type(Config.KeySystem.Key) == "table")
                    and table.find(Config.KeySystem.Key, savedKey)
                    or tostring(Config.KeySystem.Key) == tostring(savedKey)
                    
                if isKey then
                    CanLoadWindow = true
                else
                    loadKeysystem()
                end
            else
                loadKeysystem()
            end
        else
            if isfile(keyPath) then
                local fileKey = readfile(keyPath)
                local isSuccess = false
                 
                for _, i in next, Config.KeySystem.API do
                    local serviceData = ArtUI.Services[i.Type]
                    if serviceData then
                        local args = {}
                        for _, argName in next, serviceData.Args do
                            table.insert(args, i[argName])
                        end
                        
                        local service = serviceData.New(table.unpack(args))
                        local success = service.Verify(fileKey)
                        if success then
                            isSuccess = true
                            break
                        end
                    end
                end
                    
                CanLoadWindow = isSuccess
                if not isSuccess then loadKeysystem() end
            else
                loadKeysystem()
            end
        end
        
        repeat task.wait() until CanLoadWindow
    end

    local Window = CreateWindow(Config)

    ArtUI.Transparent = Config.Transparent
    ArtUI.Window = Window
    
    if Config.Acrylic then
        Acrylic.init()
    end
    
    -- function Window:ToggleTransparency(Value)
    --     ArtUI.Transparent = Value
    --     ArtUI.Window.Transparent = Value
        
    --     Window.UIElements.Main.Background.BackgroundTransparency = Value and ArtUI.TransparencyValue or 0
    --     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and ArtUI.TransparencyValue or 0
    --     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
    --         NumberSequenceKeypoint.new(0, 1), 
    --         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
    --     }
    -- end
    
    return Window
end

return ArtUI