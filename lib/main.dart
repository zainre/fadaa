import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // مفاتيح مشروعك الحقيقية لربط الفايربيس بنجاح
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

// أضفنا SingleTickerProviderStateMixin لدعم الأنميشن
class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  
  // متغيرات الأنميشن
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد الأنميشن ليشتغل بشكل مستمر (نبض)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // سرعة النبضة
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // إغلاق الأنميشن عند الخروج من الشاشة
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signUp() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنشاء الحساب بنجاح! 🎉"), backgroundColor: Colors.green));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => isLoading = false);
  }

  void signIn() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تأكد من البريد وكلمة المرور!"), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // تطبيق الأنميشن على اللوكو والكلمة
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: const [
                      Icon(Icons.blur_on, size: 100, color: Colors.white),
                      SizedBox(height: 20),
                      Text("فَـضـاء", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'sans-serif')),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "البريد الإلكتروني",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF121212),
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
                    fillColor: const Color(0xFF121212),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0095F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("تسجيل الدخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ليس لديك حساب؟ ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: isLoading ? null : signUp,
                      child: const Text("إنشاء حساب جديد", style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
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
