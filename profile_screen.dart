import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';//kayıt adını al yoksa boşluk koy
  }

  // --- 1. ÇIKIŞ YAP ---
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  // --- 2. ŞİFRE DEĞİŞTİR (DİREKT UYGULAMA İÇİNDEN) ---
  void _showChangePasswordDialog() {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Şifre Değiştir"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Güvenlik gereği mevcut şifrenizi girmeniz gerekmektedir.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),

                      // MEVCUT ŞİFRE
                      TextFormField(
                        controller: currentPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mevcut Şifre",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (val) => val!.isEmpty ? "Mevcut şifre gerekli" : null,
                      ),
                      const SizedBox(height: 10),

                      // YENİ ŞİFRE
                      TextFormField(
                        controller: newPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Yeni Şifre",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        validator: (val) => val!.length < 6 ? "En az 6 karakter olmalı" : null,
                      ),
                      const SizedBox(height: 10),

                      // YENİ ŞİFRE TEKRAR
                      TextFormField(
                        controller: confirmPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Yeni Şifre (Tekrar)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        validator: (val) {
                          if (val != newPassController.text) return "Şifreler eşleşmiyor";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A4A3F)),
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      try {
                        // 1. Önce kullanıcıyı yeniden doğrula (Re-Authenticate)
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user!.email!,
                          password: currentPassController.text.trim(),
                        );

                        await user!.reauthenticateWithCredential(credential);

                        // 2. Şifreyi güncelle
                        await user!.updatePassword(newPassController.text.trim());

                        if (mounted) {
                          Navigator.pop(context); // Diyalog kapat
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Şifreniz başarıyla değiştirildi! ")),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String err = "Hata oluştu";
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          err = "Mevcut şifrenizi yanlış girdiniz.";
                        } else if (e.code == 'weak-password') {
                          err = "Yeni şifre çok zayıf.";
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err), backgroundColor: Colors.red),
                        );
                      } finally {
                        if (mounted) setState(() => isLoading = false);
                      }
                    }
                  },
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Değiştir", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. HESAP SİL ---
  Future<void> _deleteAccount() async {
    bool confirm = await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Hesabı Sil", style: TextStyle(color: Colors.red)),
          content: const Text("Hesabın kalıcı olarak silinecek. Emin misin?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("İptal")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("SİL", style: TextStyle(color: Colors.red))),
          ],
        )
    ) ?? false;

    if (confirm) {
      try {
        await user?.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hesap silindi.")));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Güvenlik gereği: Lütfen ÇIKIŞ yapıp TEKRAR GİRİN ve sonra silmeyi deneyin.")),
        );
      }
    }
  }

  // --- 4. İSİM GÜNCELLE ---
  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) return;
    try {
      await user?.updateDisplayName(_nameController.text.trim());
      await user?.reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İsim güncellendi ")));
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Giriş yapılmamış"));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.account_circle, size: 100, color: Color(0xFF0A4A3F)),
          const SizedBox(height: 10),
          Text(user?.email ?? "", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

          // İsim Güncelleme Alanı
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Görünen İsim",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save, color: Color(0xFF0A4A3F)),
                onPressed: _updateName,
              ),
            ),
          ),

          const SizedBox(height: 40),
          const Divider(),

          // İşlem Butonları
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.orange),
            title: const Text("Şifre Değiştir"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.blueGrey),
            title: const Text("Çıkış Yap"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _signOut,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Hesabımı Sil", style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}