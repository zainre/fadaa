import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';
import 'dart:math' as math;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  
  late AnimationController _floatController;
  late AnimationController _glowController;
  
  bool _isGeneratingBio = false;

  // مفتاح Gemini الذي أرسلته (يمكنك تغييره لاحقاً)
  final String _apiKey = 'AIzaSyDN6c9X9txXrD7OaIgYrzIY1d_sk_zZmdI';

  @override
  void initState() {
    super.initState();
    // أنميشن طفو الصورة الشخصية
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    // أنميشن التوهج للخلفية
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // 🪄 دالة الذكاء الاصطناعي السحرية لكتابة البايو
  Future<void> _generateAIBio() async {
    setState(() => _isGeneratingBio = true);
    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
      
      // هنا نعطي الذكاء الاصطناعي تعليمات دقيقة ومخصصة
      final prompt = 'اكتب نبذة شخصية (Bio) قصيرة ومميزة لتطبيق تواصل اجتماعي لشاب اسمه زين العابدين، طالب سادس علمي من بابل، مهتم بالبرمجة وبناء التطبيقات، ومحب للشعر العربي الفصيح. اجعلها سطرين فقط وبطابع إبداعي.';
      
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null && mounted) {
        // حفظ البايو الجديد في Firestore
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
          'bio': response.text,
        }, SetOptions(merge: true));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ تم توليد البايو السحري بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في الذكاء الاصطناعي: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingBio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('المَـرصَـد', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: const Color(0xFF1A1A2E),
                title: const Text('مغادرة الفضاء؟', style: TextStyle(color: Colors.white)),
                content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج والعودة للأرض؟', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('البقاء', style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    child: const Text('خروج', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // خلفية الفضاء المتوهجة
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2A1B54).withOpacity(0.5 + (_glowController.value * 0.2)),
                      const Color(0xFF0B0B19),
                    ],
                    center: const Alignment(0, -0.5),
                    radius: 1.2,
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0095F6)));
                }
                
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                
                // جلب البيانات من فايربيس أو استخدام بيانات افتراضية
                final displayName = userData?['name'] ?? 'مستكشف الفضاء';
                final username = userData?['username'] ?? '@zain_explorer';
                final bio = userData?['bio'] ?? 'لم تتم كتابة نبذة شخصية بعد...';
                final postsCount = userData?['posts_count'] ?? '0';
                final followersCount = userData?['followers_count'] ?? '0';
                final followingCount = userData?['following_count'] ?? '0';

                return RefreshIndicator(
                  color: const Color(0xFF0095F6),
                  backgroundColor: const Color(0xFF1A1A2E),
                  onRefresh: () async { setState(() {}); },
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    children: [
                      // صورة الحساب مع أنميشن الطفو
                      Center(
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 10 * math.sin(_floatController.value * math.pi)),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF0095F6).withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                                      ]
                                    ),
                                    child: CircleAvatar(
                                      radius: 55,
                                      backgroundColor: const Color(0xFF0B0B19),
                                      child: Text(
                                        displayName.substring(0, 1).toUpperCase(), 
                                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Color(0xFF1A1A2E), shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // الاسم واليوزر
                      Center(child: Text(displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
                      const SizedBox(height: 4),
                      Center(child: Text(username, style: const TextStyle(fontSize: 16, color: Color(0xFF0095F6), letterSpacing: 1))),
                      
                      const SizedBox(height: 25),
                      
                      // قسم البايو (Bio) مع الذكاء الاصطناعي
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('النبذة الشخصية', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                if (_isGeneratingBio)
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA259FF)))
                                else
                                  GestureDetector(
                                    onTap: _generateAIBio,
                                    child: const Row(
                                      children: [
                                        Text('توليد سحري ', style: TextStyle(color: Color(0xFFA259FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                        Icon(Icons.auto_awesome, color: Color(0xFFA259FF), size: 16),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(bio, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // الإحصائيات (المتابعون، المنشورات)
                      GlassContainer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCol('منشور', postsCount),
                            Container(width: 1, height: 40, color: Colors.white24),
                            _buildStatCol('متابِع', followersCount),
                            Container(width: 1, height: 40, color: Colors.white24),
                            _buildStatCol('يتابِع', followingCount),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // قائمة الخيارات السفلية
                      _buildMenuTile(Icons.edit_note, 'تعديل الملف الشخصي', () {}),
                      _buildMenuTile(Icons.bookmark_border, 'العناصر المحفوظة', () {}),
                      _buildMenuTile(Icons.settings_outlined, 'إعدادات النظام', () {}),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: onTap,
      ),
    );
  }
}

// ويدجت مخصص لتأثير الزجاج (Glassmorphism)
class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
