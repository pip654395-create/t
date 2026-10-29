-- =========================================================================
--   🌶️ AUG HUB V5 • KEY SYSTEM - STEAL AN EGG 🥚 (PHẦN 1/6)
--   TARGET: SOICAIDITMEMAY.LUA · CHỐNG XÓA FILE ĐA TẦNG · CHU KỲ 00:00 GMT+7
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/nSmyHW"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/ronnei/hihi/refs/heads/main/soicaiditmemay.lua"

local HubAvatarId = "rbxassetid://92622270383869"  -- Hình quả ớt ngoài Menu
local GiftBoxAssetId = "rbxassetid://115116611981430" -- Hình hộp quà bên trong Mini-game

-- Hệ thống lưu trữ đa tầng chống xóa file thủ công
local PrimaryVaultFile = "AugV5_SystemVault.json"
local BackupCacheFile = ".rbx_shader_cache_v7.dat"
local BackupTelemetryFile = ".rbx_telemetry_sync_v7.bin"
local VaultAttributeName = "RBX_Engine_State_V7"

local TRIAL_DURATION = 120 -- Thời gian dùng thử 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local MainScreenGui = nil
local OpenKeySystemUI = nil

task.spawn(function()
    pcall(function()
        ContentProvider:PreloadAsync({ GiftBoxAssetId, HubAvatarId })
    end)
end)

local CIPHER_KEY = 139

local function EncryptData(str: string): string
    local hex = {}
    for i = 1, #str do
        table.insert(hex, string.format("%02X", bit32.bxor(string.byte(str, i), CIPHER_KEY)))
    end
    return table.concat(hex)
end

local function DecryptData(hexStr: string): string?
    local res = {}
    for i = 1, #hexStr, 2 do
        local b = tonumber(hexStr:sub(i, i + 1), 16)
        if not b then return nil end
        table.insert(res, string.char(bit32.bxor(b, CIPHER_KEY)))
    end
    return table.concat(res)
end

local function GetCurrentDateGMT7(): string
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    return string.format("%04d-%02d-%02d", d.year, d.month, d.day)
end

local function GetSecondsUntilMidnightGMT7(): number
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    local elapsed = (d.hour * 3600) + (d.min * 60) + d.sec
    return 86400 - elapsed
end

-- =========================================================================
--   CƠ CHẾ ĐỒNG BỘ ĐA TẦNG (CHỐNG XÓA FILE ĐỂ RESET MINI-GAME)
-- =========================================================================
local function ReadRawVaultFromSource(rawStr: string?): table?
    if not rawStr or rawStr == "" then return nil end
    local dec = DecryptData(rawStr)
    if not dec then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(dec) end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local function SaveMasterVault(vault: table)
    local encoded = EncryptData(HttpService:JSONEncode(vault))
    if getgenv then
        getgenv().__AugV5_VaultCache = encoded
    end
    pcall(function() Lighting:SetAttribute(VaultAttributeName, encoded) end)
    pcall(function() CoreGui:SetAttribute(VaultAttributeName, encoded) end)
    if writefile then
        for _, fName in ipairs({ PrimaryVaultFile, BackupCacheFile, BackupTelemetryFile }) do
            pcall(function() writefile(fName, encoded) end)
        end
    end
end

local function LoadMasterVault(): table
    local candidates = {}

    if getgenv and getgenv().__AugV5_VaultCache then
        local d = ReadRawVaultFromSource(getgenv().__AugV5_VaultCache)
        if d then table.insert(candidates, d) end
    end

    pcall(function()
        local attr1 = Lighting:GetAttribute(VaultAttributeName)
        local d1 = ReadRawVaultFromSource(attr1)
        if d1 then table.insert(candidates, d1) end
    end)

    pcall(function()
        local attr2 = CoreGui:GetAttribute(VaultAttributeName)
        local d2 = ReadRawVaultFromSource(attr2)
        if d2 then table.insert(candidates, d2) end
    end)

    if isfile and readfile then
        for _, fName in ipairs({ PrimaryVaultFile, BackupCacheFile, BackupTelemetryFile }) do
            if isfile(fName) then
                local ok, raw = pcall(readfile, fName)
                if ok then
                    local d = ReadRawVaultFromSource(raw)
                    if d then table.insert(candidates, d) end
                end
            end
        end
    end

    local today = GetCurrentDateGMT7()
    local merged = {
        TrialStart = nil,
        LastSeen = 0,
        Tampered = false,
        KeyExpire = 0,
        LastGachaDate = "",
        LastSpinDate = "",
        BonusHours = 0,
        SpinClaimed = false
    }

    for _, c in ipairs(candidates) do
        if c.TrialStart and (not merged.TrialStart or c.TrialStart < merged.TrialStart) then
            merged.TrialStart = c.TrialStart
        end
        if c.LastSeen and c.LastSeen > merged.LastSeen then
            merged.LastSeen = c.LastSeen
        end
        if c.Tampered then merged.Tampered = true end
        if c.KeyExpire and c.KeyExpire > merged.KeyExpire then
            merged.KeyExpire = c.KeyExpire
        end
        if c.LastGachaDate == today then
            merged.LastGachaDate = today
        end
        if c.LastSpinDate == today then
            merged.LastSpinDate = today
            if (tonumber(c.BonusHours) or 0) > merged.BonusHours then
                merged.BonusHours = tonumber(c.BonusHours) or 0
            end
            if c.SpinClaimed then merged.SpinClaimed = true end
        end
    end

    if merged.LastSeen > 0 and os.time() < merged.LastSeen then
        merged.Tampered = true
    end

    if #candidates > 0 then
        SaveMasterVault(merged)
    end

    return merged
end
-- =========================================================================
--   🌶️ AUG HUB V5 • KEY SYSTEM - STEAL AN EGG 🥚 (PHẦN 2/6)
--   XÁC THỰC KEY CHILLIHUBV7VIP · NẠP SCRIPT AN TOÀN (KHÔNG DESTROY UI)
-- =========================================================================

local function CanPlayGachaToday(): boolean
    local v = LoadMasterVault()
    return v.LastGachaDate ~= GetCurrentDateGMT7()
end

local function SaveGachaPlayed()
    local v = LoadMasterVault()
    v.LastGachaDate = GetCurrentDateGMT7()
    v.LastSeen = os.time()
    SaveMasterVault(v)
end

local function LoadSpinDataToday(): { Played: boolean, BonusHours: number, Claimed: boolean }
    local v = LoadMasterVault()
    if v.LastSpinDate == GetCurrentDateGMT7() then
        return {
            Played = true,
            BonusHours = tonumber(v.BonusHours) or 0,
            Claimed = v.SpinClaimed == true
        }
    end
    return { Played = false, BonusHours = 0, Claimed = false }
end

local function SaveSpinResult(bonusHours: number, claimed: boolean)
    local v = LoadMasterVault()
    v.LastSpinDate = GetCurrentDateGMT7()
    v.BonusHours = bonusHours
    v.SpinClaimed = claimed
    v.LastSeen = os.time()
    SaveMasterVault(v)
end

local function GetKeyRemainingTime(): number?
    local v = LoadMasterVault()
    if v.KeyExpire and v.KeyExpire > os.time() then
        return v.KeyExpire - os.time()
    end
    return nil
end

