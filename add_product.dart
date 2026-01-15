import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();

  // Resim yükleme yerine Link alma kutusu ekledik
  final TextEditingController imageUrlController = TextEditingController();

  bool _isLoading = false;
  final String _adminEmail = "sudenaztekdemir@gmail.com";

  // --- RESİM ÖNİZLEME (Link geçerli mi diye) ---
  Widget _buildImagePreview() {
    if (imageUrlController.text.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 40, color: Colors.grey),
            SizedBox(height: 5),
            Text("Fotoğraf Linki Yapıştırın", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        imageUrlController.text,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            color: Colors.grey.shade200,
            child: const Center(child: Text("Görsel yüklenemedi (Link hatalı)", style: TextStyle(color: Colors.red))),
          );
        },
      ),
    );
  }

  Future<void> _saveProduct() async {
    final name = nameController.text.trim();
    final rawIngredients = ingredientsController.text.trim();
    final imageUrl = imageUrlController.text.trim(); // Linki al
    final user = FirebaseAuth.instance.currentUser;

    if (name.isEmpty || rawIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen isim ve içerik giriniz")));
      return;
    }

    final ingredients = rawIngredients.split(',').map((e) => e.trim()).toList();
    setState(() => _isLoading = true);

    try {
      String docId = name.toLowerCase().replaceAll(' ', '_');

      // Veriyi Hazırla (Storage yok, direkt linki kaydediyoruz)
      Map<String, dynamic> productData = {
        "name": name,
        "ingredients": ingredients,
        "created_at": FieldValue.serverTimestamp(),
      };

      // Eğer link boş değilse ekle
      if (imageUrl.isNotEmpty) {
        productData["image_url"] = imageUrl;
      }

      // 1. VERİTABANINA KAYDET
      if (user != null && user.email == _adminEmail) {
        // ADMIN İŞLEMİ
        await FirebaseFirestore.instance.collection("products").doc(docId).set(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin: Ürün eklendi ✅")));
          Navigator.pop(context);
        }
      } else {
        // KULLANICI İSTEĞİ
        productData["doc_id_suggestion"] = docId;
        productData["requested_by"] = user?.email ?? "Anonim";

        await FirebaseFirestore.instance.collection("product_requests").add(productData);

        if (mounted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                content: const Text(
                  "İsteğiniz Gönderildi!\n\nEditörlerimiz inceledikten sonra yayınlanacaktır.",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(c); Navigator.pop(context);
                      },
                      child: const Text("Tamam")
                  )
                ],
              )
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ürün Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Resim Önizleme Alanı
            _buildImagePreview(),
            const SizedBox(height: 20),

            // Resim Linki Giriş Alanı
            TextField(
              controller: imageUrlController,
              onChanged: (val) => setState(() {}), // Yazdıkça önizlemeyi güncelle
              decoration: const InputDecoration(
                  labelText: "Fotoğraf Linki (URL)",
                  hintText: "https://ornek.com/resim.jpg",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link)
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Ürün Adı", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ingredientsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "İçerikler (Virgülle ayırın)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A4A3F)),
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KAYDET", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}