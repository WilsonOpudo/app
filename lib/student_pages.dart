import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/material.dart';
import 'screens/stu_page1.dart';
import 'screens/stu_page2.dart';
import 'screens/stu_page3.dart';
import 'screens/stu_page4.dart';
import 'main.dart';

class AppNavigation {
  static void Function(int pageIndex)? jumpToPage;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();
  int _bottomNavIndex = 0;

  // Global access for navigation
  static late void Function(int) jumpToPage;
  @override
  void initState() {
    super.initState();
    AppNavigation.jumpToPage = (index) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon:
              Icon(Icons.person_rounded, color: Theme.of(context).shadowColor),
          onPressed: () {
            // Handle user profile action
          },
        ),
        title: Text(
          'Meet Me',
          style: TextStyle(
            color: Theme.of(context).shadowColor,
            fontSize: 24,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded,
                color: Theme.of(context).shadowColor),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoadingScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _bottomNavIndex = index;
              });
            },
            children: const [
              StudentPage1(),
              StudentPage2(),
              StudentPage3(),
              StudentPage4(),
            ],
          ),
          Container(
            alignment: const Alignment(0, 0.97),
            child: SmoothPageIndicator(
              controller: _controller,
              count: 4,
              effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: Theme.of(context).shadowColor,
                dotColor: Theme.of(context).hintColor,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: GNav(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          gap: 8,
          padding: const EdgeInsets.all(16),
          selectedIndex: _bottomNavIndex,
          onTabChange: (index) {
            setState(() {
              _bottomNavIndex = index;
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            });
          },
          tabs: [
            GButton(
              icon: Icons.home_filled,
              text: 'Home',
              iconActiveColor: Theme.of(context).shadowColor,
              iconColor: Theme.of(context).hintColor,
            ),
            GButton(
              icon: Icons.dashboard_customize_rounded,
              text: 'Appointments',
              iconActiveColor: Theme.of(context).shadowColor,
              iconColor: Theme.of(context).hintColor,
            ),
            GButton(
              icon: Icons.storage_rounded,
              text: 'Calendar',
              iconActiveColor: Theme.of(context).shadowColor,
              iconColor: Theme.of(context).hintColor,
            ),
            GButton(
              icon: Icons.message_rounded,
              text: 'Chat',
              iconActiveColor: Theme.of(context).shadowColor,
              iconColor: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }
}

// Access this method anywhere to jump to a specific page:
void navigateToStudentPage(int index) {
  _HomePageState.jumpToPage(index);
}