local function Save24hKey(customDuration: number?): number
    local v = LoadMasterVault()
    local bonusSeconds = 0
    local bonusHoursAdded = 0
    if v.LastSpinDate == GetCurrentDateGMT7() and not v.SpinClaimed and (tonumber(v.BonusHours) or 0) > 0 then
        bonusHoursAdded = tonumber(v.BonusHours) or 0
        bonusSeconds = bonusHoursAdded * 3600
        v.SpinClaimed = true
    end
    local baseDur = customDuration or 86400
    v.KeyExpire = os.time() + baseDur + bonusSeconds
    v.LastSeen = os.time()
    SaveMasterVault(v)
    return bonusHoursAdded
end

-- ĐỒNG BỘ CHUẨN XÁC VỚI KEY TẠO TỪ WEB: chillihubv7vip-XXXX-YYYY-ZZZZ
local function VerifyAugV5Key(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^chillihubv7vip%-", ""):gsub("^chilliv7vip%-", ""):gsub("^chillihubv7%-", "")

    local vnTime = os.time() + (7 * 3600)
    for _, t in ipairs({ vnTime, vnTime - 86400, vnTime + 3600 }) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 4339 + d.month * 3187 + d.year * 173) % 65535
        local v2 = (d.day * 6823 + d.month * 4931 + d.year * 293) % 65535
        local v3 = (d.day * 8513 + d.month * 7109 + d.year * 431) % 65535
        if clean == string.format("%04x-%04x-%04x", v1, v2, v3) then
            return true
        end
    end
    return false
end

local function TakeGuiSnapshot()
    table.clear(InitialGuis)
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                InitialGuis[child] = true
            end
        end
    end
end

local function ApplyScreenLockdown()
    if not ActiveBlurEffect then
        ActiveBlurEffect = Instance.new("BlurEffect")
        ActiveBlurEffect.Name = "AugV5_LockdownBlur"
        ActiveBlurEffect.Size = 14
        ActiveBlurEffect.Parent = Lighting
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
        end
        if hrp then
            hrp.Anchored = true
        end
    end

    if not InputBlockerScreen then
        InputBlockerScreen = Instance.new("ScreenGui")
        InputBlockerScreen.Name = "AugV5_InputBlocker"
        InputBlockerScreen.IgnoreGuiInset = true
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then InputBlockerScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundTransparency = 1
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.Modal = true
        shield.ZIndex = 15
        shield.Parent = InputBlockerScreen
    end
end

local function RemoveScreenLockdown()
    if ActiveBlurEffect then
        ActiveBlurEffect:Destroy()
        ActiveBlurEffect = nil
    end
    if InputBlockerScreen then
        InputBlockerScreen:Destroy()
        InputBlockerScreen = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        if hrp then
            hrp.Anchored = false
        end
    end
end

-- KHỞI CHẠY SCRIPT GỐC AN TOÀN: CHỈ ẨN GIAO DIỆN (GIỮ THREAD KHÔNG BỊ HỦY)
local function LaunchTargetScriptSafe(onErrorCallback: (string) -> ())
    RemoveScreenLockdown()
    if MainScreenGui then
        MainScreenGui.Enabled = false
    end

    task.spawn(function()
        local fetchOk, scriptContent = pcall(game.HttpGet, game, TargetScriptUrl)
        if not fetchOk or not scriptContent or scriptContent == "" then
            warn("[Aug V5] Không thể nạp script gốc: " .. tostring(scriptContent))
            if MainScreenGui then MainScreenGui.Enabled = true end
            if onErrorCallback then
                onErrorCallback("❌ Lỗi mạng: Không tải được link script gốc!")
            end
            return
        end

        local compileOk, executable = pcall(loadstring, scriptContent)
        if not compileOk or type(executable) ~= "function" then
            warn("[Aug V5] Lỗi biên dịch script gốc: " .. tostring(executable))
            if MainScreenGui then MainScreenGui.Enabled = true end
            if onErrorCallback then
                onErrorCallback("❌ Lỗi cú pháp trong script gốc!")
            end
            return
        end

        local runOk, runError = pcall(executable)
        if not runOk then
            warn("[Aug V5] Lỗi thực thi script gốc: " .. tostring(runError))
        end
    end)
end

local function TerminateTargetScript()
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not InitialGuis[child] and not string.find(child.Name, "^AugV5_") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function FormatTime(seconds: number): string
    if seconds < 0 then seconds = 0 end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%02dh %02dp %02ds", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText: string, initialSeconds: number, color: Color3, duration: number?)
    if CoreGui:FindFirstChild("AugV5_ToastUI") then CoreGui.AugV5_ToastUI:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("AugV5_ToastUI") then
        LocalPlayer.PlayerGui.AugV5_ToastUI:Destroy()
    end

    local showDur = duration or 6
    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "AugV5_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 320, 0, 54)
    ToastFrame.Position = UDim2.new(0.5, -160, 0, -80)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 12)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1
    Stroke.Color = color or Color3.fromRGB(205, 45, 75)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 34, 1, 0)
    Icon.Position = UDim2.new(0, 8, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🌶️"
    Icon.TextSize = 18
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 0, 18)
    Title.Position = UDim2.new(0, 42, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(226, 232, 240)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -50, 0, 16)
    Msg.Position = UDim2.new(0, 42, 0, 26)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Thời hạn còn lại: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(148, 163, 184)
    Msg.TextSize = 10
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    TweenService:Create(ToastFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -160, 0, 16) }):Play()

    task.delay(showDur, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -160, 0, -80) })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end
