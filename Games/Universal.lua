local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Saersa/Vyper-Development/refs/heads/main/WindUI_Custom.lua"))()
local Window = WindUI:CreateWindow({
    Title = "My Super Hub",
    Icon = "door-open", -- lucide icon
    Author = "by .ftgs and .ftgs",
    Folder = "MySuperHub",
    

    NewElements = true,

    -- ↓ This all is Optional. You can remove it.
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(580, 460),
    MaxSize = Vector2.new(580, 460),
    Transparent = true,
    Theme = "Vyper",
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
     KeySystem = {                                                   
        Note = "By completing this key system you support the devs.",        
        API = {                                                     
            {
                Type = "junkiedevelopment",
                Service = "Vyper",
                Identifier = "1078290",
                Provider = "Vyper"
            },                                                      
        },                                                          
    }, 
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

Window:Tag({
    Title = Window:IsPremium() and "Premium User" or "Free User",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 8,
})


function checkPremium()
    return Window:IsPremium()
end

if checkPremium() then
    local PremiumTab = Window:Tab({ Title = "Premium ⭐" })
    -- add premium elements...
end