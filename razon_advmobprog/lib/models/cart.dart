class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) => CartProduct.fromJson(e))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
      userId: json['userId'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }

  // returns a copy of the cart with new products and recalculated totals
  Cart copyWithProducts(List<CartProduct> newProducts) {
    final newTotal =
        newProducts.fold<double>(0, (sum, product) => sum + product.total);
    final newDiscountedTotal = newProducts.fold<double>(
      0,
      (sum, product) => sum + product.discountedTotal,
    );
    final newTotalQuantity =
        newProducts.fold<int>(0, (sum, product) => sum + product.quantity);

    return Cart(
      id: id,
      products: newProducts,
      total: double.parse(newTotal.toStringAsFixed(2)),
      discountedTotal: double.parse(newDiscountedTotal.toStringAsFixed(2)),
      userId: userId,
      totalProducts: newProducts.length,
      totalQuantity: newTotalQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((e) => e.toJson()).toList(),
      'total': total,
      'discountedTotal': discountedTotal,
      'userId': userId,
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
    };
  }
}

class CartProduct {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      discountedTotal:
          (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'total': total,
      'discountPercentage': discountPercentage,
      'discountedTotal': discountedTotal,
      'thumbnail': thumbnail,
    };
  }

  // returns a copy of the product with a new quantity and recalculated totals
  CartProduct copyWithQuantity(int newQuantity) {
    final newTotal = price * newQuantity;
    final newDiscountedTotal = newTotal * (1 - discountPercentage / 100);

    return CartProduct(
      id: id,
      title: title,
      price: price,
      quantity: newQuantity,
      total: double.parse(newTotal.toStringAsFixed(2)),
      discountPercentage: discountPercentage,
      discountedTotal: double.parse(newDiscountedTotal.toStringAsFixed(2)),
      thumbnail: thumbnail,
    );
  }
}