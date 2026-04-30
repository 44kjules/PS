-- ================================================
-- Booth Sniper | Mod Tool
-- ================================================

local RS = game:GetService("ReplicatedStorage")

-- Remote
local purchaseRemote = RS:WaitForChild("Network"):WaitForChild("Booths_RequestPurchase")

-- ================================================
-- Asset ID -> Item Name table
-- Add new items here as needed!
-- ================================================
local ITEM_NAMES = {
    ["rbxassetid://92541145782702"] = "Blue Bell Token",
    -- ["rbxassetid://XXXXXXXXXX"] = "Item Name Here",
    -- ["rbxassetid://XXXXXXXXXX"] = "Item Name Here",
}

-- ================================================
-- Sniper config (set by mod before running)
-- ================================================
local TARGET_ITEM_NAME = "Blue Bell Token"  -- must match a name in ITEM_NAMES
local MAX_PRICE = 10
local BUY_QUANTITY = 100

-- ================================================
-- Helper: parse number text e.g. "35m", "1.5k", "1b", "600" -> number
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

-- ================================================
-- Helper: safe InvokeServer with timeout
-- ================================================
local INVOKE_TIMEOUT = 10

local function safeInvoke(remote, ...)
    local args = { ... }
    local result = nil
    local done = false

    task.spawn(function()
        result = remote:InvokeServer(unpack(args))
        done = true
    end)

    local elapsed = 0
    while not done and elapsed < INVOKE_TIMEOUT do
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end

    if not done then
        warn("[BoothSniper] InvokeServer timed out after " .. INVOKE_TIMEOUT .. "s")
    end

    return result
end

-- ================================================
-- Helper: find target asset ID from name table
-- ================================================
local function getAssetIdForName(name)
    for assetId, itemName in pairs(ITEM_NAMES) do
        if itemName == name then
            return assetId
        end
    end
    return nil
end

-- ================================================
-- Main sniper function
-- ================================================
local function sniperScan()
    local boothsFolder = workspace:FindFirstChild("__THINGS") and
                         workspace.__THINGS:FindFirstChild("Booths")

    if not boothsFolder then
        warn("[BoothSniper] Could not find Booths folder in workspace.__THINGS")
        return
    end

    -- Get the asset ID we're looking for
    local targetAssetId = getAssetIdForName(TARGET_ITEM_NAME)
    if not targetAssetId then
        warn("[BoothSniper] Item name not found in ITEM_NAMES table: " .. TARGET_ITEM_NAME)
        return
    end

    print("[BoothSniper] Scanning for: " .. TARGET_ITEM_NAME .. " (" .. targetAssetId .. ")")

    local found = 0

    for _, boothModel in ipairs(boothsFolder:GetChildren()) do
        if not boothModel:IsA("Model") then continue end

        local ownerID = boothModel:GetAttribute("owner")
        if not ownerID then continue end

        local petsFrame = boothModel:FindFirstChild("Pets")
        if not petsFrame then continue end

        local boothTop = petsFrame:FindFirstChild("BoothTop")
        if not boothTop then continue end

        local petScroll = boothTop:FindFirstChild("PetScroll")
        if not petScroll then continue end

        -- Scan each UUID frame in this booth
        for _, itemFrame in ipairs(petScroll:GetChildren()) do
            if not itemFrame:IsA("Frame") then continue end

            -- Navigate to the icon
            local holder = itemFrame:FindFirstChild("Holder")
            if not holder then continue end

            local itemSlot = holder:FindFirstChild("ItemSlot")
            if not itemSlot then continue end

            local icon = itemSlot:FindFirstChild("Icon")
            if not icon or not icon:IsA("ImageLabel") then continue end

            -- Check if this item's image matches our target
            if icon.Image ~= targetAssetId then continue end

            -- Found a match! Now get price
            local buyButton = itemFrame:FindFirstChild("Buy")
            if not buyButton then continue end

            local costLabel = buyButton:FindFirstChild("Cost")
            if not costLabel then continue end

            local price = parseNumber(costLabel.Text)

            -- Get quantity
            local quantityLabel = itemSlot:FindFirstChild("Quantity")
            local qty = quantityLabel and parseNumber(quantityLabel.Text) or 0

            print(string.format("[BoothSniper] Found %s at booth owned by %s | Price: %s | Qty: %s",
                TARGET_ITEM_NAME, tostring(ownerID), tostring(price), tostring(qty)))

            -- Price check
            if price <= MAX_PRICE and qty > 0 then
                local itemUUID = itemFrame.Name

                print(string.format("[BoothSniper] Sniping! UUID: %s | Buying %d...", itemUUID, BUY_QUANTITY))

                safeInvoke(purchaseRemote,
                    ownerID,
                    { [itemUUID] = BUY_QUANTITY },
                    {}
                )

                found = found + 1
            end
        end
    end

    if found == 0 then
        print("[BoothSniper] Scan complete. No matching booths found under max price.")
    else
        print(string.format("[BoothSniper] Done! Purchased from %d booth(s).", found))
    end
end

-- ================================================
-- Run
-- ================================================
sniperScan()
