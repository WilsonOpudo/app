import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:meetme/app_navigation.dart';
import 'package:meetme/state/profile_status.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/prof_page1.dart';
import 'screens/prof_page2.dart';
import 'screens/prof_page3.dart';
import 'screens/prof_page4.dart';
import 'screens/professorWelcomePage.dart';
import 'package:meetme/screens/professor_notifications.dart';

class ProfessorHomePage extends StatefulWidget {
  const ProfessorHomePage({super.key});

  @override
  State<ProfessorHomePage> createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  final PageController _controller = PageController();
  int _bottomNavIndex = 0;

  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService.getNotifications();

    _badgeTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      setState(() {
        _notificationsFuture = ApiService.getNotifications();
      });
    });

    AppNavigation.jumpToPage = (index) {
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
    _badgeTimer?.cancel();
    AppNavigation.jumpToPage = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? [];
            final unreadCount =
                notifications.where((n) => n['read'] == false).length;

            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 26),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorNotificationsPage(),
                  ),
                );

                setState(() {
                  _notificationsFuture = ApiService.getNotifications();
                });
              },
            );
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
      body: Column(
        children: [
          if (ProfileStatus.isProfileIncomplete) const SizedBox(height: 0),
          Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() => _bottomNavIndex = index);
                  },
                  children: const [
                    ProfessorWelcomePage(),
                    ProfessorPage1(),
                    ProfessorPage2(),
                    ProfessorPage3(),
                    ProfessorPage4(),
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
            AppNavigation.jumpToPage?.call(index);
          },
          tabs: const [
            GButton(icon: Icons.home_filled, text: 'Welcome'),
            GButton(icon: Icons.class_, text: 'Classes'),
            GButton(
                icon: Icons.dashboard_customize_rounded, text: 'Appointments'),
            GButton(icon: Icons.storage_rounded, text: 'Calendar'),
            GButton(icon: Icons.message_rounded, text: 'Chat'),
          ],
        ),
      ),
    );
  }
}
