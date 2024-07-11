import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

part 'product.g.dart';

@freezed
sealed class Product with _$Product {
  factory Product({
    String? docId,
    String? title,
    String? description,
    int? price,
    bool? isSale,
    int? stock,
    double? saleRate,
    String? imgUrl,
    int? timestamp,
  }) = _Product;

  // json_serializable 적용
  // fromJson()
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

@freezed
sealed class Cart with _$Cart {
  factory Cart({
    String? cartDocId,
    String? uid,
    String? email,
    int? timestamp,
    int? count,
    Product? product,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
}
