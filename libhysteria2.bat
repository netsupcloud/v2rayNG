@echo off
setlocal enabledelayedexpansion

:: Set targets for building
set targets[0]=aarch64-linux-android21 arm64 arm64-v8a
set targets[1]=armv7a-linux-androideabi21 arm armeabi-v7a
::set targets[2]=x86_64-linux-android21 amd64 x86_64
::set targets[3]=i686-linux-android21 386 x86

:: Change directory to hysteria
cd hysteria || exit /b 1

:: Loop through each target
for /L %%i in (0,1,3) do (
    set "target=!targets[%%i]!"
    
    :: Split the target string into components
    for /f "tokens=1-3" %%a in ("!target!") do (
        set "ndk_target=%%a"
        set "goarch=%%b"
        set "abi=%%c"
        
        echo Building for !abi! with !ndk_target! (!goarch!)
        
        :: Set compiler path (adjust NDK_HOME as needed)
        set "CC=%NDK_HOME%\toolchains\llvm\prebuilt\windows-x86_64\bin\!ndk_target!-clang.cmd"
        
        :: Run the build command
        set "GOOS=android"
        set "GOARCH=!goarch!"
        set "CGO_ENABLED=1"
        
        go build -o libs\!abi!\libhysteria2.so -trimpath -ldflags "-s -w -buildid=" -buildvcs=false ./app
        
        echo Built libhysteria2.so for !abi!
    )
)

echo All builds completed
endlocal