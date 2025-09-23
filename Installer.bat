@echo off
setlocal enabledelayedexpansion

:: #############################################################################
:: #                                                                           #
:: #      AI-Characters Content Installer for Silly Tavern                     #
:: #      Revision 2.1 - Public                 #
:: #                                                                           #
:: #############################################################################

title Dracaerys AI-Characters Content Installer V2.1

:: --- Configuration ---
set "DATABASE_FILE=installer_database.txt"
set "REPO_ROOT=%~dp0"

:: --- Start the main execution ---
call :main
:: --- End the script after :main is finished ---
exit /b


:: ============================================================================
::  MAIN SCRIPT LOGIC
:: ============================================================================
:main
    cls
    echo =================================================================
    echo  Dracaerys AI-Characters Content Installer for Silly Tavern
    echo =================================================================
    echo.
    echo This script will copy content from the AI-Characters repository
    echo into your Silly Tavern installation.
    echo.

    :: --- Step 1: Get Silly Tavern Path ---
    call :getSillyTavernPath
    
    echo.
    echo Silly Tavern path set to: "%sillyTavernPath%"
    echo.
    pause
    cls

    :: --- Step 2: Initialize Database ---
    call :initializeDatabase
    echo.
    echo Database is ready.
    echo.
    pause
    cls

    :: --- Step 3: Scan for New Content ---
    echo =================================================================
    echo  Scanning for new content packs...
    echo =================================================================
    echo.
    call :scanForNewContent
    echo.
    echo Scan complete.
    echo.
    pause
    cls

    :: --- Step 4: Run Installation ---
    echo =================================================================
    echo  Starting Installation...
    echo =================================================================
    echo.
    call :installContent
    echo.
    echo =================================================================
    echo  Installation Complete!
    echo =================================================================
    echo.
    echo All content packs have been successfully installed.
    pause
goto :eof


:: ============================================================================
::  SUBROUTINES
:: ============================================================================

:getSillyTavernPath
    set "sillyTavernPath="
    set /p "sillyTavernPath=Please enter the full path to your Silly Tavern root folder: "

    if not defined sillyTavernPath (
        echo.
        echo ERROR: You must provide a path. Please try again.
        echo.
        goto getSillyTavernPath
    )

    if not exist "%sillyTavernPath%\data\default-user" (
        echo.
        echo ERROR: The path provided is not a valid Silly Tavern installation.
        echo A valid installation must contain a 'data\default-user' folder.
        echo Path checked: "%sillyTavernPath%\data\default-user"
        echo.
        pause
        goto getSillyTavernPath
    )
goto :eof

:initializeDatabase
    echo Checking for database file...
    if exist "%DATABASE_FILE%" (
        echo Database file '%DATABASE_FILE%' found.
    ) else (
        echo No database found. Creating '%DATABASE_FILE%' with default entries...
        (
            echo Lumina star system\characters ^(Lumina Dominion^);characters
            echo Events + Jokes\characters ^(Magical Parfait Girls, April Fools 2024^);characters
            echo Video Game Replicants\characters ^(DDLC^);characters
            echo Shadowrun\Characters ^(Neo-Seattle Mercenaries^);characters
            echo Lumina star system\backgrounds ^(Lumina Dominion^);backgrounds
            echo Lumina star system\Backgrounds ^(Planet Nihon^);backgrounds
            echo Video Game Replicants\backgrounds ^(DDLC^);backgrounds
            echo Lumina star system\sysprompt;sysprompt
            echo Video Game Replicants\sysprompt;sysprompt
        ) > "%DATABASE_FILE%"
        
        if not exist "%DATABASE_FILE%" (
            echo.
            echo FATAL ERROR: Failed to create the database file '%DATABASE_FILE%'.
            pause
            exit /b 1
        )
        echo Database created successfully.
    )
goto :eof

:scanForNewContent
    set "NEW_CONTENT_FOUND=0"
    for /d /r . %%d in (*) do (
        set "folderName=%%~nd"
        if /i "!folderName:~0,10!"=="characters"  call :updateDatabase "%%d" "characters"
if /i "!folderName:~0,10!"=="assets"  call :updateDatabase "%%d" "assets"
if /i "!folderName:~0,10!"=="chats"  call :updateDatabase "%%d" "chats"
if /i "!folderName:~0,10!"=="group chats"  call :updateDatabase "%%d" "group chats"
if /i "!folderName:~0,10!"=="themes"  call :updateDatabase "%%d" "themes"
if /i "!folderName:~0,10!"=="worlds"  call :updateDatabase "%%d" "worlds"
        if /i "!folderName:~0,10!"=="backgrounds" call :updateDatabase "%%d" "backgrounds"
        if /i "!folderName!"=="sysprompt"         call :updateDatabase "%%d" "sysprompt"
    )

    if "%NEW_CONTENT_FOUND%"=="0" (
        echo No new content packs were found.
    )
goto :eof

:updateDatabase
    set "fullPath=%~1"
    set "contentType=%~2"

    rem --- FIX: Robustly remove any potential leading/trailing spaces from contentType ---
    for /f "tokens=*" %%a in ("!contentType!") do set "contentType=%%a"

    rem --- Check and skip the REPO_ROOT itself ---
    set "tempRepoRoot=!REPO_ROOT!"
    rem --- FIX: Corrected typo in variable name from tempRoo to tempRepoRoot ---
    if "!tempRepoRoot:~-1!"=="\" set "tempRepoRoot=!tempRepoRoot:~0,-1!"
    if /i "!fullPath!"=="!tempRepoRoot!" ( goto :eof )
    
    rem --- Calculate relativePath using correct string substitution ---
    set "relativePath=!fullPath:%REPO_ROOT%=!"

    rem --- Final check to ensure calculation worked ---
    if not defined relativePath ( goto :eof )

    findstr /L /C:"!relativePath!;!contentType!" "%DATABASE_FILE%" >nul
    if %errorlevel% neq 0 (
        echo New Content Found: !relativePath!
        echo !relativePath!;!contentType!>> "%DATABASE_FILE%"
        echo  -^> Added to database.
        set "NEW_CONTENT_FOUND=1"
    )
goto :eof

:installContent
    if not exist "%DATABASE_FILE%" (
        echo ERROR: Database file not found. Cannot proceed with installation.
        goto :eof
    )
    for /f "usebackq tokens=1,2 delims=;" %%a in ("%DATABASE_FILE%") do (
        call :processInstall "%%a" "%%b"
    )
goto :eof

:processInstall
    set "relativePath=%~1"
    set "destType=%~2"
    set "sourcePath=%REPO_ROOT%!relativePath!"
    set "destPath=%sillyTavernPath%\data\default-user\!destType!"

    if exist "!sourcePath!" (
        echo [INSTALLING] '!relativePath!'
        echo    -^> TO: '!destPath!'
        
        if not exist "!destPath!" (
            mkdir "!destPath!"
            echo    -^> Created destination folder.
        )
        
        xcopy "!sourcePath!\*.*" "!destPath!\" /s /e /i /y /q
        
        echo    -^> Success.
        echo.
    ) else (
        echo [WARNING] Source path not found, skipping: '!sourcePath!'
        echo.
    )
goto :eof