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
    // أنميشن نبض فاخر لزر الذكاء الاصطناعي (سديم)
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
      backgroundColor: const Color(0xFF050508), // ثيم الأوبسيديان الفاخر الموحد
      extendBody: true, // مهم جداً لجعل المحتوى يمتد خلف الشريط الزجاجي
      
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // -----------------------------------------------------
      // الزر العائم المركزي (سَديم) - يطفو وينبض بلمسة بلاتينية
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
                  color: Colors.white.withOpacity(0.3 * _fabController.value),
                  blurRadius: 20 * _fabController.value,
                  spreadRadius: 5 * _fabController.value,
                )
              ],
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE0E0E0)], // تدرج أبيض/فضي
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen()));
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              tooltip: 'المُرشِد سديم',
              child: const Icon(Icons.auto_awesome, color: Colors.black, size: 28),
            ),
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // -----------------------------------------------------
      // شريط التنقل الزجاجي المخصص (أفخم أنميشن)
      // -----------------------------------------------------
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // ضبابية زجاجية عالية
          child: Container(
            height: 85, // ارتفاع مريح للإبهام
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF050508).withOpacity(0.7),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // توزيع المسافات بذكاء
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_filled, 'الرئيسية'),
                _buildNavItem(1, Icons.slow_motion_video_outlined, Icons.slow_motion_video, 'ريلز'),
                
                const SizedBox(width: 65), // 👈 هذه المساحة السحرية تُترك فارغة لزر سديم في المنتصف!
                
                _buildNavItem(2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'المحادثات'),
                _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'حسابي'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🪄 ويدجت داخلي لصناعة الأيقونات المتحركة بذكاء
  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque, // لالتقاط النقرات حتى في المساحات الفارغة
      child: SizedBox(
        width: 60, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أنميشن الأيقونة (تقفز للأعلى وتكبر قليلاً وتتوهج)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack, // حركة فيزيائية مرنة
              transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? Colors.white : Colors.white38,
                size: isSelected ? 28 : 24,
                shadows: isSelected ? [const Shadow(color: Colors.white, blurRadius: 15)] : [],
              ),
            ),
            const SizedBox(height: 4),
            // النقطة المتوهجة السفلية تظهر فقط عند التحديد
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
                height: 5,
                width: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white, blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
