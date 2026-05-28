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
    // 🚀 عدنا للطريقة اليدوية لأنها الأنسب لبرمجة الجوال وتغنيك عن ملف google-services
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC1Ao53gJgrlw3DwoRoq0xK9Wq1-dPB8uc",
        appId: "1:611756083257:android:9f48cc6b3aad31d29865e8",
        messagingSenderId: "611756083257",
        projectId: "gen-lang-client-0777727516",
        storageBucket: "gen-lang-client-0777727516.firebasestorage.app", 
        authDomain: "gen-lang-client-0777727516.firebaseapp.com",
      ),
    );
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
          if (snapshot.hasData) return const HomeScreen(); 
          return const LoginScreen(); 
        },
      ),
    );
  }
}