-- =========================================================================
--   🌶️ AUG HUB V5 • KEY SYSTEM - STEAL AN EGG 🥚 (PHẦN 3/6)
--   CHIỀU CAO 395PX KHÔNG TRÀN ĐÁY · TỈ LỆ 0.95 · BẢNG MÀU TỐI DỊU MẮT
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VI",
        Title = "Aug Hub V5 • Key System",
        Subtitle = "steal an egg 🥚",
        CenterTitle = "Aug Hub V5 • Key System",
        CenterSub = "steal an egg 🥚",
        Placeholder = "Dán mã key tại đây...",
        QuickPaste = "Dán",
        GetKey = "Lấy Key (24 Tiếng)",
        CheckKey = "Kích Hoạt V7",
        Tutorial = "📖 Hướng dẫn vượt link lấy key",
        MiniGameBox = "mini game ( getkey or nokey ) 🤑",
        MiniGameBoxLocked = "🔒 Hộp quà (00:00)",
        MiniGameSpin = "mini game (vòng quay +thời gian sử dụng)",
        MiniGameSpinLocked = "🔒 Đã quay (+%dH)",
        Notice = "📌 Link getkey 24 tiếng thao tác nhanh gọn (chỉ 1 phút). Key hoạt động đúng 24 giờ sau khi kích hoạt.",
        FooterText = "steal an egg 🥚",
        CopiedLink = "Đã sao chép link getkey 24 tiếng vào clipboard!",
        CopiedTutorial = "Đã sao chép link hướng dẫn vào clipboard!",
        Checking = "Đang xác nhận...",
        CheckingMsg = "Đang đối soát mã key...",
        Success = "Xác nhận thành công! Đang mở script...",
        Error = "Mã Key không hợp lệ hoặc đã hết hạn!",
        -- Hộp quà
        GachaTitle = "🎁 HỘP QUÀ MAY MẮN (1 LẦN/NGÀY)",
        GachaSub = "Chọn 1 hộp bất kỳ. Trúng NoKey sẽ vào thẳng script không cần GetKey!",
        Rate5050 = "TỈ LỆ: 50% - 50%",
        Box1Name = "HỘP QUÀ #1",
        Box2Name = "HỘP QUÀ #2",
        OpenBoxBtn = "MỞ HỘP",
        OpeningBox = "ĐANG MỞ...",
        BoxBannerIdle = "Bấm vào 1 trong 2 hộp quà phía trên để thử vận may!",
        BoxBannerOpening = "⏳ Đang mở hộp quà...",
        BoxWonTitle = "🎉 TRÚNG NOKEY!",
        BoxWonBtn = "VÀO SCRIPT NGAY",
        BoxWonBanner = "🎉 Chúc mừng! Bạn trúng NoKey! Đang tải script...",
        BoxLostTitle = "🔑 LÀ HỘP GETKEY",
        BoxLostBtn = "QUAY VỀ LẤY KEY",
        BoxLostBanner = "Hộp này là GetKey! Vui lòng vượt link để nhận key nhé.",
        -- Vòng quay
        SpinTitle = "🎡 VÒNG QUAY CỘNG GIỜ (1 LẦN/NGÀY)",
        SpinSub = "4 phần thưởng chia đều 4 góc vòng quay (50% - 50%)",
        SpinNote = "sau khi bạn getkey,thời gian bạn quay ra sẽ được cộng vào thời gian key sử dụng của bạn",
        SpinBtnText = "QUAY NGAY",
        SpinningText = "ĐANG QUAY...",
        SpinDoneText = "ĐÃ QUAY HÔM NAY",
        Prize2H = "+2 Tiếng",
        Prize3H = "+3 Giờ",
        Prize4H = "+4 Giờ",
        Prize12H = "+12 Giờ",
        Msg2H = "ngon thí 😋 (+2 tiếng thời gian sử dụng)",
        Msg3H = "ngon thííííí😲 (+3 giờ thời gian sử dụng)",
        Msg4H = "bạn biết không bạn đã may mắn hơn 70% mọi người rồi đó🤑 (+4 giờ)",
        Msg12H = "ôi trời đấy quỷ thần ơi sao trên đời lại có người hên đến vậy chứ 😱 (+12 giờ)"
    },
    EN = {
        LangBtnText = "🇺🇸 EN",
        Title = "Aug Hub V5 • Key System",
        Subtitle = "steal an egg 🥚",
        CenterTitle = "Aug Hub V5 • Key System",
        CenterSub = "steal an egg 🥚",
        Placeholder = "Paste your license key here...",
        QuickPaste = "Paste",
        GetKey = "Get Key (24 Hours)",
        CheckKey = "Activate V7",
        Tutorial = "📖 How to bypass link tutorial",
        MiniGameBox = "mini game ( getkey or nokey ) 🤑",
        MiniGameBoxLocked = "🔒 Box Opened (00:00)",
        MiniGameSpin = "mini game (spin wheel +usage time)",
        MiniGameSpinLocked = "🔒 Spun (+%dH)",
        Notice = "📌 24-hour key link takes about 1 min. Valid for exactly 24 hours after activation.",
        FooterText = "steal an egg 🥚",
        CopiedLink = "24-hour key link copied to clipboard!",
        CopiedTutorial = "Tutorial link copied to clipboard!",
        Checking = "Checking...",
        CheckingMsg = "Verifying license key...",
        Success = "Verified! Launching script...",
        Error = "Invalid key or expired license!",
        -- Mystery Box
        GachaTitle = "🎁 MYSTERY BOX (1 TIME/DAY)",
        GachaSub = "Pick any box. Winning NoKey launches the script immediately without GetKey!",
        Rate5050 = "RATE: 50% - 50%",
        Box1Name = "MYSTERY BOX #1",
        Box2Name = "MYSTERY BOX #2",
        OpenBoxBtn = "OPEN BOX",
        OpeningBox = "OPENING...",
        BoxBannerIdle = "Click one of the 2 boxes above to test your luck!",
        BoxBannerOpening = "⏳ Opening mystery box...",
        BoxWonTitle = "🎉 WON NOKEY!",
        BoxWonBtn = "LAUNCH SCRIPT",
        BoxWonBanner = "🎉 Congrats! You won NoKey! Loading script...",
        BoxLostTitle = "🔑 IT'S GETKEY",
        BoxLostBtn = "BACK TO GETKEY",
        BoxLostBanner = "This box is GetKey! Please complete the link to get your key.",
        -- Spin Wheel
        SpinTitle = "🎡 BONUS TIME WHEEL (1 TIME/DAY)",
        SpinSub = "4 equal slices on the wheel (50% - 50% equal chance)",
        SpinNote = "after you getkey, the time you spin will be added to your key usage time",
        SpinBtnText = "SPIN WHEEL",
        SpinningText = "SPINNING...",
        SpinDoneText = "ALREADY SPUN TODAY",
        Prize2H = "+2 Hours",
        Prize3H = "+3 Hours",
        Prize4H = "+4 Hours",
        Prize12H = "+12 Hours",
        Msg2H = "Pretty sweet! 😋 (+2 hours usage time)",
        Msg3H = "Soooo sweet! 😲 (+3 hours usage time)",
        Msg4H = "Did you know you're luckier than 70% of people?! 🤑 (+4 hours)",
        Msg12H = "Oh my goodness, how can someone in this world be this lucky?! 😱 (+12 hours)"
    }
}
local CurrentLang = "VI"

local function PlaySpringButton(btn: GuiButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local shrinkSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 2)
    local shrinkPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + 2, origPos.Y.Scale, origPos.Y.Offset + 1)

    local t1 = TweenService:Create(btn, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize, Position = shrinkPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

OpenKeySystemUI = function()
    if MainScreenGui and MainScreenGui.Parent then
        MainScreenGui.Enabled = true
        return
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AugV5_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    MainScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 420, 0, 395)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.95

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(36, 41, 52)

    -- HEADER
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -28, 0, 36)
    HeaderBar.Position = UDim2.new(0, 14, 0, 8)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 26, 0, 26)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -13)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    MiniLogo.ClipsDescendants = true
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(190, 40, 70)
    MiniLogoStroke.Thickness = 1

    local MiniLogoImg = Instance.new("ImageLabel")
    MiniLogoImg.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoImg.BackgroundTransparency = 1
    MiniLogoImg.Image = HubAvatarId
    MiniLogoImg.ScaleType = Enum.ScaleType.Fit
    MiniLogoImg.ZIndex = 33
    MiniLogoImg.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -100, 0, 16)
    TitleLabel.Position = UDim2.new(0, 34, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
    TitleLabel.TextSize = 11.5
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -100, 0, 14)
    SubTitleLabel.Position = UDim2.new(0, 34, 0, 18)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
    SubTitleLabel.TextSize = 9.5
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 56, 0, 24)
    OpenLangBtn.Position = UDim2.new(1, -56, 0.5, -12)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
    OpenLangBtn.TextSize = 10
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 6)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(42, 48, 62)
    LangStroke.Thickness = 1

    -- AVATAR QUẢ ỚT CHÍNH GIỮA
    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 46, 0, 46)
    CenterLogoBox.Position = UDim2.new(0.5, -23, 0, 44)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    CenterLogoBox.ClipsDescendants = true
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 12)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(190, 40, 70)
    CenterLogoStroke.Thickness = 1

    local CenterLogoImg = Instance.new("ImageLabel")
    CenterLogoImg.Size = UDim2.new(0.88, 0, 0.88, 0)
    CenterLogoImg.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterLogoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterLogoImg.BackgroundTransparency = 1
    CenterLogoImg.Image = HubAvatarId
    CenterLogoImg.ScaleType = Enum.ScaleType.Fit
    CenterLogoImg.ZIndex = 32
    CenterLogoImg.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 18)
    CenterTitle.Position = UDim2.new(0, 15, 0, 94)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(226, 232, 240)
    CenterTitle.TextSize = 12.5
    CenterTitle.Font = Enum.Font.GothamBold
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 14)
    CenterSub.Position = UDim2.new(0, 15, 0, 112)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(148, 163, 184)
    CenterSub.TextSize = 9.5
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    -- KHUNG NHẬP LIỆU & NÚT DÁN NHANH
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -36, 0, 36)
    InputContainer.Position = UDim2.new(0, 18, 0, 131)
    InputContainer.BackgroundColor3 = Color3.fromRGB(21, 24, 33)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 9)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(40, 46, 60)
    InputStroke.Thickness = 1

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -74, 1, 0)
    InputBox.Position = UDim2.new(0, 12, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(226, 232, 240)
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 52, 0, 24)
    QuickPasteBtn.Position = UDim2.new(1, -58, 0.5, -12)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
    QuickPasteBtn.TextSize = 10
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 6)
    -- =========================================================================
