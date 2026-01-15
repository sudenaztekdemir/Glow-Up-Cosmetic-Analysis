import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Giriş yapmalısınız")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Filtreleme ve Sıralama aynı anda kullanıldığı için indeks gerekir
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_email', isEqualTo: user.email)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. HATA VARSA GÖSTER (Sürekli dönmesinin sebebi bu olabilir)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Bir hata oluştu:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // 2. Yükleniyorsa göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          // 3. Veri yoksa
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Henüz bildiriminiz yok", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. Veri varsa listele
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),//listein o anki konumu ve indexi alıyor
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              bool isSuccess = data['is_success'] ?? true;

              return Card(
                elevation: 2,
                //kçşeleri yuvarlat
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      isSuccess ? Icons.check : Icons.close,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(data['title'] ?? 'Bildirim', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['message'] ?? 'Mesaj içeriği bulunamadı.'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () {
                      docs[index].reference.delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}