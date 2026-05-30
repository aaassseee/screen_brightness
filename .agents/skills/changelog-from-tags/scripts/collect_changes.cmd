@echo off
setlocal enabledelayedexpansion

REM Prints scoped commits and diffstat for a package folder, comparing the most
REM recent stable tag (e.g. 1.2.3 or 1.2.3+4) against HEAD.

if "%~1"=="" (
  echo Usage: %~nx0 ^<path-to-package^>
  echo Example: %~nx0 ..\screen_brightness_windows
  exit /b 2
)

set "PKG=%~1"

for /f "usebackq delims=" %%T in (`git -C "%PKG%" tag --list --sort=-v:refname`) do (
  set "TAG=%%T"

  REM Heuristic for a stable semver-ish tag:
  REM - must have at least 2 dots (X.Y.Z...)
  REM - does NOT include '-' (pre-release marker)
  for /f "tokens=1-3 delims=." %%A in ("!TAG!") do (
    REM If we can split into 3 dot-delimited tokens, we treat it as semver-ish.
    REM We don't strictly validate numeric tokens here to keep this script robust.
    if not "%%C"=="" (
      REM Exclude prereleases like 1.2.3-dev.1
      echo !TAG! | findstr /c:"-" >nul
      if !errorlevel! == 1 (
        set "PREV=!TAG!"
        goto :found
      )
    )
  )
)

:found
if "%PREV%"=="" (
  echo No stable tag found.
  exit /b 3
)

echo previousStableTag: %PREV%
echo.

echo # commits (scoped)
git -C "%PKG%" log %PREV%..HEAD --oneline --decorate -- .
echo.

echo # diff --stat (scoped)
git -C "%PKG%" diff --stat %PREV%..HEAD -- .

endlocal