--   🌶️ AUG HUB V5 • KEY SYSTEM - STEAL AN EGG 🥚 (PHẦN 4/6)
--   2 NÚT MINI-GAME SONG SONG (1 HÀNG) · THÔNG BÁO ĐÁY CÂN ĐỐI KHÔNG TRÀN
-- =========================================================================

    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 36)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 173)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(190, 35, 68)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(241, 245, 249)
    GetKeyBtn.TextSize = 11
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 9)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 5, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
    CheckKeyBtn.TextSize = 11
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 9)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(48, 56, 72)
    CheckStroke.Thickness = 1

    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 28)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 215)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(21, 24, 33)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    TutorialBtn.TextSize = 10
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 8)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(36, 41, 52)
    TutorialStroke.Thickness = 1

    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 44)
    NoticeCard.Position = UDim2.new(0, 18, 0, 249)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 9)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(32, 37, 49)
    NoticeStroke.Thickness = 1

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -16, 1, -6)
    NoticeText.Position = UDim2.new(0, 8, 0, 3)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(148, 163, 184)
    NoticeText.TextSize = 9.5
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    -- 2 NÚT MINI-GAME XẾP SONG SONG NẰM TRÊN CÙNG 1 HÀNG
    local MiniGamesRow = Instance.new("Frame")
    MiniGamesRow.Size = UDim2.new(1, -36, 0, 36)
    MiniGamesRow.Position = UDim2.new(0, 18, 0, 299)
    MiniGamesRow.BackgroundTransparency = 1
    MiniGamesRow.ZIndex = 31
    MiniGamesRow.Parent = MainFrame

    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(0.5, -4, 1, 0)
    MiniGameBtn.Position = UDim2.new(0, 0, 0, 0)
    MiniGameBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGameBox or Languages[CurrentLang].MiniGameBoxLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(203, 213, 225) or Color3.fromRGB(100, 116, 139)
    MiniGameBtn.TextSize = 10
    MiniGameBtn.Font = Enum.Font.GothamBold
    MiniGameBtn.TextWrapped = true
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = MiniGamesRow
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 9)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(52, 62, 82) or Color3.fromRGB(34, 39, 50)
    MiniGameStroke.Thickness = 1

    local initSpin = LoadSpinDataToday()
    local SpinGameBtn = Instance.new("TextButton")
    SpinGameBtn.Size = UDim2.new(0.5, -4, 1, 0)
    SpinGameBtn.Position = UDim2.new(0.5, 4, 0, 0)
    SpinGameBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    SpinGameBtn.Text = (not initSpin.Played) and Languages[CurrentLang].MiniGameSpin or string.format(Languages[CurrentLang].MiniGameSpinLocked, initSpin.BonusHours)
    SpinGameBtn.TextColor3 = (not initSpin.Played) and Color3.fromRGB(203, 213, 225) or Color3.fromRGB(100, 116, 139)
    SpinGameBtn.TextSize = 9.5
    SpinGameBtn.Font = Enum.Font.GothamBold
    SpinGameBtn.TextWrapped = true
    SpinGameBtn.AutoButtonColor = false
    SpinGameBtn.ZIndex = 32
    SpinGameBtn.Parent = MiniGamesRow
    Instance.new("UICorner", SpinGameBtn).CornerRadius = UDim.new(0, 9)
    local SpinGameStroke = Instance.new("UIStroke", SpinGameBtn)
    SpinGameStroke.Color = (not initSpin.Played) and Color3.fromRGB(52, 62, 82) or Color3.fromRGB(34, 39, 50)
    SpinGameStroke.Thickness = 1

    -- DÒNG CHỮ ĐÁY CÂN ĐỐI (CÁCH MÉP DƯỚI RỘNG RÃI, KHÔNG TRÀN ẨN)
    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 22)
    StatusMsg.Position = UDim2.new(0, 18, 0, 344)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = Languages[CurrentLang].FooterText
    StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
    StatusMsg.TextSize = 10.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.TextWrapped = true
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- MODAL HỘP QUÀ GACHA (TỈ LỆ THỰC: 5% NOKEY / 95% GETKEY)
    local GachaModal = Instance.new("Frame")
    GachaModal.Name = "GachaModal"
    GachaModal.Size = UDim2.new(1, 0, 1, 0)
    GachaModal.Position = UDim2.new(0, 0, 1, 0)
    GachaModal.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    GachaModal.ZIndex = 45
    GachaModal.ClipsDescendants = true
    GachaModal.Parent = MainFrame
    Instance.new("UICorner", GachaModal).CornerRadius = UDim.new(0, 16)

    local GachaHeader = Instance.new("TextLabel")
    GachaHeader.Size = UDim2.new(1, -60, 0, 24)
    GachaHeader.Position = UDim2.new(0, 18, 0, 12)
    GachaHeader.BackgroundTransparency = 1
    GachaHeader.Text = Languages[CurrentLang].GachaTitle
    GachaHeader.TextColor3 = Color3.fromRGB(226, 232, 240)
    GachaHeader.TextSize = 12
    GachaHeader.Font = Enum.Font.GothamBold
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 46
    GachaHeader.Parent = GachaModal

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 26, 0, 26)
    GachaCloseBtn.Position = UDim2.new(1, -36, 0, 12)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaCloseBtn.TextSize = 11
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.ZIndex = 46
    GachaCloseBtn.Parent = GachaModal
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 6)

    local GachaSubText = Instance.new("TextLabel")
    GachaSubText.Size = UDim2.new(1, -36, 0, 20)
    GachaSubText.Position = UDim2.new(0, 18, 0, 36)
    GachaSubText.BackgroundTransparency = 1
    GachaSubText.Text = Languages[CurrentLang].GachaSub
    GachaSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaSubText.TextSize = 10
    GachaSubText.Font = Enum.Font.GothamMedium
    GachaSubText.TextXAlignment = Enum.TextXAlignment.Left
    GachaSubText.ZIndex = 46
    GachaSubText.Parent = GachaModal

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -36, 0, 210)
    BoxesContainer.Position = UDim2.new(0, 18, 0, 62)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    local function CreateMysteryBox(name: string, posXScale: number, posXOffset: number, boxTitle: string)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -6, 1, 0)
        BoxCard.Position = UDim2.new(posXScale, posXOffset, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(21, 24, 33)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 14)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(42, 48, 62)
        BoxStroke.Thickness = 1

        local Tag5050 = Instance.new("TextLabel")
        Tag5050.Size = UDim2.new(1, -16, 0, 18)
        Tag5050.Position = UDim2.new(0, 8, 0, 8)
        Tag5050.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
        Tag5050.Text = Languages[CurrentLang].Rate5050
        Tag5050.TextColor3 = Color3.fromRGB(203, 213, 225)
        Tag5050.TextSize = 9
        Tag5050.Font = Enum.Font.GothamBold
        Tag5050.ZIndex = 48
        Tag5050.Parent = BoxCard
        Instance.new("UICorner", Tag5050).CornerRadius = UDim.new(0, 6)

        local CropMask = Instance.new("Frame")
        CropMask.Name = "CropMask"
        CropMask.AnchorPoint = Vector2.new(0.5, 0)
        CropMask.Size = UDim2.new(0, 90, 0, 90)
        CropMask.Position = UDim2.new(0.5, 0, 0, 30)
        CropMask.BackgroundTransparency = 1
        CropMask.BorderSizePixel = 0
        CropMask.ClipsDescendants = false
        CropMask.ZIndex = 48
        CropMask.Parent = BoxCard

        local GiftImage = Instance.new("ImageLabel")
        GiftImage.Name = "GiftImage"
        GiftImage.AnchorPoint = Vector2.new(0.5, 0.5)
        GiftImage.Size = UDim2.new(0.85, 0, 0.85, 0)
        GiftImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        GiftImage.BackgroundTransparency = 1
        GiftImage.Image = GiftBoxAssetId
        GiftImage.ScaleType = Enum.ScaleType.Fit
        GiftImage.ZIndex = 49
        GiftImage.Parent = CropMask

        local Aspect = Instance.new("UIAspectRatioConstraint", GiftImage)
        Aspect.AspectRatio = 1

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.Position = UDim2.new(0, 0, 0, 126)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(226, 232, 240)
        Title.TextSize = 11.5
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -20, 0, 26)
        ActionHint.Position = UDim2.new(0, 10, 0, 158)
        ActionHint.BackgroundColor3 = Color3.fromRGB(190, 35, 68)
        ActionHint.Text = Languages[CurrentLang].OpenBoxBtn
        ActionHint.TextColor3 = Color3.fromRGB(241, 245, 249)
        ActionHint.TextSize = 10.5
        ActionHint.Font = Enum.Font.GothamBold
        ActionHint.ZIndex = 48
        ActionHint.Parent = BoxCard
        Instance.new("UICorner", ActionHint).CornerRadius = UDim.new(0, 8)

        return BoxCard, BoxStroke, CropMask, Title, ActionHint, Tag5050
    end

    local Box1, Box1Stroke, Box1Mask, Box1Title, Box1Hint, Box1Tag = CreateMysteryBox("Box1", 0, 0, Languages[CurrentLang].Box1Name)
    local Box2, Box2Stroke, Box2Mask, Box2Title, Box2Hint, Box2Tag = CreateMysteryBox("Box2", 0.5, 6, Languages[CurrentLang].Box2Name)

    local GachaResultBanner = Instance.new("TextLabel")
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 32)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 282)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(21, 24, 33)
    GachaResultBanner.Text = Languages[CurrentLang].BoxBannerIdle
    GachaResultBanner.TextColor3 = Color3.fromRGB(203, 213, 225)
    GachaResultBanner.TextSize = 10
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 8)
    -- =========================================================================
