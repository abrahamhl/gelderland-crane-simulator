# ¿Descomprimir `03_PREVIOUS_SKILLS_REFERENCE_PACK.zip`?

## Respuesta

No dentro de `.claude/skills/`.

El ZIP anterior contiene skills válidas para el planteamiento browser, pero dos chocan con el nuevo objetivo desktop/Godot.

## Qué hacer

- Conserva el ZIP en `_reference/legacy/`.
- Si quieres inspeccionarlo, extráelo en `_reference/legacy/extracted/`.
- No copies sus cuatro skills a `.claude/skills/`.
- Usa las skills V2 que ya vienen activas en este paquete.

## Excepción

`gld-vacancy-verifier` y `operator-scenario-forge` pueden servir como documentación histórica. Sus ideas ya se han incorporado a `verify-vacancies` y `forge-scenario`.
