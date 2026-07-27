@echo off
REM Doble clic para abrir el simulador de grua puente.
REM Cualquier argumento extra se pasa tal cual a Godot.
cd /d "%~dp0"

set "GODOT=tools\godot\Godot_v4.6.3-stable_win64_console.exe"

if not exist "%GODOT%" (
    echo.
    echo  ERROR: no encuentro Godot en:
    echo    %~dp0%GODOT%
    echo.
    pause
    exit /b 1
)

echo.
echo  ==========================================================
echo   SIMULADOR DE GRUA PUENTE - Gelderland Operator Academy
echo  ==========================================================
echo.
echo   CONTROLES:
echo     1, 2, 3  Inspeccion previa  ^(OBLIGATORIA: la grua
echo              arranca SIN corriente y no se movera hasta
echo              completar las tres comprobaciones^)
echo     W / S    Puente adelante / atras
echo     A / D    Carro izquierda / derecha
echo     Q / E    Subir / bajar gancho
echo     SHIFT    Modo fino ^(velocidad reducida^)
echo     V        Viento ON / OFF
echo     R        Reset
echo     C        Reset de camara
echo     Flechas  Orbitar camara      + / -   Zoom
echo     L        Idioma NL / EN
echo.
echo   Cierra la ventana del simulador para volver aqui.
echo.

"%GODOT%" --path src/simulator %*

echo.
echo  Simulador cerrado.
pause
