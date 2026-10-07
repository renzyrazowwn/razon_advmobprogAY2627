import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

// Enhancement 2
// DummyJSON vs Firebase Auth
// DummyJSON uses username + POST /auth/login
// Firebase uses email + UserService.signIn (FirebaseAuth SDK)
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');

  bool _isLoading = false;

  bool _obscurePassword = true;

  LoginType _loginType = LoginType.dummyJson;

  bool get _isFirebase => _loginType == LoginType.firebase;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    UserService userService = UserService();

    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        Map<String, dynamic> response;

        if (_isFirebase) {
          // Firebase: signInWithEmailAndPassword
          await userService.signIn(
            email: _usernameController.text.trim(),
            password: _passwordController.text,
          );
          response = await userService.getUserData();
        } else {
          // DummyJSON: POST /auth/login
          response = await userService.loginUser(
            _usernameController.text,
            _passwordController.text,
          );

          // save user data to SharedPreferences.
          await userService.saveUserData(response);
        }

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: response,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${UserService.errorMessage(e)}'),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Image.asset(
                    'assets/images/nubdexchange_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 24.h),

                CustomText(
                  text: 'Welcome back, User!',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),

                SizedBox(height: 4.h),

                CustomText(
                  text: 'Sign in again to continue your shopping',
                  fontSize: 13.sp,
                ),

                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LoginType>(
                    segments: const [
                      ButtonSegment(
                        value: LoginType.dummyJson,
                        label: Text('DummyJSON'),
                      ),
                      ButtonSegment(
                        value: LoginType.firebase,
                        label: Text('Firebase'),
                      ),
                    ],
                    selected: {_loginType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _loginType = selection.first;
                        _usernameController.clear();
                      });
                    },
                  ),
                ),

                SizedBox(height: 20.h),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: _isFirebase
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _isFirebase ? 'Email' : 'Username',
                    prefixIcon: Icon(
                      _isFirebase ? Icons.email_outlined : Icons.person_outline,
                    ),
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
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _isFirebase
                          ? 'Email is required'
                          : 'Username is required';
                    }
                    if (_isFirebase &&
                        !RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$')
                            .hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 14.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Log in'),
                  ),
                ),

                SizedBox(height: 12.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: "Don't have an account?",
                      fontSize: 13.sp,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('Sign up'),
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