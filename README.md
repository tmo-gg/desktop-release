# TMO.GG Lua 스크립팅 가이드

## 목차

- [개요](#개요)
- [기본 사용법](#기본-사용법)
- [API 참조](#api-참조)
  - [War3 객체](#war3-객체)
    - [속성](#속성)
    - [메서드](#메서드)
  - [Callbacks 객체](#callbacks-객체)
    - [메서드](#메서드-1)
    - [지원되는 이벤트](#지원되는-이벤트)
  - [유틸리티 함수](#유틸리티-함수)
- [예제](#예제)
  - [기본 스크립트](#기본-스크립트)
- [주의사항](#주의사항)

## 개요

TMO.GG는 Lua 스크립팅을 통해 워크래프트 3 게임 내 기능을 확장할 수 있는 기능을 제공합니다. 이 문서는 Lua 스크립팅 API에 대한 설명을 제공합니다.

## 기본 사용법

1. `scripts` 폴더에 `.lua` 확장자를 가진 스크립트 파일을 생성합니다.
2. 스크립트 파일을 작성합니다.
3. 메인 프로그램에서 스크립트의 체크박스를 체크하고 실행을 누릅니다.
4. 이후부턴 자동 실행 스크립트로 지정되어 프로그램을 재실행하여도 자동 실행됩니다.

## API 참조

### War3 객체

워크래프트 3 게임과 상호작용하기 위한 주요 객체입니다.

#### 속성

- `WorldInitialized`: 게임 월드가 초기화되었는지 여부를 반환합니다.
- `LoadedMapFileName`: 현재 로드된 맵 파일 이름을 반환합니다.

#### 메서드

- `GetDataDirectory()`: 워크래프트 3 데이터 디렉토리 경로를 반환합니다.
- `IsRunning()`: 워크래프트 3가 실행 중인지 여부를 반환합니다.
- `GetLocalPlayerId()`: 현재 로컬 플레이어의 ID를 반환합니다.
- `GetPlayerName(playerId)`: 지정된 플레이어 ID의 이름을 반환합니다.
- `IsChatInputEnabled()`: 채팅 입력이 활성화되어 있는지 여부를 반환합니다.
- `PostChat(message)`: 채팅 메시지를 전송합니다.
- `GetSelectedUnit()`: 현재 선택된 유닛 정보를 반환합니다.
  - 반환값: 테이블 형태로 유닛 정보 (Pointer, Id, Owner, Color)
- `GetUnitItem(unit, index)`: 지정된 유닛의 인벤토리 아이템을 반환합니다.
  - `unit`: GetSelectedUnit()으로 얻은 유닛 테이블
  - `index`: 인벤토리 슬롯 (0-5)

### Callbacks 객체

이벤트 콜백을 등록하기 위한 객체입니다.

#### 메서드

- `Bind(eventName, callback)`: 이벤트 콜백을 등록합니다.
  - `eventName`: 이벤트 이름
  - `callback`: 콜백 함수

#### 지원되는 이벤트

- `Run`: 게임이 실행될 때마다 호출됩니다.
- `IsBannedUnit`: 유닛이 금지된 유닛인지 확인할 때 호출됩니다.
  - 콜백 함수는 유닛 정보 테이블을 매개변수로 받습니다.

### 유틸리티 함수

- `DirecotryExists(path)`: 디렉토리가 존재하는지 확인합니다.
- `FileExists(path)`: 파일이 존재하는지 확인합니다.
- `GetFiles(path)`: 지정된 경로의 파일 목록을 반환합니다.
- `GetAsyncKeyState(virtualKey)`: 지정된 가상 키의 상태를 반환합니다.

## 예제

### 기본 스크립트

```lua
-- 채팅 메시지 전송 예제
War3.PostChat("Hello, World!")

-- 선택된 유닛 정보 출력
local unit = War3.GetSelectedUnit()
if unit then
    print("Unit ID: " .. unit.Id)
    print("Owner: " .. unit.Owner)
    print("Color: " .. unit.Color)
end

-- 이벤트 콜백 등록
Callbacks.Bind("Run", function()
    print("Game is running!")
end)

-- 금지된 유닛 확인
Callbacks.Bind("IsBannedUnit", function(unit)
    -- 특정 유닛 ID를 금지
    if unit.Id == "hfoo" then
        return true
    end
    return false
end)
```

## 주의사항

1. 스크립트는 게임 성능에 영향을 줄 수 있으므로 효율적으로 작성해야 합니다.
2. 무한 루프나 과도한 연산을 피해야 합니다.
3. 게임 클라이언트의 안정성을 해치지 않도록 주의해야 합니다. 