@echo off
setlocal enabledelayedexpansion

echo ========================================
echo         FLUTTER FLAVOR BUILDER
echo ========================================

:: Elegir flavor
echo.
echo Elige el flavor:
echo [1] Familcar
echo [2] Alsur
set /p FLAVOR_OPTION=Opcion:

if "%FLAVOR_OPTION%"=="1" (
    set FLAVOR_NAME=familcar
) else if "%FLAVOR_OPTION%"=="2" (
    set FLAVOR_NAME=alsur
) else (
    echo Opcion invalida. Saliendo...
    exit /b
)

:: Elegir entorno (QA o Prod)
echo.
echo Elige el entorno:
echo [1] QA
echo [2] Produccion
set /p ENV_OPTION=Opcion:

if "%ENV_OPTION%"=="1" (
    set IS_PROD=false
    set FLAVOR_SUFFIX=Qa
) else if "%ENV_OPTION%"=="2" (
    set IS_PROD=true
    set FLAVOR_SUFFIX=Prod
) else (
    echo Opcion invalida. Saliendo...
    exit /b
)

:: Elegir modo de build (release o debug)
echo.
echo Elige el modo de build:
echo [1] Release
echo [2] Debug
set /p BUILD_OPTION=Opcion:

if "%BUILD_OPTION%"=="1" (
    set BUILD_MODE=release
) else if "%BUILD_OPTION%"=="2" (
    set BUILD_MODE=debug
) else (
    echo Opcion invalida. Saliendo...
    exit /b
)

:: Compilar
echo.
echo ========================================
echo Compilando: !FLAVOR_NAME! (!FLAVOR_SUFFIX!) en modo !BUILD_MODE!
echo ========================================

flutter build apk --flavor !FLAVOR_NAME!!FLAVOR_SUFFIX! --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!

pause
