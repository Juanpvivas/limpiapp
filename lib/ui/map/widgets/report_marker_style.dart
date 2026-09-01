import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/models/report_status.dart';

/// Centro por defecto del mapa cuando no hay marcadores que encuadrar
/// (FR-023). Ibagué, Tolima.
const LatLng kIbagueCenter = LatLng(4.4389, -75.2322);

/// Zoom a nivel ciudad (estado vacío) y zoom para un único marcador
/// (FR-009 — legible, no un acercamiento máximo).
const double kCityZoom = 12;
const double kSingleMarkerZoom = 15;

/// Color de la burbuja de clúster: neutro, no un color de estado — un clúster
/// puede agrupar reportes de estados distintos (research.md §10).
const Color kClusterColor = Color(0xFF37474F);

/// Color del marcador según el estado del reporte (FR-005, mock
/// `docs/mocks/6 mapa reporte.jpg`). Distinto de la paleta de
/// `ReportStatusChip` (ámbar/azul/verde) usada en la tarjeta resumen —
/// divergencia deliberada, ver research.md §6.
Color markerColorFor(ReportStatus status) => switch (status) {
  ReportStatus.pendiente => const Color(0xFFD32F2F), // rojo
  ReportStatus.enProceso => const Color(0xFFF57C00), // naranja
  ReportStatus.solucionado => const Color(0xFF388E3C), // verde
};

/// Entradas de la leyenda color → estado (FR-007), en el mismo orden que el
/// mock.
const List<({Color color, String label})> kMarkerLegend = [
  (color: Color(0xFFD32F2F), label: 'Pendiente'),
  (color: Color(0xFFF57C00), label: 'En proceso'),
  (color: Color(0xFF388E3C), label: 'Solucionado'),
];
