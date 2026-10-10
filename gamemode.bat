@echo off
chcp 65001 >nul
setlocal
title Game Mode

:: ============================================================
::  gamemode.bat - free CPU/RAM before gaming
::  SAFE   : closes known background bloat (blacklist)
::  STRONG : kills every user-session process that is not a
::           Windows-critical or Session 0 (service) process
::  MEMORY : only trims working set + flushes DNS
::  Requires Administrator.
:: ============================================================

:: --- self elevate ---
fltmc >nul 2>&1
if errorlevel 1 (
  echo [i] requesting Administrator rights ...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
  exit /b
)

:menu
cls
echo ==============================================
echo                GAME MODE
echo ==============================================
echo   [1] SAFE   - close known background apps
echo   [2] STRONG - kill all non-Windows-session processes
echo   [3] MEMORY - trim working set + flush DNS only
echo   [0] EXIT
echo ==============================================
set "choice="
set /p "choice=Select [1]: "
if "%choice%"=="" set "choice=1"
if "%choice%"=="1" goto safe
if "%choice%"=="2" goto strong
if "%choice%"=="3" goto memonly
if "%choice%"=="0" exit /b 0
goto menu

:: ------------------------------------------------------------
:safe
echo.
echo [*] SAFE mode: closing background applications ...
set "SAFE_LIST=chrome.exe msedge.exe firefox.exe opera.exe brave.exe 360se.exe 360chrome.exe QQBrowser.exe SogouExplorer.exe iexplore.exe QQ.exe TIM.exe WeChat.exe WeChatAppEx.exe DingTalk.exe Telegram.exe Discord.exe Slack.exe Skype.exe Spotify.exe cloudmusic.exe QQMusic.exe PotPlayerMini64.exe OneDrive.exe Dropbox.exe GoogleDriveFS.exe BaiduNetdisk.exe NutstoreClient.exe AdobeIPCBroker.exe CCXProcess.exe TeamViewer.exe AnyDesk.exe ToDesk.exe SunloginClient.exe SearchApp.exe YourPhone.exe PhoneExperienceHost.exe Widgets.exe"
for %%p in (%SAFE_LIST%) do taskkill /F /IM "%%p" >nul 2>&1 && echo   closed: %%p
goto finish

:: ------------------------------------------------------------
:strong
echo.
echo ==================================================
echo  WARNING
echo  STRONG mode force-kills every process in your
echo  user session that is not on the Windows
echo  critical / service (Session 0) keep list.
echo  Unsaved work in those programs is LOST.
echo  Explorer, Defender, audio and all services stay.
echo ==================================================
set "confirm="
set /p "confirm=Type YES to continue: "
if /i not "%confirm%"=="YES" goto menu

echo [*] STRONG mode: terminating user-session processes ...
:: keep = Windows critical + shell + this console; Session 0 (services) always spared
powershell -NoProfile -ExecutionPolicy Bypass -Command "$keep='System','Registry','Idle','Memory Compression','Secure System','smss','csrss','wininit','winlogon','services','lsass','svchost','fontdrvhost','dwm','conhost','WmiPrvSE','spoolsv','audiodg','sihost','taskhostw','explorer','MsMpEng','NisSrv','SecurityHealthService','SecurityHealthSystray','StartMenuExperienceHost','SearchHost','SearchIndexer','SearchApp','ShellExperienceHost','RuntimeBroker','TextInputHost','ctfmon','LogonUI','TabTip','ApplicationFrameHost','powershell','pwsh','cmd','taskkill','dllhost','sppsvc','msdtc'; $self=$PID; $n=0; Get-Process | Where-Object { $_.Id -ne $self -and $_.SessionId -ne 0 -and $keep -notcontains $_.ProcessName } | ForEach-Object { try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; $n++ } catch {} }; Write-Host ('  terminated: ' + $n + ' process(es)')"
goto finish

:: ------------------------------------------------------------
:memonly
echo.
echo [*] MEMORY mode ...
goto finish

:: ------------------------------------------------------------
:finish

:: --- trim working set of every remaining process ---
echo [*] trimming working set ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -MemberDefinition ('[DllImport(' + [char]34 + 'psapi.dll' + [char]34 + ')] public static extern bool EmptyWorkingSet(IntPtr h);') -Name PsApi -Namespace Win32; $n=0; Get-Process | ForEach-Object { try { if ([Win32.PsApi]::EmptyWorkingSet($_.Handle)) { $n++ } } catch {} }; Write-Host ('  trimmed: ' + $n + ' process(es)')"

:: --- flush DNS cache ---
ipconfig /flushdns >nul 2>&1 && echo [*] DNS cache flushed

:: NOTE: deeper standby-list purge needs an external tool, e.g.
::       EmptyStandbyList.exe workingsets (run as admin) - not bundled.
echo.
echo [OK] done. Current free memory:
powershell -NoProfile -Command "$os=Get-CimInstance Win32_OperatingSystem; Write-Host ('  free: ' + [math]::Round($os.FreePhysicalMemory/1024/1024,2) + ' GB / total: ' + [math]::Round($os.TotalVisibleMemorySize/1024/1024,2) + ' GB')"
echo.
pause
exit /b 0
