# Contrato de datos: Firebase (colección `reports`)

Esta feature no expone una API REST propia — su "contrato externo" es el esquema de datos que crea
en Firebase, del cual dependerán directamente futuras features ("Mis Reportes", "Mapa de Reportes",
detalle de un reporte) sin necesidad de leer el código de `data/` de esta feature. Cualquier cambio a
este esquema debe mantenerse retrocompatible con lo documentado aquí, o coordinarse con esas features.

## Colección `reports`

Un documento por reporte enviado exitosamente. El ID del documento es el autogenerado por Firestore
(`reports.doc().id`), reservado *antes* de subir la foto (research.md §3) — no tiene significado de
negocio por sí mismo, el identificador visible para el usuario es `reportNumber`.

| Campo | Tipo (Firestore) | Obligatorio | Descripción |
|---|---|---|---|
| `reportNumber` | `string` | Sí | Único, formato `#IL-{año}-{consecutivo de 6 dígitos}` (ej. `"#IL-2026-000125"`) |
| `wasteCategory` | `string` | Sí | Uno de: `"basuraAcumulada"`, `"escombros"`, `"mueblesEnseres"`, `"residuosVerdes"`, `"otros"` (nombre del enum `WasteCategory`, no el label en español) |
| `description` | `string` | Sí (puede ser `""`) | Texto libre opcional del usuario (FR-009) |
| `latitude` | `number` \| `null` | No | Coordenada automática, si se obtuvo |
| `longitude` | `number` \| `null` | No | Coordenada automática, si se obtuvo |
| `automaticAddress` | `string` \| `null` | No | Dirección legible por reverse geocoding, o coordenadas crudas de respaldo (research.md §6) |
| `manualAddress` | `string` \| `null` | No | Dirección escrita por el usuario, si la llenó |
| `address` | `string` | Sí | Dirección final a mostrar — `manualAddress` si existe, si no `automaticAddress` (regla de mapeo en `data-model.md`) |
| `photoUrl` | `string` | Sí | URL de descarga de Firebase Storage de la foto ya comprimida |
| `createdAt` | `timestamp` (`FieldValue.serverTimestamp()`) | Sí | Fecha/hora de creación del reporte, asignada por el servidor |

**Invariante**: un documento en `reports` solo existe si su foto correspondiente ya está subida en
Storage — nunca hay un documento con `photoUrl` inválido o faltante (research.md §4).

## Colección `counters` (soporte interno, no es un domain model)

| Documento | Campo | Tipo | Descripción |
|---|---|---|---|
| `reports_{año}` (ej. `reports_2026`) | `count` | `number` (entero) | Consecutivo más alto ya asignado para reportes de ese año. Se incrementa dentro de la misma transacción que crea el documento de `reports` (research.md §2) |

Este documento es un detalle de implementación de `ReportFirestoreService` — ninguna otra feature
debería leerlo ni depender de él directamente; solo se documenta aquí porque vive en el mismo backend
y explica de dónde sale el consecutivo de `reportNumber`.

## Firebase Storage

| Ruta | Descripción |
|---|---|
| `reports/{documentId}.jpg` | Foto ya comprimida (≤2 MB) asociada al documento `reports/{documentId}` |

El archivo se sube **antes** de crear el documento de Firestore, usando el mismo `documentId` que
tendrá el documento (research.md §3/§4). Si la creación del documento falla después de subir la foto,
`ReportRepositoryImpl` borra este archivo como compensación — no deben quedar archivos en `reports/`
sin un documento de Firestore correspondiente.

## Compatibilidad hacia adelante

- Se pueden agregar campos opcionales nuevos (ej. un futuro `status` para seguimiento) sin romper
  este contrato, siempre que no se exija en la lectura que hagan las features actuales.
- No se debe renombrar ni eliminar ninguno de los campos obligatorios listados arriba sin actualizar
  este documento y coordinar el cambio con cualquier feature que ya dependa de él.
