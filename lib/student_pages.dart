import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:meetme/student_navigation.dart';

import 'main.dart';
import 'screens/studentwelcomepage.dart';
import 'screens/stu_page1.dart';
import 'screens/stu_page2.dart';
import 'screens/stu_page3.dart';
import 'screens/stu_page4.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final PageController _controller = PageController();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    StudentNavigation.jumpToPage = (index) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      setState(() => _bottomNavIndex = index);
    };
  }

  @override
  void dispose() {
    StudentNavigation.jumpToPage = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.person, color: Theme.of(context).shadowColor),
          onPressed: () {
            // Optional: Navigate to student profile
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
                MaterialPageRoute(builder: (_) => const LoadingScreen()),
                (route) => false,
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
              setState(() => _bottomNavIndex = index);
            },
            children: const [
              StudentWelcomePage(),
              StudentPage1(),
              StudentPage2(),
              StudentPage3(),
              StudentPage4(),
            ],
          ),
          Align(
            alignment: const Alignment(0, 0.97),
            child: SmoothPageIndicator(
              controller: _controller,
              count: 5,
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
            StudentNavigation.jumpToPage?.call(index);
          },
          tabs: const [
            GButton(icon: Icons.home_filled, text: 'Welcome'),
            GButton(icon: Icons.class_, text: 'Classes'),
            GButton(icon: Icons.dashboard_customize_rounded, text: 'Book'),
            GButton(icon: Icons.calendar_month, text: 'Calendar'),
            GButton(icon: Icons.message_rounded, text: 'Chat'),
          ],
        ),
      ),
    );
  }
}
