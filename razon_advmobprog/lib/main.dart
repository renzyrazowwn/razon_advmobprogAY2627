import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

// loads environment variables before starting the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  runApp(const RazonAdvMobProg());
}

// main application widget that provides the theme state
class RazonAdvMobProg extends StatelessWidget {
  const RazonAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // creates the theme provider for the whole app
      create: (_) => ThemeProvider(),

      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,

        builder: (build, child) {
          // gets the current theme state from Provider
          final themeModel = build.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // applies the light and dark themes
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,

            // changes the theme based on the current state
            themeMode: themeModel.isDark
                ? ThemeMode.dark
                : ThemeMode.light,

            title: 'E-Commerce App',

            // Enhancement 1
            // opens the splash screen first, which checks
            // persistent authentication before deciding whether
            // to go to /signin or /home.
            initialRoute: '/splash',

            // defines the app navigation routes
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/signin': (context) => const SignInScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}