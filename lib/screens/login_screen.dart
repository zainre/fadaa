import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'home_screen.dart'; 

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
  bool _isLogin = true; 
  
  late AnimationController _pulseController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // أنميشن النبض الأبيض للوجو
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    // أنميشن الخلفية الأحادية
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat(reverse: true);
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

  Future<void> _saveUserToFirestore(User? user, {String? customName}) async {
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'name': customName ?? user.displayName ?? 'مستكشف فضاء',
          'username': '@user_${user.uid.substring(0, 6)}', 
          'bio': 'مستكشف جديد في فضاء...',
          'posts_count': 0,
          'followers_count': 0,
          'following_count': 0,
          'profilePic': '',
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
        if (_nameController.text.trim().isEmpty) {
          _showError("يرجى إدخال اسمك الكامل لبدء الرحلة.");
          setState(() => _isLoading = false);
          return;
        }
        final UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _showAuthErrorDialog(FirebaseAuthException e) {
    if (!mounted) return;
    String errorMessage = "حدث خطأ غير معروف.";
    if (e.code == 'user-not-found') errorMessage = "لم يتم العثور على حساب بهذا البريد.";
    else if (e.code == 'wrong-password') errorMessage = "كلمة المرور غير صحيحة.";
    else if (e.code == 'email-already-in-use') errorMessage = "هذا البريد الإلكتروني مسجل مسبقاً.";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101015),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("تنبيه", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(errorMessage, style: const TextStyle(color: Colors.white70)),
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
        backgroundColor: const Color(0xFF101015),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("خطأ!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(msg, style: const TextStyle(color: Colors.white70))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Stack(
        children: [
          // الخلفية المتوهجة العميقة
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
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 40 * (1 - value)), 
                      child: Opacity(opacity: value, child: child)
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // اللوجو الفاخر
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.15 * _pulseController.value), 
                                      blurRadius: 30 * _pulseController.value, 
                                      spreadRadius: 5 * _pulseController.value
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.blur_on_rounded, size: 90, color: Colors.white),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                "فَـضـاء", 
                                style: TextStyle(
                                  fontSize: 40, 
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 3, 
                                  color: Colors.white,
                                )
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _isLogin ? "مرحباً بك مجدداً" : "انضم إلى عالمنا", 
                          key: ValueKey<bool>(_isLogin), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)
                        ),
                      ),
                      const SizedBox(height: 25),

                      // حقول الإدخال الزجاجية
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutBack,
                        child: _isLogin ? const SizedBox.shrink() : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassTextField(controller: _nameController, hintText: "الاسم الكامل", icon: Icons.person_outline_rounded),
                        ),
                      ),
                      
                      GlassTextField(controller: _emailController, hintText: "البريد الإلكتروني", icon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      GlassTextField(controller: _passwordController, hintText: "كلمة المرور", icon: Icons.lock_outline_rounded, isPassword: true),
                      const SizedBox(height: 35),
                      
                      // زر الدخول/الإنشاء (Premium White Button)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : submitEmailAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            shadowColor: Colors.transparent, 
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)) 
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300), 
                                  child: Text(
                                    _isLogin ? "تسجيل الدخول" : "إنشاء حساب", 
                                    key: ValueKey<bool>(_isLogin), 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)
                                  )
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // خط فاصل
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("أو", style: TextStyle(color: Colors.white54))),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // زر جوجل
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 32),
                          label: const Text('المتابعة باستخدام Google', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white.withOpacity(0.03),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      
                      // زر التبديل
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin ? "ليس لديك حساب؟ " : "لديك حساب بالفعل؟ ", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isLogin ? "إنشاء حساب" : "تسجيل الدخول", 
                                key: ValueKey<bool>(_isLogin), 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, decoration: TextDecoration.underline)
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

// ويدجت الإدخال الزجاجي الفاخر
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;

  const GlassTextField({
    super.key, 
    required this.controller, 
    required this.hintText, 
    required this.icon, 
    this.isPassword = false
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04), 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.white.withOpacity(0.08))
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w300),
              prefixIcon: Icon(icon, color: Colors.white54, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ),
    );
  }
}
