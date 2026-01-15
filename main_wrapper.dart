import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'profile_screen.dart';
import 'add_product.dart';
import 'seeder.dart';
import 'admin_panel.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  Key _homeScreenKey = UniqueKey();

  // Admin E-postası
  final String _adminEmail = "sudenaztekdemir@gmail.com";

  // Veritabanı Yenileme Fonksiyonu
  void _forceUpdateDB() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veritabanı güncelleniyor...")));
    await DataSeeder.yukle();
    setState(() { _homeScreenKey = UniqueKey(); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güncelleme Tamamlandı! ")));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> pages = [
      HomeScreen(key: _homeScreenKey),
      const ProfileScreen(),
    ];

    final List<String> titles = ["GLOW UP", "Hesap Ayarları"];

    return Scaffold(
      // Klavye açılınca tasarımın bozulmasını engeller
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          titles[_currentIndex],
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _currentIndex == 0 ? const Color(0xFF0A4A3F) : Colors.black
          ),
        ),

        // SOL ÜST: Admin Paneli Butonu (Sadece Ana Sayfada ve Admin ise görünür)
        leading: _currentIndex == 0 && user != null && user.email == _adminEmail
            ? IconButton(
          icon: const Icon(Icons.admin_panel_settings, color: Colors.red, size: 28),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
            // Admin panelden dönünce listeyi yenile
            setState(() { _homeScreenKey = UniqueKey(); });
          },
        )
            : null,

        // SAĞ ÜST: Veritabanı Yenileme (Sadece Ana Sayfada)
        actions: _currentIndex == 0 ? [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _forceUpdateDB,
            tooltip: "Veritabanını Onar",
          )
        ] : null,
      ),

      body: pages[_currentIndex],

      // ORTA BUTON (EKLE)
      floatingActionButton: SizedBox(
        height: 56, // Standart boyut (Taşmayı önler)
        width: 56,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0A4A3F),
          shape: const CircleBorder(),
          elevation: 4,
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
            // Ürün ekleyip dönünce listeyi yenile
            setState(() { _homeScreenKey = UniqueKey(); });
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 24, color: Colors.white),
              Text("EKLE", style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ALT MENÜ
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white,
        elevation: 10,
        // Yüksekliği sabitledik (Taşma hatasını çözen kısım burası)
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(icon: Icons.home_rounded, label: "Ana Sayfa", index: 0),
              const SizedBox(width: 40), // Orta boşluk
              _buildTabItem(icon: Icons.person_rounded, label: "Profil", index: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: _currentIndex == index ? const Color(0xFF0A4A3F) : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _currentIndex == index ? const Color(0xFF0A4A3F) : Colors.grey,
            ),
          )
        ],
      ),
    );
  }
}