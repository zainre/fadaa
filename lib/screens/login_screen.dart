import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'home_screen.dart'; // تأكد من استيراد الشاشة الرئيسية الصحيحة لديك هنا أو MainScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true; // للتبديل بين تسجيل الدخول وإنشاء حساب
  
  late AnimationController _pulseController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة حفظ وبناء ملف المستخدم في قاعدة البيانات
  Future<void> _saveUserToFirestore(User? user, {String? customName}) async {
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // نتحقق أولاً إذا كان الحساب موجوداً مسبقاً حتى لا نمسح بياناته القديمة
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'name': customName ?? user.displayName ?? 'مستكشف فضاء',
          'username': '@user_${user.uid.substring(0, 6)}', // اسم مستخدم افتراضي
          'bio': 'مستكشف جديد في فضاء...',
          'posts_count': '0',
          'followers_count': '0',
          'following_count': '0',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // حفظ البيانات في Firestore
      await _saveUserToFirestore(userCred.user);
      
      _navigateToMain();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> submitEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // حفظ البيانات مع إرسال الاسم الذي أدخله المستخدم
        await _saveUserToFirestore(userCred.user, customName: _nameController.text.trim());
      }
      _navigateToMain();
    } on FirebaseAuthException catch (e) {
      _showAuthErrorDialog(e);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    if (!mounted) return;
    // قم بتغيير MainScreen إلى اسم الكلاس الرئيسي الخاص بك
    Navigator.pushReplacementNamed(context, '/main'); // أو استبدلها بـ MaterialPageRoute
  }

  void _showAuthErrorDialog(FirebaseAuthException e) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.amber.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("رمز الخطأ: ${e.code}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(e.message ?? "لا توجد تفاصيل", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("خطأ!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(msg, style: const TextStyle(color: Colors.white))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتوهجة
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: const [Color(0xFF2A1B54), Color(0xFF0B0B19)],
                    center: Alignment(math.sin(_bgController.value * math.pi), math.cos(_bgController.value * math.pi)),
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(offset: Offset(0, 30 * (1 - value)), child: Opacity(opacity: value, child: child));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // اللوجو
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.blueAccent.withOpacity(0.5 * _pulseController.value), blurRadius: 40 * _pulseController.value, spreadRadius: 5 * _pulseController.value),
                                  ],
                                ),
                                child: const Icon(Icons.blur_on, size: 90, color: Colors.white),
                              ),
                              const SizedBox(height: 15),
                              Text("فَـضـاء", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white, shadows: [Shadow(color: Colors.blueAccent.withOpacity(0.8 * _pulseController.value), blurRadius: 20 * _pulseController.value)])),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 35),
                      
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(_isLogin ? "مرحباً بك مجدداً 👋" : "انضم إلى عالمنا 🚀", key: ValueKey<bool>(_isLogin), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ),
                      const SizedBox(height: 25),

                      // حقول الإدخال الزجاجية
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutBack,
                        child: _isLogin ? const SizedBox.shrink() : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassTextField(controller: _nameController, hintText: "الاسم الكامل", icon: Icons.person_outline),
                        ),
                      ),
                      
                      GlassTextField(controller: _emailController, hintText: "البريد الإلكتروني", icon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      GlassTextField(controller: _passwordController, hintText: "كلمة المرور", icon: Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 30),
                      
                      // زر الدخول/الإنشاء
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFF005C9E)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF0095F6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : submitEmailAuth,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: _isLoading 
                              ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(_isLogin ? "تسجيل الدخول" : "إنشاء حساب", key: ValueKey<bool>(_isLogin), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // خط فاصل شفاف
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("أو", style: TextStyle(color: Colors.white54))),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // زر جوجل
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30), // آيقونة جوجل
                          label: const Text('المتابعة باستخدام Google', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            backgroundColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // زر التبديل
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin ? "ليس لديك حساب؟ " : "لديك حساب بالفعل؟ ", style: const TextStyle(color: Colors.white60)),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(_isLogin ? "إنشاء حساب" : "تسجيل الدخول", key: ValueKey<bool>(_isLogin), style: const TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ويدجت الإدخال الزجاجي 
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;

  const GlassTextField({Key? key, required this.controller, required this.hintText, required this.icon, this.isPassword = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ),
    );
  }
}
