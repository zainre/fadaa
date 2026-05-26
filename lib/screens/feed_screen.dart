import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Stories Horizontal List
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 15,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.primaries[index % Colors.primaries.length],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('مستخدم ${index + 1}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Posts Vertical List
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.primaries[(index + 3) % Colors.primaries.length],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('مستخدم ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('منذ ساعتين', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.more_vert),
                      ),
                      Container(
                        height: 350,
                        width: double.infinity,
                        color: Colors.grey[850],
                        child: const Center(
                          child: Icon(Icons.image, size: 60, color: Colors.white54),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.send), onPressed: () {}),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('${(index + 1) * 14} إعجاب', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                            'هذا نص تجريبي لوصف المنشور الخاص بالمستخدم. تصميم مشابه لإنستغرام.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
