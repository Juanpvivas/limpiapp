# Quickstart: Validar el Shell de Navegación Principal

Guía para verificar manualmente, de punta a punta, que las 3 User Stories del
[spec.md](./spec.md) funcionan antes de dar la feature por completa.

## Prerrequisitos

- Flutter SDK `^3.13.1` instalado (`flutter --version`).
- Dependencias instaladas: `flutter pub get` dentro de `limpiapp/`.
- Un emulador/simulador Android o iOS corriendo (esta feature no depende de datos, así que no
  necesitas backend ni conexión a internet — ver Assumptions del spec).

## Levantar la app

```bash
cd limpiapp
flutter pub get
flutter run
```

## Escenarios a validar

### 1. Llegar a las funciones principales desde la pantalla de inicio (US1, P1)

1. Abre la app — debe mostrarse la pantalla de inicio con el branding "Ibagué Limpia", la imagen de
   fondo y el mensaje "Reporta, haz seguimiento y juntos mantengamos nuestra ciudad limpia."
2. Toca **"Hacer un reporte"** → debe navegar a la pantalla placeholder de crear reporte.
3. Vuelve atrás, toca **"Mis reportes"** → debe navegar a la pantalla placeholder de lista de
   reportes.
4. Vuelve atrás, toca **"Mapa de reportes"** → debe navegar a la pantalla placeholder del mapa.

**Resultado esperado**: los 3 botones navegan cada uno a su destino correcto (FR-002 a FR-005).

### 2. Moverse entre secciones desde cualquier pantalla vía barra inferior (US2, P2)

1. Desde cualquier pantalla (por ejemplo, "Mis reportes"), toca **"Mapa"** en la barra de navegación
   inferior.
2. Verifica que navega directo al mapa, **sin pasar** primero por la pantalla de inicio.
3. Repite tocando **"Reportar"** y luego **"Inicio"** desde distintas pantallas.

**Resultado esperado**: los 3 accesos de la barra inferior llevan directo a su sección desde
cualquier punto de la app (FR-006, FR-007).

### 3. Identificar la sección activa (US3, P3)

1. Navega a "Mapa" (por botón o por barra inferior).
2. Observa la barra de navegación inferior: el ícono "Mapa" debe verse visualmente distinto
   (resaltado/seleccionado) respecto a "Inicio" y "Reportar".
3. Repite para las otras 2 secciones.

**Resultado esperado**: el ícono activo en la barra inferior siempre corresponde a la pantalla
visible (FR-008).

## Casos límite a probar

- **Sin conexión**: activa modo avión antes de abrir la app — la pantalla de inicio y toda la
  navegación deben funcionar igual (assets estáticos, sin red).
- **Doble tap**: toca dos veces seguidas y rápido el mismo ícono de la barra inferior estando ya en
  esa sección — no debe abrirse una pantalla duplicada ni apilarse navegación.
- **Sin login**: confirma que en ningún punto de este flujo se pide iniciar sesión o registrarse
  (FR-009).

## Siguiente paso

Con estos escenarios validados manualmente, corre `/speckit-tasks` para desglosar esta feature en
tareas de implementación, y luego `/speckit-implement` para construirla.
