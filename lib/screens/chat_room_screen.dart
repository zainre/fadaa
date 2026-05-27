import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'api_keys.dart'; // 👈 استدعاء ملف المفاتيح المركزي

class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  late AnimationController _bgController;
  bool _isGeneratingAI = false;

  // حفظ مؤشر المفتاح الحالي
  int _currentKeyIndex = 0;

  @override
  void initState() {
    super.initState();
    // أنميشن الخلفية الأحادية الفاخرة
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  String get _chatRoomId {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final msg = _msgController.text.trim();
    _msgController.clear();

    if (currentUserId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': msg,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 🪄 دالة سديم لتحسين الرسائل (مربوطة بالمركز)
  Future<void> _smartReplyAI() async {
    setState(() => _isGeneratingAI = true);
    bool success = false;
    int attempts = 0;

    String prompt;
    if (_msgController.text.trim().isEmpty) {
      prompt = 'اكتب رسالة ترحيبية قصيرة ولطيفة جداً باللغة العربية الفصحى لبدء محادثة مع صديق.';
    } else {
      prompt = 'قم بتحسين وصياغة هذه الرسالة لتصبح أكثر لباقة واحترافية باللغة العربية: ${_msgController.text}';
    }

    // 🛡️ القراءة من الملف المركزي
    while (!success && attempts < ApiKeys.geminiKeys.length) {
      try {
        final currentKey = ApiKeys.geminiKeys[_currentKeyIndex];
        final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: currentKey);
        
        final response = await model.generateContent([Content.text(prompt)]);
        
        if (response.text != null && mounted) {
          setState(() {
            _msgController.text = response.text!.replaceAll('"', '');
          });
          success = true;
        }
      } catch (e) {
        attempts++;
        _currentKeyIndex = (_currentKeyIndex + 1) % ApiKeys.geminiKeys.length; // الانتقال للمفتاح التالي
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سديم يواجه تشويشاً حالياً، حاول مرة أخرى.'), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isGeneratingAI = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508), // ثيم الأوبسيديان العميق
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF050508).withOpacity(0.6),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.white24, width: 1.5)
              ),
              child: CircleAvatar(
                radius: 16, 
                backgroundColor: const Color(0xFF101015),
                child: Text(
                  widget.receiverName.substring(0, 1).toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          // الخلفية المتحركة الفاخرة
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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chat_rooms')
                        .doc(_chatRoomId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('الفضاء هادئ هنا... ابدأ المحادثة الآن 🚀', style: TextStyle(color: Colors.white54, fontSize: 15)));
                      }

                      final messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final isMe = messages[index]['senderId'] == currentUserId;
                          
                          // أنميشن خفيف لظهور الرسالة
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child), // تمت إضافة الـ clamp كحماية إضافية للأنميشن
                              );
                            },
                            child: Align(
                              alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 0 : 20),
                                    bottomRight: Radius.circular(isMe ? 20 : 0),
                                  ),
                                  child: BackdropFilter(
                                    filter: isMe ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isMe ? Colors.white : Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: Radius.circular(isMe ? 0 : 20),
                                          bottomRight: Radius.circular(isMe ? 20 : 0),
                                        ),
                                        border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                                        boxShadow: isMe ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                                      ),
                                      child: Text(
                                        messages[index]['text'],
                                        style: TextStyle(
                                          color: isMe ? Colors.black : Colors.white, 
                                          fontSize: 15, 
                                          height: 1.4,
                                          fontWeight: isMe ? FontWeight.w600 : FontWeight.normal
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // منطقة إدخال الرسالة الزجاجية (Obsidian Input)
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050508).withOpacity(0.7),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white54, size: 28),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _msgController,
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        hintText: 'اكتب رسالتك...',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w300),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  // زر سديم لتحسين الرسائل
                                  IconButton(
                                    icon: _isGeneratingAI 
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                                    onPressed: _isGeneratingAI ? null : _smartReplyAI,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
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
