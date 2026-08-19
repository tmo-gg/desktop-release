-- 원피스 랜덤 디펜스 클래식 맵 진화체 변수명 추출 스크립트
local MAP_FILE_PATH = "C:\\Users\\John\\Documents\\Warcraft III\\Maps\\Download\\ORDR_S2_2.111_[C].w3x"

function parse()
  -- MPQ 아카이브 열기 (priority=0, flags=MPQ_OPEN_READ_ONLY)
  local hMpq = stormlib.openArchive(MAP_FILE_PATH, 0, MPQ_OPEN_READ_ONLY)
  if not hMpq then
    print("SFileOpenArchive failed")
    return
  end
  
  local found = false
  local searchPattern = "set (%w+)%["
  local targetText = "bj_lastCreatedUnit,\"origin\"))"
  
  -- *.xxx 파일 검색 시작
  -- findFirstFile 반환값: findHandle, fileName, fileSize, compSize
  local hFind, fileName, fileSize, compSize = stormlib.findFirstFile(hMpq, "*.xxx")
  
  if not hFind then
    print("SFileFindFirstFile failed")
    stormlib.closeArchive(hMpq)
    return
  end
  
  repeat
    if fileSize > 0 then
      -- 파일 열기
      local hFile = stormlib.openFile(hMpq, fileName, 0)
      if hFile then
        -- 파일 크기 확인
        local actualSize = stormlib.getFileSize(hFile)
        
        if actualSize then
          -- 파일 읽기
          local buffer = stormlib.readFile(hFile, actualSize)
          stormlib.closeFile(hFile)
          
          if buffer then
              -- 줄 단위로 분리
              local lines = {}
              for line in buffer:gmatch("[^\r\n]+") do
                  table.insert(lines, line)
              end
              
              -- 특정 텍스트 검색
              for i = 1, #lines do
                -- Lua 패턴에서 특수문자 이스케이프
                if lines[i]:find(targetText, 1, true) then
                  -- 다음 줄부터 변수명 패턴 검색
                  for j = i + 1, #lines do
                    local varName = lines[j]:match(searchPattern)
                    if varName then
                      found = true
                      print("found: " .. varName)
                      break
                    end
                  end
                end
                
                if found then
                  break
                end
              end
            end
          else
              stormlib.closeFile(hFile)
          end
      end
    end
    
    if found then
      break
    end
    
    -- 다음 파일 검색
    -- findNextFile 반환값: fileName, fileSize, compSize
    fileName, fileSize, compSize = stormlib.findNextFile(hFind)
  until not fileName
  
  -- 리소스 정리
  stormlib.findClose(hFind)
  stormlib.closeArchive(hMpq)
  
  if not found then
    print("variable not found.")
  end
end

-- 함수 실행
parse()
