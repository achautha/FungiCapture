@echo off
REM ===================================================================
REM  Build the Windows FungiCapture.exe
REM
REM  Double-click this ON A WINDOWS COMPUTER. It produces a standalone
REM  folder that runs without Python.
REM
REM  This cannot be done from Linux or Mac: the tool that makes the
REM  .exe has to run on Windows itself. Any Windows PC will do - it
REM  does not have to be the one that will use the program.
REM
REM  Takes about 10-20 minutes and needs an internet connection.
REM ===================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

set "LOG=build_log.txt"
set "UV_PROJECT_ENVIRONMENT=.venv-build"

echo.
echo  ======================================================
echo    Building FungiCapture for Windows
echo  ======================================================
echo.

REM ---------- find uv (it provisions the pinned Python) ----------
echo  [1/6] Looking for uv...
where uv >nul 2>&1
if errorlevel 1 goto :nouv

REM ---------- environment ----------
echo  [2/6] Synchronizing the locked non-SAM build environment...
uv sync --locked --extra gui --group build >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

echo  [3/6] Checking the Python and dependency profile...
uv run --no-sync python --version >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
uv run --no-sync python -c "import importlib.util; assert all(importlib.util.find_spec(p) is None for p in ('torch', 'torchvision', 'ultralytics')), 'Build environment must not contain SAM dependencies'" >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

echo  [4/6] Checking the program works before packaging it...
set "QT_QPA_PLATFORM=offscreen"
uv run --no-sync python -m pytest -ra >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
set "QT_QPA_PLATFORM="

echo  [5/6] Recording the licences of everything included...
uv run --no-sync python -m piplicenses --format=markdown --with-urls --output-file THIRD_PARTY_LICENSES.md >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

echo  [6/6] Building the .exe (this takes a while)...
uv run --no-sync python -m PyInstaller packaging\fungicapture.spec --noconfirm >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

if not exist "dist\FungiCapture\FungiCapture.exe" goto :failed

REM ---------- add the helper files ----------
copy /y "docs\USER_GUIDE.md" "dist\FungiCapture\User Guide.md" >nul 2>&1
copy /y "LICENSE" "dist\FungiCapture\LICENSE" >nul 2>&1
xcopy /e /i /y "examples\sample_dataset" "dist\FungiCapture\sample_dataset" >nul 2>&1

> "dist\FungiCapture\READ ME FIRST.txt" (
echo ===============================================================
echo   FungiCapture  -  Windows
echo ===============================================================
echo.
echo TO START THE PROGRAM
echo --------------------
echo.
echo   Double-click:   FungiCapture.exe
echo.
echo If Windows shows a blue box saying "Windows protected your PC",
echo click "More info" then "Run anyway". This appears because the
echo file is not signed by Microsoft, not because anything is wrong.
echo.
echo.
echo THAT IS ALL
echo -----------
echo.
echo Everything the program needs is already inside this folder.
echo You do NOT need to install Python or anything else.
echo.
echo The folder is large because it carries its own copy of
echo everything. Do not delete files from inside it.
echo.
echo.
echo WANT TO PRACTISE FIRST?
echo -----------------------
echo.
echo The folder "sample_dataset" has 3 practice plates. Point the
echo program at sample_dataset\plates and set the plate size to
echo 4 rows by 6 columns.
echo.
echo ===============================================================
)

echo.
echo  ======================================================
echo    Done.
echo.
echo    Your program is in:   dist\FungiCapture\
echo    Start it with:        dist\FungiCapture\FungiCapture.exe
echo.
echo    To give it to someone else, zip the whole
echo    dist\FungiCapture folder and send that.
echo  ======================================================
echo.
pause
goto :end

:nouv
echo.
echo  --------------------------------------------------------------
echo   Install uv 0.12.9, then double-click this file again.
echo   See docs\DEVELOPMENT.md for installation instructions.
echo   uv provisions the Python version recorded in .python-version.
echo  --------------------------------------------------------------
echo.
pause
goto :end

:failed
echo.
echo  --------------------------------------------------------------
echo   The build did not finish.
echo.
echo   The most common cause is the internet connection dropping
echo   part way through. Try running this file again - it carries on
echo   from where it stopped.
echo.
echo   What went wrong was written to:  %LOG%
echo  --------------------------------------------------------------
echo.
pause

:end
endlocal
