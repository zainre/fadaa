import 'package:flutter/material.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Placeholder for video
              Container(
                color: Colors.accents[index % Colors.accents.length].withOpacity(0.15),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
                ),
              ),
              // Right side actions
              Positioned(
                bottom: 20,
                left: 16, 
                child: Column(
                  children: [
                    IconButton(icon: const Icon(Icons.favorite, color: Colors.white, size: 30), onPressed: () {}),
                    const Text('1.2K', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 30), onPressed: () {}),
                    const Text('300', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 30), onPressed: () {}),
                    const SizedBox(height: 16),
                    IconButton(icon: const Icon(Icons.more_vert, color: Colors.white, size: 30), onPressed: () {}),
                  ],
                ),
              ),
              // Bottom info
              Positioned(
                bottom: 20,
                right: 16,
                left: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                        const SizedBox(width: 8),
                        Text('@مستخدم_$index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            side: const BorderSide(color: Colors.white),
                            minimumSize: const Size(0, 30)
                          ),
                          child: const Text('متابعة', style: TextStyle(color: Colors.white, fontSize: 12)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('وصف مقطع الريلز التجريبي.. #برمجة #تطبيقات #فلاتر', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
