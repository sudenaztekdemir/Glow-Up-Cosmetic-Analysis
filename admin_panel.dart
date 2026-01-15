import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A4A3F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0A4A3F),
          tabs: const [
            Tab(icon: Icon(Icons.science), text: "İçerikler"),
            Tab(icon: Icon(Icons.shopping_bag), text: "Ürünler"),
            Tab(icon: Icon(Icons.notification_important), text: "İstekler"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IngredientsTab(),
          ProductsTab(),
          RequestsTab(),
        ],
      ),
    );
  }
}

// ===============================================================
// 1. SEKME: İÇERİK YÖNETİMİ
// ===============================================================
class IngredientsTab extends StatefulWidget {
  const IngredientsTab({super.key});

  @override
  State<IngredientsTab> createState() => _IngredientsTabState();
}

class _IngredientsTabState extends State<IngredientsTab> {
  String _search = "";

  void _addOrUpdateIngredient({String? id, String? currentLevel}) {
    TextEditingController nameCtrl = TextEditingController(text: id ?? "");
    String selectedLevel = currentLevel ?? "healthy";

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(id == null ? "Yeni Madde Ekle" : "Maddeyi Düzenle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (id == null)
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Madde Adı (Örn: aqua)"),
                  )
                else
                  Text("Düzenlenen: $id", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButton<String>( //açılır menü
                  value: selectedLevel,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "healthy", child: Text(" Healthy (Temiz)")),
                    DropdownMenuItem(value: "medium", child: Text(" Medium (Orta)")),
                    DropdownMenuItem(value: "harmful", child: Text(" Harmful (Zararlı)")),
                  ],
                  onChanged: (val) => setDialogState(
                          () => selectedLevel = val!),//null olamaz
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
              ElevatedButton(
                onPressed: () async {
                  String docId = id ?? nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
                  if (docId.isEmpty) return;
                  await FirebaseFirestore.instance.collection('ingredients').doc(docId).set({'safetyLevel': selectedLevel});
                  if (mounted) Navigator.pop(c);
                },
                child: const Text("Kaydet"),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "btn1",
        onPressed: () => _addOrUpdateIngredient(),
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Arama Çubuğu (TextField)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Madde ara...", border: OutlineInputBorder()),
              // Metin değiştiğinde çalışan fonksiyon
              onChanged: (v) => setState(
                      () => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
          //Firebase'den anlık veri akışı
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((d) => d.id.contains(_search)).toList();

                return ListView.builder(
                  // Filtrelenmiş belge sayısı kadar satır çizer
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // Belgenin verisini bir Map'e dönüştürür
                    var data = docs[index].data() as Map<String, dynamic>;
                    // Güvenlik seviyesini okur, yoksa 'unknown' atar
                    String level = data['safetyLevel'] ?? 'unknown';
                    Color color = level == 'healthy' ? Colors.green : level == 'medium' ? Colors.orange : Colors.red;

                    // Tek bir liste öğesi (satır) oluşturur
                    return ListTile(
                      title: Text(docs[index].id, style: const TextStyle(fontWeight: FontWeight.bold)),
                      // leading: Başlık önünde risk seviyesini temsil eden renkli daire
                      leading: CircleAvatar(backgroundColor: color, radius: 10),
                      // trailing: Sağda duran düzenleme butonu.
                      trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addOrUpdateIngredient(id: docs[index].id, currentLevel: level)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 2. SEKME: ÜRÜN YÖNETİMİ
// ===============================================================
class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  String _search = "";

  Future<void> _deleteProduct(String id) async {
    bool confirm = await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Ürünü Sil"),
          content: const Text("Bu işlem geri alınamaz."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("İptal")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
          ],
        )
    ) ?? false;//bir yere asmadan çıkarsa işlem iptal edildi

    if (confirm) { //sil
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
    }
  }

  // --- ÜRÜN EKLE/DÜZENLE ---
  void _addOrUpdateProduct({DocumentSnapshot? doc}) {
    TextEditingController nameCtrl = TextEditingController(text: doc != null ? doc['name'] : "");
    List<dynamic> currentIngredients = doc != null ? (doc['ingredients'] ?? []) : [];
    TextEditingController ingCtrl = TextEditingController(text: currentIngredients.join(', '));

    // --- GÜVENLİ FOTOĞRAF ÇEKME KODU (HATA BURADAYDI, DÜZELTİLDİ) ---
    String currentUrl = "";
    if (doc != null) {
      // Önce veriyi güvenli bir Map'e çeviriyoruz
      var data = doc.data() as Map<String, dynamic>;
      // Sonra "image_url" alanı var mı diye kontrol ediyoruz
      if (data.containsKey('image_url')) {
        currentUrl = data['image_url'] ?? "";
      }
    }
    TextEditingController imgCtrl = TextEditingController(text: currentUrl);
    // ----------------------------------------------------------------

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(doc == null ? "Yeni Ürün Ekle" : "Ürünü Düzenle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: imgCtrl,
                decoration: const InputDecoration(
                    labelText: "Fotoğraf Linki (URL)",
                    prefixIcon: Icon(Icons.link),
                    hintText: "https://..."
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Ürün Adı")),
              const SizedBox(height: 10),
              TextField(
                  controller: ingCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: "İçerikler (Virgülle ayır)", border: OutlineInputBorder())
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              List<String> newIngredients = ingCtrl.text.split(',').map((e) => e.trim()).toList();
              String? imageUrl = imgCtrl.text.trim().isNotEmpty ? imgCtrl.text.trim() : null;

              if (doc == null) {
                String docId = nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
                if (docId.isEmpty) return;
                await FirebaseFirestore.instance.collection('products').doc(docId).set({
                  'name': nameCtrl.text.trim(),
                  'ingredients': newIngredients,
                  'image_url': imageUrl,
                  'created_at': FieldValue.serverTimestamp(),
                });
              } else {
                await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
                  'name': nameCtrl.text.trim(),
                  'ingredients': newIngredients,
                  'image_url': imageUrl,
                });
              }
              if (mounted) Navigator.pop(c);
            },
            child: Text(doc == null ? "Ekle" : "Güncelle"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "btn2",
        onPressed: () => _addOrUpdateProduct(),
        backgroundColor: const Color(0xFF0A4A3F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Ürün ara...", border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((d) {
                  var data = d.data() as Map<String, dynamic>;
                  return data['name'].toString().toLowerCase().contains(_search);
                }).toList();

                if (docs.isEmpty) return const Center(child: Text("Ürün bulunamadı"));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    // Burada da güvenli kontrol yapalım
                    String? imgUrl;
                    if (data.containsKey('image_url')) {
                      imgUrl = data['image_url'];
                    }

                    return ListTile(
                      leading: imgUrl != null
                          ? ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(imgUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.error))
                      )
                          : const Icon(Icons.shopping_bag, color: Color(0xFF0A4A3F)),

                      title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${(data['ingredients'] as List).length} bileşen"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addOrUpdateProduct(doc: docs[index])),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(docs[index].id)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 3. SEKME: İSTEK KUTUSU
// ===============================================================
class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {

  Future<void> _sendNotification(String email, String title, String message, bool isSuccess) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'user_email': email,
      'title': title,
      'message': message,
      'is_success': isSuccess,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),//kaydın ne zaman düzenlendiği
    });
  }

  Future<void> _approveRequest(DocumentSnapshot doc) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Güvenli veri çekimi
      String? imgUrl;
      if (data.containsKey('image_url')) {
        imgUrl = data['image_url'];
      }

      await FirebaseFirestore.instance.collection('products').doc(data['doc_id_suggestion']).set({
        'name': data['name'],
        'ingredients': data['ingredients'],
        'image_url': imgUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      await _sendNotification(
          data['requested_by'],
          "İsteğiniz Onaylandı! ",
          "${data['name']} adlı ürün isteğiniz onaylandı ve listeye eklendi.",
          true
      );

      await doc.reference.delete();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Onaylandı ve Bildirim Gitti! ")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  Future<void> _rejectRequest(DocumentSnapshot doc) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      await _sendNotification(
          data['requested_by'],
          "İsteğiniz Reddedildi ",
          "${data['name']} adlı ürün isteğiniz uygun bulunmadığı için reddedildi.",
          false
      );
      await doc.reference.delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reddedildi ve Bildirim Gitti ")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('product_requests').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox, size: 60, color: Colors.grey), SizedBox(height: 10), Text("Bekleyen istek yok", style: TextStyle(color: Colors.grey))]));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;

            // Güvenli Resim Kontrolü
            String? imgUrl;
            if (data.containsKey('image_url')) {
              imgUrl = data['image_url'];
            }

            return Card(
              margin: const EdgeInsets.all(8),
              elevation: 2,
              child: ListTile(
                leading: imgUrl != null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(imgUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.broken_image))
                )
                    : const Icon(Icons.inbox, color: Colors.grey),

                title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ekleyen: ${data['requested_by']}", style: const TextStyle(fontSize: 12)),
                    Text("İçerik Sayısı: ${(data['ingredients'] as List).length}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _rejectRequest(docs[index]), tooltip: "Reddet"),
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _approveRequest(docs[index]), tooltip: "Onayla"),
                  ],
                ),
                onTap: () {
                  showDialog(context: context, builder: (c) => AlertDialog(
                    title: Column(
                      children: [
                        if(imgUrl != null) Image.network(imgUrl, height: 100, fit: BoxFit.cover),
                        const SizedBox(height: 5),
                        Text(data['name']),
                      ],
                    ),
                    content: SingleChildScrollView(child: Text("İçerikler:\n\n${(data['ingredients'] as List).join(', ')}")),
                    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Kapat"))],
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }
}