import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 1
// Splash screen shown on app launch. Checks whether a
// user session is already saved (persistent authentication)
// and routes straight to /home if so, otherwise to /signin.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // Enhancement 1:
  // Waits briefly (so the splash is visible), then checks
  // SharedPreferences for a saved session via isLoggedIn().
  // Logged in -> /home with the saved user data as arguments.
  // Not logged in -> /signin.
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 8));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UI Enhancement
            // logo mark restyled as a circle filled with the
            // brand royal blue, matching the sign-in screen.
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Padding(
                padding: EdgeInsets.all(18.r),
                child: Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return Icon(
                      Icons.storefront_outlined,
                      size: 44.sp,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 20.h),

            CustomText(
              text: 'NU Bulldogs Exchange',
              fontSize: 30.sp,
              fontWeight: FontWeight.w600,
            ),

            SizedBox(height: 32.h),

            // UI Enhancement
            // spinner explicitly colored royal blue so it's
            // consistent with the button/logo branding rather
            // than whatever the default theme color happens to be.
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