--   🌶️ AUG HUB V5 • KEY SYSTEM - STEAL AN EGG 🥚 (PHẦN 5/6)
--   VÒNG QUAY TRÒN ĐỐI XỨNG · KIM CHỈ ĐỈNH · NÚT BẤM BÊN DƯỚI
-- =========================================================================

    local SpinModal = Instance.new("Frame")
    SpinModal.Name = "SpinModal"
    SpinModal.Size = UDim2.new(1, 0, 1, 0)
    SpinModal.Position = UDim2.new(0, 0, 0, 0)
    SpinModal.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    SpinModal.Visible = false
    SpinModal.ClipsDescendants = false
    SpinModal.ZIndex = 55
    SpinModal.Parent = MainFrame
    Instance.new("UICorner", SpinModal).CornerRadius = UDim.new(0, 16)

    local SpinHeader = Instance.new("TextLabel")
    SpinHeader.Size = UDim2.new(1, -60, 0, 22)
    SpinHeader.Position = UDim2.new(0, 18, 0, 10)
    SpinHeader.BackgroundTransparency = 1
    SpinHeader.Text = Languages[CurrentLang].SpinTitle
    SpinHeader.TextColor3 = Color3.fromRGB(226, 232, 240)
    SpinHeader.TextSize = 12
    SpinHeader.Font = Enum.Font.GothamBold
    SpinHeader.TextXAlignment = Enum.TextXAlignment.Left
    SpinHeader.ZIndex = 56
    SpinHeader.Parent = SpinModal

    local SpinCloseBtn = Instance.new("TextButton")
    SpinCloseBtn.Size = UDim2.new(0, 24, 0, 24)
    SpinCloseBtn.Position = UDim2.new(1, -34, 0, 10)
    SpinCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    SpinCloseBtn.Text = "✕"
    SpinCloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    SpinCloseBtn.TextSize = 11
    SpinCloseBtn.Font = Enum.Font.GothamBold
    SpinCloseBtn.ZIndex = 56
    SpinCloseBtn.Parent = SpinModal
    Instance.new("UICorner", SpinCloseBtn).CornerRadius = UDim.new(0, 6)

    local SpinSubText = Instance.new("TextLabel")
    SpinSubText.Size = UDim2.new(1, -36, 0, 16)
    SpinSubText.Position = UDim2.new(0, 18, 0, 32)
    SpinSubText.BackgroundTransparency = 1
    SpinSubText.Text = Languages[CurrentLang].SpinSub
    SpinSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
    SpinSubText.TextSize = 9.5
    SpinSubText.Font = Enum.Font.GothamMedium
    SpinSubText.TextXAlignment = Enum.TextXAlignment.Left
    SpinSubText.ZIndex = 56
    SpinSubText.Parent = SpinModal

    local PointerArrow = Instance.new("TextLabel")
    PointerArrow.AnchorPoint = Vector2.new(0.5, 0)
    PointerArrow.Size = UDim2.new(0, 24, 0, 18)
    PointerArrow.Position = UDim2.new(0.5, 0, 0, 48)
    PointerArrow.BackgroundTransparency = 1
    PointerArrow.Text = "▼"
    PointerArrow.TextColor3 = Color3.fromRGB(210, 50, 80)
    PointerArrow.TextSize = 16
    PointerArrow.Font = Enum.Font.GothamBlack
    PointerArrow.ZIndex = 65
    PointerArrow.Parent = SpinModal

    local WheelDisk = Instance.new("Frame")
    WheelDisk.Name = "WheelDisk"
    WheelDisk.AnchorPoint = Vector2.new(0.5, 0.5)
    WheelDisk.Size = UDim2.new(0, 168, 0, 168)
    WheelDisk.Position = UDim2.new(0.5, 0, 0, 148)
    WheelDisk.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    WheelDisk.ClipsDescendants = false
    WheelDisk.ZIndex = 57
    WheelDisk.Parent = SpinModal
    Instance.new("UICorner", WheelDisk).CornerRadius = UDim.new(1, 0)

    local DiskStroke = Instance.new("UIStroke", WheelDisk)
    DiskStroke.Color = Color3.fromRGB(55, 65, 85)
    DiskStroke.Thickness = 2.5

    local Line1 = Instance.new("Frame")
    Line1.AnchorPoint = Vector2.new(0.5, 0.5)
    Line1.Size = UDim2.new(1, 0, 0, 2)
    Line1.Position = UDim2.new(0.5, 0, 0.5, 0)
    Line1.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
    Line1.BorderSizePixel = 0
    Line1.Rotation = 45
    Line1.ZIndex = 58
    Line1.Parent = WheelDisk

    local Line2 = Instance.new("Frame")
    Line2.AnchorPoint = Vector2.new(0.5, 0.5)
    Line2.Size = UDim2.new(1, 0, 0, 2)
    Line2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Line2.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
    Line2.BorderSizePixel = 0
    Line2.Rotation = -45
    Line2.ZIndex = 58
    Line2.Parent = WheelDisk

    local CenterCap = Instance.new("Frame")
    CenterCap.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterCap.Size = UDim2.new(0, 24, 0, 24)
    CenterCap.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterCap.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
    CenterCap.ZIndex = 61
    CenterCap.Parent = WheelDisk
    Instance.new("UICorner", CenterCap).CornerRadius = UDim.new(1, 0)
    local CapStroke = Instance.new("UIStroke", CenterCap)
    CapStroke.Color = Color3.fromRGB(190, 40, 70)
    CapStroke.Thickness = 1.2

    local function CreateSliceLabel(posX: number, posY: number, titleText: string)
        local Holder = Instance.new("Frame")
        Holder.AnchorPoint = Vector2.new(0.5, 0.5)
        Holder.Size = UDim2.new(0, 62, 0, 32)
        Holder.Position = UDim2.new(posX, 0, posY, 0)
        Holder.BackgroundTransparency = 1
        Holder.ZIndex = 59
        Holder.Parent = WheelDisk

        local MainTxt = Instance.new("TextLabel")
        MainTxt.Size = UDim2.new(1, 0, 0, 16)
        MainTxt.Position = UDim2.new(0, 0, 0, 0)
        MainTxt.BackgroundTransparency = 1
        MainTxt.Text = titleText
        MainTxt.TextColor3 = Color3.fromRGB(226, 232, 240)
        MainTxt.TextSize = 11
        MainTxt.Font = Enum.Font.GothamBold
        MainTxt.ZIndex = 60
        MainTxt.Parent = Holder

        local SubTxt = Instance.new("TextLabel")
        SubTxt.Size = UDim2.new(1, 0, 0, 14)
        SubTxt.Position = UDim2.new(0, 0, 0, 16)
        SubTxt.BackgroundTransparency = 1
        SubTxt.Text = "50% - 50%"
        SubTxt.TextColor3 = Color3.fromRGB(148, 163, 184)
        SubTxt.TextSize = 8.5
        SubTxt.Font = Enum.Font.GothamMedium
        SubTxt.ZIndex = 60
        SubTxt.Parent = Holder

        return MainTxt
    end

    local Title1 = CreateSliceLabel(0.5, 0.22, Languages[CurrentLang].Prize2H)
    local Title2 = CreateSliceLabel(0.78, 0.5, Languages[CurrentLang].Prize3H)
    local Title3 = CreateSliceLabel(0.5, 0.78, Languages[CurrentLang].Prize4H)
    local Title4 = CreateSliceLabel(0.22, 0.5, Languages[CurrentLang].Prize12H)

    local WheelSlices = {
        { Title = Title1, Hours = 2, TargetAngle = 0, MsgKey = "Msg2H" },
        { Title = Title2, Hours = 3, TargetAngle = 270, MsgKey = "Msg3H" },
        { Title = Title3, Hours = 4, TargetAngle = 180, MsgKey = "Msg4H" },
        { Title = Title4, Hours = 12, TargetAngle = 90, MsgKey = "Msg12H" }
    }

    local TriggerSpinBtn = Instance.new("TextButton")
    TriggerSpinBtn.Size = UDim2.new(0, 170, 0, 32)
    TriggerSpinBtn.Position = UDim2.new(0.5, -85, 0, 244)
    TriggerSpinBtn.BackgroundColor3 = (not initSpin.Played) and Color3.fromRGB(190, 35, 68) or Color3.fromRGB(30, 35, 47)
    TriggerSpinBtn.Text = (not initSpin.Played) and Languages[CurrentLang].SpinBtnText or Languages[CurrentLang].SpinDoneText
    TriggerSpinBtn.TextColor3 = (not initSpin.Played) and Color3.fromRGB(241, 245, 249) or Color3.fromRGB(148, 163, 184)
    TriggerSpinBtn.TextSize = 11
    TriggerSpinBtn.Font = Enum.Font.GothamBold
    TriggerSpinBtn.AutoButtonColor = false
    TriggerSpinBtn.ZIndex = 60
    TriggerSpinBtn.Parent = SpinModal
    Instance.new("UICorner", TriggerSpinBtn).CornerRadius = UDim.new(0, 8)

    local SpinResultBanner = Instance.new("TextLabel")
    SpinResultBanner.Size = UDim2.new(1, -36, 0, 34)
    SpinResultBanner.Position = UDim2.new(0, 18, 0, 284)
    SpinResultBanner.BackgroundColor3 = Color3.fromRGB(21, 24, 33)
    SpinResultBanner.Text = initSpin.Played and string.format("✔ Hôm nay bạn đã quay trúng +%d giờ sử dụng!", initSpin.BonusHours) or "Bấm nút QUAY NGAY để nhận thêm giờ dùng Key!"
    SpinResultBanner.TextColor3 = initSpin.Played and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(203, 213, 225)
    SpinResultBanner.TextSize = 10
    SpinResultBanner.Font = Enum.Font.GothamMedium
    SpinResultBanner.TextWrapped = true
    SpinResultBanner.ZIndex = 56
    SpinResultBanner.Parent = SpinModal
    Instance.new("UICorner", SpinResultBanner).CornerRadius = UDim.new(0, 8)

    local SpinFooterNote = Instance.new("TextLabel")
    SpinFooterNote.Size = UDim2.new(1, -36, 0, 28)
    SpinFooterNote.Position = UDim2.new(0, 18, 0, 324)
    SpinFooterNote.BackgroundTransparency = 1
    SpinFooterNote.Text = Languages[CurrentLang].SpinNote
    SpinFooterNote.TextColor3 = Color3.fromRGB(148, 163, 184)
    SpinFooterNote.TextSize = 9.5
    SpinFooterNote.Font = Enum.Font.GothamMedium
    SpinFooterNote.TextWrapped = true
    SpinFooterNote.ZIndex = 56
    SpinFooterNote.Parent = SpinModal
    -- =========================================================================
