import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repositories/connectivity_repository_impl.dart';
import '../data/repositories/device_identifier_repository_impl.dart';
import '../data/repositories/location_repository_impl.dart';
import '../data/repositories/photo_repository_impl.dart';
import '../data/repositories/report_list_repository_impl.dart';
import '../data/repositories/report_repository_impl.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/device_identifier_service.dart';
import '../data/services/firebase/report_firestore_service.dart';
import '../data/services/firebase/report_query_service.dart';
import '../data/services/firebase/report_storage_service.dart';
import '../data/services/location/geocoding_service.dart';
import '../data/services/location/geolocation_service.dart';
import '../data/services/permission_service.dart';
import '../data/services/photo/photo_capture_service.dart';
import '../data/services/photo/photo_compressor_service.dart';
import '../domain/repositories/connectivity_repository.dart';
import '../domain/repositories/device_identifier_repository.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/photo_repository.dart';
import '../domain/repositories/report_list_repository.dart';
import '../domain/repositories/report_repository.dart';

/// Único `ServiceLocator` del proyecto (Principio V de la constitución):
/// registra Repositories y Services con `registerLazySingleton`. Se llama
/// desde `main.dart` antes de `runApp()`.
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Clientes de backend administrado — registrados igual que cualquier
  // otro Service, nunca instanciados directamente dentro de un Repository.
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  getIt.registerLazySingleton<ImagePicker>(() => ImagePicker());

  // Services delgados.
  getIt.registerLazySingleton(
    () => ReportFirestoreService(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => ReportQueryService(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => ReportStorageService(getIt<FirebaseStorage>()),
  );
  getIt.registerLazySingleton(() => DeviceIdentifierService());
  getIt.registerLazySingleton(() => PhotoCaptureService(getIt<ImagePicker>()));
  getIt.registerLazySingleton(() => PhotoCompressorService());
  getIt.registerLazySingleton(() => GeolocationService());
  getIt.registerLazySingleton(() => GeocodingService());
  getIt.registerLazySingleton(() => PermissionService());
  getIt.registerLazySingleton(() => Connectivity());
  getIt.registerLazySingleton(() => ConnectivityService(getIt<Connectivity>()));

  // Repositories (interfaz → implementación).
  getIt.registerLazySingleton<DeviceIdentifierRepository>(
    () => DeviceIdentifierRepositoryImpl(getIt<DeviceIdentifierService>()),
  );
  getIt.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(getIt<ConnectivityService>()),
  );
  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(
      firestoreService: getIt<ReportFirestoreService>(),
      storageService: getIt<ReportStorageService>(),
      deviceIdentifierRepository: getIt<DeviceIdentifierRepository>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );
  getIt.registerLazySingleton<ReportListRepository>(
    () => ReportListRepositoryImpl(
      getIt<ReportQueryService>(),
      getIt<ConnectivityService>(),
    ),
  );
  getIt.registerLazySingleton<PhotoRepository>(
    () => PhotoRepositoryImpl(
      permissionService: getIt<PermissionService>(),
      captureService: getIt<PhotoCaptureService>(),
      compressorService: getIt<PhotoCompressorService>(),
    ),
  );
  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      permissionService: getIt<PermissionService>(),
      geolocationService: getIt<GeolocationService>(),
      geocodingService: getIt<GeocodingService>(),
    ),
  );
}
