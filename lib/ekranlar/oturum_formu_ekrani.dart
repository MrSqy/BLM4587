import 'package:flutter/material.dart';

import '../rotalar.dart';
import '../servisler/oturum_servisi.dart';
import '../servisler/api_istemcisi.dart';

// Mobil API ile gerçek giriş/kayıt; parola yalnız istek sırasında kullanılır.
class OturumFormuEkrani extends StatefulWidget {
  final bool kayit;

  const OturumFormuEkrani({super.key, this.kayit = false});

  @override
  State<OturumFormuEkrani> createState() => _OturumFormuEkraniState();
}

class _OturumFormuEkraniState extends State<OturumFormuEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _sifre = TextEditingController();
  final _eposta = TextEditingController();
  final _ad = TextEditingController();
  bool _bekliyor = false;
  String? _hata;
  bool _sifreGorunur = false;
  bool _tekrarGorunur = false;

  @override
  void dispose() {
    _sifre.dispose();
    _eposta.dispose();
    _ad.dispose();
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
    if (widget.kayit &&
        (!RegExp(r'[A-Z]').hasMatch(deger) ||
            !RegExp(r'[a-z]').hasMatch(deger) ||
            !RegExp(r'[0-9]').hasMatch(deger) ||
            !RegExp(r'[^a-zA-Z0-9]').hasMatch(deger))) {
      return 'Büyük/küçük harf, rakam ve özel karakter kullanın.';
    }
    return null;
  }

  Future<void> _gonder() async {
    if (_bekliyor) return;
    FocusScope.of(context).unfocus();
    if (!_formAnahtari.currentState!.validate()) return;
    setState(() {
      _bekliyor = true;
      _hata = null;
    });
    try {
      await oturumServisi.giris(
        _eposta.text,
        _sifre.text,
        adSoyad: widget.kayit ? _ad.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiHatasi catch (e) {
      if (mounted) setState(() => _hata = e.mesaj);
    } catch (_) {
      if (mounted) {
        setState(() => _hata = 'İşlem tamamlanamadı. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _bekliyor = false);
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.kayit ? 'Öğrenmeye başla.' : 'Öğrenmeye devam et.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.kayit
                          ? 'Hesabını oluştur, tüm derslere ve alıştırmalara eriş.'
                          : 'Hesabınla tüm derslere ve kod çalışmalarına eriş.',
                    ),
                    const SizedBox(height: 24),
                    if (widget.kayit) ...[
                      TextFormField(
                        key: const ValueKey('adSoyad'),
                        controller: _ad,
                        enabled: !_bekliyor,
                        decoration: const InputDecoration(
                          labelText: 'Ad soyad',
                        ),
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
                      controller: _eposta,
                      enabled: !_bekliyor,
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
                        helperText: widget.kayit
                            ? 'En az 8 karakter; büyük/küçük harf, rakam ve özel karakter.'
                            : null,
                        helperMaxLines: 3,
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
                            () => setState(
                              () => _tekrarGorunur = !_tekrarGorunur,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _gonder(),
                        validator: (deger) {
                          if (deger == null || deger.isEmpty) {
                            return 'Şifre tekrarı zorunludur.';
                          }
                          if (deger != _sifre.text) {
                            return 'Şifreler eşleşmiyor.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_hata != null) ...[
                      Text(
                        _hata!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      key: const ValueKey('formGonder'),
                      onPressed: _bekliyor ? null : _gonder,
                      child: Text(_bekliyor ? 'Lütfen bekleyin…' : baslik),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _bekliyor
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              widget.kayit ? Rotalar.giris : Rotalar.kayit,
                            ),
                      child: Text(
                        widget.kayit
                            ? 'Hesabın var mı? Giriş yap'
                            : 'Hesabın yok mu? Kayıt ol',
                      ),
                    ),
                    TextButton(
                      onPressed: _bekliyor
                          ? null
                          : () => Navigator.maybePop(context),
                      child: const Text('Misafir olarak devam et'),
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
