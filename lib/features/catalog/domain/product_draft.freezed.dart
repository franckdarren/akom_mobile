// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductDraft {

 String get name; String get description; int get price; String? get categoryId; String? get barcode; String? get imageUrl; String? get localImagePath;
/// Create a copy of ProductDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDraftCopyWith<ProductDraft> get copyWith => _$ProductDraftCopyWithImpl<ProductDraft>(this as ProductDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.localImagePath, localImagePath) || other.localImagePath == localImagePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,price,categoryId,barcode,imageUrl,localImagePath);

@override
String toString() {
  return 'ProductDraft(name: $name, description: $description, price: $price, categoryId: $categoryId, barcode: $barcode, imageUrl: $imageUrl, localImagePath: $localImagePath)';
}


}

/// @nodoc
abstract mixin class $ProductDraftCopyWith<$Res>  {
  factory $ProductDraftCopyWith(ProductDraft value, $Res Function(ProductDraft) _then) = _$ProductDraftCopyWithImpl;
@useResult
$Res call({
 String name, String description, int price, String? categoryId, String? barcode, String? imageUrl, String? localImagePath
});




}
/// @nodoc
class _$ProductDraftCopyWithImpl<$Res>
    implements $ProductDraftCopyWith<$Res> {
  _$ProductDraftCopyWithImpl(this._self, this._then);

  final ProductDraft _self;
  final $Res Function(ProductDraft) _then;

/// Create a copy of ProductDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? price = null,Object? categoryId = freezed,Object? barcode = freezed,Object? imageUrl = freezed,Object? localImagePath = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,localImagePath: freezed == localImagePath ? _self.localImagePath : localImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductDraft].
extension ProductDraftPatterns on ProductDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductDraft value)  $default,){
final _that = this;
switch (_that) {
case _ProductDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ProductDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  int price,  String? categoryId,  String? barcode,  String? imageUrl,  String? localImagePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductDraft() when $default != null:
return $default(_that.name,_that.description,_that.price,_that.categoryId,_that.barcode,_that.imageUrl,_that.localImagePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  int price,  String? categoryId,  String? barcode,  String? imageUrl,  String? localImagePath)  $default,) {final _that = this;
switch (_that) {
case _ProductDraft():
return $default(_that.name,_that.description,_that.price,_that.categoryId,_that.barcode,_that.imageUrl,_that.localImagePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  int price,  String? categoryId,  String? barcode,  String? imageUrl,  String? localImagePath)?  $default,) {final _that = this;
switch (_that) {
case _ProductDraft() when $default != null:
return $default(_that.name,_that.description,_that.price,_that.categoryId,_that.barcode,_that.imageUrl,_that.localImagePath);case _:
  return null;

}
}

}

/// @nodoc


class _ProductDraft extends ProductDraft {
  const _ProductDraft({this.name = '', this.description = '', this.price = 0, this.categoryId, this.barcode, this.imageUrl, this.localImagePath}): super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  int price;
@override final  String? categoryId;
@override final  String? barcode;
@override final  String? imageUrl;
@override final  String? localImagePath;

/// Create a copy of ProductDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductDraftCopyWith<_ProductDraft> get copyWith => __$ProductDraftCopyWithImpl<_ProductDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.localImagePath, localImagePath) || other.localImagePath == localImagePath));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,price,categoryId,barcode,imageUrl,localImagePath);

@override
String toString() {
  return 'ProductDraft(name: $name, description: $description, price: $price, categoryId: $categoryId, barcode: $barcode, imageUrl: $imageUrl, localImagePath: $localImagePath)';
}


}

/// @nodoc
abstract mixin class _$ProductDraftCopyWith<$Res> implements $ProductDraftCopyWith<$Res> {
  factory _$ProductDraftCopyWith(_ProductDraft value, $Res Function(_ProductDraft) _then) = __$ProductDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, int price, String? categoryId, String? barcode, String? imageUrl, String? localImagePath
});




}
/// @nodoc
class __$ProductDraftCopyWithImpl<$Res>
    implements _$ProductDraftCopyWith<$Res> {
  __$ProductDraftCopyWithImpl(this._self, this._then);

  final _ProductDraft _self;
  final $Res Function(_ProductDraft) _then;

/// Create a copy of ProductDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? price = null,Object? categoryId = freezed,Object? barcode = freezed,Object? imageUrl = freezed,Object? localImagePath = freezed,}) {
  return _then(_ProductDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,localImagePath: freezed == localImagePath ? _self.localImagePath : localImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
