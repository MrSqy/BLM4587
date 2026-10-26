import 'package:flutter/material.dart';

import '../rotalar.dart';

// 2. hafta: yalnızca form doğrulama. API ve gerçek oturum 3. haftada eklenecek.
class OturumFormuEkrani extends StatefulWidget {
  final bool kayit;

  const OturumFormuEkrani({super.key, this.kayit = false});

  @override
  State<OturumFormuEkrani> createState() => _OturumFormuEkraniState();
}

class _OturumFormuEkraniState extends State<OturumFormuEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _sifre = TextEditingController();
  bool _sifreGorunur = false;
  bool _tekrarGorunur = false;

  @override
  void dispose() {
    _sifre.dispose();
    super.dispose();
  }

  String? _epostaDogrula(String? deger) {
    final eposta = deger?.trim() ?? '';
    if (eposta.isEmpty) return 'E-posta zorunludur.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(eposta)) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    return null;
  }

  String? _sifreDogrula(String? deger) {
    if (deger == null || deger.trim().isEmpty) return 'Şifre zorunludur.';
    if (deger.length < 8) return 'Şifre en az 8 karakter olmalıdır.';
    return null;
  }

  void _gonder() {
    FocusScope.of(context).unfocus();
    if (!_formAnahtari.currentState!.validate()) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo form doğrulandı'),
        content: Text(
          widget.kayit
              ? 'Bilgiler biçim olarak uygun. Bu bir demodur; hesap oluşturulmadı ve bilgiler kaydedilmedi.'
              : 'Bilgiler biçim olarak uygun. Bu bir demodur; kimlik doğrulanmadı ve oturum açılmadı.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _gorunurlukDugmesi(bool gorunur, VoidCallback degistir) {
    return IconButton(
      tooltip: gorunur ? 'Şifreyi gizle' : 'Şifreyi göster',
      onPressed: degistir,
      icon: Icon(gorunur ? Icons.visibility_off : Icons.visibility),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baslik = widget.kayit ? 'Kayıt ol' : 'Giriş yap';
    return Scaffold(
      appBar: AppBar(title: Text(baslik)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formAnahtari,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Demo: Bu formlar yalnızca alanları kontrol eder. Hesap oluşturulmaz, oturum açılmaz ve bilgiler kaydedilmez.',
                  ),
                  const SizedBox(height: 24),
                  if (widget.kayit) ...[
                    TextFormField(
                      key: const ValueKey('adSoyad'),
                      decoration: const InputDecoration(labelText: 'Ad soyad'),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (deger) =>
                          deger == null || deger.trim().isEmpty
                          ? 'Ad soyad zorunludur.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const ValueKey('eposta'),
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    validator: _epostaDogrula,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('sifre'),
                    controller: _sifre,
                    obscureText: !_sifreGorunur,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      helperText: 'En az 8 karakter',
                      suffixIcon: _gorunurlukDugmesi(
                        _sifreGorunur,
                        () => setState(() => _sifreGorunur = !_sifreGorunur),
                      ),
                    ),
                    textInputAction: widget.kayit
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: widget.kayit ? null : (_) => _gonder(),
                    validator: _sifreDogrula,
                  ),
                  if (widget.kayit) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('sifreTekrari'),
                      obscureText: !_tekrarGorunur,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Şifre tekrarı',
                        suffixIcon: _gorunurlukDugmesi(
                          _tekrarGorunur,
                          () =>
                              setState(() => _tekrarGorunur = !_tekrarGorunur),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _gonder(),
                      validator: (deger) {
                        if (deger == null || deger.isEmpty) {
                          return 'Şifre tekrarı zorunludur.';
                        }
                        if (deger != _sifre.text) return 'Şifreler eşleşmiyor.';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('formGonder'),
                    onPressed: _gonder,
                    child: Text(baslik),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      widget.kayit ? Rotalar.giris : Rotalar.kayit,
                    ),
                    child: Text(
                      widget.kayit
                          ? 'Hesabın var mı? Giriş yap'
                          : 'Hesabın yok mu? Kayıt ol',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
