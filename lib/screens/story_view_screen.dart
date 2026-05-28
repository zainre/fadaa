import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class StoryViewScreen extends StatefulWidget {
  final Map<String, dynamic> storyData;

  const StoryViewScreen({super.key, required this.storyData});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.storyData['isVideo'] ?? false;
    final mediaUrl = widget.storyData['mediaUrl'] ?? '';

    // إعداد المؤقت (5 ثوانٍ للصور افتراضياً)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), 
    );

    // إذا كانت القصة فيديو، نشغل الفيديو ونجعل المؤقت ينتهي بانتهاء الفيديو
    if (_isVideo && mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          setState(() {
            _progressController.duration = _videoController!.value.duration;
          });
          _videoController!.play();
          _progressController.forward();
        });
    } else {
      _progressController.forward();
    }

    // إغلاق الشاشة تلقائياً عند انتهاء المؤقت
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // إيقاف المؤقت عند الضغط مطولاً
  void _handleTapDown(TapDownDetails details) {
    _progressController.stop();
    _videoController?.pause();
  }

  // استئناف المؤقت عند رفع الإصبع
  void _handleTapUp(TapUpDetails details) {
    _progressController.forward();
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = widget.storyData['mediaUrl'] ?? '';
    final displayName = widget.storyData['displayName'] ?? 'مستكشف';
    final profilePic = widget.storyData['profilePic'] ?? '';
    final caption = widget.storyData['caption'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // عرض الوسائط (صورة أو فيديو)
            if (_isVideo && _videoController != null)
              _videoController!.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (!_isVideo)
              CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
              ),

            // تدرج لوني علوي لضمان وضوح النص
            Positioned(
              top: 0, left: 0, right: 0, height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  )
                ),
              ),
            ),

            // شريط التقدم العلوي
            Positioned(
              top: 50, left: 10, right: 10,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: Colors.white38,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 2.5,
                    borderRadius: BorderRadius.circular(10),
                  );
                }
              ),
            ),

            // معلومات المستخدم وزر الإغلاق
            Positioned(
              top: 65, left: 15, right: 15,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                    child: profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // وصف القصة (إذا وجد)
            if (caption.isNotEmpty)
              Positioned(
                bottom: 40, left: 20, right: 20,
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
