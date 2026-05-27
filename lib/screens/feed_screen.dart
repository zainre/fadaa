import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'dart:math' as math;

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
    timeago.setLocaleMessages('ar', timeago.ArMessages());

    // أنميشن الخلفية الفاخرة
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
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
      backgroundColor: const Color(0xFF050508), // ثيم الأوبسيديان العميق
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        elevation: 0,
        title: const Text('المَـرصَـد', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        // تم إزالة الأيقونات العلوية بناءً على طلبك لتنظيف الواجهة
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 10,
        child: const Icon(Icons.add_rounded, size: 28),
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // -----------------------------------------------------
                // شريط القصص (Stories) المربوط بقاعدة البيانات
                // -----------------------------------------------------
                SliverToBoxAdapter(
                  child: Container(
                    height: 110,
                    margin: const EdgeInsets.only(top: 10),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('stories').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white24));
                        }
                        
                        final stories = snapshot.data?.docs ?? [];
                        
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: stories.length + 1, // +1 لقصتك
                          itemBuilder: (context, index) {
                            final isMe = index == 0;
                            
                            String name = 'قصتك';
                            String profilePic = '';
                            bool hasStory = false;

                            if (!isMe && stories.isNotEmpty) {
                              final data = stories[index - 1].data() as Map<String, dynamic>;
                              name = data['displayName']?.split(' ')[0] ?? 'مستكشف';
                              profilePic = data['profilePic'] ?? '';
                              hasStory = true;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: isMe 
                                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
                                      : () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عرض القصص قيد التطوير'), backgroundColor: Colors.black87));
                                        },
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isMe ? Colors.white38 : Colors.white, width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 32,
                                            backgroundColor: const Color(0xFF101015),
                                            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                            child: profilePic.isEmpty && !isMe 
                                                ? Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                                : isMe ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                                          ),
                                        ),
                                        if (isMe)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                                            child: const Icon(Icons.add, color: Colors.black, size: 14, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(name, style: TextStyle(fontSize: 12, color: isMe ? Colors.white : Colors.white70, fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: Divider(color: Colors.white12, height: 1, indent: 20, endIndent: 20)),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                
                // -----------------------------------------------------
                // قسم المنشورات (Posts) المربوط بـ Firestore
                // -----------------------------------------------------
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: Colors.white))),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: Text('المرصد فارغ حالياً! 🚀\nكن أول من يطلق منشوراً.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16))),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // أنميشن دخول متدرج للمنشورات
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 500)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: PostWidget(post: posts[index]),
                          );
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
// ويدجت المنشور المستقل
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
  bool _isLiked = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  // مفتاح Gemini لسديم
  final String _apiKey = 'AIzaSyDN6c9X9txXrD7OaIgYrzIY1d_sk_zZmdI';

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _likeScale = Tween<double>(begin: 0.0, end: 1.2).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));
    _checkIfLiked();
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    if (currentUser == null) return;
    final likeDoc = await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).collection('likes').doc(currentUser!.uid).get();
    if (mounted) setState(() => _isLiked = likeDoc.exists);
  }

  void _triggerLike() async {
    if (currentUser == null) return;
    setState(() => _isLiked = !_isLiked);
    
    if (_isLiked) {
      _likeController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _likeController.reverse();
        });
      });
      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).collection('likes').doc(currentUser!.uid).set({});
      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({'likesCount': FieldValue.increment(1)});
    } else {
      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).collection('likes').doc(currentUser!.uid).delete();
      await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({'likesCount': FieldValue.increment(-1)});
    }
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassCommentsSheet(postId: widget.post.id),
    );
  }

  // ✨ نافذة سديم المخصصة للمنشورات
  void _showAIPostDialog(String caption) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
              const SizedBox(height: 15),
              const Text('سديم المُحلل ✨', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('بناءً على نص هذا المنشور، ماذا تريد أن أفعل؟', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 25),
              _buildAIActionBtn(Icons.comment, 'اقترح تعليقاً إبداعياً', caption),
              const SizedBox(height: 10),
              _buildAIActionBtn(Icons.translate, 'ترجمة النص', caption),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIActionBtn(IconData icon, String label, String caption) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم يفكر... ✨'), backgroundColor: Colors.black87));
          try {
            final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: _apiKey);
            final response = await model.generateContent([Content.text('المستخدم يطلب: $label. بناءً على هذا المنشور: "$caption". أجب باختصار وإبداع.')]);
            if (response.text != null && mounted) {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: const Color(0xFF101015),
                   title: const Text('رد سديم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   content: Text(response.text!, style: const TextStyle(color: Colors.white70, height: 1.5)),
                   actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً', style: TextStyle(color: Colors.white)))],
                 )
               );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في الاتصال بسديم.'), backgroundColor: Colors.red));
          }
        },
        icon: Icon(icon, color: Colors.white70, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.post.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    final timeString = timestamp != null ? timeago.format(timestamp.toDate(), locale: 'ar') : 'الآن';
    final profilePic = data['profilePic'] ?? '';
    final commentsCount = data['commentsCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.only(bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة المنشور
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1.5)),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF101015),
                  backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                  child: profilePic.isEmpty ? Text(data['displayName'].substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                ),
              ),
              title: Text(data['displayName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              subtitle: Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              trailing: IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white54), onPressed: () {}),
            ),
            
            // صورة المنشور
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
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.white.withOpacity(0.02),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.white.withOpacity(0.02),
                        child: const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 50),
                      ),
                    ),
                    ScaleTransition(
                      scale: _likeScale,
                      child: const Icon(Icons.favorite, color: Colors.white, size: 100, shadows: [Shadow(color: Colors.white, blurRadius: 40)]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 5),
            
            // أزرار التفاعل
            Row(
              children: [
                IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border_rounded, color: _isLiked ? Colors.white : Colors.white), onPressed: _triggerLike),
                IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white), onPressed: _showCommentsBottomSheet),
                IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.white70, size: 20), tooltip: 'تحليل سديم', onPressed: () => _showAIPostDialog(data['caption'])),
                const Spacer(),
                IconButton(icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white), onPressed: () {}),
              ],
            ),
            
            // الإعجابات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('${data['likesCount']} إعجاب', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
            ),
            
            // الوصف
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontFamily: 'sans-serif'),
                  children: [
                    TextSpan(text: '${data['username']} ', style: const TextStyle(fontWeight: FontWeight.w900)),
                    TextSpan(text: data['caption']),
                  ],
                ),
              ),
            ),
            
            // التعليقات
            if (commentsCount > 0)
              GestureDetector(
                onTap: _showCommentsBottomSheet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Text('عرض جميع التعليقات الـ $commentsCount', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ويدجت التعليقات الزجاجي
// ---------------------------------------------------------
class GlassCommentsSheet extends StatefulWidget {
  final String postId;
  const GlassCommentsSheet({super.key, required this.postId});

  @override
  State<GlassCommentsSheet> createState() => _GlassCommentsSheetState();
}

class _GlassCommentsSheetState extends State<GlassCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;
    final text = _commentController.text.trim();
    _commentController.clear();
    
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'userId': currentUser!.uid,
      'username': userDoc.data()?['username'] ?? '@مستكشف',
      'profilePic': userDoc.data()?['profilePic'] ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({'commentsCount': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.8,
      builder: (_, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0E).withOpacity(0.85),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10))),
                  const Padding(padding: EdgeInsets.all(15), child: Text('التعليقات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                        final comments = snapshot.data!.docs;
                        if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد.', style: TextStyle(color: Colors.white54)));
                        return ListView.builder(
                          controller: controller, itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final c = comments[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white12,
                                backgroundImage: c['profilePic'] != '' ? NetworkImage(c['profilePic']) : null,
                                child: c['profilePic'] == '' ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              title: Text(c['username'], style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(c['text'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          },
                        );
                      }
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, top: 10, left: 15, right: 15),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController, style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'أضف تعليقاً...', hintStyle: const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              filled: true, fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _addComment),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ويدجت الزجاج المخصص
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  
  const GlassContainer({super.key, required this.child, this.padding = const EdgeInsets.all(0)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ),
    );
  }
}
