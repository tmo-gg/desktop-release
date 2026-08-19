local function contains(arr, target)
    for _, value in ipairs(arr) do
        if value == target then
            return true
        end
    end
    return false
end

local function getEvolutionUnit(playerId)
  local x, y = war3.getPlayerStartLocation(playerId)

  local units = war3.getUnitHandle()

  if units then
      for _, realHandle in ipairs(units) do
          local unit = war3.getUnit(realHandle)

          if unit and unit.owner == 27 then
              if unit.x == x and unit.y == y then
                local abilities = war3.getUnitAbility(realHandle)
                if abilities and contains(abilities, '2enA') then
                  return unit.typeId
                end
              end
          end
      end
  end
  
  return nil
end

callbacks.bind("OnUnitBanEvaluate", function(handle, info)
  if (info.vertexColor & 0x00FFFFFF) == 0x00262626 then
    return true
  else
    return false
  end
end)

callbacks.bind("OnResponse", function()
  local playerId = war3.getLocalPlayer()
  local evolutionUnit = getEvolutionUnit(playerId)
  
  if evolutionUnit then
    setCustomResponse(evolutionUnit, 1)
  end
  
  local items = {"AI00", "AI01", "AI02", "AI03",
    "AI04", "AI05", "AI06", "AI07", "AI08", "AI09",
    "AI10", "AI11", "AI12", "AI13", "AI14", "AI15",
    "AI16", "AI17", "AI18", "AI19", "AI20", "AI21"}
  for index, value in ipairs(items) do
    if war3.getPlayerAbilityAvailable(playerId, value:reverse()) then
      setCustomResponse(value, 1)
    end
  end  

end)

