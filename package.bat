@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem VS Code extension VSIX build script
rem Put this file in the root of the extension repo.
rem ============================================================

cd /d "%~dp0"

echo.
echo [1/8] Verifying package.json exists...
if not exist "package.json" (
    echo ERROR: package.json was not found in this folder.
    echo Make sure this .bat file is in the root of the VS Code extension repo.
    exit /b 1
)

echo.
echo [2/8] Checking for Node.js...
where node >nul 2>nul
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not on PATH.
    echo Install Node.js, then reopen the terminal and try again.
    exit /b 1
)

echo.
echo [3/8] Checking for npm...
where npm >nul 2>nul
if errorlevel 1 (
    echo ERROR: npm is not installed or not on PATH.
    exit /b 1
)

for /f "delims=" %%A in ('node -v') do set NODEVER=%%A
echo Detected Node version: %NODEVER%

echo.
echo [4/8] Installing dependencies...

if exist "package-lock.json" (
    echo Found package-lock.json, using npm ci...
    call npm ci
) else (
    echo No package-lock.json found, using npm install...
    call npm install
)

if errorlevel 1 (
    echo ERROR: dependency installation failed.
    exit /b 1
)

echo.
echo [5/8] Running common pre-package scripts if present...

call npm run | findstr /R /C:" v\?scode:prepublish" >nul
if not errorlevel 1 (
    echo Found script: vscode:prepublish
    call npm run vscode:prepublish
    if errorlevel 1 (
        echo ERROR: npm run vscode:prepublish failed.
        exit /b 1
    )
    goto :packageStep
)

call npm run | findstr /R /C:" build" >nul
if not errorlevel 1 (
    echo Found script: build
    call npm run build
    if errorlevel 1 (
        echo ERROR: npm run build failed.
        exit /b 1
    )
    goto :packageStep
)

call npm run | findstr /R /C:" compile" >nul
if not errorlevel 1 (
    echo Found script: compile
    call npm run compile
    if errorlevel 1 (
        echo ERROR: npm run compile failed.
        exit /b 1
    )
    goto :packageStep
)

echo No vscode:prepublish, build, or compile script found. Continuing.

:packageStep
echo.
echo [6/8] Cleaning old VSIX files from repo root...
del /q "*.vsix" >nul 2>nul

echo.
echo [7/8] Packaging extension into VSIX...
call npx @vscode/vsce package
if errorlevel 1 (
    echo ERROR: VSIX packaging failed.
    echo.
    echo Possible causes:
    echo   - Missing build dependencies
    echo   - Missing publisher/name/version fields in package.json
    echo   - README/CHANGELOG/icon/path issues
    echo   - Node version too old for this repo/tooling
    exit /b 1
)

echo.
echo [8/8] Done. Generated VSIX:
dir /b "*.vsix"
echo.
echo You can install it with:
echo   code --install-extension your-extension-name.vsix
echo.

endlocal
exit /b 0