# MCP y herramientas gratuitas

## Decisión principal

No instales ningún MCP antes de la primera vertical slice.

Claude Code ya puede leer/escribir archivos, ejecutar herramientas locales y usar capacidades de navegación disponibles. Un MCP solo se añade cuando elimina un bloqueo concreto.

## Configuración recomendada

### Obligatorio, sin MCP
- Godot 4.6 estable.
- Jolt Physics integrado.
- Git local.
- Python para validadores/hooks.
- GdUnit4 cuando el proyecto Godot exista.
- Blender solo si hacen falta assets propios o reducción de polígonos.

### Opcional
- Playwright CLI/skill: verificar vacantes y probar una exportación web.
- Playwright MCP: solo para sesiones web interactivas difíciles.
- GitHub MCP: solo después de crear un repositorio remoto; activar herramientas mínimas o modo lectura.
- GitHub/`gh` CLI suele bastar.

### No recomendado inicialmente
- Godot MCP comunitario.
- Filesystem MCP duplicando las herramientas nativas.
- Context/documentation MCP permanente.
- Bases vectoriales/RAG para un repositorio pequeño.
- Agentes paralelos masivos.

## Recursos gratuitos
- Documentación oficial local de Godot.
- Poly Haven para HDRI, texturas y modelos CC0.
- GdUnit4 para pruebas.
- Datos y manuales oficiales como referencias, sin copiar tablas propietarias no autorizadas.

## Regla de activación
Añade una herramienta solo si:
- aporta una capacidad nueva;
- reduce trabajo del modelo;
- tiene alcance restringido;
- es mantenida;
- no requiere secretos en el repositorio;
- puede apagarse sin romper el proyecto.
