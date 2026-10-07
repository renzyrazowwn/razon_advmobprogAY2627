import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  // keeps the carts edited in the Cart screen (quantity changes) so they
  // stay the same when switching tabs. DummyJSON does not save changes.
  static final Map<int, Cart> _editedCarts = {};

  void saveEditedCart(int userId, Cart cart) {
    _editedCarts[userId] = cart;
  }

  void clearEditedCarts() {
    _editedCarts.clear();
  }

  // adds a product to a cart, or increases its quantity if it is already
  // in the cart, then recalculates the totals
  Cart mergeProduct(Cart cart, Product product, {int quantity = 1}) {
    final exists = cart.products.any((p) => p.id == product.id);

    final products = exists
        ? cart.products
            .map((p) =>
                p.id == product.id ? p.copyWithQuantity(p.quantity + quantity) : p)
            .toList()
        : [
            ...cart.products,
            CartProduct(
              id: product.id,
              title: product.title,
              price: product.price,
              quantity: 0,
              total: 0,
              discountPercentage: product.discountPercentage,
              discountedTotal: 0,
              thumbnail: product.thumbnail,
            ).copyWithQuantity(quantity),
          ];

    return cart.copyWithProducts(products);
  }

  Cart _emptyCart(int userId) => Cart(
        id: 0,
        products: [],
        total: 0,
        discountedTotal: 0,
        userId: userId,
        totalProducts: 0,
        totalQuantity: 0,
      );

  // DummyJSON users: sends the product to /carts/add, then merges it into
  // the user's cart so it shows in the Cart screen (DummyJSON does not
  // save the change on its server)
  Future<Cart> addProductForDummyJsonUser(int userId, Product product) async {
    await addToCart(
      userId: userId,
      products: [
        {'id': product.id, 'quantity': 1},
      ],
    );

    final carts = await getCartsByUserId(userId);
    final current = carts.isNotEmpty ? carts.first : _emptyCart(userId);
    final updated = mergeProduct(current, product);

    saveEditedCart(userId, updated);
    return updated;
  }

  // Firebase users don't have a DummyJSON user id, so their cart is saved
  // in Firestore: carts/{uid}
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Cart>> getFirebaseCart(String uid) async {
    final doc = await _firestore.collection('carts').doc(uid).get();
    final data = doc.data();
    if (data == null) return [];
    return [Cart.fromJson(data)];
  }

  Future<void> saveFirebaseCart(String uid, Cart cart) async {
    await _firestore.collection('carts').doc(uid).set(cart.toJson());
  }

  Future<Cart> addProductForFirebaseUser(String uid, Product product) async {
    final carts = await getFirebaseCart(uid);
    final current = carts.isNotEmpty ? carts.first : _emptyCart(0);
    final updated = mergeProduct(current, product);

    await saveFirebaseCart(uid, updated);
    return updated;
  }

  // gets all carts from the DummyJSON API
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(
      Uri.parse('$host/carts'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List cartsJson = data['carts'] ?? [];

      return cartsJson
          .map((json) => Cart.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // Enhancement 1
  // gets the cart belonging to a specific user
  Future<List<Cart>> getCartsByUserId(int userId) async {
    final editedCart = _editedCarts[userId];
    if (editedCart != null) return [editedCart];

    final response = await http.get(
      Uri.parse('$host/carts/user/$userId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List cartsJson = data['carts'] ?? [];

      return cartsJson
          .map((json) => Cart.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Failed to load cart for user $userId',
      );
    }
  }

  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, int>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'userId': userId,
        'products': products,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      return Cart.fromJson(data);
    } else {
      throw Exception(
        'Failed to add product to cart',
      );
    }
  }
}