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
set "VENV=.venv-build"
set "PYEXE=%VENV%\Scripts\python.exe"
REM Disable Ultralytics' optional dependency installer during analysis too.
set "YOLO_AUTOINSTALL=false"

echo.
echo  ======================================================
echo    Building FungiCapture for Windows
echo  ======================================================
echo.

REM ---------- find Python ----------
echo  [1/6] Looking for Python...
set "PY="
where py >nul 2>&1 && set "PY=py -3"
if not defined PY (
    where python >nul 2>&1 && set "PY=python"
)
if not defined PY goto :nopython

%PY% -c "import sys, struct; sys.exit(0 if (3,10) <= sys.version_info < (3,14) and struct.calcsize('P') == 8 else 1)" >nul 2>&1
if errorlevel 1 goto :oldpython
for /f "delims=" %%v in ('%PY% -c "import sys; print(sys.version.split()[0])"') do set "PYVER=%%v"
echo        found Python !PYVER!

REM ---------- environment ----------
echo  [2/6] Creating a build environment...
if not exist "%PYEXE%" (
    %PY% -m venv "%VENV%" >>"%LOG%" 2>&1
    if errorlevel 1 goto :failed
)
"%PYEXE%" -m pip install --upgrade pip >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
"%PYEXE%" -c "import sys, struct; sys.exit(0 if (3,10) <= sys.version_info < (3,14) and struct.calcsize('P') == 8 else 1)" >>"%LOG%" 2>&1
if errorlevel 1 goto :oldpython

echo  [3/6] Installing FungiCapture and its parts...
echo        (the slow step - several minutes)
REM Explicit CPU index and pins also replace a reused CUDA build environment.
"%PYEXE%" -m pip install --upgrade --force-reinstall torch==2.7.1+cpu torchvision==0.22.1+cpu --index-url https://download.pytorch.org/whl/cpu >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
"%PYEXE%" -m pip install -e ".[gui,model]" -c packaging\windows-constraints.txt >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
REM Ultralytics declares desktop OpenCV. Remove ALL variants sharing cv2,
REM then restore only headless (uninstall alone damages the shared cv2 tree).
"%PYEXE%" -m pip uninstall -y opencv-python opencv-contrib-python opencv-contrib-python-headless opencv-python-headless >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
"%PYEXE%" -m pip install --force-reinstall --no-deps "opencv-python-headless>=4.8" >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
"%PYEXE%" -m pip install "pyinstaller>=6,<7" "pyinstaller-hooks-contrib>=2025.0" pip-licenses >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

echo  [4/6] Checking the program works before packaging it...
"%PYEXE%" -c "import fungicapture, PySide6; print('ok')" >>"%LOG%" 2>&1
if errorlevel 1 goto :failed
"%PYEXE%" packaging\check_sam_runtime.py >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

echo  [5/6] Recording the licences of everything included...
"%PYEXE%" -m piplicenses --format=markdown --with-urls --output-file THIRD_PARTY_LICENSES.md >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

echo  [6/6] Building the .exe (this takes a while)...
"%PYEXE%" -m PyInstaller packaging\fungicapture.spec --noconfirm --clean >>"%LOG%" 2>&1
if errorlevel 1 goto :failed

if not exist "dist\FungiCapture\FungiCapture.exe" goto :failed

REM ---------- add the helper files ----------
copy /y "docs\USER_GUIDE.md" "dist\FungiCapture\User Guide.md" >nul 2>&1
copy /y "LICENSE" "dist\FungiCapture\LICENSE" >nul 2>&1
copy /y "packaging\tokenizer-LICENSE.txt" "dist\FungiCapture\tokenizer-LICENSE.txt" >nul 2>&1
copy /y "THIRD_PARTY_LICENSES.md" "dist\FungiCapture\THIRD_PARTY_LICENSES.md" >nul 2>&1
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
echo SAM runs on CPU. Its model weights are NOT included: obtain
echo authorised sam3.pt weights from Meta and import them in setup.
echo The tokenizer vocabulary is included; no runtime download is needed.
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

:nopython
echo.
echo  --------------------------------------------------------------
echo   Python is not installed on this computer.
echo.
echo     1. Go to  https://www.python.org/downloads/
echo     2. Download Python 3.11 or newer.
echo     3. IMPORTANT: on the FIRST screen of the installer, tick
echo        "Add Python to PATH"  before clicking Install.
echo     4. Install it, then double-click this file again.
echo  --------------------------------------------------------------
echo.
pause
goto :end

:oldpython
echo.
echo   This CPU SAM build needs 64-bit Python 3.10 through 3.13.
echo   Get one from https://www.python.org/downloads/
echo   If .venv-build uses another version, remove that build environment
echo   and run this file again with a supported Python.
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
