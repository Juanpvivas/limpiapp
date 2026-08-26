// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReportLocation {

 double? get latitude; double? get longitude; String? get automaticAddress; String? get manualAddress;
/// Create a copy of ReportLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportLocationCopyWith<ReportLocation> get copyWith => _$ReportLocationCopyWithImpl<ReportLocation>(this as ReportLocation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportLocation&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.automaticAddress, automaticAddress) || other.automaticAddress == automaticAddress)&&(identical(other.manualAddress, manualAddress) || other.manualAddress == manualAddress));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,automaticAddress,manualAddress);

@override
String toString() {
  return 'ReportLocation(latitude: $latitude, longitude: $longitude, automaticAddress: $automaticAddress, manualAddress: $manualAddress)';
}


}

/// @nodoc
abstract mixin class $ReportLocationCopyWith<$Res>  {
  factory $ReportLocationCopyWith(ReportLocation value, $Res Function(ReportLocation) _then) = _$ReportLocationCopyWithImpl;
@useResult
$Res call({
 double? latitude, double? longitude, String? automaticAddress, String? manualAddress
});




}
/// @nodoc
class _$ReportLocationCopyWithImpl<$Res>
    implements $ReportLocationCopyWith<$Res> {
  _$ReportLocationCopyWithImpl(this._self, this._then);

  final ReportLocation _self;
  final $Res Function(ReportLocation) _then;

/// Create a copy of ReportLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = freezed,Object? longitude = freezed,Object? automaticAddress = freezed,Object? manualAddress = freezed,}) {
  return _then(ReportLocation(
latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,automaticAddress: freezed == automaticAddress ? _self.automaticAddress : automaticAddress // ignore: cast_nullable_to_non_nullable
as String?,manualAddress: freezed == manualAddress ? _self.manualAddress : manualAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportLocation].
extension ReportLocationPatterns on ReportLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportLocation value)  $default,){
final _that = this;
switch (_that) {
case _ReportLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportLocation value)?  $default,){
final _that = this;
switch (_that) {
case _ReportLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? latitude,  double? longitude,  String? automaticAddress,  String? manualAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportLocation() when $default != null:
return $default(_that.latitude,_that.longitude,_that.automaticAddress,_that.manualAddress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? latitude,  double? longitude,  String? automaticAddress,  String? manualAddress)  $default,) {final _that = this;
switch (_that) {
case _ReportLocation():
return $default(_that.latitude,_that.longitude,_that.automaticAddress,_that.manualAddress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? latitude,  double? longitude,  String? automaticAddress,  String? manualAddress)?  $default,) {final _that = this;
switch (_that) {
case _ReportLocation() when $default != null:
return $default(_that.latitude,_that.longitude,_that.automaticAddress,_that.manualAddress);case _:
  return null;

}
}

}

/// @nodoc


class _ReportLocation extends ReportLocation {
  const _ReportLocation({this.latitude, this.longitude, this.automaticAddress, this.manualAddress}): super._();
  

@override final  double? latitude;
@override final  double? longitude;
@override final  String? automaticAddress;
@override final  String? manualAddress;

/// Create a copy of ReportLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportLocationCopyWith<_ReportLocation> get copyWith => __$ReportLocationCopyWithImpl<_ReportLocation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportLocation&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.automaticAddress, automaticAddress) || other.automaticAddress == automaticAddress)&&(identical(other.manualAddress, manualAddress) || other.manualAddress == manualAddress));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,automaticAddress,manualAddress);

@override
String toString() {
  return 'ReportLocation(latitude: $latitude, longitude: $longitude, automaticAddress: $automaticAddress, manualAddress: $manualAddress)';
}


}

/// @nodoc
abstract mixin class _$ReportLocationCopyWith<$Res> implements $ReportLocationCopyWith<$Res> {
  factory _$ReportLocationCopyWith(_ReportLocation value, $Res Function(_ReportLocation) _then) = __$ReportLocationCopyWithImpl;
@override @useResult
$Res call({
 double? latitude, double? longitude, String? automaticAddress, String? manualAddress
});




}
/// @nodoc
class __$ReportLocationCopyWithImpl<$Res>
    implements _$ReportLocationCopyWith<$Res> {
  __$ReportLocationCopyWithImpl(this._self, this._then);

  final _ReportLocation _self;
  final $Res Function(_ReportLocation) _then;

/// Create a copy of ReportLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = freezed,Object? longitude = freezed,Object? automaticAddress = freezed,Object? manualAddress = freezed,}) {
  return _then(_ReportLocation(
latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,automaticAddress: freezed == automaticAddress ? _self.automaticAddress : automaticAddress // ignore: cast_nullable_to_non_nullable
as String?,manualAddress: freezed == manualAddress ? _self.manualAddress : manualAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
