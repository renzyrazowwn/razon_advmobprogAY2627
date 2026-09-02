import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

import '../widgets/custom_text.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Stores the name of the currently logged-in user.
  String _userName = 'Profile';
  final UserService _userService = UserService();

  // Enhancement 3
  // The userId of the currently signed-in user.
  int _userId = 0;
  bool _userIdResolved = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Loads the currently logged-in user from SharedPreferences.
  Future<void> _loadUser() async {
    try {
      final user = await _userService.getUser();

      if (!mounted) return;

      setState(() {
        _userName = user.firstName;
      });
    } catch (e) {
      // Keep "Profile" if the user cannot be loaded.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Enhancement 3
    // Only resolve the route arguments once.
    if (!_userIdResolved) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map && args['id'] != null) {
        _userId = args['id'] as int;
      }

      _userIdResolved = true;
    }
  }

  // Enhancement 2
  // Displays the Chat FloatingActionButton.
  // The button is hidden when the current screen is Cart.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chat feature opened.',
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.chat,
                ),
              ),

        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,

          title: (_selectedIndex == 0)
              ? Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  scale: 11.sp,
                )
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Cart'
                      : (_selectedIndex == 2)
                          ? _userName
                          : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),

          actions: [
            IconButton(
              icon: Icon(
                Icons.settings,
                size: 24.sp,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),

        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,

          // Enhancement 3
          // CartScreen receives the ID of the currently signed-in user.
          children: <Widget>[
            const ProductScreen(),
            CartScreen(userId: _userId),
            const ProfileScreen(),
          ],

          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),

        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shop_2),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });

    _pageController.jumpToPage(value);
  }
}