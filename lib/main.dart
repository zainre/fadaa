import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math;
import 'dart:ui'; // مطلوب لتأثير الزجاج (Glassmorphism)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // تم ربط بيانات Firebase من ملف الـ JSON الذي أرسلته
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC1Ao53gJgrlw3DwoRoq0xK9Wq1-dPB8uc",
        appId: "1:611756083257:android:9f48cc6b3aad31d29865e8",
        messagingSenderId: "611756083257",
        projectId: "gen-lang-client-0777727516",
        storageBucket: "gen-lang-client-0777727516.firebasestorage.app", 
      ),
    );
  } catch (e) {
    print("خطأ في تهيئة فايربيس: $e");
  }
  
  runApp(const FadaaApp());
}

class FadaaApp extends StatelessWidget {
  const FadaaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فَضاء',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B19), 
        primaryColor: const Color(0xFF0095F6),
        fontFamily: 'sans-serif', 
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'AE')],
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;
  bool isLogin = true;
  
  late AnimationController _pulseController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    
    // أنميشن النبض والتوهج الثابت (مدته ثانيتين ليعطي تأثير الإضاءة الهادئة)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // أنميشن الخلفية (حركة بطيئة للألوان)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("تم إنشاء الحساب بنجاح! 🎉", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = "حدث خطأ غير معروف!";
      
      // معالجة أخطاء فايربيس بالتفصيل
      if (e.code == 'weak-password') {
        errorMessage = 'كلمة المرور ضعيفة جداً.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'هذا البريد الإلكتروني مسجل لدينا مسبقاً.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      
      // النافذة المنبثقة لمعرفة الخطأ الحقيقي
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.red.shade900,
          title: const Text("تفاصيل الخطأ السري", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(e.toString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("حسناً", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية المتحركة
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: const [Color(0xFF2A1B54), Color(0xFF0B0B19)],
                    center: Alignment(
                      math.sin(_bgController.value * math.pi), 
                      math.cos(_bgController.value * math.pi)
                    ),
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),
          
          // 2. المحتوى مع تأثير الظهور
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)), 
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أنميشن التوهج والنبض الثابت (بدون حركة طفو)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.6 * _pulseController.value), 
                                      blurRadius: 40 * _pulseController.value, 
                                      spreadRadius: 10 * _pulseController.value
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.blur_on, size: 100, color: Colors.white),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "فَـضـاء", 
                                style: TextStyle(
                                  fontSize: 42, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 2, 
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.blueAccent.withOpacity(0.8 * _pulseController.value),
                                      blurRadius: 20 * _pulseController.value,
                                    )
                                  ]
                                )
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation), child: child));
                        },
                        child: Text(isLogin ? "مرحباً بك مجدداً 👋" : "انضم إلى عالمنا 🚀", key: ValueKey<bool>(isLogin), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ),
                      const SizedBox(height: 30),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutBack,
                        child: isLogin ? const SizedBox.shrink() : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassTextField(controller: nameController, hintText: "الاسم الكامل", icon: Icons.person_outline),
                        ),
                      ),
                      
                      GlassTextField(controller: emailController, hintText: "البريد الإلكتروني", icon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      
                      GlassTextField(controller: passwordController, hintText: "كلمة المرور", icon: Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 35),
                      
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFF005C9E)]),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0095F6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isLoading 
                              ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(isLogin ? "تسجيل الدخول" : "إنشاء حساب", key: ValueKey<bool>(isLogin), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isLogin ? "ليس لديك حساب؟ " : "لديك حساب بالفعل؟ ", style: const TextStyle(color: Colors.white60)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                isLogin ? "إنشاء حساب" : "تسجيل الدخول", 
                                key: ValueKey<bool>(isLogin),
                                style: const TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 16)
                              ),
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

// ---------------------------------------------------------
// ويدجت مخصص لحقول الإدخال بتأثير الزجاج
// ---------------------------------------------------------
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;

  const GlassTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('الرئيسية', style: TextStyle(fontSize: 24, color: Colors.white))),
    Center(child: Text('ريلز', style: TextStyle(fontSize: 24, color: Colors.white))),
    Center(child: Text('المحادثات', style: TextStyle(fontSize: 24, color: Colors.white))),
    Center(child: Text('حسابي', style: TextStyle(fontSize: 24, color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("فَضاء", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF0B0B19), centerTitle: true, elevation: 0),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0B19), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'ريلز'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'المحادثات'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0095F6),
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: const Color(0xFF0B0B19),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
