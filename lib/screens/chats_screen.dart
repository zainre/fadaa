import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'chat_room_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // أنميشن الخلفية الفاخرة
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    // مستمع لتحديث البحث فورياً
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF050508), // ثيم الأوبسيديان العميق
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('المُـراسَـلات', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF050508).withOpacity(0.6),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // الخلفية الفضائية أحادية اللون
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.04),
                      const Color(0xFF0A0A0E),
                      const Color(0xFF030305),
                    ],
                    center: Alignment(math.sin(_bgController.value * math.pi) * 0.5, math.cos(_bgController.value * math.pi) * 0.5),
                    radius: 1.6,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // شريط البحث الزجاجي الفاخر
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن اليوزر أو الاسم...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w300),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus(); // إخفاء الكيبورد عند المسح
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // اقتباس ترحيبي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'وَكُلُّ قَرينٍ بِالمُقارِنِ يَقتَدي ✨',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // قائمة المستخدمين (مبنية على البحث فقط)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('حدث خطأ في الاتصال 📡', style: TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('لا يوجد مستكشفين آخرين هنا بعد!', style: TextStyle(color: Colors.white54)));
                      }

                      // 🛡️ تصفية المستخدمين: لا تظهر أحداً إذا كان مربع البحث فارغاً
                      if (_searchQuery.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.radar_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 16),
                              Text('اكتب اسم المستخدم للبحث في الفضاء', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                            ],
                          ),
                        );
                      }

                      // جلب المطابقات بناءً على الاسم أو اليوزرنيم
                      final users = snapshot.data!.docs.where((doc) {
                        final isNotMe = doc.id != currentUser?.uid;
                        final userData = doc.data() as Map<String, dynamic>;
                        final name = (userData['name'] ?? '').toString().toLowerCase();
                        final username = (userData['username'] ?? '').toString().toLowerCase();
                        
                        final matchesSearch = name.contains(_searchQuery) || username.contains(_searchQuery);
                        return isNotMe && matchesSearch;
                      }).toList();

                      // إذا بحث ولم يجد أحداً
                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 16),
                              Text('لم نجد أحداً يحمل هذا الاسم أو اليوزر...', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userData = user.data() as Map<String, dynamic>;
                          final String name = userData['name'] ?? 'مجهول';
                          final String username = userData['username'] ?? '@مجهول';
                          final String profilePic = userData['profilePic'] ?? '';
                          
                          // أنميشن دخول متدرج للبطاقات
                          return TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + (index * 100).clamp(0, 400)), // تأخير متدرج سريع
                            curve: Curves.easeOutQuint,
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      leading: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24, width: 1.5),
                                        ),
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: const Color(0xFF101015),
                                          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                          child: profilePic.isEmpty 
                                              ? Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white))
                                              : null,
                                        ),
                                      ),
                                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                      subtitle: Text(username, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, letterSpacing: 0.5)),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 18),
                                      ),
                                      onTap: () {
                                        // غلق الكيبورد قبل الانتقال
                                        FocusScope.of(context).unfocus();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatRoomScreen(
                                              receiverId: user.id,
                                              receiverName: name,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // مسافة أسفل القائمة لتجنب تداخلها مع شريط التنقل السفلي والزر العائم
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
