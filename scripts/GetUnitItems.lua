Callbacks.Bind("Run", function()
    if War3.WorldInitialized then
        if (GetAsyncKeyState(33) % 2 ~= 0) then  -- VK_PRIOR(Page Up)
            local unit = War3.GetSelectedUnit()
            if unit then                
                for i = 0, 5 do
                    local itemId = War3.GetUnitItem(unit, i)
                    print(itemId)
                end
            end
        end
    end
end)
