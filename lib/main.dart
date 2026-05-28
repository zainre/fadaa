import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// استدعاء الشاشات من مجلد screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 🛡️ التعديل الذكي: تم إزالة الإعدادات اليدوية
    // الآن سيقوم التطبيق بقراءة ملف google-services.json المحدث تلقائياً
    // مما يضمن عمل "تسجيل الدخول بجوجل" بعد إضافة بصمات SHA-1
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("خطأ في تهيئة فايربيس: $e");
  }
  
  runApp(const FadaaApp());
}

class FadaaApp extends StatelessWidget {
  const FadaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فَضاء',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // تم توحيد اللون هنا ليكون مطابقاً للثيم الفاخر في كل التطبيق
        scaffoldBackgroundColor: const Color(0xFF050508), 
        primaryColor: Colors.white,
        fontFamily: 'sans-serif', 
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'AE')],
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF050508),
              body: Center(
                child: CircularProgressIndicator(color: Colors.white)
              )
            );
          }
          
          if (snapshot.hasData) {
            return const HomeScreen(); 
          }
          
          return const LoginScreen(); 
        },
      ),
    );
  }
}
