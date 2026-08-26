// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_report_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewReportState {

 Photo? get photo; WasteCategory? get category; String get description;/// Resultado de `LocationRepository.getCurrentLocation()`; `null` si
/// falló o aún no se resuelve (ver `isLoadingLocation`).
 ReportLocation? get autoLocation; String get manualAddress; bool get isLoadingLocation; bool get isSubmitting; String? get submitError; bool get showPermissionDeniedAlert;
/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewReportStateCopyWith<NewReportState> get copyWith => _$NewReportStateCopyWithImpl<NewReportState>(this as NewReportState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewReportState&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.autoLocation, autoLocation) || other.autoLocation == autoLocation)&&(identical(other.manualAddress, manualAddress) || other.manualAddress == manualAddress)&&(identical(other.isLoadingLocation, isLoadingLocation) || other.isLoadingLocation == isLoadingLocation)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.showPermissionDeniedAlert, showPermissionDeniedAlert) || other.showPermissionDeniedAlert == showPermissionDeniedAlert));
}


@override
int get hashCode => Object.hash(runtimeType,photo,category,description,autoLocation,manualAddress,isLoadingLocation,isSubmitting,submitError,showPermissionDeniedAlert);

@override
String toString() {
  return 'NewReportState(photo: $photo, category: $category, description: $description, autoLocation: $autoLocation, manualAddress: $manualAddress, isLoadingLocation: $isLoadingLocation, isSubmitting: $isSubmitting, submitError: $submitError, showPermissionDeniedAlert: $showPermissionDeniedAlert)';
}


}

/// @nodoc
abstract mixin class $NewReportStateCopyWith<$Res>  {
  factory $NewReportStateCopyWith(NewReportState value, $Res Function(NewReportState) _then) = _$NewReportStateCopyWithImpl;
@useResult
$Res call({
 Photo? photo, WasteCategory? category, String description, ReportLocation? autoLocation, String manualAddress, bool isLoadingLocation, bool isSubmitting, String? submitError, bool showPermissionDeniedAlert
});


$PhotoCopyWith<$Res>? get photo;$ReportLocationCopyWith<$Res>? get autoLocation;

}
/// @nodoc
class _$NewReportStateCopyWithImpl<$Res>
    implements $NewReportStateCopyWith<$Res> {
  _$NewReportStateCopyWithImpl(this._self, this._then);

  final NewReportState _self;
  final $Res Function(NewReportState) _then;

/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photo = freezed,Object? category = freezed,Object? description = null,Object? autoLocation = freezed,Object? manualAddress = null,Object? isLoadingLocation = null,Object? isSubmitting = null,Object? submitError = freezed,Object? showPermissionDeniedAlert = null,}) {
  return _then(NewReportState(
photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as Photo?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WasteCategory?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,autoLocation: freezed == autoLocation ? _self.autoLocation : autoLocation // ignore: cast_nullable_to_non_nullable
as ReportLocation?,manualAddress: null == manualAddress ? _self.manualAddress : manualAddress // ignore: cast_nullable_to_non_nullable
as String,isLoadingLocation: null == isLoadingLocation ? _self.isLoadingLocation : isLoadingLocation // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,showPermissionDeniedAlert: null == showPermissionDeniedAlert ? _self.showPermissionDeniedAlert : showPermissionDeniedAlert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $PhotoCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportLocationCopyWith<$Res>? get autoLocation {
    if (_self.autoLocation == null) {
    return null;
  }

  return $ReportLocationCopyWith<$Res>(_self.autoLocation!, (value) {
    return _then(_self.copyWith(autoLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [NewReportState].
extension NewReportStatePatterns on NewReportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewReportState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewReportState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewReportState value)  $default,){
final _that = this;
switch (_that) {
case _NewReportState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewReportState value)?  $default,){
final _that = this;
switch (_that) {
case _NewReportState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Photo? photo,  WasteCategory? category,  String description,  ReportLocation? autoLocation,  String manualAddress,  bool isLoadingLocation,  bool isSubmitting,  String? submitError,  bool showPermissionDeniedAlert)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewReportState() when $default != null:
return $default(_that.photo,_that.category,_that.description,_that.autoLocation,_that.manualAddress,_that.isLoadingLocation,_that.isSubmitting,_that.submitError,_that.showPermissionDeniedAlert);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Photo? photo,  WasteCategory? category,  String description,  ReportLocation? autoLocation,  String manualAddress,  bool isLoadingLocation,  bool isSubmitting,  String? submitError,  bool showPermissionDeniedAlert)  $default,) {final _that = this;
switch (_that) {
case _NewReportState():
return $default(_that.photo,_that.category,_that.description,_that.autoLocation,_that.manualAddress,_that.isLoadingLocation,_that.isSubmitting,_that.submitError,_that.showPermissionDeniedAlert);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Photo? photo,  WasteCategory? category,  String description,  ReportLocation? autoLocation,  String manualAddress,  bool isLoadingLocation,  bool isSubmitting,  String? submitError,  bool showPermissionDeniedAlert)?  $default,) {final _that = this;
switch (_that) {
case _NewReportState() when $default != null:
return $default(_that.photo,_that.category,_that.description,_that.autoLocation,_that.manualAddress,_that.isLoadingLocation,_that.isSubmitting,_that.submitError,_that.showPermissionDeniedAlert);case _:
  return null;

}
}

}

/// @nodoc


class _NewReportState extends NewReportState {
  const _NewReportState({this.photo, this.category, this.description = '', this.autoLocation, this.manualAddress = '', this.isLoadingLocation = false, this.isSubmitting = false, this.submitError, this.showPermissionDeniedAlert = false}): super._();
  

@override final  Photo? photo;
@override final  WasteCategory? category;
@override@JsonKey() final  String description;
/// Resultado de `LocationRepository.getCurrentLocation()`; `null` si
/// falló o aún no se resuelve (ver `isLoadingLocation`).
@override final  ReportLocation? autoLocation;
@override@JsonKey() final  String manualAddress;
@override@JsonKey() final  bool isLoadingLocation;
@override@JsonKey() final  bool isSubmitting;
@override final  String? submitError;
@override@JsonKey() final  bool showPermissionDeniedAlert;

/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewReportStateCopyWith<_NewReportState> get copyWith => __$NewReportStateCopyWithImpl<_NewReportState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewReportState&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.autoLocation, autoLocation) || other.autoLocation == autoLocation)&&(identical(other.manualAddress, manualAddress) || other.manualAddress == manualAddress)&&(identical(other.isLoadingLocation, isLoadingLocation) || other.isLoadingLocation == isLoadingLocation)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.showPermissionDeniedAlert, showPermissionDeniedAlert) || other.showPermissionDeniedAlert == showPermissionDeniedAlert));
}


