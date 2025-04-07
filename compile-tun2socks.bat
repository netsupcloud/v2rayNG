@echo on
setlocal enabledelayedexpansion

:: Set paths
set "SCRIPT_DIR=%~dp0"
set "TMPDIR=%TEMP%\build_%RANDOM%"

:: Check NDK
if not defined NDK_HOME (
    echo [ERROR] NDK_HOME environment variable not set
    exit /b 1
)
echo Using NDK at: %NDK_HOME%
if not exist "%NDK_HOME%\ndk-build.cmd" (
    echo [ERROR] ndk-build.cmd not found in %NDK_HOME%
    exit /b 1
)

:: Create temp dir
echo Creating temp directory: %TMPDIR%
mkdir "%TMPDIR%" || (
    echo [ERROR] Failed to create temp directory
    exit /b 1
)

:: Copy files
echo Copying tun2socks.mk
copy "%SCRIPT_DIR%tun2socks.mk" "%TMPDIR%\" || (
    echo [ERROR] Failed to copy tun2socks.mk
    goto :cleanup
)

:: Copy dependencies (instead of symlinks)
echo Copying dependencies...
xcopy /E /I /Y "%SCRIPT_DIR%badvpn" "%TMPDIR%\badvpn\" || (
    echo [ERROR] Failed to copy badvpn
    goto :cleanup
)
xcopy /E /I /Y "%SCRIPT_DIR%libancillary" "%TMPDIR%\libancillary\" || (
    echo [ERROR] Failed to copy libancillary
    goto :cleanup
)

:: Run ndk-build
echo Starting NDK build...
pushd "%TMPDIR%"
call "%NDK_HOME%\ndk-build.cmd" ^
    NDK_PROJECT_PATH=. ^
    APP_BUILD_SCRIPT=./tun2socks.mk ^
    APP_ABI=all ^
    APP_PLATFORM=android-21 ^
    NDK_LIBS_OUT="%TMPDIR%\libs" ^
    NDK_OUT="%TMPDIR%\tmp" ^
    APP_SHORT_COMMANDS=false LOCAL_SHORT_COMMANDS=false -B -j4 || (
    echo [ERROR] NDK build failed
    popd
    goto :cleanup
)
popd

:: Copy results
if exist "%TMPDIR%\libs" (
    echo Copying results to %SCRIPT_DIR%libs
    robocopy "%TMPDIR%\libs" "%SCRIPT_DIR%\libs" /E || (
        if %ERRORLEVEL% GTR 1 (
            echo [ERROR] Failed to copy libs
            goto :cleanup
        )
    )
)

:cleanup
echo Cleaning up...
if exist "%TMPDIR%" (
    rmdir /s /q "%TMPDIR%"
)
echo Build completed successfully
pause