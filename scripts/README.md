# TMO.GG 루아 스크립팅 가이드

이 문서는 TMO.GG 클라이언트에서 사용 가능한 루아 스크립팅 API에 대한 완전한 가이드입니다.

## 목차

- [기본 함수](#기본-함수)
- [콜백 시스템](#콜백-시스템)
- [War3 API](#war3-api)
  - [게임 상태](#게임-상태)
  - [맵 정보](#맵-정보)
  - [플레이어 정보](#플레이어-정보)
  - [카메라 제어](#카메라-제어)
  - [유닛 정보](#유닛-정보)
  - [타이머](#타이머)
  - [JASS 인터페이스](#jass-인터페이스)
- [StormLib API](#stormlib-api)
  - [MPQ 아카이브 관리](#mpq-아카이브-관리)
  - [파일 작업](#파일-작업)
  - [파일 검색](#파일-검색)
- [상수](#상수)
  - [플레이어 상태](#플레이어-상태-상수)
  - [종족](#종족-상수)
  - [플레이어 슬롯 상태](#플레이어-슬롯-상태-상수)
  - [카메라 필드](#카메라-필드-상수)
  - [StormLib 상수](#stormlib-상수)

---

## 기본 함수

### `print(message)`
콘솔에 메시지를 출력합니다.

**매개변수:**
- `message` (string): 출력할 메시지

**예제:**
```lua
print("Hello, World!")
```

---

### `directoryExists(path)`
디렉토리가 존재하는지 확인합니다.

**매개변수:**
- `path` (string): 확인할 디렉토리 경로

**반환값:**
- (boolean): 디렉토리가 존재하면 `true`, 아니면 `false`

**예제:**
```lua
if directoryExists("C:\\War3") then
    print("워크래프트 3 디렉토리가 존재합니다")
end
```

---

### `fileExists(path)`
파일이 존재하는지 확인합니다.

**매개변수:**
- `path` (string): 확인할 파일 경로

**반환값:**
- (boolean): 파일이 존재하면 `true`, 아니면 `false`

**예제:**
```lua
if fileExists("config.ini") then
    print("설정 파일이 존재합니다")
end
```

---

### `getFiles(directory)`
디렉토리의 모든 파일 목록을 가져옵니다.

**매개변수:**
- `directory` (string): 검색할 디렉토리 경로

**반환값:**
- (table): 파일 전체 경로 배열

**예제:**
```lua
local files = getFiles("C:\\Scripts")
for i, file in ipairs(files) do
    print(file)
end
```

---

### `getAsyncKeyState(vkCode)`
키보드 키의 현재 상태를 확인합니다.

**매개변수:**
- `vkCode` (number): 가상 키 코드 (VK_* 상수)

**반환값:**
- (number): Windows API `GetAsyncKeyState`의 반환값
  - 최상위 비트(0x8000)가 설정되어 있으면 키가 현재 눌려있음
  - 최하위 비트(0x0001)가 설정되어 있으면 키가 이전 호출 이후 눌렸음

**예제:**
```lua
-- F1 키 확인 (VK_F1 = 0x70)
local state = getAsyncKeyState(0x70)
if state & 0x8000 ~= 0 then
    print("F1 키가 눌려있습니다")
end

-- 또는 간단하게 음수 체크 (최상위 비트가 설정되면 음수)
if getAsyncKeyState(0x70) < 0 then
    print("F1 키가 눌려있습니다")
end
```

---

### `setCustomResponse(key, value)`
커스텀 응답 데이터를 설정합니다.

**매개변수:**
- `key` (string): 키
- `value` (number): 정수 값

**예제:**
```lua
setCustomResponse("level", 10)
setCustomResponse("score", 1500)
setCustomResponse("status", 1)  -- 0=비활성, 1=활성 등
```

---

## 콜백 시스템

콜백 시스템을 사용하면 특정 이벤트가 발생할 때 루아 함수를 자동으로 호출할 수 있습니다.

### 사용 가능한 이벤트

#### `OnTick`
게임이 실행 중일 때 주기적으로 호출됩니다 (약 100ms마다).

**콜백 함수 형식:**
```lua
function()
```

**예제:**
```lua
callbacks.bind("OnTick", function()
    -- 게임이 실행 중일 때 주기적으로 실행
    local gold = war3.getPlayerState(war3.getLocalPlayer(), PLAYER_STATE_RESOURCE_GOLD)
    if gold > 10000 then
        print("골드가 10000을 초과했습니다!")
    end
end)
```

---

#### `OnResponse`
웹 API 응답을 생성할 때 호출됩니다. `setCustomResponse`로 설정한 데이터를 응답에 포함시킬 수 있습니다.

**콜백 함수 형식:**
```lua
function()
```

**예제:**
```lua
callbacks.bind("OnResponse", function()
    local player = war3.getLocalPlayer()
    local gold = war3.getPlayerState(player, PLAYER_STATE_RESOURCE_GOLD)
    local lumber = war3.getPlayerState(player, PLAYER_STATE_RESOURCE_LUMBER)
    
    setCustomResponse("myGold", gold)
    setCustomResponse("myLumber", lumber)
end)
```

---

#### `OnUnitBanEvaluate`
각 유닛이 밴 대상인지 평가할 때 호출됩니다. 유닛을 숨기거나 필터링하는 데 사용됩니다.

**콜백 함수 형식:**
```lua
function(realHandle, unitInfo)
```

**매개변수:**
- `realHandle` (lightuserdata): 유닛의 realHandle
- `unitInfo` (table): 유닛 정보 테이블
  - `typeId` (string): 유닛 타입 ID (4글자)
  - `owner` (number): 소유자 플레이어 인덱스
  - `vertexColor` (number): 버텍스 컬러
  - `x` (number): X 좌표
  - `y` (number): Y 좌표
  - `z` (number): Z 좌표

**반환값:**
- (boolean): `true`를 반환하면 해당 유닛이 밴됨 (숨김 처리)

**예제:**
```lua
-- 특정 유닛 타입을 숨기기
callbacks.bind("OnUnitBanEvaluate", function(realHandle, unitInfo)
    -- 'hfoo' (보병) 유닛을 숨김
    if unitInfo.typeId:reverse() == "hfoo" then
        return true
    end
    
    -- 특정 플레이어의 유닛만 숨김
    if unitInfo.owner == 5 then
        return true
    end
    
    -- 특정 영역의 유닛 숨김
    if unitInfo.x > 1000 and unitInfo.y > 1000 then
        return true
    end
    
    return false
end)
```

---

### 콜백 관리 함수

#### `callbacks.bind(eventName, function)`
이벤트에 콜백 함수를 바인딩합니다.

**매개변수:**
- `eventName` (string): 이벤트 이름 (`"OnTick"`, `"OnResponse"`, `"OnUnitBanEvaluate"`)
- `function` (function): 호출될 콜백 함수

**반환값:**
- (lightuserdata): 콜백 핸들 (제거 시 사용)

**예제:**
```lua
local handle = callbacks.bind("OnTick", function()
    print("틱 이벤트 발생")
end)
```

---

#### `callbacks.remove(handle)`
바인딩된 콜백을 제거합니다.

**매개변수:**
- `handle` (lightuserdata): `callbacks.bind`에서 반환된 핸들

**반환값:**
- (boolean): 성공 여부

**예제:**
```lua
local handle = callbacks.bind("OnTick", function() end)
-- 나중에 제거
callbacks.remove(handle)
```

---

## War3 API

### 게임 상태

#### `war3.isRunning()`
워크래프트 3가 실행 중인지 확인합니다.

**반환값:**
- (boolean): 실행 중이면 `true`

**예제:**
```lua
if war3.isRunning() then
    print("워크래프트 3가 실행 중입니다")
end
```

---

#### `war3.hasWorld()`
게임 월드가 로드되었는지 확인합니다 (게임 중인지).

**반환값:**
- (boolean): 게임 중이면 `true`

**예제:**
```lua
if war3.hasWorld() then
    print("게임이 진행 중입니다")
end
```

---

#### `war3.isChatAvailable()`
채팅이 사용 가능한지 확인합니다.

**반환값:**
- (boolean): 채팅 가능하면 `true`

---

### 입력 제어

#### `war3.sendInput(input)`
게임에 키보드 입력을 전송합니다.

**매개변수:**
- `input` (number): 전송할 입력 값

**예제:**
```lua
war3.sendInput(27)  -- ESC 키
```

---

#### `war3.sendChat(message)`
게임 채팅에 메시지를 전송합니다.

**매개변수:**
- `message` (string): 채팅 메시지

**예제:**
```lua
war3.sendChat("Hello everyone!")
```

---

### 맵 정보

#### `war3.getMapName()`
현재 맵의 이름을 가져옵니다.

**반환값:**
- (string): 맵 이름

**예제:**
```lua
local mapName = war3.getMapName()
print("현재 맵: " .. mapName)
```

---

#### `war3.getMapFileName()`
현재 맵의 파일 이름을 가져옵니다.

**반환값:**
- (string): 맵 파일 이름

**예제:**
```lua
local fileName = war3.getMapFileName()
print("맵 파일: " .. fileName)
```

---

### 플레이어 정보

#### `war3.getLocalPlayer()`
로컬 플레이어의 인덱스를 가져옵니다.

**반환값:**
- (number): 플레이어 인덱스

**예제:**
```lua
local playerIndex = war3.getLocalPlayer()
print("내 플레이어 번호: " .. playerIndex)
```

---

#### `war3.getPlayerName(playerIndex)`
플레이어의 이름을 가져옵니다.

**매개변수:**
- `playerIndex` (number): 플레이어 인덱스

**반환값:**
- (string): 플레이어 이름

**예제:**
```lua
local name = war3.getPlayerName(0)
print("플레이어 0: " .. name)
```

---

#### `war3.getPlayerTeam(playerIndex)`
플레이어의 팀을 가져옵니다.

**매개변수:**
- `playerIndex` (number): 플레이어 인덱스

**반환값:**
- (number): 팀 번호

**예제:**
```lua
local team = war3.getPlayerTeam(0)
print("플레이어 0의 팀: " .. team)
```

---

#### `war3.getPlayerRace(playerIndex)`
플레이어의 종족을 가져옵니다.

**매개변수:**
- `playerIndex` (number): 플레이어 인덱스

**반환값:**
- (number): 종족 ID (RACE_* 상수 참조)

**예제:**
```lua
local race = war3.getPlayerRace(0)
if race == RACE_HUMAN then
    print("휴먼")
elseif race == RACE_ORC then
    print("오크")
end
```

---

#### `war3.getPlayerSlotState(playerIndex)`
플레이어 슬롯의 상태를 가져옵니다.

**매개변수:**
- `playerIndex` (number): 플레이어 인덱스

**반환값:**
- (number): 슬롯 상태 (PLAYER_SLOT_STATE_* 상수 참조)

**예제:**
```lua
local state = war3.getPlayerSlotState(0)
if state == PLAYER_SLOT_STATE_PLAYING then
    print("플레이 중")
end
```

---

#### `war3.getPlayerState(playerIndex, stateType)`
플레이어의 특정 상태 값을 가져옵니다.

**매개변수:**
- `playerIndex` (number): 플레이어 인덱스
- `stateType` (number): 상태 타입 (PLAYER_STATE_* 상수 참조)

**반환값:**
- (number): 상태 값

**예제:**
```lua
local gold = war3.getPlayerState(0, PLAYER_STATE_RESOURCE_GOLD)
local lumber = war3.getPlayerState(0, PLAYER_STATE_RESOURCE_LUMBER)
print("골드: " .. gold .. ", 목재: " .. lumber)
```

---

#### `war3.getPlayerAbilityAvailable(playerIndex, abilId)`
플레이어의 능력 활성화 값을 가져옵니다.

**매개변수:**
- `playerIndex` (number): 플레이어 인덱스
- `abilId` (string): 능력 ID

**반환값:**
- (boolean): 활성화 값

---

### 카메라 제어

#### `war3.getCameraPosition()`
카메라의 현재 위치를 가져옵니다.

**반환값:**
- (number, number): x, y 좌표

**예제:**
```lua
local x, y = war3.getCameraPosition()
print(string.format("카메라 위치: (%.2f, %.2f)", x, y))
```

---

#### `war3.setCameraPosition(x, y)`
카메라 위치를 설정합니다.

**매개변수:**
- `x` (number): X 좌표
- `y` (number): Y 좌표

**예제:**
```lua
war3.setCameraPosition(0, 0)
```

---

#### `war3.getCameraField(fieldType)`
카메라의 특정 필드 값을 가져옵니다.

**매개변수:**
- `fieldType` (number): 필드 타입 (CAMERA_FIELD_* 상수 참조)

**반환값:**
- (number): 필드 값

**예제:**
```lua
local distance = war3.getCameraField(CAMERA_FIELD_TARGET_DISTANCE)
print("카메라 거리: " .. distance)

local fov = war3.getCameraField(CAMERA_FIELD_FIELD_OF_VIEW)
print("시야각: " .. fov)
```

---

#### `war3.setCameraField(fieldType, value)`
카메라의 특정 필드 값을 설정합니다.

**매개변수:**
- `fieldType` (number): 필드 타입 (CAMERA_FIELD_* 상수 참조)
- `value` (number): 설정할 값

**예제:**
```lua
-- 카메라 거리 설정
war3.setCameraField(CAMERA_FIELD_TARGET_DISTANCE, 2000)

-- 카메라 회전 설정
war3.setCameraField(CAMERA_FIELD_ROTATION, 90)
```

---

### 유닛 정보

#### `war3.getObjectName(objectId)`
오브젝트의 이름을 가져옵니다.

**매개변수:**
- `objectId` (string): 오브젝트 ID (4글자)

**반환값:**
- (string): 오브젝트 이름

**예제:**
```lua
local name = war3.getObjectName("hfoo":reverse())
print("보병: " .. name)
```

---

#### `war3.getRealHandle(handleId)`
핸들 ID로부터 실제 핸들 주소를 가져옵니다.

**매개변수:**
- `handleId` (number): 핸들 ID

**반환값:**
- (number): 핸들 주소

---

#### `war3.getSelectedUnit()`
현재 선택된 유닛을 가져옵니다.

**반환값:**
- (number): 유닛 핸들

---

#### `war3.getUnitHandle()`
게임 내 모든 유닛의 realHandle을 가져옵니다.

**반환값:**
- (table): 유닛 realHandle 배열 (lightuserdata)

**예제:**
```lua
local units = war3.getUnitHandle()
if units then
    print("총 유닛 수: " .. #units)
    for i, realHandle in ipairs(units) do
        local unit = war3.getUnit(realHandle)
        if unit then
            print(string.format("유닛 %d: %s", i, unit.typeId))
        end
    end
end
```

---

#### `war3.getUnit(realHandle)`
유닛 realHandle로부터 유닛 정보를 가져옵니다.

**매개변수:**
- `realHandle` (lightuserdata): 유닛 realHandle

**반환값:**
- (table or nil): 유닛 정보 테이블 (유효하지 않으면 nil)
  - `typeId` (string): 유닛 타입 ID (4글자, 역순으로 저장됨)
  - `owner` (number): 소유자 플레이어 인덱스
  - `vertexColor` (number): 버텍스 컬러
  - `x` (number): X 좌표
  - `y` (number): Y 좌표
  - `z` (number): Z 좌표

**예제:**
```lua
local units = war3.getUnitHandle()
if units and #units > 0 then
    local unit = war3.getUnit(units[1])
    if unit then
        -- typeId는 역순으로 저장되어 있음
        print("유닛 타입: " .. unit.typeId:reverse())
        print("소유자: " .. unit.owner)
        print(string.format("위치: (%.2f, %.2f, %.2f)", unit.x, unit.y, unit.z))
        print("버텍스 컬러: " .. unit.vertexColor)
    end
end
```

---

#### `war3.getUnitHasInventory(realHandle)`
유닛이 인벤토리를 가지고 있는지 확인합니다.

**매개변수:**
- `realHandle` (lightuserdata): 유닛 realHandle

**반환값:**
- (boolean): 인벤토리 보유 여부

---

#### `war3.getUnitItem(realHandle, slot)`
유닛의 특정 슬롯에 있는 아이템을 가져옵니다.

**매개변수:**
- `realHandle` (lightuserdata): 유닛 realHandle
- `slot` (number): 아이템 슬롯 (0-5)

**반환값:**
- (string): 아이템 타입 ID (4글자, 역순으로 저장됨)

---

#### `war3.getUnitAbility(realHandle)`
유닛이 가진 모든 능력 목록을 가져옵니다.

**매개변수:**
- `realHandle` (lightuserdata): 유닛 realHandle

**반환값:**
- (table): 능력 ID 배열 (각 ID는 4글자 문자열, 역순으로 저장됨)

**예제:**
```lua
local units = war3.getUnitHandle()
if units and #units > 0 then
    local abilities = war3.getUnitAbility(units[1])
    if abilities then
        print("유닛의 능력 목록:")
        for i, abilityId in ipairs(abilities) do
            -- abilityId는 역순으로 저장되어 있음
            print(string.format("%d. %s", i, abilityId:reverse()))
        end
    end
end
```

---

### 타이머

#### `war3.getTimerRemaining(realHandle)`
타이머의 남은 시간을 가져옵니다.

**매개변수:**
- `realHandle` (lightuserdata): 타이머 realHandle

**반환값:**
- (number): 실수 값

---

### JASS 인터페이스

#### `war3.jass.variables()`
JASS 전역 변수 목록을 가져옵니다.

**반환값:**
- (table): 변수 정보 배열. 각 요소는 다음 필드를 포함:
  - `name` (string): 변수 이름
  - `type` (string): 변수 타입 ("real", "integer", "handle", "boolean", "string", "integerArray", "handleArray" 등)
  - `value` (any): 변수 값
    - real: number
    - integer/handle: integer
    - boolean: boolean
    - string: string
    - integerArray/handleArray: table (배열)

**예제:**
```lua
local vars = war3.jass.variables()
if vars then
    for i, var in ipairs(vars) do
        print(string.format("%s (%s) = %s", var.name, var.type, tostring(var.value)))
    end
end
```

---

#### `war3.jass.get(variableName)`
JASS 전역 변수의 값을 가져옵니다.

**매개변수:**
- `variableName` (string): 변수 이름

**반환값:**
- (any): 변수 값 (타입에 따라 다름)
  - real 타입: number
  - integer/handle 타입: integer
  - boolean 타입: boolean
  - string 타입: string
  - integerArray/handleArray 타입: table (인덱스는 1부터 시작)

**예제:**
```lua
-- 단일 값
local gold = war3.jass.get("udg_PlayerGold")
print("골드: " .. tostring(gold))

-- 배열
local scores = war3.jass.get("udg_PlayerScores")
if type(scores) == "table" then
    for i, score in ipairs(scores) do
        print(string.format("플레이어 %d 점수: %d", i-1, score))
    end
end

-- 문자열
local mapName = war3.jass.get("udg_MapName")
print("맵 이름: " .. mapName)
```

---

#### `war3.jass.loadBoolean(hashtable, parentKey, childKey)`
해시테이블에서 불린 값을 로드합니다.

**매개변수:**
- `hashtable` (number): 해시테이블 핸들
- `parentKey` (number): 부모 키
- `childKey` (number): 자식 키

**반환값:**
- (boolean): 불린 값

---

## StormLib API

StormLib는 Blizzard의 MPQ 아카이브 파일을 읽고 쓰기 위한 라이브러리입니다.

### MPQ 아카이브 관리

#### `stormlib.openArchive(mpqPath, priority, flags)`
MPQ 아카이브를 엽니다.

**매개변수:**
- `mpqPath` (string): MPQ 파일 경로
- `priority` (number, optional): 우선순위 (기본값: 0)
- `flags` (number, optional): 열기 플래그 (기본값: 0)

**반환값:**
- (lightuserdata, string): 아카이브 핸들, 에러 메시지 (실패 시)

**예제:**
```lua
local mpq, err = stormlib.openArchive("war3map.w3x", 0, MPQ_OPEN_READ_ONLY)
if not mpq then
    print("MPQ 열기 실패: " .. err)
    return
end
```

---

#### `stormlib.closeArchive(handle)`
MPQ 아카이브를 닫습니다.

**매개변수:**
- `handle` (lightuserdata): 아카이브 핸들

**반환값:**
- (boolean): 성공 여부

**예제:**
```lua
stormlib.closeArchive(mpq)
```

---

### 파일 작업

#### `stormlib.hasFile(handle, fileName)`
MPQ에 파일이 존재하는지 확인합니다.

**매개변수:**
- `handle` (lightuserdata): 아카이브 핸들
- `fileName` (string): 파일 이름

**반환값:**
- (boolean): 파일 존재 여부

**예제:**
```lua
if stormlib.hasFile(mpq, "war3map.j") then
    print("war3map.j 파일이 존재합니다")
end
```

---

#### `stormlib.openFile(handle, fileName, searchScope)`
MPQ에서 파일을 엽니다.

**매개변수:**
- `handle` (lightuserdata): 아카이브 핸들
- `fileName` (string): 파일 이름
- `searchScope` (number, optional): 검색 범위 (기본값: 0)

**반환값:**
- (lightuserdata, string): 파일 핸들, 에러 메시지 (실패 시)

**예제:**
```lua
local file, err = stormlib.openFile(mpq, "war3map.j")
if not file then
    print("파일 열기 실패: " .. err)
    return
end
```

---

#### `stormlib.closeFile(fileHandle)`
파일 핸들을 닫습니다.

**매개변수:**
- `fileHandle` (lightuserdata): 파일 핸들

**반환값:**
- (boolean): 성공 여부

**예제:**
```lua
stormlib.closeFile(file)
```

---

#### `stormlib.getFileSize(fileHandle)`
파일의 크기를 가져옵니다.

**매개변수:**
- `fileHandle` (lightuserdata): 파일 핸들

**반환값:**
- (number): 파일 크기 (바이트)

**예제:**
```lua
local size = stormlib.getFileSize(file)
print("파일 크기: " .. size .. " bytes")
```

---

#### `stormlib.readFile(fileHandle, bytesToRead)`
파일에서 데이터를 읽습니다.

**매개변수:**
- `fileHandle` (lightuserdata): 파일 핸들
- `bytesToRead` (number): 읽을 바이트 수

**반환값:**
- (string, string): 데이터, 에러 메시지 (실패 시)

**예제:**
```lua
local size = stormlib.getFileSize(file)
local data, err = stormlib.readFile(file, size)
if not data then
    print("파일 읽기 실패: " .. err)
else
    print("파일 내용: " .. data)
end
```

---

#### `stormlib.extractFile(handle, fileNameInMpq, targetPath, searchScope)`
MPQ에서 파일을 추출합니다.

**매개변수:**
- `handle` (lightuserdata): 아카이브 핸들
- `fileNameInMpq` (string): MPQ 내 파일 이름
- `targetPath` (string): 추출할 경로
- `searchScope` (number, optional): 검색 범위 (기본값: 0)

**반환값:**
- (boolean): 성공 여부

**예제:**
```lua
local success = stormlib.extractFile(mpq, "war3map.j", "extracted_map.j")
if success then
    print("파일 추출 완료")
end
```

---

### 파일 검색

#### `stormlib.findFirstFile(handle, mask, listFile)`
MPQ에서 파일 검색을 시작합니다.

**매개변수:**
- `handle` (lightuserdata): 아카이브 핸들
- `mask` (string): 검색 마스크 (예: "*", "*.txt")
- `listFile` (string, optional): 리스트 파일

**반환값:**
- (lightuserdata, string, number, number): 검색 핸들, 파일 이름, 파일 크기, 압축 크기

**예제:**
```lua
local findHandle, fileName, fileSize, compSize = stormlib.findFirstFile(mpq, "*")
if findHandle then
    print(string.format("%s - %d bytes (압축: %d)", fileName, fileSize, compSize))
end
```

---

#### `stormlib.findNextFile(findHandle)`
다음 파일을 찾습니다.

**매개변수:**
- `findHandle` (lightuserdata): 검색 핸들

**반환값:**
- (string, number, number): 파일 이름, 파일 크기, 압축 크기 (더 이상 없으면 nil)

**예제:**
```lua
while true do
    local fileName, fileSize, compSize = stormlib.findNextFile(findHandle)
    if not fileName then break end
    print(string.format("%s - %d bytes", fileName, fileSize))
end
```

---

#### `stormlib.findClose(findHandle)`
파일 검색 핸들을 닫습니다.

**매개변수:**
- `findHandle` (lightuserdata): 검색 핸들

**반환값:**
- (boolean): 성공 여부

**예제:**
```lua
stormlib.findClose(findHandle)
```

---

## 상수

### 플레이어 상태 상수

```lua
PLAYER_STATE_GAME_RESULT = 0
PLAYER_STATE_RESOURCE_GOLD = 1
PLAYER_STATE_RESOURCE_LUMBER = 2
PLAYER_STATE_RESOURCE_HERO_TOKENS = 3
PLAYER_STATE_RESOURCE_FOOD_CAP = 4
PLAYER_STATE_RESOURCE_FOOD_USED = 5
PLAYER_STATE_FOOD_CAP_CEILING = 6
PLAYER_STATE_GIVES_BOUNTY = 7
PLAYER_STATE_ALLIED_VICTORY = 8
PLAYER_STATE_PLACED = 9
PLAYER_STATE_OBSERVER_ON_DEATH = 10
PLAYER_STATE_OBSERVER = 11
PLAYER_STATE_UNFOLLOWABLE = 12
PLAYER_STATE_GOLD_UPKEEP_RATE = 13
PLAYER_STATE_LUMBER_UPKEEP_RATE = 14
PLAYER_STATE_GOLD_GATHERED = 15
PLAYER_STATE_LUMBER_GATHERED = 16
PLAYER_STATE_NO_CREEP_SLEEP = 25
```

---

### 종족 상수

```lua
RACE_HUMAN = 1
RACE_ORC = 2
RACE_UNDEAD = 3
RACE_NIGHTELF = 4
RACE_DEMON = 5
RACE_OTHER = 7
```

---

### 플레이어 슬롯 상태 상수

```lua
PLAYER_SLOT_STATE_EMPTY = 0
PLAYER_SLOT_STATE_PLAYING = 1
PLAYER_SLOT_STATE_LEFT = 2
```

---

### 카메라 필드 상수

```lua
CAMERA_FIELD_TARGET_DISTANCE = 0  -- 카메라 거리
CAMERA_FIELD_FARZ = 1             -- 원거리 클리핑 평면
CAMERA_FIELD_ANGLE_OF_ATTACK = 2  -- 공격 각도
CAMERA_FIELD_FIELD_OF_VIEW = 3    -- 시야각 (FOV)
CAMERA_FIELD_ROLL = 4             -- 롤 (기울기)
CAMERA_FIELD_ROTATION = 5         -- 회전
CAMERA_FIELD_ZOFFSET = 6          -- Z 오프셋
```

**예제:**
```lua
-- 카메라 거리 조정
local currentDistance = war3.getCameraField(CAMERA_FIELD_TARGET_DISTANCE)
war3.setCameraField(CAMERA_FIELD_TARGET_DISTANCE, currentDistance + 500)

-- 카메라 회전
war3.setCameraField(CAMERA_FIELD_ROTATION, 90)

-- 시야각 변경
war3.setCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 70)
```

---

### StormLib 상수

#### Base Provider 상수
```lua
BASE_PROVIDER_FILE = 0
BASE_PROVIDER_MAP = 1
BASE_PROVIDER_HTTP = 2
BASE_PROVIDER_MASK = 0xF
```

#### Stream Provider 상수
```lua
STREAM_PROVIDER_FLAT = 0
STREAM_PROVIDER_PARTIAL = 0x10
STREAM_PROVIDER_MPQE = 0x20
STREAM_PROVIDER_BLOCK4 = 0x30
STREAM_PROVIDER_MASK = 0xF0
```

#### Stream Flag 상수
```lua
STREAM_FLAG_READ_ONLY = 0x100
STREAM_FLAG_WRITE_SHARE = 0x200
STREAM_FLAG_USE_BITMAP = 0x400
STREAM_OPTIONS_MASK = 0xFF00
STREAM_PROVIDERS_MASK = 0xFF
STREAM_FLAGS_MASK = 0xFFFF
```

#### MPQ Open 플래그
```lua
MPQ_OPEN_NO_LISTFILE = 0x10000
MPQ_OPEN_NO_ATTRIBUTES = 0x20000
MPQ_OPEN_NO_HEADER_SEARCH = 0x40000
MPQ_OPEN_FORCE_MPQ_V1 = 0x80000
MPQ_OPEN_CHECK_SECTOR_CRC = 0x100000
MPQ_OPEN_PATCH = 0x20000
MPQ_OPEN_FORCE_LISTFILE = 0x400000
MPQ_OPEN_READ_ONLY = 0x100
```

#### SFileInfoClass 상수

**Archive Info:**
```lua
SFileMpqFileName, SFileMpqStreamBitmap, SFileMpqUserDataOffset,
SFileMpqUserDataHeader, SFileMpqUserData, SFileMpqHeaderOffset,
SFileMpqHeaderSize, SFileMpqHeader, SFileMpqHetTableOffset,
SFileMpqHetTableSize, SFileMpqHetHeader, SFileMpqHetTable,
SFileMpqBetTableOffset, SFileMpqBetTableSize, SFileMpqBetHeader,
SFileMpqBetTable, SFileMpqHashTableOffset, SFileMpqHashTableSize64,
SFileMpqHashTableSize, SFileMpqHashTable, SFileMpqBlockTableOffset,
SFileMpqBlockTableSize64, SFileMpqBlockTableSize, SFileMpqBlockTable,
SFileMpqHiBlockTableOffset, SFileMpqHiBlockTableSize64, SFileMpqHiBlockTable,
SFileMpqSignatures, SFileMpqStrongSignatureOffset, SFileMpqStrongSignatureSize,
SFileMpqStrongSignature, SFileMpqArchiveSize64, SFileMpqArchiveSize,
SFileMpqMaxFileCount, SFileMpqFileTableSize, SFileMpqSectorSize,
SFileMpqNumberOfFiles, SFileMpqRawChunkSize, SFileMpqStreamFlags, SFileMpqFlags
```

**File Info:**
```lua
SFileInfoPatchChain, SFileInfoFileEntry, SFileInfoHashEntry,
SFileInfoHashIndex, SFileInfoNameHash1, SFileInfoNameHash2,
SFileInfoNameHash3, SFileInfoLocale, SFileInfoFileIndex,
SFileInfoByteOffset, SFileInfoFileTime, SFileInfoFileSize,
SFileInfoCompressedSize, SFileInfoFlags, SFileInfoEncryptionKey,
SFileInfoEncryptionKeyRaw, SFileInfoCRC32, SFileInfoInvalid
```

---

## 완전한 예제

### MPQ 파일 분석기

```lua
-- MPQ 파일 열기
local mpq, err = stormlib.openArchive("war3map.w3x", 0, MPQ_OPEN_READ_ONLY)
if not mpq then
    print("MPQ 열기 실패: " .. err)
    return
end

print("=== MPQ 파일 분석 ===\n")

-- 모든 파일 나열
local findHandle, fileName, fileSize, compSize = stormlib.findFirstFile(mpq, "*")
if findHandle then
    print(string.format("%-50s %12s %12s %6s", "파일명", "크기", "압축크기", "비율"))
    print(string.rep("-", 82))
    
    -- 첫 번째 파일
    local ratio = (compSize / fileSize * 100)
    print(string.format("%-50s %12d %12d %5.1f%%", fileName, fileSize, compSize, ratio))
    
    -- 나머지 파일들
    while true do
        fileName, fileSize, compSize = stormlib.findNextFile(findHandle)
        if not fileName then break end
        
        ratio = (compSize / fileSize * 100)
        print(string.format("%-50s %12d %12d %5.1f%%", fileName, fileSize, compSize, ratio))
    end
    
    stormlib.findClose(findHandle)
end

-- 특정 파일 읽기
if stormlib.hasFile(mpq, "war3map.j") then
    local file = stormlib.openFile(mpq, "war3map.j")
    if file then
        local size = stormlib.getFileSize(file)
        local data = stormlib.readFile(file, size)
        
        print("\n=== war3map.j 내용 (처음 500자) ===")
        print(string.sub(data, 1, 500))
        
        stormlib.closeFile(file)
    end
end

-- MPQ 닫기
stormlib.closeArchive(mpq)
```

### 게임 정보 모니터

```lua
-- 게임 정보 업데이트 콜백
local function updateGameInfo()
    if not war3.isRunning() then
        return
    end
    
    if not war3.hasWorld() then
        print("게임이 진행 중이 아닙니다")
        return
    end
    
    -- 맵 정보
    local mapName = war3.getMapName()
    local mapFile = war3.getMapFileName()
    print("맵: " .. mapName .. " (" .. mapFile .. ")")
    
    -- 플레이어 정보
    local localPlayer = war3.getLocalPlayer()
    print("\n=== 플레이어 정보 ===")
    
    for i = 0, 11 do
        local state = war3.getPlayerSlotState(i)
        if state == PLAYER_SLOT_STATE_PLAYING then
            local name = war3.getPlayerName(i)
            local team = war3.getPlayerTeam(i)
            local race = war3.getPlayerRace(i)
            local gold = war3.getPlayerState(i, PLAYER_STATE_RESOURCE_GOLD)
            local lumber = war3.getPlayerState(i, PLAYER_STATE_RESOURCE_LUMBER)
            
            local raceNames = {"", "휴먼", "오크", "언데드", "나이트엘프", "데몬"}
            local raceName = raceNames[race] or "기타"
            
            local marker = (i == localPlayer) and " (나)" or ""
            print(string.format("[%d] %s%s - 팀 %d, %s, 골드: %d, 목재: %d", 
                i, name, marker, team, raceName, gold, lumber))
        end
    end
    
    -- 카메라 위치
    local camX, camY = war3.getCameraPosition()
    print(string.format("\n카메라 위치: (%.2f, %.2f)", camX, camY))
end

-- 콜백 바인딩
local handle = callbacks.bind("OnTick", updateGameInfo)

-- 나중에 제거하려면:
-- callbacks.remove(handle)
```

---

## 주의사항

1. **핸들 관리**: StormLib의 핸들(아카이브, 파일, 검색)은 사용 후 반드시 닫아야 합니다.
2. **에러 처리**: 파일 작업 시 항상 에러를 확인하세요.
3. **게임 상태**: War3 API는 게임이 실행 중일 때만 작동합니다.
4. **메모리**: 큰 파일을 읽을 때는 메모리 사용량에 주의하세요.
5. **성능**: 루프 내에서 무거운 작업을 피하세요.



