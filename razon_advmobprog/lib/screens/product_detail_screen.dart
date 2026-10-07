import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../widgets/custom_text.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

// displays the selected product and product details
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          // displays the details of the selected product
          children: [
            // displays the product image
            Container(
              width: double.infinity,
              height: 280.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 60.sp,
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // displays the product title, price, rating and reviews
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 8.h),

                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                            ),
                            SizedBox(width: 4.w),
                            CustomText(
                              text: product.rating.toStringAsFixed(1),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 10.w),

                      CustomText(
                        text: '${product.reviews.length} reviews',
                        fontSize: 13.sp,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // displays the product category and stock
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.category_outlined,
                    title: 'Category',
                    value: product.category,
                  ),
                ),

                SizedBox(width: 10.w),

                Expanded(
                  child: _InfoCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Stock',
                    value: '${product.stock}',
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // displays the product brand
            _InfoCard(
              icon: Icons.business_outlined,
              title: 'Brand',
              value: product.brand,
            ),

            SizedBox(height: 16.h),

            // displays the product description
            _SectionCard(
              icon: Icons.description_outlined,
              title: 'Description',
              child: CustomText(
                text: product.description,
                fontSize: 14.sp,
              ),
            ),

            SizedBox(height: 12.h),

            // displays shipping and warranty information
            _SectionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Shipping & Warranty',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.shippingInformation,
                    fontSize: 14.sp,
                  ),

                  SizedBox(height: 12.h),

                  CustomText(
                    text: product.warrantyInformation,
                    fontSize: 14.sp,
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // displays the product return policy
            _SectionCard(
              icon: Icons.assignment_return_outlined,
              title: 'Return Policy',
              child: CustomText(
                text: product.returnPolicy,
                fontSize: 14.sp,
              ),
            ),

            SizedBox(height: 20.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final userData = await UserService().getUserData();

                    // Firebase accounts have no DummyJSON user id, so
                    // their cart is saved in Firestore instead
                    if (userData['loginType'] == LoginType.firebase.name) {
                      await CartService().addProductForFirebaseUser(
                        userData['uid'],
                        product,
                      );
                    } else {
                      await CartService().addProductForDummyJsonUser(
                        userData['id'],
                        product,
                      );
                    }

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Product added to cart.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to add product to cart.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                ),
                label: const Text(
                  'Add to Cart',
                ),
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

// displays a small card for product information
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22.sp,
          ),

          SizedBox(height: 8.h),

          CustomText(
            text: title,
            fontSize: 11.sp,
          ),

          SizedBox(height: 3.h),

          CustomText(
            text: value.isEmpty ? 'N/A' : value,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// displays a styled section for product details
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 21.sp,
              ),

              SizedBox(width: 8.w),

              CustomText(
                text: title,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),

          SizedBox(height: 12.h),

          child,
        ],
      ),
    );
  }
}