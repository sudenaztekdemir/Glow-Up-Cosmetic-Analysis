import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form Doğrulama (Validation) için anahtar
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); //form yönetebilen kontrol

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Form Doğrulamasını Kontrol Etme
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Firebase Authentication ile kayıt
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 3. Kullanıcının Adını Kaydetme (Display Name)
      await userCredential.user!.updateDisplayName(nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı! Giriş ekranına yönlendiriliyorsunuz.")),
      );

      // Başarılı kayıt sonrası Giriş Ekranına geri dön
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = "Bu e-posta adresiyle kayıtlı kullanıcı zaten var.";
      } else if (e.code == 'weak-password') {
        message = "Şifre en az 6 karakter olmalıdır.";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz e-posta formatı.";
      } else {
        print("Firebase Hata Kodu: ${e.code}");
        print("Firebase Detaylı Mesaj: ${e.message}");
        message = "Kayıt sırasında bir hata oluştu. Lütfen konsolu kontrol edin.";
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Yardımcı Alan Oluşturucu ---

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String validatorMessage,//hata mesajı(lütfen mail girin)
    required IconData icon,
    TextInputType keyboardType = TextInputType.text, // klavye nasıl açılsın
    bool obscureText = false,
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(), //yazi tipi
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF0A4A3F)),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return validatorMessage;
        }
        if (isEmail && !val.contains('@')) {
          return 'Geçerli bir E-posta adresi girin.';
        }
        if (isPassword && val.length < 6) {
          return 'Şifre en az 6 karakter olmalıdır.';
        }
        return null;
      },
    );
  }

  // --- Ana Build Metodu ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Üye Ol", style: GoogleFonts.poppins(color: const Color(0xFF0A4A3F))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0A4A3F)),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Yeni Hesap Oluşturun",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Ad Soyad Alanı
                _buildTextFormField(
                  controller: nameController,
                  label: "Ad Soyad",
                  validatorMessage: "Ad Soyad boş bırakılamaz.",
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),

                // E-posta Alanı (Giriş Kimliği)
                _buildTextFormField(
                  controller: emailController,
                  label: "E-posta",
                  keyboardType: TextInputType.emailAddress,
                  validatorMessage: "Geçerli bir E-posta adresi giriniz.",
                  icon: Icons.email,
                  isEmail: true,
                ),
                const SizedBox(height: 20),

                // Şifre Alanı
                _buildTextFormField(
                  controller: passwordController,
                  label: "Şifre (Min 6 karakter)",
                  obscureText: true,
                  validatorMessage: "Şifre en az 6 karakter olmalıdır.",
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 30),

                // Hata Mesajı
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Kayıt Ol Butonu
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4A3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "KAYIT OL",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Giriş ekranına geri dönüş butonu
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Zaten hesabınız var mı? Giriş yapın",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}