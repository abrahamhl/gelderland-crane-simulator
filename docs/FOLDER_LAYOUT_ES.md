# Estructura recomendada

`simulador-grua/` debe ser la raíz abierta en Claude Code.

- `.claude/` — configuración activa
- `research/seed/` — DOCX original, solo lectura
- `research/raw/` — resultados sin limpiar
- `docs/` — arquitectura, licencias y auditorías
- `src/` — proyecto Godot
- `scenarios/` — contratos de escenarios
- `tests/` — pruebas y reportes
- `logs/` — comandos, fallos y trabajo
- `_reference/legacy/` — paquetes anteriores no activos

Evita una carpeta `FINAL...` anidada dentro de otra raíz abierta.
