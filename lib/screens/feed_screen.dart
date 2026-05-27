import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'dart:math' as math;

// استدعاء شاشة إضافة المنشور
import 'create_post_screen.dart';

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
    // تفعيل اللغة العربية للأوقات (منذ دقيقتين، إلخ)
    timeago.setLocaleMessages('ar', timeago.ArMessages());

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
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
      
      // الزر العائم الآن يفتح شاشة النشر الحقيقية
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: const Color(0xFFA259FF),
        child: const Icon(Icons.add_photo_alternate, color: Colors.white),
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
                    colors: [const Color(0xFF2A1B54).withOpacity(0.4), const Color(0xFF0B0B19)],
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
                // قسم القصص (سيتم ربطه لاحقاً بقاعدة البيانات)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 8,
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
                                      gradient: isMe ? null : const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                                      border: isMe ? Border.all(color: Colors.white38, width: 2) : null,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.primaries[(index * 2) % Colors.primaries.length].withOpacity(0.5),
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
                              Text(isMe ? 'قصتك' : 'مستكشف ${index + 1}', style: TextStyle(fontSize: 12, color: isMe ? Colors.white : Colors.white70, fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                
                // قسم المنشورات (مربوط بـ Firestore)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: Color(0xFFA259FF)))),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: Text('الفضاء فارغ حالياً! 🚀\nكن أول من يطلق منشوراً.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 18))),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return PostWidget(post: post);
                        },
                        childCount: posts.length,
                      ),
                    );
                  },
                ),
                
                // مسافة سفلية لشريط التنقل
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// ويدجت المنشور المستقل (ليحتوي على أنميشن الإعجاب الخاص به)
// ---------------------------------------------------------
class PostWidget extends StatefulWidget {
  final QueryDocumentSnapshot post;
  const PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _isLiked = false; // لاحقاً سيتم ربطها بقاعدة البيانات لمعرفة إذا أعجبت به مسبقاً

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _likeScale = Tween<double>(begin: 0.0, end: 1.2).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  // دالة الإعجاب عند الضغط مرتين
  void _triggerLike() {
    setState(() => _isLiked = true);
    _likeController.forward().then((value) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _likeController.reverse();
      });
    });
    
    // تحديث عدد الإعجابات في Firestore
    FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.post.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    final timeString = timestamp != null ? timeago.format(timestamp.toDate(), locale: 'ar') : 'الآن';

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
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA259FF), width: 1.5)),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueAccent.withOpacity(0.6),
                  child: Text(data['displayName'].substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              title: Text(data['displayName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              trailing: IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white70), onPressed: () {}),
            ),
            
            // صورة المنشور مع أنميشن الإعجاب
            GestureDetector(
              onDoubleTap: _triggerLike,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.black.withOpacity(0.2),
                        child: const Center(child: CircularProgressIndicator(color: Color(0xFF0095F6))),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.black.withOpacity(0.2),
                        child: const Icon(Icons.broken_image, color: Colors.white38, size: 50),
                      ),
                    ),
                    // القلب المتوهج الذي يظهر عند النقر المزدوج
                    ScaleTransition(
                      scale: _likeScale,
                      child: const Icon(Icons.favorite, color: Colors.white, size: 100, shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 30)]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // أزرار التفاعل
            Row(
              children: [
                IconButton(
                  icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.pinkAccent : Colors.white), 
                  onPressed: _triggerLike
                ),
                IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.send_outlined, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.auto_awesome, color: Color(0xFFA259FF), size: 20), tooltip: 'رد ذكي', onPressed: () {}),
                const Spacer(),
                IconButton(icon: const Icon(Icons.bookmark_border, color: Colors.white), onPressed: () {}),
              ],
            ),
            
            // عدد الإعجابات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('${data['likesCount']} إعجاب', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            
            // النص (Caption)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'sans-serif'),
                  children: [
                    TextSpan(text: '${data['username']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: data['caption']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ويدجت الزجاج المخصص
class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

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
