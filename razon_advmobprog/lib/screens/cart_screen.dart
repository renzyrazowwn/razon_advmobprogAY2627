import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
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

  @override
  void initState() {
    super.initState();
    _cartFuture = CartService().getCartsByUserId(widget.userId);
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
                'No cart found for this user.',
              ),
            );
          }

          final cart = carts.first;

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
                                    text: 'Quantity: ${cartProduct.quantity}',
                                    fontSize: 13.sp,
                                  ),
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