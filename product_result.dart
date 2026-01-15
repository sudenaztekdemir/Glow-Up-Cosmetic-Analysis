import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductResultScreen extends StatefulWidget {
  final String productName;
  final String? imageUrl;

  const ProductResultScreen({
    super.key,
    required this.productName,
    this.imageUrl
  });

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  Map<String, dynamic>? _productData;
  Map<String, String> _ingredientLevels = {};
  bool _isLoading = true;
  double _safetyPercentage = 0;
  String _riskLabel = "Hesaplanıyor...";
  Color _riskColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _analyzeProduct();
  }

  Future<void> _analyzeProduct() async {
    try {
      // 1. Ürünü bul
      final productQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: widget.productName)
          .limit(1)
          .get();

      if (productQuery.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      var productDoc = productQuery.docs.first.data();
      List<dynamic> ingredients = productDoc['ingredients'] ?? [];

      // 2. İçeriklerin seviyelerini çek
      final ingredientsSnapshot = await FirebaseFirestore.instance.collection('ingredients').get();
      final levels = {
        for (var doc in ingredientsSnapshot.docs)
          doc.id: doc.data()['safetyLevel'] as String
      };

      // 3. ANALİZ MANTIĞI
      int harmfulCount = 0;
      int mediumCount = 0;
      int healthyCount = 0;
      int knownTotal = 0;

      for (var ing in ingredients) {
        String originalName = ing.toString();

        // --- AKILLI TEMİZLEYİCİ YAMASI  ---
        // 1. Tüm harfleri küçült
        // 2. Alt satırları (\n) boşluğa çevir
        // 3. Çift boşlukları tek boşluğa indir
        // 4. Kenar boşluklarını sil (trim)
        // 5. Aradaki boşluk ve slashleri alt çizgi yap (veritabanı formatı)

        String searchKey = originalName.toLowerCase()
            .replaceAll('\n', ' ')       // Alt satırları sil
            .replaceAll(RegExp(r'\s+'), ' ') // Çift boşlukları teke indir
            .trim()
            .replaceAll(' ', '_')
            .replaceAll('/', '_');

        String level = levels[searchKey] ?? 'unknown';

        if (level == 'harmful') {
          harmfulCount++;
          knownTotal++;
        } else if (level == 'medium') {
          mediumCount++;
          knownTotal++;
        } else if (level == 'healthy') {
          healthyCount++;
          knownTotal++;
        }
      }

      double score = 0;
      if (knownTotal > 0) {
        double totalPoints = (harmfulCount * 10.0) + (healthyCount * 100.0) + (mediumCount * 60.0);
        score = totalPoints / knownTotal;
      }

      String label;
      Color color;

      if (knownTotal == 0) {
        label = "ANALİZ EDİLEMEDİ ";
        color = Colors.grey;
      } else if (score >= 60) {
        label = "TEMİZ İÇERİK ";
        color = Colors.green;
      } else if (score >= 40) {
        label = "ORTA RİSKLİ ";
        color = Colors.orange;
      } else {
        label = "YÜKSEK RİSKLİ ";
        color = Colors.red;
      }

      setState(() {
        _productData = productDoc;
        _ingredientLevels = levels;
        _safetyPercentage = score;
        _riskLabel = label;
        _riskColor = color;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _riskLabel = "Hata";
      });
    }
  }

  Color _getLevelColor(String level) {
    if (level == 'harmful')
      return Colors.red;
    if (level == 'medium')
      return Colors.orange;
    if (level == 'healthy')
      return Colors.green;
    return Colors.grey;
  }

  String _translateLevel(String level) {
    if (level == 'harmful')
      return "Zararlı";
    if (level == 'medium')
      return "Orta";
    if (level == 'healthy')
      return "Yararlı";
    return "Tanımsız";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator()));
    if (_productData == null)
      return const Scaffold(
          body: Center(
              child: Text("Ürün verisi bulunamadı.")));

    List<dynamic> ingredients = _productData!['ingredients'];

    return Scaffold(
      appBar: AppBar(title: const Text("Analiz Sonucu"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(15)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    widget.imageUrl!,
                    height: 180,
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (c,o,s) => const SizedBox(),
                  ),
                ),
              ),

            Text(
              widget.productName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120, height: 120,
                  child: CircularProgressIndicator(
                    value: _safetyPercentage / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                  ),
                ),
                Text(
                  _riskLabel.contains("?") ? "?" : "%${_safetyPercentage.toInt()}",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _riskColor),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.1), //sulandırma
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _riskColor)
              ),
              child: Text(_riskLabel, style: TextStyle(color: _riskColor, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text("İçerik Analizi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(),

            ListView.builder(
              shrinkWrap: true,
              // Bu liste kendi başına kaymasın, tüm sayfa ile birlikte kaysın
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                String name = ingredients[index].toString();

                String searchKey = name.toLowerCase()
                    .replaceAll('\n', ' ')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim()
                    .replaceAll(' ', '_')
                    .replaceAll('/', '_');

                String level = _ingredientLevels[searchKey] ?? 'unknown';
                Color color = _getLevelColor(level);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 3)]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 15))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5)
                        ),
                        child: Text(
                            _translateLevel(level),
                            style: TextStyle(
                                color: level == 'unknown' ? Colors.black54 : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      )
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}