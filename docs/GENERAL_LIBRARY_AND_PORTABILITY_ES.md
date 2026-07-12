# Biblioteca general y portabilidad

## Claude Code

Para uso transversal en todos los proyectos:
- copia skills genéricas a `~/.claude/skills/`; o
- empaquétalas como plugin versionado.

No conviene hacer globales las skills específicas de Gelderland, TCVT o grúas. Mantén globales solo:
- evidencia y verificación;
- decision logging;
- QA/release;
- handoff;
- investigación con fuentes.

## Claude Web/Desktop

Las custom skills ZIP pueden instalarse en la biblioteca de Skills, pero una skill de Claude Code puede necesitar adaptación si usa Bash, hooks, agentes o rutas locales.

## Otras IAs

Gemini, Grok, ChatGPT y otros agentes no “instalan” automáticamente una skill de Claude. Sí pueden reutilizar:
- `AGENTS.md`;
- `SKILL.md` como procedimiento;
- esquemas JSON/CSV;
- scripts;
- MCPs compatibles;
- un plugin adaptado a su formato.

## Tangencialidad

Alta reutilización:
- vacancy/evidence verifier → empleo, compras, OSINT, proveedores, subvenciones.
- scenario forge → formación, simuladores, SOP, onboarding.
- physics validation → robótica, vehículos, juegos y digital twins.
- release audit → web, backend, apps desktop.
- handoff/decision log → cualquier proyecto largo.

Baja reutilización:
- códigos TCVT;
- búsqueda geográfica Gelderland;
- contenido específico de grúas.
