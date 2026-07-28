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
echo     RATON     Mirar              WASD      Caminar
echo     SHIFT     Correr a pie / control fino
echo     ESPACIO   Saltar
echo     E         Recoger el mando; bajar gancho al operar
echo     F         Soltar el mando
echo     1, 2, 3  Inspeccion previa obligatoria
echo     W / S    Puente adelante / atras al operar
echo     A / D    Carro izquierda / derecha al operar
echo     Q / E    Subir / bajar gancho al operar
echo     V         Viento ON / OFF     R         Reset maquina
echo     TAB       Cambiar camara      C         Reset camara
echo     F1        Ayuda               L         Idioma
echo     ESC       Capturar / liberar raton
echo.
echo   Cierra la ventana del simulador para volver aqui.
echo.

"%GODOT%" --path src/simulator %*

echo.
echo  Simulador cerrado.
pause
