# Informe técnico — Gelderland Crane Simulator

Fecha de corte: 2026-07-28

## Resultado

El simulador de grúa puente está jugable y sus dos niveles de verificación
automatizada pasan:

| Indicador | Resultado |
|---|---:|
| Período frente a la solución `2π√(L/g)` | **0,15 % de error** |
| Comprobaciones de módulos y física | **14/14** |
| Comprobaciones integradas de escena | **21/21** |
| Total | **35/35** |
| Repetibilidad | Hashes de trayectoria iguales |

Las fuentes machine-readable son `logs/MODULE_TEST_RESULTS.json` y
`logs/SELFTEST_RESULTS.json`. `logs/TEST_LOG.md` conserva también los fallos
intermedios que obligaron a corregir código o planificación de pruebas.

## Corrección humana registrada

El agente de IA diseñó primero una cabina elevada con escalera. La experiencia
directa del propietario en fábrica permitió detectar que el modelo operacional
era incorrecto para la grúa elegida: debía utilizarse un mando desde el suelo.

La corrección es auditable:

1. `DEC-006` conserva la decisión inicial y la marca como sustituida.
2. `DEC-014` registra la corrección y sus consecuencias.
3. El historial Git contiene el hito de cabina y el commit posterior de mando.
4. Las pruebas se actualizaron y volvieron a ejecutarse.

## Capacidades demostradas

- Dirección de un agente de IA contra reglas y límites explícitos.
- Detección de un error factual mediante experiencia de dominio.
- Registro de decisiones de arquitectura y sustituciones.
- Simulación física determinista validada numéricamente.
- Verificación a dos niveles con salidas JSON.
- Documentación honesta de fallos, limitaciones y trabajo pendiente.

## Límites

- La geometría y los materiales siguen siendo provisionales.
- Los coeficientes de impacto necesitan calibración contra un objetivo físico.
- El comportamiento está automatizado; falta una auditoría visual formal de la
  última interfaz, el radio de seguridad y el rebote.
- No es una certificación ni reemplaza formación práctica supervisada.

## Próximo hito

Crear escenarios `SC-002+` con obstáculos, cargas de distinto tamaño y alturas
de colocación diferentes, validarlos uno por uno y mantenerlos separados del
pase artístico.
