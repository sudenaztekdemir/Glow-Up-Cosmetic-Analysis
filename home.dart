import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_result.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    // Arama kutusuna yazılanı dinle
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Ürün Listesi"),
          centerTitle: true,
          // *** BİLDİRİM ZİLİ BURAYA EKLENDİ ***
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Bildirim ekranına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const NotificationScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // --- ARAMA ÇUBUĞU ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Ürün ara...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: _searchText.isNotEmpty // yandakş "X" butonu
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchText = '');
                    },
                  )
                      : null,
                ),
              ),
            ),
        // --- ÜRÜN LİSTESİ ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance //firebaseden ürünleri seçtim
                .collection('products')
                .orderBy('name')
                .snapshots(), //guncel veri çekmeyi sağlıyor
            builder: (context, snapshot) {
              // Yükleniyor
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Veri Yok...
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Henüz ürün bulunmamaktadır."));
              }

              // Filtreleme İşlemi (Arama)
              var filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'].toString().toLowerCase();
                return name.contains(_searchText);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(child: Text("'$_searchText' için sonuç bulunamadı."));
              }

              // Listeyi Göster
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'İsimsiz Ürün';
                  final ingredients = (data['ingredients'] as List<dynamic>?) ?? [];

                  // Resim URL kontrolü (Hata almamak için güvenli çekiyoruz)
                  String? imageUrl;
                  if (data.containsKey('image_url')) {
                    imageUrl = data['image_url'];
                  }

                  return ListTile(
                    // SOL TARAFTA FOTOĞRAF (Varsa Foto, Yoksa İkon)
                    leading: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect( //clip rounded rectangle (yuvarlatılmış dikdörtgen kesimi)
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        // Resim yüklenemezse kırık resim ikonu göster
                        errorBuilder: (c, o, s) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),//c(context)= uygulamanın o anki konumu
                        //o(object)= hatanın ne olduğu
                        //s(stackTrace)= hatanın teknik deta izi
                    )
                        : const Icon(Icons.shopping_bag, color: Color(0xFF0A4A3F), size: 30),

                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${ingredients.length} bileşen', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    //alt başlık

                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

                    // TIKLAYINCA DETAY SAYFASINA GİT
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductResultScreen(
                              productName: name,
                              imageUrl: imageUrl
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],),
    );
  }
}