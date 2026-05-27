import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';

import 'api_keys.dart'; // 👈 استدعاء ملف المفاتيح المركزي

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508), // ثيم الأوبسيديان الفاخر
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ريـلـز الفضاء', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      // جلب الفيديوهات الحقيقية من قاعدة البيانات
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reels').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.slow_motion_video_rounded, size: 80, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('لا توجد فيديوهات في الفضاء حالياً 🚀', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              )
            );
          }

          final reels = snapshot.data!.docs;

          return PageView.builder(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: reels.length,
            itemBuilder: (context, index) {
              return ReelVideoItem(reelDoc: reels[index]);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// ويدجت الريلز المستقل
// ---------------------------------------------------------
class ReelVideoItem extends StatefulWidget {
  final QueryDocumentSnapshot reelDoc;
  const ReelVideoItem({super.key, required this.reelDoc});

  @override
  State<ReelVideoItem> createState() => _ReelVideoItemState();
}

class _ReelVideoItemState extends State<ReelVideoItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  
  bool _isLiked = false;
  bool _isPlaying = true;
  
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final data = widget.reelDoc.data() as Map<String, dynamic>;
    
    // إعداد مشغل الفيديو من الرابط الحقيقي
    _videoController = VideoPlayerController.networkUrl(Uri.parse(data['mediaUrl']))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
      });

    // إعداد أنميشن الإعجاب المزدوج
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _likeScale = Tween<double>(begin: 0.0, end: 1.5).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));
    
    _checkIfLiked();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _likeController.dispose();
    super.dispose();
  }

  // التحقق مما إذا كان المستخدم قد أعجب بالفيديو مسبقاً
  Future<void> _checkIfLiked() async {
    if (currentUser == null) return;
    final likeDoc = await FirebaseFirestore.instance.collection('reels').doc(widget.reelDoc.id).collection('likes').doc(currentUser!.uid).get();
    if (mounted) {
      setState(() => _isLiked = likeDoc.exists);
    }
  }

  // تفعيل الإعجاب
  void _triggerLike() async {
    if (currentUser == null) return;
    
    setState(() => _isLiked = !_isLiked);
    
    if (_isLiked) {
      _likeController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _likeController.reverse();
        });
      });
      // إضافة الإعجاب في القاعدة
      await FirebaseFirestore.instance.collection('reels').doc(widget.reelDoc.id).collection('likes').doc(currentUser!.uid).set({});
      await FirebaseFirestore.instance.collection('reels').doc(widget.reelDoc.id).update({'likesCount': FieldValue.increment(1)});
    } else {
      // إزالة الإعجاب
      await FirebaseFirestore.instance.collection('reels').doc(widget.reelDoc.id).collection('likes').doc(currentUser!.uid).delete();
      await FirebaseFirestore.instance.collection('reels').doc(widget.reelDoc.id).update({'likesCount': FieldValue.increment(-1)});
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    });
  }

  // 💬 نافذة التعليقات الزجاجية
  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassBottomSheet(reelId: widget.reelDoc.id),
    );
  }

  // ✨ نافذة سديم المخصصة للريلز (تقرأ من المركز)
  void _showAIReelDialog(String caption) {
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
              const Text(
                'بناءً على محتوى ووصف هذا المقطع، ماذا تريد أن أفعل؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 25),
              _buildAIActionBtn(Icons.comment, 'اقترح تعليقاً إبداعياً', caption),
              const SizedBox(height: 10),
              _buildAIActionBtn(Icons.summarize, 'ما هي الفكرة العامة؟', caption),
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
            // 🛡️ استخدام المفتاح من الملف المركزي
            final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: ApiKeys.geminiKeys.first);
            final response = await model.generateContent([Content.text('المستخدم يطلب: $label. بناءً على هذا الوصف للمقطع: "$caption". أجب باختصار وإبداع.')]);
            if (response.text != null && mounted) {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: const Color(0xFF101015),
                   title: const Text('رد سديم', style: TextStyle(color: Colors.white)),
                   content: Text(response.text!, style: const TextStyle(color: Colors.white70)),
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
    final data = widget.reelDoc.data() as Map<String, dynamic>;
    final caption = data['caption'] ?? '';
    final username = data['username'] ?? '@مجهول';
    final likesCount = data['likesCount'] ?? 0;
    final commentsCount = data['commentsCount'] ?? 0;
    final profilePic = data['profilePic'] ?? '';

    return GestureDetector(
      onDoubleTap: _triggerLike,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الفيديو أو التحميل
          Container(
            color: const Color(0xFF050508),
            child: _videoController != null && _videoController!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          
          // التعتيم السفلي الفاخر
          Positioned(
            bottom: 0, left: 0, right: 0, height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
            ),
          ),

          // أيقونة الإيقاف
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                child: const Icon(Icons.play_arrow_rounded, size: 60, color: Colors.white),
              ),
            ),

          // القلب المتوهج
          Center(
            child: ScaleTransition(
              scale: _likeScale,
              child: const Icon(Icons.favorite, color: Colors.white, size: 120, shadows: [Shadow(color: Colors.white, blurRadius: 40)]),
            ),
          ),

          // الأزرار الجانبية
          Positioned(
            bottom: 30,
            left: 16, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSideAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.redAccent : Colors.white,
                  label: likesCount.toString(),
                  onTap: _triggerLike,
                ),
                const SizedBox(height: 25),
                _buildSideAction(
                  icon: Icons.chat_bubble_outline_rounded, 
                  label: commentsCount.toString(), 
                  onTap: _showCommentsBottomSheet
                ),
                const SizedBox(height: 25),
                _buildSideAction(icon: Icons.send_rounded, label: 'مشاركة', onTap: () {}),
                const SizedBox(height: 25),
                
                // زر سديم
                GestureDetector(
                  onTap: () => _showAIReelDialog(caption),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white38)
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // معلومات الفيديو
          Positioned(
            bottom: 30,
            right: 16,
            left: 80, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black,
                        backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                        child: profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(0, 30)
                      ),
                      child: const Text('متابعة', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  caption, 
                  style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text('الصوت الأصلي - فضاء', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideAction({required IconData icon, Color color = Colors.white, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// ويدجت التعليقات الزجاجي (BottomSheet)
// ---------------------------------------------------------
class GlassBottomSheet extends StatefulWidget {
  final String reelId;
  const GlassBottomSheet({super.key, required this.reelId});

  @override
  State<GlassBottomSheet> createState() => _GlassBottomSheetState();
}

class _GlassBottomSheetState extends State<GlassBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;
    
    final text = _commentController.text.trim();
    _commentController.clear();
    
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    
    await FirebaseFirestore.instance.collection('reels').doc(widget.reelId).collection('comments').add({
      'userId': currentUser!.uid,
      'username': userDoc.data()?['username'] ?? '@مستكشف',
      'profilePic': userDoc.data()?['profilePic'] ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await FirebaseFirestore.instance.collection('reels').doc(widget.reelId).update({'commentsCount': FieldValue.increment(1)});
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
                color: const Color(0xFF101015).withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10))),
                  const Padding(padding: EdgeInsets.all(15), child: Text('التعليقات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  const Divider(color: Colors.white12, height: 1),
                  
                  // قائمة التعليقات
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('reels').doc(widget.reelId).collection('comments').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                        final comments = snapshot.data!.docs;
                        if (comments.isEmpty) return const Center(child: Text('كن أول من يعلق!', style: TextStyle(color: Colors.white54)));
                        
                        return ListView.builder(
                          controller: controller,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final c = comments[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white12,
                                backgroundImage: c['profilePic'] != '' ? NetworkImage(c['profilePic']) : null,
                                child: c['profilePic'] == '' ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              title: Text(c['username'], style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(c['text'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                            );
                          },
                        );
                      }
                    ),
                  ),
                  
                  // حقل الإدخال
                  Container(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, top: 10, left: 15, right: 15),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'أضف تعليقاً في الفضاء...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              filled: true, fillColor: Colors.white.withOpacity(0.1),
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

// ويدجت الزجاج
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: child,
        ),
      ),
    );
  }
}
