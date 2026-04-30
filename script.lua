local petScroll = workspace.__THINGS.Booths:GetChildren()[1].Pets.BoothTop.PetScroll

for _, itemFrame in ipairs(petScroll:GetChildren()) do
    if not itemFrame:IsA("Frame") then continue end
    
    local buyButton = itemFrame:FindFirstChild("Buy")
    if not buyButton then continue end
    
    local costLabel = buyButton:FindFirstChild("Cost")
    
    print("Frame:", itemFrame.Name)
    print("  Buy button found:", tostring(buyButton ~= nil))
    print("  Cost label found:", tostring(costLabel ~= nil))
    if costLabel then
        print("  Cost label class:", costLabel.ClassName)
        print("  Cost label text:", costLabel.Text)
    end
    
    -- Also dump ALL children of buy button just in case
    print("  All Buy children:")
    for _, child in pairs(buyButton:GetChildren()) do
        print("   -", child.ClassName, "|", child.Name)
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            print("     Text:", child.Text)
        end
    end
    
    break
end
