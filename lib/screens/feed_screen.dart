import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // أنميشن الخلفية الفضائية
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  // نافذة الذكاء الاصطناعي لكتابة المنشورات
  void _showAIPostDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFA259FF), size: 40),
              const SizedBox(height: 15),
              const Text(
                'الكاتب الذكي ✨',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'اكتب فكرة بسيطة، وسأقوم بتحويلها إلى منشور احترافي مع الهاشتاجات المناسبة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'مثال: كنت أدرس البرمجة اليوم واكتشفت طريقة جديدة...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA259FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // هنا سيتم ربط الـ API لاحقاً لتوليد المنشور
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري التفكير وكتابة المنشور...'), backgroundColor: Color(0xFF0095F6)),
                    );
                  },
                  child: const Text('توليد المنشور', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
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
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      // زر عائم لإنشاء المنشورات بالذكاء الاصطناعي
      floatingActionButton: FloatingActionButton(
        onPressed: _showAIPostDialog,
        backgroundColor: const Color(0xFFA259FF),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      body: Stack(
        children: [
          // الخلفية المتحركة
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2A1B54).withOpacity(0.4),
                      const Color(0xFF0B0B19),
                    ],
                    center: Alignment(math.sin(_bgController.value * math.pi), math.cos(_bgController.value * math.pi)),
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // قسم القصص (Stories)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 15,
                      itemBuilder: (context, index) {
                        final isMe = index == 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0, left: 4.0, top: 12.0),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: isMe 
                                        ? null // بدون إطار إذا كانت قصتي للتو
                                        : const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                                      border: isMe ? Border.all(color: Colors.white38, width: 2) : null,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.primaries[(index * 2) % Colors.primaries.length].withOpacity(0.5),
                                      backgroundImage: isMe ? null : null, // هنا سنضع صور المستخدمين لاحقاً
                                      child: isMe ? const Icon(Icons.person, color: Colors.white, size: 30) : const Icon(Icons.face, color: Colors.white70),
                                    ),
                                  ),
                                  if (isMe)
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Color(0xFF0095F6), shape: BoxShape.circle),
                                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isMe ? 'قصتك' : 'مستكشف ${index + 1}', 
                                style: TextStyle(fontSize: 12, color: isMe ? Colors.white : Colors.white70, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // فاصل بسيط
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                
                // قسم المنشورات (Posts)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: GlassContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ترويسة المنشور
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFA259FF), width: 1.5),
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.primaries[(index + 3) % Colors.primaries.length].withOpacity(0.6),
                                    child: const Icon(Icons.person_outline, color: Colors.white),
                                  ),
                                ),
                                title: Text('رائد فضاء ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: const Text('منذ ساعتين', style: TextStyle(fontSize: 12, color: Colors.white54)),
                                trailing: IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white70), onPressed: () {}),
                              ),
                              
                              // صورة المنشور
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.satellite_alt_outlined, size: 60, color: Colors.white24), // صورة افتراضية
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // أزرار التفاعل
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
                                  IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () {}),
                                  IconButton(icon: const Icon(Icons.send_outlined, color: Colors.white), onPressed: () {}),
                                  // زر الذكاء الاصطناعي للمنشور
                                  IconButton(icon: const Icon(Icons.auto_awesome, color: Color(0xFFA259FF), size: 20), tooltip: 'رد ذكي', onPressed: () {}),
                                  const Spacer(),
                                  IconButton(icon: const Icon(Icons.bookmark_border, color: Colors.white), onPressed: () {}),
                                ],
                              ),
                              
                              // عدد الإعجابات
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('${(index + 1) * 24} إعجاب', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                              
                              // النص (Caption)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'sans-serif'),
                                    children: [
                                      TextSpan(text: 'رائد فضاء ${index + 1} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const TextSpan(text: 'هذا نص تجريبي للمنشور في تطبيق فضاء. التصميم الآن أصبح يدمج بين تأثيرات الزجاج والذكاء الاصطناعي ليبدو عصرياً ومميزاً! 🚀✨'),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // زر عرض التعليقات
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('عرض جميع التعليقات الـ 12', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ويدجت مخصص لتأثير الزجاج (Glassmorphism) تم استخدامه هنا أيضاً لتوحيد التصميم
class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
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
