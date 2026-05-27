import 'package:flutter/material.dart';
import 'dart:ui';

// استدعاء جميع شاشات تطبيق فضاء
import 'feed_screen.dart';
import 'reels_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // القائمة النهائية للشاشات
  final List<Widget> _screens = [
    const FeedScreen(),
    const ReelsScreen(),
    const ChatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      // هذه الخاصية تجعل المحتوى ينزل خلف شريط التنقل الشفاف
      extendBody: true, 
      
      // IndexedStack يحافظ على حالتك (مكان نزولك) في كل شاشة
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // شريط التنقل الزجاجي
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFA259FF),
              unselectedItemColor: Colors.white54,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), 
                  activeIcon: Icon(Icons.home_filled), 
                  label: 'الرئيسية'
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.slow_motion_video_outlined), 
                  activeIcon: Icon(Icons.slow_motion_video), 
                  label: 'ريلز'
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline), 
                  activeIcon: Icon(Icons.chat_bubble), 
                  label: 'المحادثات'
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), 
                  activeIcon: Icon(Icons.person), 
                  label: 'حسابي'
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
