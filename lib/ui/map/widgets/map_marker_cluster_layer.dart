import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/models/report.dart';
import '../providers/selected_map_report_provider.dart';
import 'report_marker_style.dart';

/// Capa de marcadores del mapa: un pin por reporte mapeable, coloreado por
/// estado (FR-005/FR-006), con agrupación de los que quedan próximos según el
/// zoom (FR-010/FR-011). Tocar un pin abre su tarjeta resumen (FR-017).
class MapMarkerClusterLayer extends ConsumerWidget {
  const MapMarkerClusterLayer({required this.reports, super.key});

  final List<Report> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = [
      for (final report in reports)
        if (report.latitude != null && report.longitude != null)
          Marker(
            key: ValueKey(report.id),
            point: LatLng(report.latitude!, report.longitude!),
            width: 40,
            height: 40,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => ref
                  .read(selectedMapReportProvider.notifier)
                  .select(report.id),
              child: Icon(
                Icons.location_pin,
                size: 36,
                color: markerColorFor(report.status),
              ),
            ),
          ),
    ];

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 45,
        size: const Size(44, 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(48),
        maxZoom: 18,
        zoomToBoundsOnClick: true,
        builder: (context, clusterMarkers) => DecoratedBox(
          decoration: const BoxDecoration(
            color: kClusterColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${clusterMarkers.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
