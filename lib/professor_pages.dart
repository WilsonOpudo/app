import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/material.dart';
import 'screens/prof_page1.dart';
import 'screens/prof_page2.dart';
import 'screens/prof_page3.dart';
import 'screens/prof_page4.dart';
import 'main.dart';
import 'screens/profdetails.dart';

class ProfessorHomePage extends StatefulWidget {
  const ProfessorHomePage({super.key});

  @override
  State<ProfessorHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<ProfessorHomePage> {
  final PageController _controller = PageController();
  int _bottomNavIndex = 0;

  // Simulated profile check (replace with dynamic logic later)
  bool isProfileIncomplete = true;

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfDetailsPage()),
            ).then((_) {
              // Optionally refresh profile state after returning from details
              setState(() {
                // Here you can re-check if the profile is now complete
                isProfileIncomplete = false; // simulate completion
              });
            });
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
      body: Column(
        children: [
          if (isProfileIncomplete)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Colors.amber[100],
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded,
                      color: Colors.amber[800]),
                  title: Text("Complete your profile details"),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfDetailsPage()),
                      ).then((_) {
                        setState(() {
                          isProfileIncomplete = false;
                        });
                      });
                    },
                    child: Text("Edit"),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      _bottomNavIndex = index;
                    });
                  },
                  children: [
                    ProfessorPage1(),
                    ProfessorPage2(),
                    ProfessorPage3(),
                    ProfessorPage4(),
                  ],
                ),
                Align(
                  alignment: Alignment(0, 0.97),
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
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0),
        child: GNav(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          gap: 8,
          padding: EdgeInsets.all(16),
          selectedIndex: _bottomNavIndex,
          onTabChange: (index) {
            setState(() {
              _bottomNavIndex = index;
              _controller.animateToPage(
                index,
                duration: Duration(milliseconds: 600),
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
