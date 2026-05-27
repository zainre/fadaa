import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math; // أضفنا هذه المكتبة لحسابات الدوران والطفو

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC1Ao53gJgrlw3DwoRoq0xK9Wq1-dPB8uc",
        appId: "1:611756083257:android:9f48cc6b3aad31d29865e8",
        messagingSenderId: "611756083257",
        projectId: "gen-lang-client-0777727516",
      ),
    );
  } catch (e) {
    print("خطأ في فايربيس: $e");
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
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF0095F6),
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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;
  bool isLogin = true; // للتبديل بين تسجيل الدخول وإنشاء الحساب
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // أنميشن مستمر وبطيء يناسب الفضاء (10 ثواني للدورة الكاملة)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        // تسجيل الدخول
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // إنشاء حساب جديد
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        // هنا يمكن حفظ الاسم (nameController.text) في Firestore لاحقاً
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنشاء الحساب بنجاح! 🎉"), backgroundColor: Colors.green));
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isLogin ? "تأكد من البريد وكلمة المرور!" : "حدث خطأ أثناء إنشاء الحساب!"), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية متدرجة تعطي إيحاء بعمق الفضاء
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A1A2E), Colors.black],
            center: Alignment.center,
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أنميشن الطفو والدوران
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        // حركة طفو للأعلى وللأسفل
                        offset: Offset(0, 15 * math.sin(_animationController.value * 2 * math.pi)),
                        child: Column(
                          children: [
                            Transform.rotate(
                              // دوران بطيء ومستمر للأيقونة
                              angle: _animationController.value * 2 * math.pi,
                              child: const Icon(Icons.blur_on, size: 100, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            const Text("فَـضـاء", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'sans-serif')),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // عنوان الشاشة يتغير حسب الحالة
                  Text(isLogin ? "تسجيل الدخول" : "إنشاء حساب جديد", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 30),

                  // حقل الاسم يظهر فقط في حالة إنشاء حساب
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isLogin ? 0 : 70,
                    curve: Curves.easeInOut,
                    child: isLogin ? const SizedBox.shrink() : TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "الاسم الكامل",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "البريد الإلكتروني",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "كلمة المرور",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0095F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(isLogin ? "دخول" : "إنشاء حساب", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // زر التبديل بين الواجهتين
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? "ليس لديك حساب؟ " : "لديك حساب بالفعل؟ ", style: const TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isLogin = !isLogin;
                            emailController.clear();
                            passwordController.clear();
                          });
                        },
                        child: Text(isLogin ? "إنشاء حساب" : "تسجيل الدخول", style: const TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
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
    Center(child: Text('الرئيسية', style: TextStyle(fontSize: 24))),
    Center(child: Text('ريلز', style: TextStyle(fontSize: 24))),
    Center(child: Text('المحادثات', style: TextStyle(fontSize: 24))),
    Center(child: Text('حسابي', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("فَضاء", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.black, centerTitle: true),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
