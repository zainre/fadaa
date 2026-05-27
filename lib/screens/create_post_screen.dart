import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'dart:math' as math;

enum UploadType { post, reel, story }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with TickerProviderStateMixin {
  File? _mediaFile;
  UploadType _selectedType = UploadType.post;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  bool _isGeneratingAI = false;

  late AnimationController _bgController;

  // ==========================================
  // مفاتيح Supabase الخاصة بك (تم دمجها برمجياً)
  // ==========================================
  final String _supabaseUrl = 'https://qkphtbweyeubtyxudscb.supabase.co';
  final String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrcGh0YndleWV1YnR5eHVkc2NiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4OTA3OTMsImV4cCI6MjA5NTQ2Njc5M30.s1XrUlPQNkbWPBoCt_a7wRNspfv40CVcD0f5dOGtWDg'; 
  final String _bucketName = 'media'; 
  // ==========================================

  final List<String> _apiKeys = [
    'AIzaSyCub9KcJtGTZdZ-PAC6rheWOmAw0EZORxc',
    'AIzaSyD86oeJ6ZNQHkjzIyYAaOZ1oiUZR4G-h-Q',
    'AIzaSyA2swL6nANoba5HC8VZ_iKzH5ElfNOKrZU',
    'AIzaSyD6QamLUA9y3ugUH2tl8H6eYBmwo9-wtBU',
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (_selectedType == UploadType.reel) {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 1));
      _isVideo = true;
    } else {
      pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      _isVideo = false;
    }

    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
      });

      if (_isVideo) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_mediaFile!)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.setLooping(true);
            _videoController!.play();
          });
      }
    }
  }

  Future<void> _enhanceCaptionWithAI() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب فكرة بسيطة أولاً ليقوم سديم بتطويرها! 🌌', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white));
      return;
    }

    setState(() => _isGeneratingAI = true);
    bool success = false;
    int attempts = 0;
    int currentKeyIndex = 0;

    final prompt = 'أنت سديم، المساعد الذكي لتطبيق "فضاء". قم بصياغة وتحسين هذا النص ليصبح وصفاً احترافياً وجذاباً لمنشور، استخدم لغة عربية فصيحة راقية، وأضف هاشتاجات مناسبة. النص هو: ${_captionController.text}';

    while (!success && attempts < _apiKeys.length) {
      try {
        final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: _apiKeys[currentKeyIndex]);
        final response = await model.generateContent([Content.text(prompt)]);
        
        if (response.text != null && mounted) {
          setState(() {
            _captionController.text = response.text!.replaceAll('"', '');
          });
          success = true;
        }
      } catch (e) {
        attempts++;
        currentKeyIndex = (currentKeyIndex + 1) % _apiKeys.length;
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم يواجه تشويشاً حالياً، حاول مرة أخرى.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isGeneratingAI = false);
  }

  // 🚀 دالة الرفع لـ Supabase المدمجة مع Firestore
  Future<void> _uploadMedia() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب اختيار ملف وسائط أولاً!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'المستخدم غير مسجل الدخول';

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] ?? '@مستكشف';
      final displayName = userDoc.data()?['name'] ?? 'رائد فضاء';
      final profilePic = userDoc.data()?['profilePic'] ?? '';

      String collectionName;
      switch (_selectedType) {
        case UploadType.post: collectionName = 'posts'; break;
        case UploadType.reel: collectionName = 'reels'; break;
        case UploadType.story: collectionName = 'stories'; break;
      }

      final fileExt = _isVideo ? '.mp4' : '.jpg';
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final mimeType = _isVideo ? 'video/mp4' : 'image/jpeg';
      
      // رفع الملف إلى Supabase
      final uploadUrl = Uri.parse('$_supabaseUrl/storage/v1/object/$_bucketName/$collectionName/$fileName');
      final request = await HttpClient().postUrl(uploadUrl);
      
      request.headers.set('Authorization', 'Bearer $_supabaseAnonKey');
      request.headers.set('apikey', _supabaseAnonKey);
      request.headers.set('Content-Type', mimeType);
      
      final fileBytes = await _mediaFile!.readAsBytes();
      request.add(fileBytes);
      
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw 'تأكد أن حاوية media تم تفعيل خيار Public لها في Supabase!';
      }

      // الحصول على الرابط
      final mediaUrl = '$_supabaseUrl/storage/v1/object/public/$_bucketName/$collectionName/$fileName';

      // الحفظ في قاعدة بياناتك (Firebase)
      await FirebaseFirestore.instance.collection(collectionName).add({
        'userId': user.uid,
        'username': username,
        'displayName': displayName,
        'profilePic': profilePic,
        'mediaUrl': mediaUrl,
        'isVideo': _isVideo,
        'caption': _captionController.text.trim(),
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_selectedType != UploadType.story) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'posts_count': FieldValue.increment(1),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 تم الإطلاق بنجاح!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الرفع: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إطلاق جديد', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.05), const Color(0xFF050508)],
                    center: Alignment(math.sin(_bgController.value * math.pi), math.cos(_bgController.value * math.pi)),
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        _buildTypeSelector(UploadType.post, 'منشور', Icons.grid_on_rounded),
                        _buildTypeSelector(UploadType.reel, 'ريلز', Icons.slow_motion_video_rounded),
                        _buildTypeSelector(UploadType.story, 'قصة', Icons.data_usage_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  GestureDetector(
                    onTap: _pickMedia,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: _selectedType == UploadType.reel ? 400 : 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: _mediaFile != null
                              ? _isVideo && _videoController != null && _videoController!.value.isInitialized
                                  ? FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _videoController!.value.size.width,
                                        height: _videoController!.value.size.height,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                    )
                                  : Image.file(_mediaFile!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _selectedType == UploadType.reel ? Icons.video_library_rounded : Icons.add_photo_alternate_rounded,
                                      size: 60, color: Colors.white38
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedType == UploadType.reel ? 'اختر فيديو من الفضاء' : 'اختر صورة من المجرة',
                                      style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_selectedType != UploadType.story) ...[
                    const Text('وصف الإطلاق', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: TextField(
                        controller: _captionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'بمَ تفكر؟ اكتب هنا أو دع سديم يصيغ أفكارك...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تحتاج لمسة إبداعية؟', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ElevatedButton.icon(
                          onPressed: _isGeneratingAI ? null : _enhanceCaptionWithAI,
                          icon: _isGeneratingAI 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                          label: const Text('صياغة سديم ✨', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 10,
                            shadowColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],

                  if (_selectedType == UploadType.story) const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _uploadMedia,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        shadowColor: Colors.white.withOpacity(0.2),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              _selectedType == UploadType.story ? 'نشر القصة 💫' : 'إطلاق للمجتمع 🚀',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(UploadType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _mediaFile = null;
            _videoController?.dispose();
            _videoController = null;
            _captionController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.white54, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  
  const GlassContainer({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
