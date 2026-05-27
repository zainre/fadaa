import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'dart:math' as math;

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ريـلـز الفضاء', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: 5, // لاحقاً سيتم سحب العدد من قاعدة البيانات
        itemBuilder: (context, index) {
          // كل مقطع ريلز هو ويدجت مستقل ليتعامل مع الفيديو الخاص به
          return ReelVideoItem(index: index);
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// ويدجت الريلز المستقل (يحتوي على مشغل الفيديو والأنميشن)
// ---------------------------------------------------------
class ReelVideoItem extends StatefulWidget {
  final int index;
  const ReelVideoItem({super.key, required this.index});

  @override
  State<ReelVideoItem> createState() => _ReelVideoItemState();
}

class _ReelVideoItemState extends State<ReelVideoItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _isLiked = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // أنميشن الإعجاب عند الضغط المزدوج
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _likeScale = Tween<double>(begin: 0.0, end: 1.5).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut));

    // إعداد مشغل الفيديو (هنا نضع رابط فيديو افتراضي أو نتركه فارغاً مؤقتاً)
    // _videoController = VideoPlayerController.networkUrl(Uri.parse('رابط_الفيديو_هنا'))
    //   ..initialize().then((_) {
    //     setState(() {});
    //     _videoController!.setLooping(true);
    //     _videoController!.play();
    //   });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _likeController.dispose();
    super.dispose();
  }

  void _triggerLike() {
    setState(() => _isLiked = true);
    _likeController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _likeController.reverse();
      });
    });
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

  // نافذة الذكاء الاصطناعي الخاصة بالريلز
  void _showAIReelDialog() {
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
              const Text('محلل الفضاء الذكي ✨', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'ماذا تريد من الذكاء الاصطناعي أن يفعل بهذه اللقطة؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 25),
              _buildAIActionBtn(Icons.summarize, 'لخّص لي هذا المقطع'),
              const SizedBox(height: 10),
              _buildAIActionBtn(Icons.comment, 'اقترح تعليقاً إبداعياً'),
              const SizedBox(height: 10),
              _buildAIActionBtn(Icons.translate, 'ترجمة محتوى الفيديو'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIActionBtn(IconData icon, String label) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
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
    return GestureDetector(
      onDoubleTap: _triggerLike,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية مؤقتة متدرجة (إلى أن يتم ربط الفيديوهات الحقيقية)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.primaries[(widget.index * 3) % Colors.primaries.length].withOpacity(0.6),
                  const Color(0xFF0B0B19),
                ],
              ),
            ),
            child: _videoController != null && _videoController!.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.slow_motion_video, size: 80, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 10),
                        Text('فيديو ريلز رقم ${widget.index + 1}', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
          ),
          
          // تأثير التعتيم السفلي لكي تظهر النصوص بوضوح
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
            ),
          ),

          // أيقونة الإيقاف المؤقت
          if (!_isPlaying)
            const Center(
              child: Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white54),
            ),

          // القلب المتوهج (أنميشن الإعجاب المزدوج)
          Center(
            child: ScaleTransition(
              scale: _likeScale,
              child: const Icon(Icons.favorite, color: Colors.white, size: 120, shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 40)]),
            ),
          ),

          // قائمة الأزرار الجانبية (الإعجاب، التعليق، المشاركة، الذكاء الاصطناعي)
          Positioned(
            bottom: 30,
            left: 16, // في الواجهات العربية (RTL) نضع الأزرار على اليسار
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSideAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.pinkAccent : Colors.white,
                  label: '${(widget.index + 1) * 12}K',
                  onTap: _triggerLike,
                ),
                const SizedBox(height: 20),
                _buildSideAction(icon: Icons.chat_bubble_outline, label: '${(widget.index + 1) * 300}', onTap: () {}),
                const SizedBox(height: 20),
                _buildSideAction(icon: Icons.send_outlined, label: 'مشاركة', onTap: () {}),
                const SizedBox(height: 20),
                
                // زر الذكاء الاصطناعي الخاص بالريلز
                GestureDetector(
                  onTap: _showAIReelDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                      boxShadow: [BoxShadow(color: const Color(0xFFA259FF).withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),

          // معلومات الفيديو السفلية
          Positioned(
            bottom: 30,
            right: 16,
            left: 80, // ترك مساحة للأزرار الجانبية
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black,
                        child: Text('م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '@رائد_الفضاء_${widget.index}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                    ),
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
                const Text(
                  'لقطة من أعماق الفضاء.. هذا النص يتم جلبه من قاعدة البيانات لاحقاً 🚀 #فلاتر #تطبيقات #برمجة', 
                  style: TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text('الصوت الأصلي - موسيقى الفضاء', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // دالة مساعدة لإنشاء الأزرار الجانبية
  Widget _buildSideAction({required IconData icon, Color color = Colors.white, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
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
