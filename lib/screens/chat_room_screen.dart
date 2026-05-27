import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';
import 'dart:math' as math;

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

  // مفتاح Gemini الخاص بك
  final String _apiKey = 'AIzaSyDN6c9X9txXrD7OaIgYrzIY1d_sk_zZmdI';

  @override
  void initState() {
    super.initState();
    // أنميشن الخلفية الفضائية
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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

  // 🪄 دالة الذكاء الاصطناعي لتحسين الرسائل أو اقتراح رد
  Future<void> _smartReplyAI() async {
    setState(() => _isGeneratingAI = true);
    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
      String prompt;
      
      if (_msgController.text.trim().isEmpty) {
        prompt = 'اكتب رسالة ترحيبية قصيرة ولطيفة جداً باللغة العربية الفصحى لبدء محادثة مع صديق.';
      } else {
        prompt = 'قم بتحسين وصياغة هذه الرسالة لتصبح أكثر لباقة واحترافية باللغة العربية: ${_msgController.text}';
      }
      
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null && mounted) {
        setState(() {
          _msgController.text = response.text!.replaceAll('"', ''); // إزالة علامات التنصيص إن وُجدت
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الذكاء الاصطناعي: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA259FF), width: 1.5)),
              child: CircleAvatar(
                radius: 18, 
                backgroundColor: Colors.blueAccent.withOpacity(0.6),
                child: Text(widget.receiverName.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          // الخلفية المتحركة
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [const Color(0xFF2A1B54).withOpacity(0.4), const Color(0xFF0B0B19)],
                    center: Alignment(math.sin(_bgController.value * math.pi), math.cos(_bgController.value * math.pi)),
                    radius: 1.5,
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
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFA259FF)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('الفضاء هادئ هنا... ابدأ المحادثة الآن 🚀', style: TextStyle(color: Colors.white54, fontSize: 16)));
                      }

                      final messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final isMe = messages[index]['senderId'] == currentUserId;
                          return Align(
                            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                gradient: isMe ? const LinearGradient(colors: [Color(0xFF0095F6), Color(0xFFA259FF)]) : null,
                                color: isMe ? null : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 0 : 20),
                                  bottomRight: Radius.circular(isMe ? 20 : 0),
                                ),
                                border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 0 : 20),
                                  bottomRight: Radius.circular(isMe ? 20 : 0),
                                ),
                                child: BackdropFilter(
                                  filter: isMe ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Text(
                                      messages[index]['text'],
                                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
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
                
                // منطقة كتابة الرسالة الزجاجية
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
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 28),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _msgController,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        hintText: 'اكتب رسالتك في الفضاء...',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  // زر الذكاء الاصطناعي السحري للرسائل
                                  IconButton(
                                    icon: _isGeneratingAI 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFA259FF), strokeWidth: 2))
                                      : const Icon(Icons.auto_awesome, color: Color(0xFFA259FF)),
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
