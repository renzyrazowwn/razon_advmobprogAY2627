import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 3:
// Renders the logged-in user's profile using the User model
// and UserService, and — based on that saved user's id —
// renders their cart via CartService.getCartsByUserId.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late Future<User> _userFuture;
  // Enhancement 3:
  // Cart future is created only after the user loads, since
  // it depends on the user's id.
  Future<List<Cart>>? _cartFuture;

  @override
  void initState() {
    super.initState();

    // Enhancement 3:
    // Reads the persisted user (saved by UserService during
    // sign-in) rather than requiring it to be passed in, so
    // this screen also works after an app restart.
    _userFuture = _userService.getUser().then((user) {
      _cartFuture = CartService().getCartsByUserId(user.id);
      return user;
    });
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signin',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: CustomText(
              text: 'Unable to load profile.',
              fontSize: 14.sp,
            ),
          );
        }

        final user = snapshot.data!;

        return ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            // profile header with avatar initials
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    // Enhancement 3
                    // shows the user's actual DummyJSON avatar
                    // (from the saved User model) when available,
                    // falling back to the initials otherwise.
                    backgroundImage: user.image.isNotEmpty ? NetworkImage(user.image) : null,
                    child: user.image.isEmpty
                        ? CustomText(
                            text: user.initials,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                  SizedBox(height: 10.h),
                  CustomText(
                    text: user.fullName,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  CustomText(
                    text: '@${user.username}',
                    fontSize: 13.sp,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // account details card
            Card(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    Divider(height: 20.h),
                    _ProfileRow(
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: user.gender,
                    ),
                    Divider(height: 20.h),
                    _ProfileRow(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: '#${user.id}',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            CustomText(
              text: 'Your Cart',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),

            SizedBox(height: 8.h),

            // Enhancement 3:
            // renders the cart belonging to this user's id
            FutureBuilder<List<Cart>>(
              future: _cartFuture,
              builder: (context, cartSnapshot) {
                if (cartSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (cartSnapshot.hasError) {
                  return CustomText(
                    text: 'Error: ${cartSnapshot.error}',
                    fontSize: 13.sp,
                  );
                }

                final carts = cartSnapshot.data ?? [];

                if (carts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.r),
                      child: CustomText(
                        text: 'No cart found for this user.',
                        fontSize: 13.sp,
                      ),
                    ),
                  );
                }

                final cart = carts.first;

                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text:
                                  '${cart.totalProducts} products \u2022 ${cart.totalQuantity} items',
                              fontSize: 13.sp,
                            ),
                            SizedBox(height: 4.h),
                            CustomText(
                              text:
                                  '\$${cart.discountedTotal.toStringAsFixed(2)}',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                        const Icon(Icons.shopping_cart_outlined),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onErrorContainer,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// displays a single labeled row of profile info
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp),
        SizedBox(width: 10.w),
        CustomText(text: label, fontSize: 13.sp),
        const Spacer(),
        CustomText(
          text: value.isEmpty ? 'N/A' : value,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
