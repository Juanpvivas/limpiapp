# Quickstart: Validar Crear Reporte

Guía para verificar manualmente, de punta a punta, que las 3 User Stories del
[spec.md](./spec.md) funcionan antes de dar la feature por completa.

## Prerrequisitos

- Flutter SDK `^3.13.1` instalado (`flutter --version`).
- Dependencias instaladas: `flutter pub get` dentro de `limpiapp/`.
- **Proyecto de Firebase configurado** (research.md §9): `flutterfire configure` ya corrido, con
  `lib/firebase_options.dart`, `android/app/google-services.json` e
  `ios/Runner/GoogleService-Info.plist` presentes — sin esto la app no puede inicializar Firebase.
- Firestore y Storage habilitados en el proyecto de Firebase (modo de prueba o reglas que permitan
  escritura desde la app, ya que no hay login).
- Un dispositivo/emulador con cámara y al menos una foto en la galería.
- Permisos de cámara, galería y ubicación del dispositivo en estado "preguntar" (reinstalar la app o
  resetear permisos si ya se habían concedido/denegado en una corrida anterior, para poder probar los
  distintos flujos).

## Levantar la app

```bash
cd limpiapp
flutter pub get
flutter run
```

## Escenarios a validar

### 1. Enviar un reporte completo con éxito (US1, P1)

1. Desde la pantalla de inicio, toca **"Hacer un reporte"** (o **"Reportar"** en la barra inferior).
2. Toca el recuadro de foto, elige "Tomar foto" o "Elegir de galería", y concede el permiso cuando se
   solicite.
3. Elige un tipo de residuo (ej. "Basura acumulada").
4. Deja que el sistema capture la ubicación automáticamente (concede el permiso de ubicación); espera
   a que se muestre una dirección aproximada.
5. Verifica que "Enviar reporte" está habilitado, y tócalo.
6. Verifica que aparece un indicador de progreso y que tocar cualquier otra parte de la pantalla (o
   el botón atrás) no hace nada mientras dura.
7. Al terminar, verifica que se navega a "Confirmación" mostrando el ícono de éxito, el mensaje
   "¡Reporte enviado con éxito!...", un número de reporte con formato `#IL-{año}-{consecutivo}`, el
   mensaje de notificación futura, el botón "Ver mis reportes" y el enlace "Volver al inicio".
8. En la consola de Firebase, confirma que existe un documento nuevo en `reports` con ese
   `reportNumber` y una foto correspondiente en Storage (`reports/{id}.jpg`).

**Resultado esperado**: FR-001 a FR-004, FR-007 a FR-012, FR-015, FR-016, FR-018 a FR-023.

### 2. Completar el reporte cuando la ubicación automática no está disponible (US2, P2)

1. Desactiva el permiso de ubicación de la app (o el GPS del dispositivo) antes de abrir "Nuevo
   reporte", o niega el permiso cuando se solicite.
2. Completa foto y tipo de residuo; verifica que el campo "Dirección manual" se muestra/marca como
   obligatorio.
3. Deja "Dirección manual" vacío y confirma que "Enviar reporte" permanece deshabilitado.
4. Escribe una dirección manual y confirma que "Enviar reporte" se habilita y el envío se completa
   igual que en el Escenario 1, mostrando esa dirección en el documento de Firestore (`address`).

**Resultado esperado**: FR-010, FR-013, FR-014, FR-015.

### 3. Manejar errores de foto y de envío sin perder los datos (US3, P3)

1. Niega el permiso de cámara **y** de galería al intentar agregar una foto → debe aparecer una
   alerta simple indicando que la foto es obligatoria, sin poder continuar. (FR-005)
2. Con una foto de muy alta resolución (o forzando el límite de intentos de compresión), verifica que
   si el resultado sigue pesando más de 2 MB, aparece el texto rojo bajo el recuadro de foto y
   "Enviar reporte" no se habilita con esa foto. Reemplázala por otra más liviana y confirma que el
   texto de error desaparece y el envío se puede habilitar. (FR-006)
3. Completa el formulario válidamente, actívalo en modo avión (o corta la conexión) justo antes de
   tocar "Enviar reporte", y confírmalo:
   - El indicador de progreso se oculta.
   - Aparece un mensaje indicando que el envío falló.
   - Permaneces en "Nuevo reporte" con foto, tipo de residuo, descripción y ubicación intactos.
4. Reactiva la conexión y toca "Enviar reporte" de nuevo sin haber perdido ningún dato → debe
   completarse con éxito y navegar a "Confirmación". (FR-017, SC-004)

**Resultado esperado**: FR-005, FR-006, FR-017.

## Casos límite a probar

- **Ninguna ubicación disponible**: sin ubicación automática y sin dirección manual, "Enviar reporte"
  debe permanecer deshabilitado (FR-014).
- **Doble tap en "Enviar reporte"**: con el progreso ya visible, tocar de nuevo no debe disparar un
  segundo envío ni desbloquear la pantalla.
- **Descripción vacía**: el envío debe completarse igual sin llenar "Descripción" (FR-009).
- **Reemplazo de foto "muy grande"**: confirma que, tras reemplazarla por una válida, el resto de
  campos ya ingresados no se pierden.
- **Sin login**: confirma que en ningún punto de este flujo se pide iniciar sesión o registrarse
  (FR-024).
- **Acceso directo a "Confirmación"**: navegar a la ruta de confirmación sin haber enviado un reporte
  (ej. manipulando la navegación) debe redirigir a Inicio, nunca mostrar una confirmación vacía
  (FR-025).

## Siguiente paso

Con estos escenarios validados manualmente, corre `/speckit-tasks` para desglosar esta feature en
tareas de implementación, y luego `/speckit-implement` para construirla.
