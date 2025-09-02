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
echo [3] TrackIt
set /p FLAVOR_OPTION=Opcion:

if "%FLAVOR_OPTION%"=="1" (
    set FLAVOR_NAME=familcar
) else if "%FLAVOR_OPTION%"=="2" (
    set FLAVOR_NAME=alsur
) else if "%FLAVOR_OPTION%"=="3" (
    set FLAVOR_NAME=trackit
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

:: Elegir plataforma
echo.
echo Elige la plataforma:
echo [1] APK (Android)
echo [2] Web
echo [3] Windows
echo [4] Todas
set /p PLATFORM_OPTION=Opcion:

:: Confirmación
echo.
echo ========================================
echo Compilando: !FLAVOR_NAME! (!FLAVOR_SUFFIX!) en modo !BUILD_MODE!
echo Plataforma: !PLATFORM_OPTION!
echo ========================================

:: --- APK ---
if "%PLATFORM_OPTION%"=="1" (
    flutter build apk --flavor !FLAVOR_NAME!!FLAVOR_SUFFIX! --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!
)

:: --- Web ---
if "%PLATFORM_OPTION%"=="2" (
    echo Limpiando recursos web...
    if exist web\icons (
        rmdir /S /Q web\icons
    )
    if exist web\manifest.json (
        del /Q web\manifest.json
    )
    if exist web\favicon.png (
        del /Q web\favicon.png
    )
    echo Copiando archivos web para !FLAVOR_NAME!...
    xcopy /E /Y /I web_assets\!FLAVOR_NAME!\* web\
    flutter build web --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!
)

:: --- Windows ---
if "%PLATFORM_OPTION%"=="3" (
    echo Copiando icono para Windows...
    copy /Y windows_assets\!FLAVOR_NAME!\app_icon.ico windows\runner\resources\app_icon.ico
    flutter build windows --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!
)

:: --- Todas las plataformas ---
if "%PLATFORM_OPTION%"=="4" (
    :: APK
    flutter build apk --flavor !FLAVOR_NAME!!FLAVOR_SUFFIX! --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!

    :: Web
    echo Limpiando recursos web...
    if exist web\icons (
        rmdir /S /Q web\icons
    )
    if exist web\manifest.json (
        del /Q web\manifest.json
    )
    if exist web\favicon.png (
        del /Q web\favicon.png
    )
    echo Copiando archivos web para !FLAVOR_NAME!...
    xcopy /E /Y /I web_assets\!FLAVOR_NAME!\* web\
    flutter build web --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!

    :: Windows
    echo Copiando icono para Windows...
    copy /Y windows_assets\!FLAVOR_NAME!\app_icon.ico windows\runner\resources\app_icon.ico
    flutter build windows --!BUILD_MODE! --dart-define=FLAVOR=!FLAVOR_NAME! --dart-define=IS_PROD=!IS_PROD!
)

pause