--   🌶️ AUG HUB V5 • KEY SYSTEM - STEAL AN EGG 🥚 (PHẦN 6/6)
--   XỬ LÝ SỰ KIỆN · THỰC THI SCRIPT GỐC KHÔNG LỖI THREAD · LUỒNG DÙNG THỬ
-- =========================================================================

    local isRollingMutex = false
    local isSpinningMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end
    local function CloseGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 1, 0) }):Play()
    end
    local function OpenSpinModal()
        MainFrame.ClipsDescendants = false
        SpinModal.Visible = true
    end
    local function CloseSpinModal()
        SpinModal.Visible = false
        MainFrame.ClipsDescendants = true
    end

    GachaCloseBtn.MouseButton1Click:Connect(function()
        if isRollingMutex then return end
        PlaySpringButton(GachaCloseBtn)
        CloseGachaModal()
    end)

    SpinCloseBtn.MouseButton1Click:Connect(function()
        if isSpinningMutex then return end
        PlaySpringButton(SpinCloseBtn)
        CloseSpinModal()
    end)

    MiniGameBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(MiniGameBtn)
        if not CanPlayGachaToday() then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local hoursLeft = math.floor(secsLeft / 3600)
            local minsLeft = math.floor((secsLeft % 3600) / 60)
            StatusMsg.Text = string.format("⏳ Hộp quà đã mở! Reset sau %02d:%02d (00:00)", hoursLeft, minsLeft)
            StatusMsg.TextColor3 = Color3.fromRGB(225, 90, 110)
            return
        end
        OpenGachaModal()
    end)

    SpinGameBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(SpinGameBtn)
        OpenSpinModal()
    end)

    -- VÒNG QUAY 360°: 50% (+2H) | 30% (+3H) | 18% (+4H) | 2% (+12H)
    TriggerSpinBtn.MouseButton1Click:Connect(function()
        if isSpinningMutex then return end
        local currentSpin = LoadSpinDataToday()
        if currentSpin.Played then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local h = math.floor(secsLeft / 3600)
            local m = math.floor((secsLeft % 3600) / 60)
            SpinResultBanner.Text = string.format("⏳ Bạn đã quay hôm nay (+%dH)! Reset sau %02d:%02d (00:00)", currentSpin.BonusHours, h, m)
            SpinResultBanner.TextColor3 = Color3.fromRGB(225, 90, 110)
            return
        end

        isSpinningMutex = true
        PlaySpringButton(TriggerSpinBtn)

        local roll = math.random(1, 100)
        local targetIndex = 1
        if roll <= 50 then
            targetIndex = 1
        elseif roll <= 80 then
            targetIndex = 2
        elseif roll <= 98 then
            targetIndex = 3
        else
            targetIndex = 4
        end

        local wonSlice = WheelSlices[targetIndex]
        SaveSpinResult(wonSlice.Hours, false)

        local activeKeyLeft = GetKeyRemainingTime()
        if activeKeyLeft and activeKeyLeft > 0 then
            Save24hKey(activeKeyLeft)
        end

        SpinGameBtn.Text = string.format(Languages[CurrentLang].MiniGameSpinLocked, wonSlice.Hours)
        SpinGameBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
        SpinGameStroke.Color = Color3.fromRGB(34, 39, 50)

        TriggerSpinBtn.Text = Languages[CurrentLang].SpinningText
        TriggerSpinBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
        SpinResultBanner.Text = "🎡 Vòng quay đang xoay..."
        SpinResultBanner.TextColor3 = Color3.fromRGB(203, 213, 225)

        WheelDisk.Rotation = 0
        local finalRotation = (360 * 6) + wonSlice.TargetAngle
        local spinTween = TweenService:Create(
            WheelDisk,
            TweenInfo.new(3.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Rotation = finalRotation }
        )
        spinTween:Play()
        spinTween.Completed:Wait()

        wonSlice.Title.TextColor3 = Color3.fromRGB(110, 231, 183)
        DiskStroke.Color = Color3.fromRGB(74, 222, 128)

        TriggerSpinBtn.Text = Languages[CurrentLang].SpinDoneText
        TriggerSpinBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
        TriggerSpinBtn.TextColor3 = Color3.fromRGB(148, 163, 184)

        SpinResultBanner.Text = Languages[CurrentLang][wonSlice.MsgKey]
        SpinResultBanner.TextColor3 = Color3.fromRGB(110, 231, 183)

        StatusMsg.Text = string.format("🎁 Đã lưu +%d giờ vào hệ thống!", wonSlice.Hours)
        StatusMsg.TextColor3 = Color3.fromRGB(110, 231, 183)

        isSpinningMutex = false
    end)

    -- MỞ HỘP QUÀ: 5% NOKEY (ẨN MENU & CHẠY SCRIPT GỐC) / 95% GETKEY
    local function ExecuteBoxRoll(chosenBox: TextButton, otherBox: TextButton, chosenStroke: UIStroke, chosenMask: Frame, chosenTitle: TextLabel, chosenHint: TextLabel)
        if isRollingMutex then return end
        isRollingMutex = true

        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameBoxLocked
        MiniGameBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
        MiniGameStroke.Color = Color3.fromRGB(34, 39, 50)

        TweenService:Create(otherBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.65 }):Play()
        otherBox.Active = false

        chosenStroke.Color = Color3.fromRGB(203, 213, 225)
        chosenHint.Text = Languages[CurrentLang].OpeningBox
        chosenHint.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
        GachaResultBanner.Text = Languages[CurrentLang].BoxBannerOpening

        for i = 1, 6 do
            local angle = (i % 2 == 0) and 5 or -5
            TweenService:Create(chosenMask, TweenInfo.new(0.06, Enum.EasingStyle.Quad), { Rotation = angle }):Play()
            task.wait(0.065)
        end
        TweenService:Create(chosenMask, TweenInfo.new(0.08, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
        task.wait(0.2)

        local roll = math.random(1, 100)
        local isNoKeyWon = (roll <= 5)

        if isNoKeyWon then
            chosenStroke.Color = Color3.fromRGB(74, 222, 128)
            chosenTitle.Text = Languages[CurrentLang].BoxWonTitle
            chosenTitle.TextColor3 = Color3.fromRGB(110, 231, 183)
            chosenHint.Text = Languages[CurrentLang].BoxWonBtn
            chosenHint.BackgroundColor3 = Color3.fromRGB(22, 163, 74)

            GachaResultBanner.Text = Languages[CurrentLang].BoxWonBanner
            GachaResultBanner.TextColor3 = Color3.fromRGB(110, 231, 183)

            Save24hKey(GetSecondsUntilMidnightGMT7())
            task.wait(0.8)

            LaunchTargetScriptSafe(function(errMsg)
                StatusMsg.Text = errMsg
                StatusMsg.TextColor3 = Color3.fromRGB(225, 90, 110)
            end)
        else
            chosenStroke.Color = Color3.fromRGB(190, 35, 68)
            chosenTitle.Text = Languages[CurrentLang].BoxLostTitle
            chosenTitle.TextColor3 = Color3.fromRGB(225, 90, 110)
            chosenHint.Text = Languages[CurrentLang].BoxLostBtn
            chosenHint.BackgroundColor3 = Color3.fromRGB(140, 25, 50)

            GachaResultBanner.Text = Languages[CurrentLang].BoxLostBanner
            GachaResultBanner.TextColor3 = Color3.fromRGB(225, 90, 110)

            task.wait(1.4)
            CloseGachaModal()
            isRollingMutex = false

            StatusMsg.Text = "📌 Mở trúng GetKey! Bấm 'Lấy Key (24 Tiếng)' để tiếp tục."
            StatusMsg.TextColor3 = Color3.fromRGB(203, 213, 225)
        end
    end

    Box1.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box1, Box2, Box1Stroke, Box1Mask, Box1Title, Box1Hint)
    end)

    Box2.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box2, Box1, Box2Stroke, Box2Mask, Box2Title, Box2Hint)
    end)

    QuickPasteBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(QuickPasteBtn)
        local pasted = false
        pcall(function()
            if getclipboard then
                InputBox.Text = getclipboard()
                pasted = true
            elseif fromclipboard then
                InputBox.Text = fromclipboard()
                pasted = true
            end
        end)
        if not pasted then
            InputBox:CaptureFocus()
        end
    end)

    local isTutorialDebounce = false
    TutorialBtn.MouseButton1Click:Connect(function()
        if isTutorialDebounce then return end
        isTutorialDebounce = true
        PlaySpringButton(TutorialBtn)

        if setclipboard then setclipboard(TutorialUrl) elseif toclipboard then toclipboard(TutorialUrl) end

        TutorialBtn.Text = "✔ Đã chép link HD"
        TutorialBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(110, 231, 183)

        task.delay(2.2, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
                StatusMsg.Text = Languages[CurrentLang].FooterText
                StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
            end
            isTutorialDebounce = false
        end)
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(GetKeyBtn)
        if setclipboard then setclipboard(KeyUrl) elseif toclipboard then toclipboard(KeyUrl) end

        GetKeyBtn.Text = "✔ Đã Chép Link (24H)"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(110, 231, 183)

        task.delay(2.2, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(190, 35, 68)
                StatusMsg.Text = Languages[CurrentLang].FooterText
                StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
            end
        end)
    end)

    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlaySpringButton(CheckKeyBtn)

        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(203, 213, 225)

        task.wait(0.25)
        local isKeyValid = VerifyAugV5Key(InputBox.Text)

        if isKeyValid then
            local bonusAdded = Save24hKey()
            CheckKeyBtn.Text = "✔ Thành Công"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
            if bonusAdded and bonusAdded > 0 then
                StatusMsg.Text = string.format("✔ Kích hoạt Key! (24H + %dH = %d Giờ)", bonusAdded, 24 + bonusAdded)
            else
                StatusMsg.Text = Languages[CurrentLang].Success
            end
            StatusMsg.TextColor3 = Color3.fromRGB(110, 231, 183)

            task.wait(0.3)
            LaunchTargetScriptSafe(function(errMsg)
                isChecking = false
                CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
                CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
                StatusMsg.Text = errMsg
                StatusMsg.TextColor3 = Color3.fromRGB(225, 90, 110)
            end)
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(225, 90, 110)

            InputStroke.Color = Color3.fromRGB(190, 35, 68)
            local origOffset = MainFrame.Position.X.Offset
            for _, off in ipairs({ -5, 5, -3, 3, 0 }) do
                local t = TweenService:Create(MainFrame, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0.5, off, 0.5, 0)
                })
                t:Play()
                t.Completed:Wait()
            end
            MainFrame.Position = UDim2.new(0.5, origOffset, 0.5, 0)
            task.wait(0.4)
            InputStroke.Color = Color3.fromRGB(40, 46, 60)
        end
    end)

    OpenLangBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(OpenLangBtn)
        CurrentLang = (CurrentLang == "VI") and "EN" or "VI"
        local data = Languages[CurrentLang]
        local sp = LoadSpinDataToday()

        OpenLangBtn.Text = data.LangBtnText
        TitleLabel.Text = data.Title
        SubTitleLabel.Text = data.Subtitle
        CenterTitle.Text = data.CenterTitle
        CenterSub.Text = data.CenterSub
        InputBox.PlaceholderText = data.Placeholder
        QuickPasteBtn.Text = data.QuickPaste
        GetKeyBtn.Text = data.GetKey
        CheckKeyBtn.Text = data.CheckKey
        TutorialBtn.Text = data.Tutorial
        MiniGameBtn.Text = CanPlayGachaToday() and data.MiniGameBox or data.MiniGameBoxLocked
        SpinGameBtn.Text = (not sp.Played) and data.MiniGameSpin or string.format(data.MiniGameSpinLocked, sp.BonusHours)
        NoticeText.Text = data.Notice
        StatusMsg.Text = data.FooterText

        GachaHeader.Text = data.GachaTitle
        GachaSubText.Text = data.GachaSub
        Box1Tag.Text = data.Rate5050
        Box2Tag.Text = data.Rate5050
        Box1Title.Text = data.Box1Name
        Box2Title.Text = data.Box2Name
        Box1Hint.Text = data.OpenBoxBtn
        Box2Hint.Text = data.OpenBoxBtn
        GachaResultBanner.Text = data.BoxBannerIdle

        SpinHeader.Text = data.SpinTitle
        SpinSubText.Text = data.SpinSub
        SpinFooterNote.Text = data.SpinNote
        Title1.Text = data.Prize2H
        Title2.Text = data.Prize3H
        Title3.Text = data.Prize4H
        Title4.Text = data.Prize12H
        TriggerSpinBtn.Text = (not sp.Played) and data.SpinBtnText or data.SpinDoneText
    end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.88
    TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
