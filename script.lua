local RS = game:GetService("ReplicatedStorage")

-- ================================================
-- DEBUG: Check booths folder exists
-- ================================================
local thingsFolder = workspace:FindFirstChild("__THINGS")
if not thingsFolder then
    warn("FAIL: Could not find __THINGS in workspace")
    return
end
print("OK: Found __THINGS")

local boothsFolder = thingsFolder:FindFirstChild("Booths")
if not boothsFolder then
    warn("FAIL: Could not find Booths inside __THINGS")
    return
end
print("OK: Found Booths folder | Children count:", #boothsFolder:GetChildren())

-- ================================================
-- DEBUG: Loop booths
-- ================================================
for _, boothModel in ipairs(boothsFolder:GetChildren()) do
    print("  Booth:", boothModel.Name, "| Class:", boothModel.ClassName)

    local ownerID = boothModel:GetAttribute("owner")
    print("    Owner attribute:", tostring(ownerID))

    local petsFrame = boothModel:FindFirstChild("Pets")
    if not petsFrame then print("    SKIP: No Pets child") continue end
    print("    OK: Found Pets")

    local boothTop = petsFrame:FindFirstChild("BoothTop")
    if not boothTop then print("    SKIP: No BoothTop child") continue end
    print("    OK: Found BoothTop")

    local petScroll = boothTop:FindFirstChild("PetScroll")
    if not petScroll then print("    SKIP: No PetScroll child") continue end
    print("    OK: Found PetScroll | Item frames:", #petScroll:GetChildren())

    -- ================================================
    -- DEBUG: Loop item frames
    -- ================================================
    for _, itemFrame in ipairs(petScroll:GetChildren()) do
        print("      Frame:", itemFrame.Name, "| Class:", itemFrame.ClassName)

        local holder = itemFrame:FindFirstChild("Holder")
        if not holder then print("        SKIP: No Holder") continue end

        local itemSlot = holder:FindFirstChild("ItemSlot")
        if not itemSlot then print("        SKIP: No ItemSlot") continue end

        local icon = itemSlot:FindFirstChild("Icon")
        if not icon then print("        SKIP: No Icon") continue end
        if not icon:IsA("ImageLabel") then print("        SKIP: Icon is not ImageLabel, it's", icon.ClassName) continue end

        print("        Icon.Image:", icon.Image)

        local buyButton = itemFrame:FindFirstChild("Buy")
        if not buyButton then print("        SKIP: No Buy button") continue end

        local price = buyButton:GetAttribute("Cost")
        print("        Cost attribute:", tostring(price))

        local quantityLabel = itemSlot:FindFirstChild("Quantity")
        print("        Quantity text:", quantityLabel and quantityLabel.Text or "NOT FOUND")
    end
end
