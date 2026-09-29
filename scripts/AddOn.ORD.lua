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

          if unit and (unit.owner == 27 or unit.owner == 15) then
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

local goroseiUnitsDetected = {
  ["E20o"] = false, -- 워큐리
  ["130o"] = false, -- 새턴
  ["230o"] = false, -- 나스쥬로
}

-- getUnitAbility()가 반환하는 코드가 역방향이므로 역방향 코드를 키로 사용
local trackedAbilities = {
  ["VK0A"] = "A0KV",
  ["A31A"] = "A13A",
  ["431A"] = "A134",
  ["WK0A"] = "A0KW",
  ["YK0A"] = "A0KY",
  ["XK0A"] = "A0KX",
  ["9P0A"] = "A0P9",
  ["8P0A"] = "A0P8",
  ["BP0A"] = "A0PB",
  ["AP0A"] = "A0PA",
}

local trackedAbilitiesDetected = {
  ["A0KV"] = false, -- 원피스
  ["A13A"] = false, -- 그린블러드 부여
  ["A134"] = false, -- 그린블러드 강화효과
  ["A0KW"] = false, -- 강렬함
  ["A0KY"] = false, -- 냉철함
  ["A0KX"] = false, -- 신속함
  ["A0P9"] = false, -- 기후 변화
  ["A0P8"] = false, -- 카리스마
  ["A0PB"] = false, -- 식량 보급
  ["A0PA"] = false, -- 해상 디너
}

local inventoryItems = {
  ["100I"] = "AI00", -- 우타의 헤드셋
  ["000I"] = "AI01", -- 태양신의 흔적
  ["200I"] = "AI02", -- 불사조의 깃털
  ["300I"] = "AI03", -- 흑도 슈스이
}

local inventoryItemsDetected = {
  ["AI00"] = false,
  ["AI01"] = false,
  ["AI02"] = false,
  ["AI03"] = false,
}

callbacks.bind("OnUnitBanEvaluate", function(handle, info)
  -- TMO의 유닛 검사 과정에서 오로성 기록
  if info and goroseiUnitsDetected[info.typeId] ~= nil then
    goroseiUnitsDetected[info.typeId] = true
  end

  -- 내 유닛이 가진 어빌리티 중 특정 어빌리티 기록
  local playerId = war3.getLocalPlayer()
  if info and info.owner == playerId then
    local abilities = war3.getUnitAbility(handle)

    if abilities then
      for _, abilityId in ipairs(abilities) do
        local responseCode = trackedAbilities[abilityId]

        if responseCode then
          trackedAbilitiesDetected[responseCode] = true
        end
      end
    end

    -- 내 유닛 인벤토리의 특정 아이템 기록
    if war3.getUnitHasInventory(handle) then
      for slot = 0, 5 do
        local itemId = war3.getUnitItem(handle, slot)

        local responseCode = itemId and inventoryItems[itemId]

        if responseCode then
          inventoryItemsDetected[responseCode] = true
        end
      end
    end
  end

  if info and (info.vertexColor & 0x00FFFFFF) == 0x00262626 then
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
	
  -- 기록지침 어빌리티 또는 인벤토리 아이템 중 하나라도 존재하면 보유로 처리
  for _, value in ipairs(items) do
    local detected = war3.getPlayerAbilityAvailable(playerId, value:reverse())

    if inventoryItemsDetected[value] then
      detected = true
    end

    setCustomResponse(value, detected and 1 or 0)
  end

  -- 오로성 상태 전달 후 초기화
  for typeId, detected in pairs(goroseiUnitsDetected) do
    setCustomResponse(typeId, detected and 1 or 0)
    goroseiUnitsDetected[typeId] = false
  end

  -- 특정 어빌리티 상태 전달 후 초기화
  for abilityId, detected in pairs(trackedAbilitiesDetected) do
    setCustomResponse(abilityId, detected and 1 or 0)
    trackedAbilitiesDetected[abilityId] = false
  end

  -- 특정 아이템 상태 초기화
  for abilityId in pairs(inventoryItemsDetected) do
    inventoryItemsDetected[abilityId] = false
  end
end)
