import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

// handles API requests for product data
class ProductService {
  // Gets all products from the API.
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('$host/products'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List productsJson =
          data['products'] ?? [];

      return productsJson
          .map((json) => Product.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Failed to load products',
      );
    }
  }

  // Enhancement 1
  // gets a single product by ID
  Future<Product> getProductById(int productId) async {
    final response = await http.get(
      Uri.parse('$host/products/$productId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      return Product.fromJson(data);
    } else {
      throw Exception(
        'Failed to load product $productId',
      );
    }
  }
}