import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ملاحظة: تأكد من إضافة ملف google-services.json لاحقاً ليعمل الفايربيس
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase not initialized: $e");
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
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
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

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // دالة إنشاء حساب جديد
  void signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  // دالة تسجيل الدخول
  void signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("تسجيل الدخول", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: signIn,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("تسجيل الدخول"),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: signUp,
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("إنشاء حساب جديد"),
              ),
            ],
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
    Center(child: Text('الرئيسية (المنشورات)', style: TextStyle(fontSize: 24))),
    Center(child: Text('ريلز', style: TextStyle(fontSize: 24))),
    Center(child: Text('المحادثات', style: TextStyle(fontSize: 24))),
    Center(child: Text('الملف الشخصي', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("فَضاء"), backgroundColor: Colors.black),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'ريلز'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'المحادثات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
