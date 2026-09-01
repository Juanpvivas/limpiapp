// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Report {

/// ID del documento de Firestore. Necesario para la ruta
/// `/mis-reportes/:reportId` y para `watchReportById`.
 String get id;/// Formato completo `#IL-{año}-{consecutivo}` (research.md §2), ya
/// listo para mostrar (FR-020).
 String get reportNumber; WasteCategory get category; String get description;/// Dirección final mostrable — `manualAddress` si existe, si no
/// `automaticAddress` (regla de mapeo en data-model.md).
 String get address;/// URL de descarga de Firebase Storage de la foto ya subida.
 String get photoUrl; DateTime get createdAt;/// Estado de seguimiento. `pendiente` al crearse; solo lo cambia un
/// mecanismo futuro fuera de alcance (FR-015).
 ReportStatus get status;/// Identificador anónimo del dispositivo que envió el reporte (FR-003),
/// llave de filtro de "Mis Reportes" (FR-004).
 String get deviceId;/// Latitud del punto reportado. `null` si el reporte no registró
/// ubicación automática. Ya persistido por "Crear Reporte"
/// (`reports.latitude`); "Mapa de Reportes" (004) lo lee de vuelta para
/// posicionar el marcador (FR-003).
 double? get latitude;/// Longitud del punto reportado. Mismo origen que [latitude].
 double? get longitude;/// `null` hasta que el reporte pase a "en proceso" (FR-014). Solo
/// lectura en esta feature.
 DateTime? get inProgressAt;/// `null` hasta que el reporte pase a "solucionado" (FR-014). Solo
/// lectura en esta feature.
 DateTime? get resolvedAt;
/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportCopyWith<Report> get copyWith => _$ReportCopyWithImpl<Report>(this as Report, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Report&&(identical(other.id, id) || other.id == id)&&(identical(other.reportNumber, reportNumber) || other.reportNumber == reportNumber)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.inProgressAt, inProgressAt) || other.inProgressAt == inProgressAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,reportNumber,category,description,address,photoUrl,createdAt,status,deviceId,latitude,longitude,inProgressAt,resolvedAt);

