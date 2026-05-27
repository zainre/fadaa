import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _imageFile;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  bool _isGeneratingAI = false;

  // مفتاح Gemini
  final String _apiKey = 'AIzaSyDN6c9X9txXrD7OaIgYrzIY1d_sk_zZmdI';

  // دالة اختيار الصورة
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // دالة الذكاء الاصطناعي السحرية لتحسين الوصف
  Future<void> _enhanceCaptionWithAI() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب فكرة بسيطة أولاً ليقوم الذكاء الاصطناعي بتطويرها!')),
      );
      return;
    }

    setState(() => _isGeneratingAI = true);
    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
      final prompt = 'قم بتحسين هذا النص ليصبح وصفاً احترافياً وجذاباً لمنشور في تطبيق تواصل اجتماعي، وأضف هاشتاجات مناسبة له. النص هو: ${_captionController.text}';
      
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null && mounted) {
        setState(() {
          _captionController.text = response.text!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الذكاء الاصطناعي: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAI = false);
    }
  }

  // دالة رفع المنشور إلى قاعدة البيانات
  Future<void> _uploadPost() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار صورة للمنشور!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. جلب بيانات المستخدم الحالية (الاسم واليوزر)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] ?? 'مستكشف';
      final displayName = userDoc.data()?['name'] ?? 'مستكشف الفضاء';

      // 2. رفع الصورة إلى Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('posts_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      // 3. حفظ بيانات المنشور في Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'username': username,
        'displayName': displayName,
        'imageUrl': imageUrl,
        'caption': _captionController.text.trim(),
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. تحديث عدد منشورات المستخدم في ملفه الشخصي
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'posts_count': FieldValue.increment(1),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 تم إطلاق المنشور بنجاح!'), backgroundColor: Colors.green));
      Navigator.pop(context); // العودة للشاشة السابقة

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الرفع: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('منشور جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // منطقة اختيار الصورة
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 60, color: Color(0xFFA259FF)),
                              SizedBox(height: 10),
                              Text('اضغط لاختيار صورة من المجرة', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // منطقة كتابة الوصف
            const Text('الوصف', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _captionController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'بمَ تفكر؟ اكتب هنا أو دع الذكاء الاصطناعي يساعدك...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // زر الذكاء الاصطناعي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('هل تحتاج مساعدة في التعبير؟', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ElevatedButton.icon(
                  onPressed: _isGeneratingAI ? null : _enhanceCaptionWithAI,
                  icon: _isGeneratingAI 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  label: const Text('تطوير سحري ✨', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA259FF).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // زر النشر
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0095F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إطلاق المنشور 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
