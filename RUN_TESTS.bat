@echo off
REM Doble clic para ejecutar las dos suites de tests y guardar resultados
REM en logs\MODULE_TEST_RESULTS.json y logs\SELFTEST_RESULTS.json
cd /d "%~dp0"

set "GODOT=tools\godot\Godot_v4.6.3-stable_win64_console.exe"
set "OUT=%~dp0logs"

if not exist "%GODOT%" (
    echo  ERROR: no encuentro Godot en %~dp0%GODOT%
    pause
    exit /b 1
)

echo.
echo  [1/2] Tests de modulos y fisica ^(14 comprobaciones^)...
echo.
"%GODOT%" --headless --path src/simulator --script res://tests/module_tests.gd -- --out="%OUT%"
set "R1=%ERRORLEVEL%"

echo.
echo  [2/2] Test de escena completa ^(21 comprobaciones^)...
echo.
"%GODOT%" --headless --fixed-fps 60 --path src/simulator -- --selftest --out="%OUT%"
set "R2=%ERRORLEVEL%"

echo.
echo  ==========================================================
if "%R1%"=="0" (echo   Fisica pura ....... OK) else (echo   Fisica pura ....... FALLO)
if "%R2%"=="0" (echo   Escena completa ... OK) else (echo   Escena completa ... FALLO)
echo  ==========================================================
echo   Resultados detallados en la carpeta logs\
echo.
pause