@override
String toString() {
  return 'Report(id: $id, reportNumber: $reportNumber, category: $category, description: $description, address: $address, photoUrl: $photoUrl, createdAt: $createdAt, status: $status, deviceId: $deviceId, latitude: $latitude, longitude: $longitude, inProgressAt: $inProgressAt, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class $ReportCopyWith<$Res>  {
  factory $ReportCopyWith(Report value, $Res Function(Report) _then) = _$ReportCopyWithImpl;
@useResult
$Res call({
 String id, String reportNumber, WasteCategory category, String description, String address, String photoUrl, DateTime createdAt, ReportStatus status, String deviceId, double? latitude, double? longitude, DateTime? inProgressAt, DateTime? resolvedAt
});




}
/// @nodoc
class _$ReportCopyWithImpl<$Res>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._self, this._then);

  final Report _self;
  final $Res Function(Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reportNumber = null,Object? category = null,Object? description = null,Object? address = null,Object? photoUrl = null,Object? createdAt = null,Object? status = null,Object? deviceId = null,Object? latitude = freezed,Object? longitude = freezed,Object? inProgressAt = freezed,Object? resolvedAt = freezed,}) {
  return _then(Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reportNumber: null == reportNumber ? _self.reportNumber : reportNumber // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WasteCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReportStatus,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,inProgressAt: freezed == inProgressAt ? _self.inProgressAt : inProgressAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Report].
extension ReportPatterns on Report {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Report value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Report value)  $default,){
final _that = this;
switch (_that) {
case _Report():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Report value)?  $default,){
final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reportNumber,  WasteCategory category,  String description,  String address,  String photoUrl,  DateTime createdAt,  ReportStatus status,  String deviceId,  double? latitude,  double? longitude,  DateTime? inProgressAt,  DateTime? resolvedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.reportNumber,_that.category,_that.description,_that.address,_that.photoUrl,_that.createdAt,_that.status,_that.deviceId,_that.latitude,_that.longitude,_that.inProgressAt,_that.resolvedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reportNumber,  WasteCategory category,  String description,  String address,  String photoUrl,  DateTime createdAt,  ReportStatus status,  String deviceId,  double? latitude,  double? longitude,  DateTime? inProgressAt,  DateTime? resolvedAt)  $default,) {final _that = this;
switch (_that) {
case _Report():
return $default(_that.id,_that.reportNumber,_that.category,_that.description,_that.address,_that.photoUrl,_that.createdAt,_that.status,_that.deviceId,_that.latitude,_that.longitude,_that.inProgressAt,_that.resolvedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reportNumber,  WasteCategory category,  String description,  String address,  String photoUrl,  DateTime createdAt,  ReportStatus status,  String deviceId,  double? latitude,  double? longitude,  DateTime? inProgressAt,  DateTime? resolvedAt)?  $default,) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.reportNumber,_that.category,_that.description,_that.address,_that.photoUrl,_that.createdAt,_that.status,_that.deviceId,_that.latitude,_that.longitude,_that.inProgressAt,_that.resolvedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Report extends Report {
  const _Report({required this.id, required this.reportNumber, required this.category, required this.description, required this.address, required this.photoUrl, required this.createdAt, required this.status, required this.deviceId, this.latitude, this.longitude, this.inProgressAt, this.resolvedAt}): super._();
  

/// ID del documento de Firestore. Necesario para la ruta
/// `/mis-reportes/:reportId` y para `watchReportById`.
@override final  String id;
/// Formato completo `#IL-{año}-{consecutivo}` (research.md §2), ya
/// listo para mostrar (FR-020).
@override final  String reportNumber;
@override final  WasteCategory category;
@override final  String description;
/// Dirección final mostrable — `manualAddress` si existe, si no
/// `automaticAddress` (regla de mapeo en data-model.md).
@override final  String address;
/// URL de descarga de Firebase Storage de la foto ya subida.
@override final  String photoUrl;
@override final  DateTime createdAt;
/// Estado de seguimiento. `pendiente` al crearse; solo lo cambia un
/// mecanismo futuro fuera de alcance (FR-015).
@override final  ReportStatus status;
/// Identificador anónimo del dispositivo que envió el reporte (FR-003),
/// llave de filtro de "Mis Reportes" (FR-004).
@override final  String deviceId;
/// Latitud del punto reportado. `null` si el reporte no registró
/// ubicación automática. Ya persistido por "Crear Reporte"
/// (`reports.latitude`); "Mapa de Reportes" (004) lo lee de vuelta para
/// posicionar el marcador (FR-003).
@override final  double? latitude;
/// Longitud del punto reportado. Mismo origen que [latitude].
@override final  double? longitude;
/// `null` hasta que el reporte pase a "en proceso" (FR-014). Solo
/// lectura en esta feature.
@override final  DateTime? inProgressAt;
/// `null` hasta que el reporte pase a "solucionado" (FR-014). Solo
/// lectura en esta feature.
@override final  DateTime? resolvedAt;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportCopyWith<_Report> get copyWith => __$ReportCopyWithImpl<_Report>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Report&&(identical(other.id, id) || other.id == id)&&(identical(other.reportNumber, reportNumber) || other.reportNumber == reportNumber)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.inProgressAt, inProgressAt) || other.inProgressAt == inProgressAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,reportNumber,category,description,address,photoUrl,createdAt,status,deviceId,latitude,longitude,inProgressAt,resolvedAt);

@override
String toString() {
  return 'Report(id: $id, reportNumber: $reportNumber, category: $category, description: $description, address: $address, photoUrl: $photoUrl, createdAt: $createdAt, status: $status, deviceId: $deviceId, latitude: $latitude, longitude: $longitude, inProgressAt: $inProgressAt, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class _$ReportCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$ReportCopyWith(_Report value, $Res Function(_Report) _then) = __$ReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String reportNumber, WasteCategory category, String description, String address, String photoUrl, DateTime createdAt, ReportStatus status, String deviceId, double? latitude, double? longitude, DateTime? inProgressAt, DateTime? resolvedAt
});




}
/// @nodoc
class __$ReportCopyWithImpl<$Res>
    implements _$ReportCopyWith<$Res> {
  __$ReportCopyWithImpl(this._self, this._then);

  final _Report _self;
  final $Res Function(_Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reportNumber = null,Object? category = null,Object? description = null,Object? address = null,Object? photoUrl = null,Object? createdAt = null,Object? status = null,Object? deviceId = null,Object? latitude = freezed,Object? longitude = freezed,Object? inProgressAt = freezed,Object? resolvedAt = freezed,}) {
  return _then(_Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reportNumber: null == reportNumber ? _self.reportNumber : reportNumber // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WasteCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReportStatus,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,inProgressAt: freezed == inProgressAt ? _self.inProgressAt : inProgressAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
