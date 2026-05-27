import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'api_keys.dart'; // استدعاء ملف المفاتيح المركزي

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
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
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

  Future<void> _generateAIBio() async {
    setState(() => _isGeneratingBio = true);
    try {
      // قراءة مفتاح سديم من الملف المركزي
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: ApiKeys.geminiKeys.first);
      final prompt = 'اكتب نبذة شخصية (Bio) قصيرة ومميزة لتطبيق تواصل اجتماعي لشاب اسمه زين العابدين، طالب سادس علمي، مهتم بالبرمجة وبناء التطبيقات، ومحب للشعر العربي الفصيح. اجعلها سطرين فقط وبطابع فخم، إبداعي، وعميق.';
      
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null && mounted) {
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
          'bio': response.text!.replaceAll('"', ''), 
        }, SetOptions(merge: true));
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ تم توليد البايو السحري بنجاح!'), backgroundColor: Colors.black87));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في الاتصال بالذكاء الاصطناعي.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGeneratingBio = false);
    }
  }

  // 📸 دالة رفع الصورة الشخصية (مربوطة بالمركز)
  Future<void> _changeProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final file = File(pickedFile.path);
      final fileName = '${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // استخدام المفاتيح المركزية
      final uploadUrl = Uri.parse('${ApiKeys.supabaseUrl}/storage/v1/object/${ApiKeys.bucketName}/profile_images/$fileName');
      final request = await HttpClient().postUrl(uploadUrl);
      
      request.headers.set('Authorization', 'Bearer ${ApiKeys.supabaseAnonKey}');
      request.headers.set('apikey', ApiKeys.supabaseAnonKey);
      request.headers.set('Content-Type', 'image/jpeg');
      
      final fileBytes = await file.readAsBytes();
      request.add(fileBytes);
      
      final response = await request.close();
      
      if (response.statusCode != 200) throw 'فشل رفع الصورة';

      final downloadUrl = '${ApiKeys.supabaseUrl}/storage/v1/object/public/${ApiKeys.bucketName}/profile_images/$fileName';

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'profilePic': downloadUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح 📸', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.black87),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصورة.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // 🛡️ نافذة التعديل مع نظام الحماية الشامل وفحص التكرار
  void _showEditProfileDialog(String currentName, String currentUsername) {
    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentUsername.replaceAll('@', ''));
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعديل الملف الشخصي', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم (Username)',
                      prefixText: '@ ',
                      prefixStyle: TextStyle(color: Colors.white70),
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving ? null : () async {
                          final newName = nameController.text.trim();
                          final newUsername = usernameController.text.trim().toLowerCase();
                          
                          if (newName.isEmpty || newUsername.isEmpty) return;

                          final String? email = user?.email;
                          final bool isVIP = email == 'sly86055r@gmail.com' || email == 'zainalabdeensalman123@gmail.com';
                          final int minLength = isVIP ? 2 : 4;

                          // فحص طول اليوزرنيم
                          if (newUsername.length < minLength || newUsername.length > 16) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isVIP ? 'اليوزر من 2 إلى 16 حرفاً للـ VIP.' : 'يجب أن يتكون اسم المستخدم من 4 إلى 16 حرفاً.'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          
                          try {
                            // 🛡️ فحص التكرار الحقيقي في قاعدة البيانات
                            final userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('username', isEqualTo: '@$newUsername')
                                .get();
                                
                            // إذا وجدنا أحداً يحمل هذا اليوزر، وهو ليس المستخدم الحالي (أنت)
                            if (userQuery.docs.isNotEmpty && userQuery.docs.first.id != user!.uid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('عذراً، هذا اليوزر محجوز مسبقاً! جرب واحداً آخر.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.red),
                              );
                              setDialogState(() => isSaving = false);
                              return;
                            }

                            // إذا اجتاز كل الاختبارات، نقوم بالحفظ
                            await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
                              'name': newName,
                              'username': '@$newUsername',
                            }, SetOptions(merge: true));
                            
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ.'), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) setDialogState(() => isSaving = false);
                          }
                        },
                        child: isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508), 
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('المِلَف الشَخصي', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: const Color(0xFF101015),
                title: const Text('مغادرة الفضاء؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('البقاء', style: TextStyle(color: Colors.white54))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    child: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.05 + (_glowController.value * 0.02)),
                      const Color(0xFF050508),
                    ],
                    center: const Alignment(0, -0.4),
                    radius: 1.5,
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
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                
                final displayName = userData?['name'] ?? 'مستكشف';
                final username = userData?['username'] ?? '@explorer';
                final bio = userData?['bio'] ?? 'لم تتم كتابة نبذة شخصية بعد...';
                final profilePic = userData?['profilePic'];
                final postsCount = userData?['posts_count'] ?? 0;
                final followersCount = userData?['followers_count'] ?? 0;
                final followingCount = userData?['following_count'] ?? 0;

                return RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  onRefresh: () async { setState(() {}); },
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    children: [
                      Center(
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 8 * math.sin(_floatController.value * math.pi)),
                              child: GestureDetector(
                                onTap: _changeProfileImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white24, width: 2),
                                        boxShadow: [
                                          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)
                                        ]
                                      ),
                                      child: CircleAvatar(
                                        radius: 55,
                                        backgroundColor: const Color(0xFF101015),
                                        backgroundImage: profilePic != null && profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                        child: (profilePic == null || profilePic.isEmpty)
                                          ? Text(displayName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white))
                                          : null,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                                      child: _isUploadingImage 
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                        : const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Center(child: Text(displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))),
                      const SizedBox(height: 4),
                      Center(child: Text(username, style: const TextStyle(fontSize: 15, color: Colors.white54, letterSpacing: 1))),
                      
                      const SizedBox(height: 25),
                      
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('النبذة الشخصية', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                                if (_isGeneratingBio)
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                else
                                  GestureDetector(
                                    onTap: _generateAIBio,
                                    child: const Row(
                                      children: [
                                        Text('صياغة سديم ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(bio, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      GlassContainer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCol('منشور', postsCount.toString()),
                            Container(width: 1, height: 35, color: Colors.white12),
                            _buildStatCol('متابِع', followersCount.toString()),
                            Container(width: 1, height: 35, color: Colors.white12),
                            _buildStatCol('يتابِع', followingCount.toString()),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      _buildMenuTile(Icons.edit_note_rounded, 'تعديل الملف الشخصي', () => _showEditProfileDialog(displayName, username)),
                      _buildMenuTile(Icons.bookmark_border_rounded, 'العناصر المحفوظة', () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الخزنة فارغة حالياً.'), backgroundColor: Colors.black87));
                      }),
                      _buildMenuTile(Icons.settings_outlined, 'إعدادات النظام', () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الإعدادات قيد التطوير.'), backgroundColor: Colors.black87));
                      }),
                      const SizedBox(height: 90),
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
        Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.1),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListTile(
              leading: Icon(icon, color: Colors.white),
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
