import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Cart>> _cartFuture;
  final CartService _cartService = CartService();
  Cart? _cart;

  // set when the logged-in user is a Firebase account (cart in Firestore)
  String? _firebaseUid;

  static const int _maxQuantity = 99;

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCart();
  }

  Future<List<Cart>> _loadCart() async {
    final userData = await UserService().getUserData();

    if (userData['loginType'] == LoginType.firebase.name) {
      _firebaseUid = userData['uid'];
      return _cartService.getFirebaseCart(_firebaseUid!);
    }

    return _cartService.getCartsByUserId(widget.userId);
  }

  void _setQuantity(Cart cart, CartProduct cartProduct, int quantity) {
    final products = cart.products
        .map((p) => p.id == cartProduct.id ? p.copyWithQuantity(quantity) : p)
        .toList();
    _updateCart(cart.copyWithProducts(products));
  }

  Future<void> _decreaseQuantity(Cart cart, CartProduct cartProduct) async {
    if (cartProduct.quantity > 1) {
      _setQuantity(cart, cartProduct, cartProduct.quantity - 1);
      return;
    }

    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove item'),
        content: Text('Remove "${cartProduct.title}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (remove != true || !mounted) return;

    final products =
        cart.products.where((p) => p.id != cartProduct.id).toList();
    _updateCart(cart.copyWithProducts(products));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cartProduct.title} removed from cart.')),
    );
  }

  void _increaseQuantity(Cart cart, CartProduct cartProduct) {
    if (cartProduct.quantity >= _maxQuantity) return;
    _setQuantity(cart, cartProduct, cartProduct.quantity + 1);
  }

  void _updateCart(Cart cart) {
    if (_firebaseUid != null) {
      _cartService.saveFirebaseCart(_firebaseUid!, cart).catchError((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save your cart.')),
        );
      });
    } else {
      _cartService.saveEditedCart(widget.userId, cart);
    }

    setState(() {
      _cart = cart;
    });
  }

  Widget _quantitySelector(Cart cart, CartProduct cartProduct) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18.sp,
            tooltip: cartProduct.quantity > 1 ? 'Decrease' : 'Remove',
            icon: Icon(
              cartProduct.quantity > 1 ? Icons.remove : Icons.delete_outline,
              color: cartProduct.quantity > 1 ? null : colorScheme.error,
            ),
            onPressed: () => _decreaseQuantity(cart, cartProduct),
          ),
          SizedBox(
            width: 28.w,
            child: CustomText(
              text: '${cartProduct.quantity}',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18.sp,
            tooltip: 'Increase',
            icon: const Icon(Icons.add),
            onPressed: cartProduct.quantity >= _maxQuantity
                ? null
                : () => _increaseQuantity(cart, cartProduct),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductDetail(
    BuildContext context,
    CartProduct cartProduct,
  ) async {
    try {
      final product = await ProductService().getProductById(
        cartProduct.id,
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            product: product,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load product details.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Cart>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final carts = snapshot.data ?? [];

          if (carts.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
              ),
            );
          }

          final cart = _cart ?? carts.first;

          if (cart.products.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              CustomText(
                text: 'Cart Items',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),

              // displays every product in the cart
              ...cart.products.map(
                (cartProduct) {
                  return Card(
                    margin: EdgeInsets.only(
                      bottom: 10.h,
                    ),
                    child: InkWell(
                      onTap: () {
                        _openProductDetail(
                          context,
                          cartProduct,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10.r),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                10.r,
                              ),
                              child: Image.network(
                                cartProduct.thumbnail,
                                width: 80.w,
                                height: 80.h,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 80.w,
                                    height: 80.h,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: cartProduct.title,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5.h),
                                  CustomText(
                                    text:
                                        '\$${cartProduct.price.toStringAsFixed(2)}',
                                    fontSize: 14.sp,
                                  ),
                                  SizedBox(height: 5.h),
                                  CustomText(
                                    text:
                                        'Subtotal: \$${cartProduct.discountedTotal.toStringAsFixed(2)}',
                                    fontSize: 12.sp,
                                  ),
                                  SizedBox(height: 6.h),
                                  _quantitySelector(cart, cartProduct),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 8.h),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items'),
                          Text('${cart.totalQuantity}'),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total'),
                          Text(
                            '\$${cart.total.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Discounted Total',
                          ),
                          Text(
                            '\$${cart.discountedTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}