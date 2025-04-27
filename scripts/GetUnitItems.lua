function GetUnitItems(unit)
    local items = {}
    for i = 0, 5 do
        local itemId = War3.GetUnitItem(unit, i)
        if itemId then
            table.insert(items, itemId)
        end
    end
    return items
end

Callbacks.Bind("Run", function()
    if War3.WorldInitialized then
        if (GetAsyncKeyState(33) % 2 ~= 0) then  -- VK_PRIOR(Page Up)
            local unit = War3.GetSelectedUnit()
            if unit then
                local items = GetUnitItems(unit)
                
                local message = "선택한 유닛의 아이템 목록:"
                for i, itemId in ipairs(items) do
                    message = message .. "\n" .. i .. ". " .. itemId
                end
                
                print(message)
            else
                print("선택한 유닛이 없습니다.")
            end
        end
    end
end)
