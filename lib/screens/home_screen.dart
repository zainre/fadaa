import 'package:flutter/material.dart';
import 'dart:ui';

// استدعاء جميع شاشات تطبيق فضاء
import 'feed_screen.dart';
import 'reels_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

// استدعاء شاشة المساعد الذكي
import 'ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  // القائمة النهائية للشاشات
  final List<Widget> _screens = [
    const FeedScreen(),
    const ReelsScreen(),
    const ChatsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // أنميشن نبض سحري لزر الذكاء الاصطناعي (سديم)
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

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

      // -----------------------------------------------------
      // الزر العائم المركزي (سَديم) - يطفو وينبض في المنتصف
      // -----------------------------------------------------
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA259FF).withOpacity(0.6 * _fabController.value),
                  blurRadius: 20 * _fabController.value,
                  spreadRadius: 5 * _fabController.value,
                )
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFF0095F6), Color(0xFFA259FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FloatingActionButton(
              onPressed: () {
                // الانتقال إلى غرفة التحكم الخاصة بسديم
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen()));
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              tooltip: 'المُرشِد سديم',
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
          );
        }
      ),
      // تحديد موقع الزر في منتصف الشريط السفلي
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // -----------------------------------------------------
      // شريط التنقل الزجاجي السفلي
      // -----------------------------------------------------
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