end

-- =========================================================================
--   LUỒNG CHÍNH: NẾU ĐÃ CÓ KEY HỢP LỆ THÌ CHẠY THẲNG SCRIPT GỐC
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("Aug Hub V5 • Key System", keyTimeLeft, Color3.fromRGB(190, 35, 68), 4)
    LaunchTargetScriptSafe(nil)
    return
end

local vaultData = LoadMasterVault()
if not vaultData.TrialStart then
    vaultData.TrialStart = os.time()
    vaultData.LastSeen = os.time()
    SaveMasterVault(vaultData)
end

if vaultData.Tampered then
    ApplyScreenLockdown()
    ShowLiveToast("Aug Hub V5 • Key System", 0, Color3.fromRGB(225, 90, 110), 5)
    OpenKeySystemUI()
    return
end

local targetEndTime = vaultData.TrialStart + TRIAL_DURATION
local remaining = targetEndTime - os.time()

if remaining <= 0 then
    ApplyScreenLockdown()
    ShowLiveToast("HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(190, 35, 68), 5)
    OpenKeySystemUI()
    return
else
    ShowLiveToast("Aug Hub V5 • Dùng thử 2 phút", remaining, Color3.fromRGB(190, 35, 68), 8)
    TakeGuiSnapshot()
    LaunchTargetScriptSafe(nil)

    task.spawn(function()
        local saveInterval = 0
        while true do
            task.wait(1)
            if GetKeyRemainingTime() then
                break
            end

            local currentRemaining = targetEndTime - os.time()
            if ActiveToastLabel and ActiveToastLabel.Parent then
                ActiveToastLabel.Text = "Thời hạn còn lại: " .. FormatTime(currentRemaining)
            end

            saveInterval = saveInterval + 1
            if saveInterval >= 10 then
                saveInterval = 0
                local v = LoadMasterVault()
                v.LastSeen = os.time()
                SaveMasterVault(v)
            end

            if currentRemaining <= 0 then
                local v = LoadMasterVault()
                v.LastSeen = os.time()
                SaveMasterVault(v)
                TerminateTargetScript()
                ApplyScreenLockdown()
                ShowLiveToast("HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(190, 35, 68), 5)
                task.wait(0.2)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
