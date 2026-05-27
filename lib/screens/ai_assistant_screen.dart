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

  // قائمة المفاتيح الأربعة لتعزيز قوة سَديم
  final List<String> _apiKeys = [
    'AIzaSyCzHgKi4LjOdMkY1ngembMvtfsvmIr9RBE',
    'AIzaSyDK9g15HqwCUY-pXcneTMgpV_35Y7sXQVA',
    'AIzaSyDN6c9X9txXrD7OaIgYrzIY1d_sk_zZmdI',
    'AIzaSyBOrfXgIPJztDb0J1xWMS3DrgrjRFKgopM',
  ];

  // دالة اختيار مفتاح عشوائي لضمان استمرارية الخدمة
  String get _randomApiKey => _apiKeys[math.Random().nextInt(_apiKeys.length)];

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

    try {
      // هنا نستخدم المفتاح العشوائي في كل طلب
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _randomApiKey);
      
      final systemPrompt = '''
أنت "سَديم"، العقل المدبر لتطبيق "فضاء". تتحدث بفصاحة، ثقة، واختصار.
إذا طلب منك المستخدم أمراً تشغيلياً داخل التطبيق، قل: "تم استلام الأمر، جاري التنفيذ".
رسالة المستخدم: "$userText"
''';

      final response = await model.generateContent([Content.text(systemPrompt)]);
      
      if (response.text != null && mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': isCommand ? 'تم الاستلام أيها القائد. جاري تنفيذ الأمر.' : response.text!});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': 'عذراً، أواجه تشويشاً في الاتصال عبر المجرة. حاول مرة أخرى.'});
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // رسالة الترحيب الأولى من المساعد "سَديم"
    _messages.add({
      'sender': 'ai',
      'text': 'أهلاً بك في غرفة التحكم الرئيسية. أنا "سَديم"، العقل المدبر لتطبيق فَضاء. كيف يمكنني إرشادك اليوم؟'
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

  // 🪄 دالة تحليل الأوامر (Command Parser) للتحكم بالتطبيق
  bool _executeCommand(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('ملف') || lowerText.contains('حسابي') || lowerText.contains('بروفايل')) {
      // سيتم تنفيذ الأمر بعد ثانية لتبدو طبيعية
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم: جاري فتح الملف الشخصي... ✨'), backgroundColor: Color(0xFFA259FF)));
           // افتراضياً: يمكن ربطها بـ Navigator للانتقال السريع
           // Navigator.pop(context); // العودة للشاشة الرئيسية
        }
      });
      return true;
    } 
    else if (lowerText.contains('ريلز') || lowerText.contains('فيديو')) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم: جاري تشغيل الريلز... 🎬'), backgroundColor: Color(0xFFA259FF)));
        }
      });
      return true;
    }
    else if (lowerText.contains('رسائل') || lowerText.contains('محادثات') || lowerText.contains('شات')) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم: جاري فتح المراسلات... 💬'), backgroundColor: Color(0xFFA259FF)));
        }
      });
      return true;
    }
    return false;
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final userText = _msgController.text.trim();
    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _isTyping = true;
    });
    _msgController.clear();
    _scrollToBottom();

    // 1. التحقق أولاً إذا كان النص يحتوي على "أمر تشغيل" للتحكم بالتطبيق
    bool isCommand = _executeCommand(userText);

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
      
      // 2. شخصية "سَديم" الصارمة والذكية
      final systemPrompt = '''
أنت لست مجرد برنامج محادثة، اسمك "سَديم" (عقل اصطناعي فائق الذكاء ومسؤول عن التحكم بتطبيق تواصل اجتماعي اسمه "فضاء").
أنت تتحدث بثقة، فصاحة، واختصار. 
إذا طلب منك المستخدم أمراً تشغيلياً (مثل فتح صفحة معينة)، قل له: "تم استلام الأمر، جاري التنفيذ".
رسالة المستخدم الحالية هي: "$userText"
''';

      final response = await model.generateContent([Content.text(systemPrompt)]);
      
      if (response.text != null && mounted) {
        setState(() {
          // إذا كان أمراً تشغيلياً، قد نعدل الرد ليكون أسرع
          _messages.add({'sender': 'ai', 'text': isCommand ? 'تم الاستلام أيها القائد. جاري تنفيذ الأمر.' : response.text!});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': 'عذراً، أواجه تداخلاً في إشارات السديم الفضائي حالياً. حاول مرة أخرى.'});
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
                      BoxShadow(color: const Color(0xFFA259FF).withOpacity(0.5 * _pulseController.value), blurRadius: 15 * _pulseController.value)
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF1A1A2E),
                    child: Icon(Icons.blur_on, color: Color(0xFFA259FF), size: 24),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سَـديـم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18, letterSpacing: 1)),
                Text('متصل بالشبكة العصبية', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [const Color(0xFF2A1B54).withOpacity(0.6), const Color(0xFF0B0B19)],
                    center: Alignment(math.sin(_bgController.value * math.pi), math.cos(_bgController.value * math.pi)),
                    radius: 1.8,
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: CircularProgressIndicator(color: Color(0xFFA259FF)),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      final isAI = msg['sender'] == 'ai';

                      return Align(
                        alignment: isAI ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isAI ? 0 : 20),
                              bottomRight: Radius.circular(isAI ? 20 : 0),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isAI ? const Color(0xFFA259FF).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                  border: Border.all(color: isAI ? const Color(0xFFA259FF).withOpacity(0.3) : Colors.white.withOpacity(0.1)),
                                ),
                                child: Text(
                                  msg['text']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // حقل الإدخال الزجاجي
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: TextField(
                                controller: _msgController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'تحدث إلى سديم...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) {
                                   if(!_isTyping) _sendMessage();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isTyping ? null : _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]),
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
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
