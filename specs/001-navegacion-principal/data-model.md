# Phase 1 Data Model: Shell de Navegación Principal

## Entidades de dominio

**Ninguna.** Esta feature no lee ni escribe datos de negocio — no crea, consulta ni transforma
ninguna entidad (`Report`, `User`, etc.). Por lo tanto no agrega archivos a `domain/models/` ni
`domain/repositories/`. La spec (sección Key Entities omitida) y el Constitution Check del plan ya
confirman que Domain/Data son N/A para esta feature.

## Concepto de UI (no es un domain model)

Para configurar las 3 ramas de `StatefulShellRoute.indexedStack`, `config/routes.dart` usa un
concepto puramente de enrutamiento — **no** vive en `domain/models/` porque no representa una
entidad de negocio, es un detalle de la capa UI:

```dart
enum AppTab { home, reportar, mapa }
```

| Valor | Ruta base | Pantalla |
|---|---|---|
| `home` | `/` | `home_screen.dart` |
| `reportar` | `/reportar` | `new_report_screen.dart` (placeholder) |
| `mapa` | `/mapa` | `report_map_screen.dart` (placeholder) |

`Mis reportes` se alcanza como una ruta anidada dentro de la rama `home` (botón "Mis reportes" en la
pantalla de inicio), no como una cuarta rama de la barra inferior — la barra inferior solo tiene 3
accesos según el spec (Inicio / Reportar / Mapa).

## Validaciones y transiciones de estado

No aplica: no hay datos que validar ni estados de negocio que transicionar en esta feature.
