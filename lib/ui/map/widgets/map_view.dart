import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/models/report.dart';
import 'map_marker_cluster_layer.dart';
import 'report_marker_style.dart';

/// Mapa base (OpenStreetMap vía `flutter_map`) con la capa de marcadores /
/// clustering encima. `ConsumerStatefulWidget` porque necesita un
/// `MapController` local (controlador efímero — Excepción del Principio III de
/// la constitución) para el encuadre automático.
class MapView extends ConsumerStatefulWidget {
  const MapView({required this.reports, this.tileProvider, super.key});

  /// Reportes ya filtrados y mapeables (de `mapMarkersProvider`).
  final List<Report> reports;

  /// Inyectable en tests para no pegarle a la red (research.md §7). En la app
  /// real es `null` → `flutter_map` usa su `NetworkTileProvider`.
  final TileProvider? tileProvider;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reports != oldWidget.reports) {
      _fitToReports();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// FR-008/FR-009/FR-016/FR-023: encuadra a los marcadores visibles; con uno
  /// solo, centra con zoom legible; con ninguno, centra en Ibagué.
  void _fitToReports() {
    if (!_ready) return;
    // Un `Set` descarta coordenadas idénticas: si todos los reportes caen en
    // el mismo punto, `fitCamera` recibiría un bounds de área cero y lanzaría.
    final points = <LatLng>{
      for (final r in widget.reports)
        if (r.latitude != null && r.longitude != null)
          LatLng(r.latitude!, r.longitude!),
    }.toList();
    if (points.isEmpty) {
      _controller.move(kIbagueCenter, kCityZoom);
    } else if (points.length == 1) {
      _controller.move(points.first, kSingleMarkerZoom);
    } else {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: kIbagueCenter,
        initialZoom: kCityZoom,
        onMapReady: () {
          _ready = true;
          _fitToReports();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.juanpvivas.limpiapp',
          tileProvider: widget.tileProvider,
          // Sin fade-in: evita un Timer de 800 ms colgado tras desmontar el
          // mapa (rompe los widget tests) y simplifica el render.
          tileDisplay: const TileDisplay.instantaneous(),
          // Constitución v2.4.0, Principio V: un fallo de tesela NO se
          // envuelve en un Failure — se degrada aquí (mapa sin mosaicos,
          // marcadores y controles siguen operativos).
          errorTileCallback: (tile, error, stackTrace) {},
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
        ),
        MapMarkerClusterLayer(reports: widget.reports),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
