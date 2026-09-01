import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/service_locator.dart';
import '../../../domain/models/connectivity_status.dart';
import '../../../domain/models/failure.dart';
import '../../../domain/models/new_report_draft.dart';
import '../../../domain/models/photo.dart';
import '../../../domain/models/report.dart';
import '../../../domain/models/waste_category.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/repositories/photo_repository.dart';
import '../../../domain/repositories/report_repository.dart';
import '../../core/offline_copy.dart';
import '../../core/providers/connectivity_provider.dart';
import 'new_report_state.dart';

part 'new_report_provider.g.dart';

/// Mensaje genérico de fallo de envío (backend que responde con error).
const _kGenericSubmitError = 'No se pudo enviar el reporte. Intenta de nuevo.';

/// Lógica de presentación de "Nuevo reporte": resuelve sus dependencias vía
/// `getIt<T>()` (Principio V) y nunca importa `lib/data/` (Principio IV.2).
@riverpod
class NewReportNotifier extends _$NewReportNotifier {
  @override
  NewReportState build() {
    // No se puede escribir `state` de forma síncrona dentro de `build()`
    // (el provider aún no termina de inicializarse) — por eso
    // `isLoadingLocation: true` se fija aquí, en el valor de retorno, y
    // `_loadAutomaticLocation` solo toca `state` después de su primer
    // `await`, cuando el provider ya está inicializado.
    _loadAutomaticLocation();
    return const NewReportState(isLoadingLocation: true);
  }

  Future<void> _loadAutomaticLocation() async {
    final result = await getIt<LocationRepository>().getCurrentLocation();
    // FR-013/FR-014: un Left solo significa "ubicación automática no
    // disponible" — no bloquea el resto del formulario.
    state = result.match(
      (failure) => state.copyWith(isLoadingLocation: false, autoLocation: null),
      (location) =>
          state.copyWith(isLoadingLocation: false, autoLocation: location),
    );
  }

  Future<void> pickPhotoFromCamera() =>
      _pickPhoto(getIt<PhotoRepository>().pickFromCamera);

  Future<void> pickPhotoFromGallery() =>
      _pickPhoto(getIt<PhotoRepository>().pickFromGallery);

  Future<void> _pickPhoto(
    Future<Either<Failure, Photo?>> Function() pick,
  ) async {
    final result = await pick();
    result.match(
      (failure) {
        // FR-005: solo un permiso denegado dispara la alerta obligatoria.
        if (failure is PermissionFailure) {
          state = state.copyWith(showPermissionDeniedAlert: true);
        }
      },
      (photo) {
        // `photo == null` es cancelación del usuario (no error): se
        // ignora sin tocar el state.
        if (photo != null) {
          state = state.copyWith(photo: photo);
        }
      },
    );
  }

  void setCategory(WasteCategory category) {
    state = state.copyWith(category: category);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setManualAddress(String manualAddress) {
    state = state.copyWith(manualAddress: manualAddress);
  }

  /// Resetea la alerta de permiso tras mostrarse — si no se reseteara,
  /// seguiría en `true` y podría reaparecer en cualquier rebuild posterior.
  void dismissPermissionAlert() {
    state = state.copyWith(showPermissionDeniedAlert: false);
  }

  /// Retorna el `Report` directamente al caller si el envío fue exitoso (el
  /// widget lo usa para navegar a "Confirmación"); `null` si falló o si aún
  /// no se puede enviar. El `Report` nunca se guarda en `NewReportState`.
  Future<Report?> submit() async {
    if (!state.canSubmit || state.isSubmitting) return null;

    // FR-013: si ya se sabe que no hay conexión, fallar rápido sin tocar
    // Storage/Firestore. `isSubmitting` nunca pasa a `true`.
    if (_isOffline) {
      state = state.copyWith(submitError: kOfflineSubmitErrorText);
      return null;
    }

    state = state.copyWith(isSubmitting: true, submitError: null);

    final draft = NewReportDraft(
      photo: state.photo!,
      category: state.category!,
      description: state.description,
      location: state.location,
    );

    final result = await getIt<ReportRepository>().submitReport(draft);

    return result.match(
      (failure) {
        // FR-015/SC-005: solo se actualizan estas 2 banderas — el resto del
        // formulario (foto, categoría, descripción, ubicación) permanece
        // intacto para poder reintentar sin perder datos. Aplica también al
        // camino de timeout (`Left(NetworkFailure)`).
        state = state.copyWith(
          isSubmitting: false,
          submitError: (failure is NetworkFailure || _isOffline)
              ? kOfflineSubmitErrorText // FR-018
              : _kGenericSubmitError,
        );
        return null;
      },
      (report) {
        state = state.copyWith(isSubmitting: false);
        return report;
      },
    );
  }

  bool get _isOffline =>
      ref.read(connectivityStatusProvider).value == ConnectivityStatus.offline;
}
