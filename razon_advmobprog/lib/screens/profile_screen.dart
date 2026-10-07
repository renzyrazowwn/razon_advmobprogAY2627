import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'signup_screen.dart';

// Enhancement 3
// renders the logged-in user's profile using the User model
// and UserService and renders their cart based on that saved user's id
// Fetches user data via UserService().getUserData() and shows user details depending on the LoginType
// allows update username, change password, delete account
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late Future<Map<String, dynamic>> _userDataFuture;

  Future<List<Cart>>? _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _userDataFuture = _userService.getUserData().then((data) {
      if (data['loginType'] != LoginType.firebase.name) {
        _cartFuture = CartService().getCartsByUserId(data['id']);
      }
      return data;
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateUsername(User user) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => _AccountDialog(
        title: 'Update Username',
        confirmText: 'Save',
        fields: [
          _DialogField(
            label: 'New username',
            initialValue: user.username,
            validator: (value, _) {
              if (value == null || value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
        ],
        onConfirm: (values) =>
            _userService.updateUsername(username: values[0].trim()),
      ),
    );

    if (success == true && mounted) {
      setState(_loadUserData);
      _showMessage('Username updated.');
    }
  }

  Future<void> _changePassword(User user) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => _AccountDialog(
        title: 'Change Password',
        confirmText: 'Update',
        fields: [
          _DialogField(
            label: 'Current password',
            obscure: true,
            validator: (value, _) => (value == null || value.isEmpty)
                ? 'Current password is required'
                : null,
          ),
          _DialogField(
            label: 'New password',
            obscure: true,
            validator: (value, _) => SignUpScreen.validatePassword(value),
          ),
          _DialogField(
            label: 'Confirm new password',
            obscure: true,
            validator: (value, values) =>
                value != values[1] ? 'Passwords do not match' : null,
          ),
        ],
        onConfirm: (values) => _userService.resetPasswordFromCurrentPassword(
          currentPassword: values[0],
          newPassword: values[1],
          email: user.email,
        ),
      ),
    );

    if (success == true && mounted) {
      _showMessage('Password changed successfully.');
    }
  }

  Future<void> _deleteAccount(User user) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => _AccountDialog(
        title: 'Delete Account',
        message: 'This permanently deletes ${user.email}. '
            'Enter your password to confirm.',
        confirmText: 'Delete',
        isDestructive: true,
        fields: [
          _DialogField(
            label: 'Password',
            obscure: true,
            validator: (value, _) => (value == null || value.isEmpty)
                ? 'Password is required'
                : null,
          ),
        ],
        onConfirm: (values) => _userService.deleteAccount(
          email: user.email,
          password: values[0],
        ),
      ),
    );

    if (success == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
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

        final data = snapshot.data!;
        final user = User.fromJson(data);

        final isFirebase = data['loginType'] == LoginType.firebase.name;

        return ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    // Enhancement 3
                    // shows the user's actual DummyJSON avatar
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
                  SizedBox(height: 6.h),
                  // Lab Act 5 - Enhancement 3: shows the LoginType
                  Chip(
                    label: Text(
                      isFirebase ? 'Firebase account' : 'DummyJSON account',
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Card(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  children: isFirebase
                      ? [
                          _ProfileRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                          Divider(height: 20.h),
                          _ProfileRow(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: '${data['age'] ?? ''}',
                          ),
                          Divider(height: 20.h),
                          _ProfileRow(
                            icon: Icons.phone_outlined,
                            label: 'Contact No.',
                            value: '${data['contactNo'] ?? ''}',
                          ),
                        ]
                      : [
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

            if (isFirebase) ...[
              CustomText(
                text: 'Account Settings',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Update Username'),
                      onTap: () => _updateUsername(user),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Change Password'),
                      onTap: () => _changePassword(user),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () => _deleteAccount(user),
                    ),
                  ],
                ),
              ),
            ],

            if (!isFirebase) ...[
              CustomText(
                text: 'Your Cart',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),

              SizedBox(height: 8.h),

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
                                    '${cart.totalProducts} products • ${cart.totalQuantity} items',
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
            ],

            SizedBox(height: 24.h),

            // Enhancement 1
            // Logout button clears session/token and redirects to login
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
        SizedBox(width: 12.w),
        // Lab Act 5: long values (e.g. Firebase UID) get an ellipsis
        Expanded(
          child: CustomText(
            text: value.isEmpty ? 'N/A' : value,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DialogField {
  final String label;
  final String initialValue;
  final bool obscure;
  final String? Function(String? value, List<String> values) validator;

  const _DialogField({
    required this.label,
    required this.validator,
    this.initialValue = '',
    this.obscure = false,
  });
}

class _AccountDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String confirmText;
  final bool isDestructive;
  final List<_DialogField> fields;
  final Future<void> Function(List<String> values) onConfirm;

  const _AccountDialog({
    required this.title,
    required this.confirmText,
    required this.fields,
    required this.onConfirm,
    this.message,
    this.isDestructive = false,
  });

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers = widget.fields
      .map((field) => TextEditingController(text: field.initialValue))
      .toList();

  bool _isLoading = false;
  String? _error;

  List<String> get _values => _controllers.map((c) => c.text).toList();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onConfirm(_values);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = UserService.errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message != null) ...[
                Text(widget.message!),
                SizedBox(height: 12.h),
              ],
              for (var i = 0; i < widget.fields.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: TextFormField(
                    controller: _controllers[i],
                    obscureText: widget.fields[i].obscure,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: widget.fields[i].label,
                      errorMaxLines: 2,
                    ),
                    validator: (value) =>
                        widget.fields[i].validator(value, _values),
                  ),
                ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: widget.isDestructive
              ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
              : null,
          onPressed: _isLoading ? null : _confirm,
          child: _isLoading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.confirmText),
        ),
      ],
    );
  }
}