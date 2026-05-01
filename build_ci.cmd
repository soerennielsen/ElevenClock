@echo off
setlocal EnableDelayedExpansion

REM Non-interactive build script intended for CI (windows-11-arm runner).
REM Produces ElevenClockBin\ as a native ARM64 build. No installer, no signing pauses.

set "py=%cd%\venv\Scripts\python.exe"

IF EXIST %py% (
    echo Using VENV Python
) ELSE (
    set "py=python"
    echo Using system Python
)

%py% -m pip install --upgrade pip
if %errorlevel% neq 0 exit /b %errorlevel%

%py% -m pip install -r requirements.txt
if %errorlevel% neq 0 exit /b %errorlevel%

%py% -m pip install packaging
if %errorlevel% neq 0 exit /b %errorlevel%

%py% scripts/check_python_version.py --min-version "3.11.0"
if %errorlevel% neq 0 exit /b %errorlevel%

%py% scripts/apply_versions.py
if %errorlevel% neq 0 exit /b %errorlevel%

if exist ElevenClockBin rmdir /Q /S ElevenClockBin
if exist elevenclock_bin rmdir /Q /S elevenclock_bin

xcopy elevenclock elevenclock_bin /E /H /C /I /Y
if %errorlevel% neq 0 exit /b %errorlevel%

pushd elevenclock_bin

%py% -m compileall -b .
if %errorlevel% neq 0 (popd & exit /b %errorlevel%)

del /S /Q *.py
if exist __pycache__ rmdir /Q /S __pycache__
if exist build rmdir /Q /S build
if exist dist rmdir /Q /S dist
if exist external\__pycache__ rmdir /Q /S external\__pycache__
if exist lang\__pycache__ rmdir /Q /S lang\__pycache__
copy ..\elevenclock\__init__.py .\

%py% -m PyInstaller elevenclock.spec
if %errorlevel% neq 0 (popd & exit /b %errorlevel%)

move dist\ElevenClock ..\ElevenClockBin
if %errorlevel% neq 0 (popd & exit /b %errorlevel%)
popd

rmdir /Q /S elevenclock_bin

REM Prune unneeded Qt plugins / DLLs (mirrors build.cmd; missing files are tolerated).
pushd ElevenClockBin\PySide6
for %%F in (opengl32sw.dll Qt6Network.dll Qt6OpenGL.dll Qt6Pdf.dll Qt6Qml.dll Qt6QmlModels.dll Qt6Quick.dll Qt6VirtualKeyboard.dll QtNetwork.pyd) do (
    if exist %%F del /Q %%F
)
popd

if exist ElevenClockBin\tcl\tzdata rmdir /Q /S ElevenClockBin\tcl\tzdata

if exist ElevenClockBin\lang\download_translations.pyc del /Q ElevenClockBin\lang\download_translations.pyc

pushd ElevenClockBin\PySide6\plugins\imageformats
if exist qico.dll (
    move qico.dll filetomaintain >nul
    del /Q *.dll
    move filetomaintain qico.dll >nul
)
popd

echo Build completed: ElevenClockBin\
exit /b 0
