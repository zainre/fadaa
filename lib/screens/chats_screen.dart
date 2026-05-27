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
    // أنميشن الخلفية
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    // مستمع لتحديث البحث فورياً
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
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
      backgroundColor: const Color(0xFF0B0B19),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('المُـراسَـلات', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // الخلفية الفضائية المتحركة
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [const Color(0xFF2A1B54).withOpacity(0.5), const Color(0xFF0B0B19)],
                    center: Alignment(math.sin(_bgController.value * math.pi), math.cos(_bgController.value * math.pi)),
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // شريط البحث الزجاجي
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن رفيق في الفضاء...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFFA259FF)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white54),
                                    onPressed: () => _searchController.clear(),
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
                      const Icon(Icons.auto_awesome, color: Color(0xFFA259FF), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'وَكُلُّ قَرينٍ بِالمُقارِنِ يَقتَدي ✨',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontFamily: 'sans-serif', fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // قائمة المستخدمين
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFA259FF)));
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('حدث خطأ في الاتصال 📡', style: TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('لا يوجد مستكشفين آخرين هنا بعد!', style: TextStyle(color: Colors.white54)));
                      }

                      // تصفية المستخدمين (إخفاء حسابي الشخصي + تطبيق البحث)
                      final users = snapshot.data!.docs.where((doc) {
                        final isNotMe = doc.id != currentUser?.uid;
                        final name = (doc.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
                        final matchesSearch = name.contains(_searchQuery);
                        return isNotMe && matchesSearch;
                      }).toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              const Text('لم نجد أحداً بهذا الاسم...', style: TextStyle(color: Colors.white54, fontSize: 16)),
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
                          
                          // أنميشن دخول متدرج للبطاقات
                          return TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 500)), // تأخير متدرج
                            curve: Curves.easeOutQuint,
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      leading: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                                          boxShadow: [BoxShadow(color: const Color(0xFFA259FF).withOpacity(0.3), blurRadius: 10)],
                                        ),
                                        child: CircleAvatar(
                                          radius: 26,
                                          backgroundColor: const Color(0xFF0B0B19),
                                          child: Text(
                                            name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                      subtitle: Text(userData['username'] ?? 'انقر لبدء الإرسال...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                                        child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFA259FF), size: 20),
                                      ),
                                      onTap: () {
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
                // مسافة أسفل القائمة لتجنب تداخلها مع شريط التنقل السفلي
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
