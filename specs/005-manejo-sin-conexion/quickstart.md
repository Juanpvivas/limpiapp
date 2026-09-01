# Quickstart: Validar Manejo de estado sin conexión

Guía para verificar de punta a punta las 3 User Stories del [spec.md](./spec.md). Comportamiento
detallado en [contracts/offline-contract.md](./contracts/offline-contract.md); decisiones técnicas
en [research.md](./research.md).

## Prerrequisitos

- La rama `fix/issue-3-offline-read-hang` (bug #3) **mergeada a `main`** y esta rama rebasada sobre
  ella (research.md §8). Si no, falta portar `_failIfNoFirstEvent` primero.
- Enmienda a la constitución para `connectivity_plus` aplicada (`/speckit-constitution`, v2.5.0) y
  `flutter pub add connectivity_plus` + `flutter pub get`.
- `dart run build_runner build --delete-conflicting-outputs` (por el `.g.dart` del provider nuevo).
- Proyecto de Firebase ya configurado (features 002–004).
- Un dispositivo/emulador Android **físico o con toggles de red reales** para poder alternar
  avión/WiFi. Para el caso "WiFi sin internet real": una red WiFi sin salida a internet, o cortar
  la salida del router.
- Al menos 2–3 reportes ya enviados desde el dispositivo (para las pruebas de lectura con datos).

## Levantar la app

```bash
cd limpiapp
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Escenarios a validar

### 1. Aviso global de sin conexión (US1, P1)

1. Con conexión, navegá por Inicio, Reportar y Mapa: **no** debe haber ninguna franja.
2. Activá **modo avión**. En ≤ 3 s aparece la franja de "sin conexión" en la pantalla actual;
   navegá a las otras y confirmá que también está (incluida "Confirmación" si llegás a ella con un
   reporte previo).
3. Verificá que podés desplazarte y tocar controles con normalidad (la franja no bloquea).
4. Desactivá modo avión. En ≤ 5 s la franja desaparece **sola**, sin tocar nada.
5. Activá/desactivá modo avión un par de veces rápido: la franja no debe parpadear de forma
   abrupta (se estabiliza antes de mostrarse/ocultarse).
6. Conectate a una **WiFi sin internet real**: tras un par de operaciones de la app que fallan
   (abrí "Mis reportes"/"Mapa"), la franja aparece aunque el dispositivo reporte que tiene red.

**Resultado esperado**: FR-001 a FR-005a, FR-019; SC-002, SC-003.

### 2. Las pantallas de lectura no se cuelgan (US2, P2)

1. Con **modo avión** y sin haber abierto antes esas pantallas en esta sesión, abrí "Mis reportes":
   en ≤ 10 s aparece el estado de error con "Reintentar" (nunca el spinner infinito). El mensaje es
   el específico de "sin conexión".
2. Repetí con "Mapa de reportes".
3. Desactivá modo avión y tocá "Reintentar": cargan los reportes y desaparece el estado de error.
4. Seguí en modo avión y tocá "Reintentar" otra vez: vuelve al mismo estado de error (no spinner).
5. Con conexión, abrí "Mis reportes" y dejá la pantalla abierta y quieta 5 minutos: **no** debe
   caer en estado de error.
6. Con "Mis reportes" mostrando datos, activá modo avión: los reportes visibles **permanecen** y
   aparece la franja; la pantalla no se reemplaza por el estado de error.
7. Con el backend accesible pero forzando un error de servidor (ej. reglas de Firestore que
   denieguen), el estado de error muestra el **mensaje genérico de servidor**, no el de "sin
   conexión".

**Resultado esperado**: FR-006 a FR-011, FR-019; SC-001, SC-007, SC-008.

### 3. El envío falla claro y sin perder el borrador (US3, P3)

1. Con **modo avión**, completá el formulario de "Crear reporte" y tocá "Enviar": en ≤ 10 s
   aparece el mensaje específico ("Sin conexión: el reporte no se envió y no se guardó nada."), el
   botón deja de estar en "enviando…".
2. Verificá que la foto, el tipo de residuo, la descripción y la ubicación **siguen** en el
   formulario.
3. Desactivá modo avión y tocá "Enviar" de nuevo: se completa, se asigna número y se muestra
   "Confirmación".
4. Revisá "Mis reportes" y el "Mapa": **no** hay ningún reporte del intento fallido; solo el que
   se envió al reintentar.
5. Caso "a mitad": empezá un envío con conexión y activá modo avión justo después de tocar
   "Enviar": el resultado es el mismo (mensaje de fallo, nada guardado, datos conservados, botón
   liberado en ≤ 10 s).

**Resultado esperado**: FR-012 a FR-018; SC-004, SC-005, SC-006.

## Checks automatizados

```bash
flutter analyze
flutter test
```

Cobertura esperada (ver plan.md → Project Structure):
- `test/data/services/connectivity_service_test.dart` — sin interfaz → offline; 2 fallos
  consecutivos → offline; un `reportBackendReachable()` resetea; debounce asimétrico.
- `test/data/repositories/connectivity_repository_impl_test.dart` — mapea el stream del Service.
- `test/ui/core/connectivity_provider_test.dart` — `ProviderContainer`: estados y debounce; trata
  `AsyncLoading` como `online`.
- `test/ui/core/offline_banner_test.dart` — `WidgetTester`: aparece con `offline`, desaparece con
  `online`, no intercepta gestos.
- `test/data/repositories/report_repository_impl_test.dart` (ampliado) — un paso de red que no
  responde en el timeout → `Left(NetworkFailure)` + intento de compensación.
- `test/ui/reports/new_report_provider_test.dart` (ampliado) — pre-check offline (no llama al
  Repository, `submitError` específico, `isSubmitting` no queda en true); `Left(NetworkFailure)` →
  mensaje específico; `isSubmitting` vuelve a false en timeout.
- `test/ui/reports/report_list_screen_test.dart` y `test/ui/map/report_map_screen_test.dart`
  (ampliados) — `DataErrorState` con mensaje offline cuando `NetworkFailure`/offline vs. genérico
  con `ServerFailure`; el estado de error no se limpia solo al volver `online`.