@override
int get hashCode => Object.hash(runtimeType,photo,category,description,autoLocation,manualAddress,isLoadingLocation,isSubmitting,submitError,showPermissionDeniedAlert);

@override
String toString() {
  return 'NewReportState(photo: $photo, category: $category, description: $description, autoLocation: $autoLocation, manualAddress: $manualAddress, isLoadingLocation: $isLoadingLocation, isSubmitting: $isSubmitting, submitError: $submitError, showPermissionDeniedAlert: $showPermissionDeniedAlert)';
}


}

/// @nodoc
abstract mixin class _$NewReportStateCopyWith<$Res> implements $NewReportStateCopyWith<$Res> {
  factory _$NewReportStateCopyWith(_NewReportState value, $Res Function(_NewReportState) _then) = __$NewReportStateCopyWithImpl;
@override @useResult
$Res call({
 Photo? photo, WasteCategory? category, String description, ReportLocation? autoLocation, String manualAddress, bool isLoadingLocation, bool isSubmitting, String? submitError, bool showPermissionDeniedAlert
});


@override $PhotoCopyWith<$Res>? get photo;@override $ReportLocationCopyWith<$Res>? get autoLocation;

}
/// @nodoc
class __$NewReportStateCopyWithImpl<$Res>
    implements _$NewReportStateCopyWith<$Res> {
  __$NewReportStateCopyWithImpl(this._self, this._then);

  final _NewReportState _self;
  final $Res Function(_NewReportState) _then;

/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photo = freezed,Object? category = freezed,Object? description = null,Object? autoLocation = freezed,Object? manualAddress = null,Object? isLoadingLocation = null,Object? isSubmitting = null,Object? submitError = freezed,Object? showPermissionDeniedAlert = null,}) {
  return _then(_NewReportState(
photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as Photo?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WasteCategory?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,autoLocation: freezed == autoLocation ? _self.autoLocation : autoLocation // ignore: cast_nullable_to_non_nullable
as ReportLocation?,manualAddress: null == manualAddress ? _self.manualAddress : manualAddress // ignore: cast_nullable_to_non_nullable
as String,isLoadingLocation: null == isLoadingLocation ? _self.isLoadingLocation : isLoadingLocation // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as String?,showPermissionDeniedAlert: null == showPermissionDeniedAlert ? _self.showPermissionDeniedAlert : showPermissionDeniedAlert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $PhotoCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}/// Create a copy of NewReportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportLocationCopyWith<$Res>? get autoLocation {
    if (_self.autoLocation == null) {
    return null;
  }

  return $ReportLocationCopyWith<$Res>(_self.autoLocation!, (value) {
    return _then(_self.copyWith(autoLocation: value));
  });
}
}

// dart format on
