import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 2
// Sign-up screen that creates a Firebase Auth account.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  // Enhancement 2
  // password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Add at least one special character (!@#\$...)';
    }
    return null;
  }

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // creates the account using the provided UserService functions
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userService = UserService();

    try {
      final credential = await userService.createAccount(
        email: _emailAddressController.text.trim(),
        password: _passwordController.text,
      );

      // username is stored as the Firebase display name
      await userService.updateUsername(
        username: _usernameController.text.trim(),
      );

      // the other fields are saved for the profile screen
      await userService.saveFirebaseProfile(credential.user!.uid, {
        'firstName': _fNameController.text.trim(),
        'lastName': _lNameController.text.trim(),
        'age': _ageController.text.trim(),
        'contactNo': _contactNoController.text.trim(),
        'username': _usernameController.text.trim(),
      });

      final userData = await userService.getUserData();

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: userData,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${UserService.errorMessage(e)}')),
      );
    }
  }

  // same field style as signin_screen.dart
  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      errorMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: 14.h);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  text: 'Sign up with Firebase',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: 'Fill in your details to start shopping',
                  fontSize: 13.sp,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                TextFormField(
                  controller: _fNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('First Name', Icons.person_outline),
                  validator: (v) => _required(v, 'First name'),
                ),
                gap,

                TextFormField(
                  controller: _lNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Last Name', Icons.person_outline),
                  validator: (v) => _required(v, 'Last name'),
                ),
                gap,

                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: _decoration('Age', Icons.cake_outlined),
                  validator: (v) {
                    final empty = _required(v, 'Age');
                    if (empty != null) return empty;
                    final age = int.parse(v!.trim());
                    if (age < 13 || age > 120) return 'Enter a valid age (13-120)';
                    return null;
                  },
                ),
                gap,

                TextFormField(
                  controller: _contactNoController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: _decoration('Contact No.', Icons.phone_outlined),
                  validator: (v) {
                    final empty = _required(v, 'Contact number');
                    if (empty != null) return empty;
                    if (!RegExp(r'^\+?[0-9]{10,12}$').hasMatch(v!.trim())) {
                      return 'Enter a valid contact number (e.g. 09171234567)';
                    }
                    return null;
                  },
                ),
                gap,

                TextFormField(
                  controller: _usernameController,
                  decoration: _decoration('Username', Icons.alternate_email),
                  validator: (v) {
                    final empty = _required(v, 'Username');
                    if (empty != null) return empty;
                    if (!RegExp(r'^[a-zA-Z0-9._]{3,20}$').hasMatch(v!.trim())) {
                      return '3-20 letters, numbers, . or _ only';
                    }
                    return null;
                  },
                ),
                gap,

                TextFormField(
                  controller: _emailAddressController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email Address', Icons.email_outlined),
                  validator: (v) {
                    final empty = _required(v, 'Email address');
                    if (empty != null) return empty;
                    if (!RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$')
                        .hasMatch(v!.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                gap,

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _decoration(
                    'Password',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: SignUpScreen.validatePassword,
                ),
                gap,

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: _decoration('Confirm Password', Icons.lock_outline),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                SizedBox(
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign up'),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: 'Already have an account?',
                      fontSize: 13.sp,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}