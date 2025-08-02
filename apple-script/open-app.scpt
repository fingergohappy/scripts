on run {appName}
    -- 检查应用是否正在运行
    tell application "System Events"
        set isRunning to (name of processes) contains appName
    end tell
    if not isRunning then
        -- 如果应用没有运行，则打开
        tell application appName to activate
    else
        -- 如果应用正在运行，检查是否已是当前激活应用
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
        end tell
        if frontApp is equal to appName then
            -- 已经是当前激活的应用，模拟cmd+~按键
            tell application "System Events"
                key code 50 using command down  -- 50是~键的键码
            end tell
        else
            -- 如果目标应用未激活，则激活它
            tell application appName to activate
        end if
    end if
end run
