import 'package:flutter/material.dart';

import '../servisler/ders_notu_deposu.dart';
import '../servisler/oturum_servisi.dart';

class DersNotuEkrani extends StatefulWidget {
  final int dersId;
  final String baslik;
  final OturumServisi oturum;
  final DersNotuDeposu depo;

  const DersNotuEkrani({
    super.key,
    required this.dersId,
    required this.baslik,
    required this.oturum,
    this.depo = const DersNotuDeposu(),
  });

  @override
  State<DersNotuEkrani> createState() => _DersNotuEkraniState();
}

class _DersNotuEkraniState extends State<DersNotuEkrani> {
  final _metin = TextEditingController();
  late final _hesap = widget.oturum.kullaniciId;
  late final _sunucu = widget.oturum.api.adres.toString();
  bool _yerImi = false;
  bool _yukleniyor = true;
  bool _okundu = false;
  bool _kaydediyor = false;
  String? _mesaj;
  int _okumaSirasi = 0;
  late bool _girisAcik;

  bool get _hesapEtkin => _hesap != null && widget.oturum.kullaniciId == _hesap;

  @override
  void initState() {
    super.initState();
    _girisAcik = _hesapEtkin;
    widget.oturum.addListener(_oturumDegisti);
    _oku();
  }

  void _oturumDegisti() {
    final girisAcik = _hesapEtkin;
    if (girisAcik == _girisAcik) return;
    _girisAcik = girisAcik;
    _okumaSirasi++;
    _metin.clear();
    setState(() {
      _okundu = false;
      _yerImi = false;
      _mesaj = null;
      _yukleniyor = girisAcik;
    });
    if (girisAcik) _oku();
  }

  Future<void> _oku() async {
    if (!_hesapEtkin) return;
    final sira = ++_okumaSirasi;
    bool gecerli() => mounted && sira == _okumaSirasi && _hesapEtkin;
    try {
      final not = await widget.depo.oku(_sunucu, _hesap!, widget.dersId);
      if (!gecerli()) return;
      _metin.text = not.metin;
      setState(() {
        _yerImi = not.yerImi;
        _okundu = true;
        _mesaj = null;
      });
    } catch (_) {
      if (gecerli()) setState(() => _mesaj = 'Ders notu okunamadı.');
    } finally {
      if (gecerli()) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _kaydet() async {
    if (!_hesapEtkin || _kaydediyor || !_okundu) return;
    final not = DersNotu(metin: _metin.text, yerImi: _yerImi);
    setState(() => _kaydediyor = true);
    try {
      await widget.depo.yaz(_sunucu, _hesap!, widget.dersId, not);
      if (mounted && _hesapEtkin) {
        setState(() => _mesaj = 'Ders notu ve yer imi kaydedildi.');
      }
    } catch (_) {
      if (mounted && _hesapEtkin) {
        setState(
          () => _mesaj = 'Kaydedilemedi. Değişiklikler ekranda duruyor.',
        );
      }
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  void dispose() {
    widget.oturum.removeListener(_oturumDegisti);
    _metin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ders notu')),
    body: !_hesapEtkin
        ? const Center(
            child: Text('Ders notuna erişmek için hesabınla giriş yap.'),
          )
        : _yukleniyor
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.baslik,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              if (_okundu) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    _yerImi ? Icons.bookmark : Icons.bookmark_outline,
                  ),
                  title: const Text('Yer imi'),
                  value: _yerImi,
                  onChanged: _kaydediyor
                      ? null
                      : (deger) => setState(() => _yerImi = deger),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _metin,
                  onChanged: (_) => setState(() {}),
                  enabled: !_kaydediyor,
                  maxLength: 5000,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Kişisel not',
                    alignLabelWithHint: true,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _kaydediyor ? null : _kaydet,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_kaydediyor ? 'Kaydediliyor…' : 'Kaydet'),
                ),
                if (_metin.text.isNotEmpty)
                  TextButton(
                    onPressed: _kaydediyor
                        ? null
                        : () => setState(_metin.clear),
                    child: const Text('Not metnini temizle'),
                  ),
              ] else
                OutlinedButton(
                  onPressed: () {
                    setState(() => _yukleniyor = true);
                    _oku();
                  },
                  child: const Text('Tekrar dene'),
                ),
              if (_mesaj != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(liveRegion: true, child: Text(_mesaj!)),
                ),
            ],
          ),
  );
}
