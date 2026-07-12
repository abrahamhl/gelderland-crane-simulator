# Auditoría V2

## Hallazgos

1. El paquete anterior contenía dos skills orientadas expresamente a navegador:
   - `browser-simulator-engineer`
   - `simulator-quality-auditor`

   No deben quedar activas en el proyecto desktop porque fuerzan `index.html`, WebGL y pruebas de navegador.

2. Las skills de vacantes y creación de escenarios eran útiles, pero necesitaban:
   - separación de licencias;
   - ciclo completo de trabajo;
   - validadores desktop/Godot;
   - registro de evidencia y estados nulos.

3. Los cuatro agentes anteriores eran role cards demasiado cortos para Claude Code. V2 usa cinco agentes con:
   - ámbito estrecho;
   - modelo explícito;
   - memoria de proyecto;
   - salidas a archivos;
   - separación entre investigación, física, implementación y QA.

4. Ocho agentes especializados habrían sido excesivos. Localización y factores humanos se aplican mediante reglas/skills, sin abrir agentes adicionales.

## Resultado V2

Skills activas:
1. `verify-vacancies`
2. `map-licences`
3. `forge-scenario`
4. `build-godot-slice`
5. `validate-physics`
6. `audit-release`
7. `handoff`

Agentes:
1. Vacancy evidence researcher — Sonnet
2. Licence/safety researcher — Sonnet
3. Physics architect — inherit/Fable
4. Implementation engineer — inherit/Fable
5. Independent QA auditor — inherit/Fable

## Por qué ahorra

- Investigación y extracción no consumen Fable.
- Los validadores rechazan errores sin releer documentos completos.
- Las reglas se cargan por rutas.
- Las skills se activan solo cuando son relevantes.
- No hay un agente separado para cada microfunción.
- El trabajo repetitivo se desplaza a scripts y hooks.
