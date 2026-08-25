# Phase 0 Research: Crear Reporte

El input técnico del usuario para `/speckit-plan` ya fijó las decisiones principales (backend
Firebase, paquetes de foto/ubicación, atomicidad del envío). Este documento registra cómo se
resuelven en el diseño y qué alternativas se descartaron — no quedó ningún `NEEDS CLARIFICATION`.

## 1. Backend: Firebase (Firestore + Storage)

- **Decision**: `cloud_firestore` para los datos estructurados del reporte (colección `reports`) y
  `firebase_storage` para la foto ya comprimida. `ReportRepository` (interfaz en Domain) es el único
  punto de entrada desde Presentation; `ReportRepositoryImpl` (Data) coordina ambos servicios.
- **Rationale**: ya es el backend aprobado en el Principio I de la constitución para features que no
  requieren una API REST propia; evita operar un servidor propio para esta funcionalidad.
- **Alternatives considered**: `dio` + API REST propia — descartado explícitamente por el usuario en
  esta iteración (Firebase es el backend elegido para "Crear Reporte").

## 2. Generación del número de reporte único

- **Decision**: una transacción de Firestore sobre un documento contador por año
  (`counters/reports_{año}`, campo `count`) que lee el valor actual, lo incrementa, y usa el nuevo
  valor como consecutivo. El número final se formatea como `#IL-{año}-{consecutivo con padding a 6
  dígitos}` (ej. `#IL-2026-000125`), igual al formato ilustrado en el spec.
- **Rationale**: una transacción de Firestore garantiza que dos envíos concurrentes nunca reciban el
  mismo consecutivo (lectura+escritura atómica), sin necesitar un backend adicional (Cloud Function)
  fuera del alcance de esta feature.
- **Alternatives considered**:
  - Usar directamente el ID autogenerado del documento (`reports.doc().id`, un string alfanumérico
    de Firestore) como número de reporte — descartado: no es legible ni sigue el formato
    `#IL-{año}-{consecutivo}` que el usuario definió explícitamente.
  - Generar el consecutivo en el cliente contando documentos existentes (`count()` query) sin
    transacción — descartado: no es atómico, dos envíos simultáneos podrían recibir el mismo número.

## 3. Identificador de la foto antes de crear el documento

- **Decision**: usar `FirebaseFirestore.instance.collection('reports').doc()` (sin argumentos) para
  obtener una referencia con un ID autogenerado *antes* de escribir nada. Ese `docId` se usa como
  nombre del archivo en Storage (`reports/{docId}.jpg`), subiéndolo primero; solo si la subida tiene
  éxito se continúa con la transacción de Firestore que hace `.set()` sobre esa misma referencia con
  el número de reporte ya calculado.
- **Rationale**: evita agregar una dependencia nueva (ej. `package:uuid`, no aprobada en la
  constitución) para generar un identificador único de archivo — Firestore ya provee uno gratis sin
  necesidad de escritura previa.
- **Alternatives considered**: generar el nombre del archivo con un timestamp — descartado por riesgo
  de colisión si dos reportes se envían en el mismo milisegundo desde instancias distintas de la app.

## 4. Atomicidad de `submitReport` (foto en Storage + documento en Firestore)

- **Decision**: `ReportRepositoryImpl.submitReport` ejecuta la secuencia: (1) comprime ya viene hecha
  desde `PhotoRepository`, (2) sube la foto a Storage vía `ReportStorageService.upload(docId, bytes)`,
  (3) si la subida fue exitosa, ejecuta la transacción de Firestore (contador + `.set()` del
  documento) vía `ReportFirestoreService.createReport(...)`. Si el paso 3 falla, se llama a
  `ReportStorageService.delete(docId)` en un `try/catch` de mejor esfuerzo (su resultado no afecta el
  `Failure` ya determinado) para no dejar la foto huérfana, y se retorna `Left(Failure)`. Si el paso 2
  falla, nunca se llega a crear el documento, por lo que no existe el caso inverso de "documento sin
  foto".
- **Rationale**: Firestore y Storage son productos separados sin transacciones conjuntas nativas; la
  compensación manual (subir → si falla el paso siguiente, borrar) es el patrón estándar para lograr
  consistencia "casi atómica" entre ambos, y es exactamente lo que pidió el usuario.
- **Alternatives considered**: crear primero el documento de Firestore con `photoUrl: null` y luego
  subir la foto y actualizar el documento — descartado: dejaría temporalmente (o permanentemente, si
  falla la subida) un reporte "confirmado" sin foto, violando el requisito de que la foto es
  obligatoria para que un reporte exista.

## 5. Permisos unificados (cámara, galería, ubicación)

- **Decision**: `permission_handler` es el único punto que solicita/verifica permisos de cámara,
  galería (fotos) y ubicación, dentro de `PhotoRepositoryImpl` y `LocationRepositoryImpl`
  respectivamente. `image_picker` y `geolocator` solo se invocan *después* de confirmar el permiso
  concedido — no se usan sus propios flujos internos de solicitud de permiso.
- **Rationale**: es la instrucción explícita del usuario ("de forma unificada"), y evita tener dos
  fuentes distintas de verdad sobre el estado de un permiso (la de `permission_handler` y la interna
  de cada plugin).
- **Alternatives considered**: dejar que cada plugin (`image_picker`, `geolocator`) maneje sus propios
  permisos nativos — descartado por el usuario explícitamente.

## 6. Ubicación automática: coordenadas + reverse geocoding

