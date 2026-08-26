// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_report_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewReportDraft {

/// Ya validada como `!exceedsMaxSize` antes de construir el draft.
 Photo get photo; WasteCategory get category;/// Puede ser cadena vacía (FR-009, opcional).
 String get description;/// Debe cumplir `hasAnyLocation == true` antes de construir el draft.
 ReportLocation get location;
/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewReportDraftCopyWith<NewReportDraft> get copyWith => _$NewReportDraftCopyWithImpl<NewReportDraft>(this as NewReportDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewReportDraft&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode => Object.hash(runtimeType,photo,category,description,location);

@override
String toString() {
  return 'NewReportDraft(photo: $photo, category: $category, description: $description, location: $location)';
}


}

/// @nodoc
abstract mixin class $NewReportDraftCopyWith<$Res>  {
  factory $NewReportDraftCopyWith(NewReportDraft value, $Res Function(NewReportDraft) _then) = _$NewReportDraftCopyWithImpl;
@useResult
$Res call({
 Photo photo, WasteCategory category, String description, ReportLocation location
});


$PhotoCopyWith<$Res> get photo;$ReportLocationCopyWith<$Res> get location;

}
/// @nodoc
class _$NewReportDraftCopyWithImpl<$Res>
    implements $NewReportDraftCopyWith<$Res> {
  _$NewReportDraftCopyWithImpl(this._self, this._then);

  final NewReportDraft _self;
  final $Res Function(NewReportDraft) _then;

/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photo = null,Object? category = null,Object? description = null,Object? location = null,}) {
  return _then(NewReportDraft(
photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as Photo,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WasteCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as ReportLocation,
  ));
}
/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoCopyWith<$Res> get photo {
  
  return $PhotoCopyWith<$Res>(_self.photo, (value) {
    return _then(_self.copyWith(photo: value));
  });
}/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportLocationCopyWith<$Res> get location {
  
  return $ReportLocationCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [NewReportDraft].
extension NewReportDraftPatterns on NewReportDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewReportDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewReportDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewReportDraft value)  $default,){
final _that = this;
switch (_that) {
case _NewReportDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewReportDraft value)?  $default,){
final _that = this;
switch (_that) {
case _NewReportDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Photo photo,  WasteCategory category,  String description,  ReportLocation location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewReportDraft() when $default != null:
return $default(_that.photo,_that.category,_that.description,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Photo photo,  WasteCategory category,  String description,  ReportLocation location)  $default,) {final _that = this;
switch (_that) {
case _NewReportDraft():
return $default(_that.photo,_that.category,_that.description,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Photo photo,  WasteCategory category,  String description,  ReportLocation location)?  $default,) {final _that = this;
switch (_that) {
case _NewReportDraft() when $default != null:
return $default(_that.photo,_that.category,_that.description,_that.location);case _:
  return null;

}
}

}

/// @nodoc


class _NewReportDraft implements NewReportDraft {
  const _NewReportDraft({required this.photo, required this.category, required this.description, required this.location});
  

/// Ya validada como `!exceedsMaxSize` antes de construir el draft.
@override final  Photo photo;
@override final  WasteCategory category;
/// Puede ser cadena vacía (FR-009, opcional).
@override final  String description;
/// Debe cumplir `hasAnyLocation == true` antes de construir el draft.
@override final  ReportLocation location;

/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewReportDraftCopyWith<_NewReportDraft> get copyWith => __$NewReportDraftCopyWithImpl<_NewReportDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewReportDraft&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode => Object.hash(runtimeType,photo,category,description,location);

@override
String toString() {
  return 'NewReportDraft(photo: $photo, category: $category, description: $description, location: $location)';
}


}

/// @nodoc
abstract mixin class _$NewReportDraftCopyWith<$Res> implements $NewReportDraftCopyWith<$Res> {
  factory _$NewReportDraftCopyWith(_NewReportDraft value, $Res Function(_NewReportDraft) _then) = __$NewReportDraftCopyWithImpl;
@override @useResult
$Res call({
 Photo photo, WasteCategory category, String description, ReportLocation location
});


@override $PhotoCopyWith<$Res> get photo;@override $ReportLocationCopyWith<$Res> get location;

}
/// @nodoc
class __$NewReportDraftCopyWithImpl<$Res>
    implements _$NewReportDraftCopyWith<$Res> {
  __$NewReportDraftCopyWithImpl(this._self, this._then);

  final _NewReportDraft _self;
  final $Res Function(_NewReportDraft) _then;

/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photo = null,Object? category = null,Object? description = null,Object? location = null,}) {
  return _then(_NewReportDraft(
photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as Photo,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WasteCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as ReportLocation,
  ));
}

/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhotoCopyWith<$Res> get photo {
  
  return $PhotoCopyWith<$Res>(_self.photo, (value) {
    return _then(_self.copyWith(photo: value));
  });
}/// Create a copy of NewReportDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportLocationCopyWith<$Res> get location {
  
  return $ReportLocationCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

// dart format on
