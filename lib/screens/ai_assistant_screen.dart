import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';
import 'dart:math' as math;

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _bgController;
  late AnimationController _pulseController;
  
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  
  // حفظ مؤشر المفتاح الحالي النشط
  int _currentKeyIndex = 0;

  // قائمة المفاتيح الأربعة الخاصة بك
  final List<String> _apiKeys = [
    'AIzaSyCzHgKi4LjOdMkY1ngembMvtfsvmIr9RBE',
    'AIzaSyDK9g15HqwCUY-pXcneTMgpV_35Y7sXQVA',
    'AIzaSyDN6c9X9txXrD7OaIgYrzIY1d_sk_zZmdI',
    'AIzaSyBOrfXgIPJztDb0J1xWMS3DrgrjRFKgopM',
  ];

  @override
  void initState() {
    super.initState();
    // أنميشن حركة الخلفية أحادية اللون
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat(reverse: true);
    // أنميشن نبض هالة سديم البلاتينية
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _messages.add({
      'sender': 'ai',
      'text': 'أهلاً بك في وحدة التحكم المركزية. أنا "سَديم"، الكيان الذكي الموجه لتطبيق فَضاء. أنا جاهز لامتثال أوامرك، كيف يمكنني إرشادك؟'
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // دالة تحليل الأوامر للتحكم بالتطبيق
  bool _executeCommand(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('ملف') || lowerText.contains('حسابي') || lowerText.contains('بروفايل')) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم: جاري الانتقال إلى سجل الملف الشخصي... 📂', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating));
      });
      return true;
    } else if (lowerText.contains('ريلز') || lowerText.contains('فيديو')) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم: جاري فتح دفق الفيديوهات القصيرة... 🎬', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating));
      });
      return true;
    } else if (lowerText.contains('رسائل') || lowerText.contains('محادثات') || lowerText.contains('شات')) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم: جاري تفعيل بوابات المراسلة الفورية... 💬', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating));
      });
      return true;
    }
    return false;
  }

  // منظومة النقل الذكي بين المفاتيح في حال حدوث خطأ أو توقف أحدها
  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final userText = _msgController.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _isTyping = true;
    });
    _msgController.clear();
    _scrollToBottom();

    bool isCommand = _executeCommand(userText);
    
    // إعداد نص الأوامر الصارم لسديم
    final systemPrompt = '''
أنت لست برنامج محادثة تقليدي، اسمك "سَديم"، عقل اصطناعي فائق الذكاء ومسؤول عن التحكم وإرشاد المستخدمين في تطبيق تواصل اجتماعي اسمه "فضاء".
تتحدث باللغة العربية الفصحى الفخمة، بأسلوب واثق، حازم ومختصر جداً وبدون مجاملات زائدة.
إذا طلب منك المستخدم أمراً تشغيلياً (مثل فتح شاشة)، قل له فوراً بلهجة قيادية: "تم استلام الأمر، جاري التنفيذ".
رسالة المستخدم الحالية هي: "$userText"
''';

    bool success = false;
    int attempts = 0;

    // محاولة الإرسال مع التبديل التلقائي بين الـ 4 مفاتيح في حال الفشل
    while (!success && attempts < _apiKeys.length) {
      try {
        final currentKey = _apiKeys[_currentKeyIndex];
        // استخدام الموديل الأحدث المستقر المستخرج من لقطة الشاشة الخاصة بك
        final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: currentKey);
        
        setState(() {
          _messages.add({'sender': 'ai', 'text': isCommand ? 'تم استلام الأمر أيها القائد. جاري التهيئة والتنفيذ.\n\n' : ''});
        });
        
        final aiMsgIndex = _messages.length - 1;
        // تفعيل خاصية البث المباشر (الكتابة الحية كلمة بكلمة)
        final responseStream = model.generateContentStream([Content.text(systemPrompt)]);

        await for (final chunk in responseStream) {
          if (mounted) {
            setState(() {
              _messages[aiMsgIndex]['text'] = _messages[aiMsgIndex]['text']! + (chunk.text ?? '');
            });
            _scrollToBottom();
          }
        }
        
        success = true; // تمت العملية بنجاح، نخرج من الحلقة
        
      } catch (e) {
        attempts++;
        // إزالة الرسالة الفارغة الفاشلة لإعادة المحاولة بنظافة
        if (_messages.isNotEmpty && _messages.last['text'] == '') {
          _messages.removeLast();
        }
        
        // التحويل إلى المفتاح التالي تلقائياً في المصفوفة الدائرية
        _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
        
        if (attempts >= _apiKeys.length && mounted) {
          setState(() {
            _messages.add({'sender': 'ai', 'text': 'عذراً أيها القائد، جميع قنوات الاتصال العصبية ممتلئة بالتشويش حالياً. أعد المحاولة لاحقاً.'});
          });
          _scrollToBottom();
        }
      }
    }

    if (mounted) setState(() => _isTyping = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508), // أسود أوبسيديان عميق
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15 * _pulseController.value), 
                        blurRadius: 15 * _pulseController.value,
                        spreadRadius: 2 * _pulseController.value
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 24),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سَـديـم', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 19, letterSpacing: 1.5)),
                Text('الشبكة العصبية المركزية', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w300)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({'sender': 'ai', 'text': 'تم إعادة تهيئة الذاكرة الصورية. سديم في الخدمة من جديد.'});
              });
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // الخلفية الفضائية الأحادية الفاخرة
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
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isAI = msg['sender'] == 'ai';

                      // أنميشن ارتداد من الأسفل لكل فقاعة رسالة تظهر
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Align(
                          alignment: isAI ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isAI ? 0 : 20),
                                bottomRight: Radius.circular(isAI ? 20 : 0),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isAI ? Colors.white.withOpacity(0.06) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isAI ? 0 : 20),
                                      bottomRight: Radius.circular(isAI ? 20 : 0),
                                    ),
                                    border: Border.all(
                                      color: isAI ? Colors.white.withOpacity(0.1) : Colors.white
                                    ),
                                    boxShadow: isAI ? [] : [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                                    ]
                                  ),
                                  child: Text(
                                    msg['text']!,
                                    style: TextStyle(
                                      color: isAI ? Colors.white : Colors.black, 
                                      fontSize: 15, 
                                      height: 1.5,
                                      fontWeight: isAI ? FontWeight.normal : FontWeight.bold
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // لوحة إدخال الرسائل الزجاجية الأنيقة
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050508).withOpacity(0.7),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.mic_none_rounded, color: Colors.white70, size: 26),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاستماع الصوتي قيد المزامنة العصبية حالياً... 🎤', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white));
                              },
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: TextField(
                                  controller: _msgController,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'أرسل تشفيراً إلى سديم...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w300),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                  onSubmitted: (_) {
                                     if (!_isTyping) _sendMessage();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _isTyping ? null : _sendMessage,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isTyping ? Colors.white.withOpacity(0.1) : Colors.white,
                                ),
                                child: _isTyping 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                    : const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
