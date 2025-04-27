Callbacks.Bind('IsBannedUnit', function (unit)
    if (unit.Color & 0x00FFFFFF) == 0x00262626 then
        return true
    end
    return false
end)