import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form Elemanları
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Firebase ve Durum Değişkenleri
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // --- Dispose: Sayfadan çıkınca hafızayı temizle ---
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- Giriş Yap Fonksiyonu ---
  Future<void> _login() async {
    // 1. Önce form kurallara uyuyor mu bak (Validasyon)
    if (!_formKey.currentState!.validate()) {
      return; // Hata varsa dur, aşağı inme.
    }

    // 2. Yükleniyor moduna geç (Buton dönsün)
    setState(() => _isLoading = true);

    try {
      // 3. Firebase'e sor: Böyle biri var mı?
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 4. Başarılıysa Ana Sayfaya yönlendir ve geçmişi sil
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainWrapper()),
              (Route<dynamic> route) => false, // Geri tuşuna basınca login'e dönmesin
        );
      }
    } on FirebaseAuthException catch (e) {
      // Hata alınırsa yüklemeyi durdur
      setState(() => _isLoading = false);

      // Hatayı Türkçeye çevir
      String message = "Giriş başarısız.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Kullanıcı bulunamadı veya şifre yanlış.";
      } else if (e.code == 'wrong-password') {
        message = "Şifre hatalı.";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz e-posta formatı.";
      } else if (e.code == 'too-many-requests') {
        message = "Çok fazla deneme yaptınız. Biraz bekleyin.";
      }

      // Kullanıcıya mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --- Ekran Tasarımı ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Klavye açılınca ekranı yukarı it
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Ekran küçükse veya klavye açılırsa kaydırma özelliği
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Form(
                key: _formKey, // Form anahtarını buraya taktık
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Başlık
                    const Text(
                      "GLOW UP",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A4A3F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tekrar Hoş Geldiniz",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // --- E-Posta Alanı ---
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "E-posta",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF0A4A3F)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Lütfen e-posta girin';
                        if (!v.contains('@'))
                          return 'Geçerli bir mail adresi girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Şifre Alanı ---
                    TextFormField(
                      controller: passwordController,
                      obscureText: true, // Şifreyi gizle (••••)
                      decoration: const InputDecoration(
                        labelText: "Şifre",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF0A4A3F)),
                      ),

                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        if (v.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- Giriş Yap Butonu ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A4A3F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Yükleniyorsa tıklamayı engelle (null), değilse _login çalıştır
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "GİRİŞ YAP",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Kayıt Ol Linki ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Hesabın yok mu? "),
                        GestureDetector(
                          onTap: () {
                            // Kayıt Ekranına Git
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "Üye Ol",
                            style: TextStyle(
                              color: Color(0xFF0A4A3F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}