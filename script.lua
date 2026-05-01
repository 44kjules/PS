-- ================================================
-- Add your pets here!
-- ================================================
print("v1.8")
local PETS = {
    ["Spring Bluebell Token"] = "rbxassetid://92541145782702",
    ["Spring Sunflower Token"] = "rbxassetid://115652718639246",
    ["Spring Rose Token"] = "rbxassetid://130170754174499",
    ["Insta-Plant Capsule"] = "rbxassetid://15554896248",
    ["Diamond Seed"] = "rbxassetid://15554896030",

    ["Placeholder"] = "Placeholder" -- DO NOT EDIT OR DELETE THIS LINE.
}

-- ================================================
-- Config
-- ================================================
local TARGET_PETS = {
    "Spring Bluebell Token"
}
local MAX_PRICE = 5
local BUY_MAX_QUANTITY = false   -- true = buy full available qty, false = use BUY_QUANTITY below
local BUY_QUANTITY = 1        -- only used if BUY_MAX_QUANTITY is false
local DELAY = 2

-- ================================================
-- Setup
-- ================================================
local function parseNumber(text)
    text = tostring(text):lower():gsub(",", ""):gsub("x", ""):gsub("%s+", "")
    local num, suffix = text:match("([%d%.]+)([kmb]?)")
    if not num then return 0 end
    num = tonumber(num) or 0
    if suffix == "k" then num = num * 1000
    elseif suffix == "m" then num = num * 1000000
    elseif suffix == "b" then num = num * 1000000000 end
    return math.floor(num)
end

local purchaseRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase")

-- ================================================
-- Validate pet names and build asset ID lookup
-- ================================================
local targetAssetIDs = {}
for _, petName in ipairs(TARGET_PETS) do
    local assetID = PETS[petName]
    if not assetID then
        warn("Pet name not found in PETS table: " .. petName .. " -- skipping!")
    else
        targetAssetIDs[assetID] = petName
        print("Queued: " .. petName .. " (" .. assetID .. ")")
    end
end

if next(targetAssetIDs) == nil then
    warn("No valid pets to snipe. Stopping.")
    return
end

print("Mode: " .. (BUY_MAX_QUANTITY and "Buy full quantity" or "Buy " .. BUY_QUANTITY .. " per booth"))

-- ================================================
-- Scan booths
-- ================================================
local allBooths = {}

for _, boothModel in ipairs(workspace.__THINGS.Booths:GetChildren()) do
    for _, descendant in ipairs(boothModel:GetDescendants()) do
        if descendant:IsA("ImageLabel") and targetAssetIDs[descendant.Image] then

            local uuidFrame = descendant.Parent.Parent.Parent
            local itemSlot = descendant.Parent

            local costLabel = nil
            for _, v in ipairs(uuidFrame:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Cost" then
                    costLabel = v
                    break
                end
            end

            local quantityLabel = itemSlot:FindFirstChild("Quantity")
            local price = costLabel and parseNumber(costLabel.ContentText) or 0
            local qty = quantityLabel and parseNumber(quantityLabel.ContentText) or 0

            local current = uuidFrame
            local ownerID = nil
            while current do
                ownerID = current:GetAttribute("Owner")
                if ownerID then break end
                current = current.Parent
            end

            table.insert(allBooths, {
                petName = targetAssetIDs[descendant.Image],
                uuid = uuidFrame.Name,
                owner = ownerID,
                price = price,
                qty = qty,
                rawPrice = costLabel and costLabel.ContentText or "?"
            })
        end
    end
end

-- ================================================
-- Print all found booths
-- ================================================
print("\n=== ALL BOOTHS WITH TARGET PETS ===")
for _, b in ipairs(allBooths) do
    print(string.format("  [%s] Owner: %s | UUID: %s | Price: %s | Qty: %d", b.petName, tostring(b.owner), b.uuid, b.rawPrice, b.qty))
end

-- ================================================
-- Filter by max price
-- ================================================
local targets = {}
print("\n=== BOOTHS UNDER OR EQUAL TO MAX PRICE (" .. MAX_PRICE .. ") ===")
for _, b in ipairs(allBooths) do
    if b.price <= MAX_PRICE then
        print(string.format("  [%s] Owner: %s | UUID: %s | Price: %s | Qty: %d", b.petName, tostring(b.owner), b.uuid, b.rawPrice, b.qty))
        table.insert(targets, b)
    end
end

if #targets == 0 then
    print("  None found under max price. Stopping.")
    return
end

-- ================================================
-- Snipe!
-- ================================================
print("\n=== SNIPING ===")
for _, b in ipairs(targets) do
    local qtyToBuy = BUY_MAX_QUANTITY and b.qty or BUY_QUANTITY
    print(string.format("Buying [%s] from Owner: %s | UUID: %s | Price: %s | Qty to buy: %d", b.petName, tostring(b.owner), b.uuid, b.rawPrice, qtyToBuy))

    local args = {
        b.owner,
        {
            [b.uuid] = qtyToBuy
        },
        {
            Caller = {
                LineNumber = 527,
                ScriptClass = "ModuleScript",
                Variadic = false,
                Traceback = "ReplicatedStorage.Library.Client.BoothCmds:527 function PromptPurchase2\nReplicatedStorage.Library.Client.BoothCmds:654 function promptOtherPlayerBooth2\nReplicatedStorage.Library.Client.BoothCmds:996",
                ScriptPath = "ReplicatedStorage.Library.Client.BoothCmds",
                FunctionName = "PromptPurchase2",
                Handle = "function: 0x7314c5d694817056",
                ScriptType = "Instance",
                ParameterCount = 2,
                SourceIdentifier = "ReplicatedStorage.Library.Client.BoothCmds"
            }
        }
    }

    local success, result = pcall(function()
        return purchaseRemote:InvokeServer(unpack(args))
    end)

    if success then
        print("  Purchase fired successfully! Result:", tostring(result))
    else
        warn("  Purchase failed! Error:", tostring(result))
    end

    task.wait(DELAY)
end

print("\n=== DONE! Purchased from " .. #targets .. " booth(s) ===")