- **Decision**: `LocationRepositoryImpl.getCurrentLocation()` primero verifica/solicita el permiso de
  ubicación con `permission_handler`; si se concede, obtiene la posición con `geolocator`
  (`getCurrentPosition`), y luego reverse-geocodea con `geocoding` (`placemarkFromCoordinates`) para
  construir un string de dirección legible. Si el permiso se deniega o `geolocator` falla (GPS
  apagado, timeout, servicio deshabilitado), se retorna `Left(PermissionFailure)` o
  `Left(LocationFailure)` según el caso — Presentation interpreta cualquier `Left` de este método como
  "ubicación automática no disponible" (FR-013), sin distinguir la causa exacta en la UI más allá de
  lo que ya define el spec.
- **Assumption**: si las coordenadas se obtienen pero el reverse geocoding falla (ej. sin señal para
  resolver la dirección), se considera que la ubicación automática **sí** se obtuvo (FR-012 aplica) y
  se usa un texto de respaldo con las coordenadas crudas (`"{lat}, {lng}"`) como `automaticAddress`,
  en vez de forzar al usuario a llenar la dirección manual por un fallo secundario de geocodificación.
- **Alternatives considered**: tratar cualquier fallo de `geocoding` como "ubicación automática no
  disponible" — descartado por la assumption anterior: las coordenadas por sí solas ya son una
  ubicación automática válida y verificable, aunque no se pueda mostrar como texto legible.

## 7. Compresión de foto a ≤2 MB

- **Decision**: `PhotoCompressorService` aplica una secuencia fija de intentos con
  `flutter_image_compress` hasta que el resultado pese ≤2 MB (2 097 152 bytes) o se agoten los
  intentos: `(quality: 88, minWidth: 1920)` → `(70, 1920)` → `(50, 1280)` → `(35, 1024)`. El resultado
  final (haya o no bajado de 2 MB) se envuelve en la entidad `Photo`, cuyo getter puro
  `exceedsMaxSize` (`sizeBytes > maxPhotoBytes`) es lo que decide si se muestra el texto rojo de
  "imagen muy grande" (FR-006) — la compresión en sí nunca produce un `Failure`.
- **Rationale**: un límite de intentos fijo evita loops de compresión indefinidos y da un
  comportamiento predecible; degradar primero la calidad y luego la resolución preserva mejor el
  detalle útil de la foto de un punto sucio que reducir resolución de entrada.
- **Alternatives considered**: comprimir en un único paso con calidad fija — descartado: fotos de
  cámaras de alta resolución (12+ MP) frecuentemente no bajan de 2 MB con un solo nivel de calidad.

## 8. Estrategia de testing frente a SDKs nativos/Firebase

- **Decision**: los `*RepositoryImpl` (donde vive toda la lógica de negocio: orquestación, mapeo de
  errores, reglas de "ubicación disponible", rollback de foto) se testean con `mocktail` mockeando sus
  propios `Service` (interfaces delgadas definidas por esta feature), no las clases del SDK de
  Firebase/`geolocator`/`image_picker` directamente. Los `Service` (`ReportFirestoreService`,
  `ReportStorageService`, `PhotoCaptureService`, `PhotoCompressorService`, `GeolocationService`,
  `GeocodingService`) se mantienen deliberadamente delgados (una llamada al SDK por método, sin
  lógica condicional propia) y se validan manualmente vía `quickstart.md`, no con tests unitarios
  profundos.
- **Rationale**: los tipos concretos de `cloud_firestore`/`firebase_storage` (`DocumentReference`,
  `Transaction`, etc.) no son mockeables de forma directa y simple con `mocktail`; paquetes que sí lo
  resuelven (`fake_cloud_firestore`, `firebase_storage_mocks`) no están en la lista de paquetes
  aprobados de la constitución. Mantener los Services delgados hace que casi toda la lógica testeable
  ya viva en el Repository, que sí se mockea sin fricción.
- **Alternatives considered**: proponer `fake_cloud_firestore`/`firebase_storage_mocks` como enmienda
  a la constitución para poder testear los Services directamente — se deja fuera de esta feature (ver
  Next Actions del plan); no bloquea el envío/aprobación de este plan porque el Principio V/Flujo de
  Desarrollo solo exige tests de Repository mockeando sus Services, no de los Services mismos.

## 9. Prerrequisito externo: proyecto de Firebase

- **Decision**: se asume que el equipo ya cuenta con (o creará antes de `/speckit-implement`) un
  proyecto de Firebase, y que se ejecutará `flutterfire configure` para generar
  `lib/firebase_options.dart`, `android/app/google-services.json` y
  `ios/Runner/GoogleService-Info.plist`. Ninguno de estos archivos se genera a mano como parte de esta
  feature — son artefactos de configuración externos, ligados a credenciales del proyecto de Firebase
  real, fuera del alcance de lo que un plan/spec puede definir.
- **Rationale**: es un prerrequisito de infraestructura común a cualquier feature que use Firebase por
  primera vez en un proyecto Flutter; no es una decisión de diseño de esta feature sino un paso de
  setup que requiere acceso a la consola de Firebase del equipo.

## Interfaces externas

Esta feature sí expone un contrato con un sistema externo: el esquema de la colección `reports` y del
contador en Firestore, y la convención de rutas de Firebase Storage. Se documenta en
`contracts/firestore-reports-contract.md` (Fase 1), ya que futuras features ("Mis Reportes", "Mapa de
Reportes") leerán esta misma colección y deben conocer su forma exacta sin necesidad de leer el código
de `data/`.
