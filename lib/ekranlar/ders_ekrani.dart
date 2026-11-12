import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../modeller/egitim.dart';
import '../modeller/gorev.dart';
import '../modeller/gorev_sonucu.dart';
import '../rotalar.dart';
import '../servisler/api_istemcisi.dart';
import '../servisler/egitim_servisi.dart';
import '../servisler/oturum_servisi.dart';

class DersEkrani extends StatefulWidget {
  final Egitim ozet;
  final EgitimServisi? servis;
  final ApiIstemcisi? api;
  const DersEkrani({super.key, required this.ozet, this.servis, this.api});
  @override
  State<DersEkrani> createState() => _DersEkraniState();
}

class _DersEkraniState extends State<DersEkrani> {
  final _kod = TextEditingController();
  late final _oturum = oturumServisi;
  // Yalnız bu açık ders oturumu boyunca; sunucu görev numarası değil gerçek ID.
  final _taslaklar = <String?, Map<(int, int), String>>{};
  String? _taslakSahibi;
  int? _seciliGorevId;
  Map<(int, int), String> get _etkinTaslaklar =>
      _taslaklar.putIfAbsent(_taslakSahibi, () => {});
  Egitim? _ders;
  Gorev? _gorev;
  GorevSonucu? _sonuc;
  String? _hata;
  bool _yukleniyor = true,
      _calisiyor = false,
      _girisGerekli = false,
      _testSonucu = false;
  int _istek = 0;
  @override
  void initState() {
    super.initState();
    _taslakSahibi = _oturum.kullaniciId;
    _oturum.addListener(_oturumDegisti);
    _yukle();
  }

  void _oturumDegisti() {
    final yeniSahip = _oturum.kullaniciId;
    if (yeniSahip != null && yeniSahip != _taslakSahibi) {
      _taslagiSakla();
      if (_taslakSahibi == null) {
        _taslaklar[yeniSahip] = _taslaklar.remove(null) ?? {};
      }
      _taslakSahibi = yeniSahip;
      _gorev = null;
    }
    _yukle();
  }

  void _taslagiSakla() {
    if (_ders != null && _gorev != null) {
      _etkinTaslaklar[(_ders!.id, _gorev!.id)] = _kod.text;
    }
  }

  void _sec(Gorev g) {
    _taslagiSakla();
    _gorev = g;
    _seciliGorevId = g.id;
    _kod.text = _etkinTaslaklar[(_ders!.id, g.id)] ?? g.baslangicKodu;
    _sonuc = null;
    _hata = null;
  }

  Future<void> _yukle() async {
    final istek = ++_istek;
    final onceki = _seciliGorevId;
    _taslagiSakla();
    setState(() {
      _ders = null;
      _gorev = null;
      _sonuc = null;
      _yukleniyor = true;
      _calisiyor = false;
      _hata = null;
      _girisGerekli = false;
    });
    try {
      final ders = await (widget.servis ?? egitimServisi).egitimGetir(
        widget.ozet.id,
      );
      if (!mounted || istek != _istek) return;
      setState(() {
        _ders = ders?.erisilebilir == true ? ders : null;
        _girisGerekli = ders != null && !ders.erisilebilir;
        if (ders == null) {
          _hata = 'Ders bulunamadı.';
        }
        if (_ders != null && _ders!.gorevler.isNotEmpty) {
          _sec(
            _ders!.gorevler.firstWhere(
              (g) => g.id == onceki,
              orElse: () => _ders!.gorevler.first,
            ),
          );
        }
      });
    } on ApiHatasi catch (e) {
      if (mounted && istek == _istek) {
        setState(() {
          _hata = e.mesaj;
          _girisGerekli = e.durum == 401;
        });
      }
    } catch (_) {
      if (mounted && istek == _istek) {
        setState(() => _hata = 'Ders yüklenemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted && istek == _istek) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  Future<void> _calistir(bool test) async {
    final g = _gorev;
    if (_calisiyor || g == null || !g.kodGorevi) return;
    if (_kod.text.trim().isEmpty || _kod.text.length > 32000) {
      setState(
        () => _hata = _kod.text.trim().isEmpty
            ? 'Çalıştırılacak kodu yazın.'
            : 'Kod en fazla 32000 karakter olabilir.',
      );
      return;
    }
    final istek = _istek;
    FocusScope.of(context).unfocus();
    setState(() {
      _calisiyor = true;
      _sonuc = null;
      _hata = null;
      _testSonucu = test;
    });
    try {
      final data = await (widget.api ?? _oturum.api).iste(
        'egitimler/${_ders!.id}/gorevler/${g.no}/${test ? 'test' : 'calistir'}',
        veri: {'kod': _kod.text},
        zamanAsimi: ApiIstemcisi.kodZamanAsimi,
      );
      final sonuc = GorevSonucu.fromJson(data as Map<String, dynamic>);
      if (sonuc.no != g.no) {
        throw const FormatException('Görev eşleşmiyor');
      }
      if (mounted && istek == _istek && _gorev?.id == g.id) {
        setState(() => _sonuc = sonuc);
      }
    } on ApiHatasi catch (e) {
      if (mounted && istek == _istek) {
        setState(() {
          _hata = e.mesaj;
          _girisGerekli = e.durum == 401;
        });
      }
    } catch (_) {
      if (mounted && istek == _istek) {
        setState(() => _hata = 'Görev sonucu okunamadı. Tekrar deneyin.');
      }
    } finally {
      if (mounted && istek == _istek) {
        setState(() => _calisiyor = false);
      }
    }
  }

  @override
  void dispose() {
    _oturum.removeListener(_oturumDegisti);
    _kod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = _gorev;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.ozet.kod)),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                Text(widget.ozet.baslik, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                if (_girisGerekli) ...[
                  Text(widget.ozet.ozet),
                  const SizedBox(height: 16),
                  const Text('Bu derse devam etmek için hesabınla giriş yap.'),
                  if (_etkinTaslaklar.isNotEmpty)
                    const Text(
                      'Bu ekran açık kaldığı sürece taslakların korunur.',
                    ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Rotalar.giris),
                    child: const Text('Giriş yap'),
                  ),
                ] else if (_ders == null) ...[
                  Text(_hata ?? 'Ders yüklenemedi.'),
                  FilledButton(
                    onPressed: _yukle,
                    child: const Text('Tekrar dene'),
                  ),
                ] else ...[
                  if (_ders!.misafireAcik && !_oturum.girisYapildi)
                    const Text(
                      'İlk ders · Misafir olarak okuyabilir, kod çalıştırabilir ve test edebilirsin.',
                    ),
                  ExpansionTile(
                    title: const Text('Ders içeriği'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      MarkdownBody(
                        data: _ders!.icerikMarkdown,
                        selectable: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Görevler', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _ders!.gorevler)
                        ChoiceChip(
                          key: ValueKey('gorev_${item.id}'),
                          label: Text('${item.no}. ${item.baslik}'),
                          selected: g?.id == item.id,
                          onSelected: _calisiyor
                              ? null
                              : (_) => setState(() => _sec(item)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (g == null)
                    const Text(
                      'Görev bilgileri henüz hazır değil. İçeriğin aktarılması gerekiyor.',
                    ),
                  if (g != null) ...[
                    Text(
                      'Görev ${g.no} · ${g.baslik}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    MarkdownBody(data: g.aciklama, selectable: true),
                    const SizedBox(height: 20),
                    if (g.tur == 'aciklama')
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Açıklama görevi · Yanıtını dersin kabul ölçütlerine göre değerlendir. Bu görev otomatik test edilmez.',
                          ),
                        ),
                      )
                    else if (!g.kodGorevi) ...[
                      const Text(
                        'Bu görev için güncel içerik aktarımı gerekiyor. Kod çalıştırma ve test kullanılamıyor.',
                      ),
                      TextButton(
                        onPressed: _calisiyor ? null : _yukle,
                        child: const Text('Dersi yeniden yükle'),
                      ),
                    ] else ...[
                      TextField(
                        key: ValueKey('kodEditoru'),
                        controller: _kod,
                        enabled: !_calisiyor,
                        minLines: 8,
                        maxLines: null,
                        maxLength: 32000,
                        keyboardType: TextInputType.multiline,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          labelText: g.baslangicDosyasi,
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => setState(() => _sonuc = null),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _calisiyor
                              ? null
                              : () {
                                  final sel = _kod.selection;
                                  final start = sel.isValid
                                      ? sel.start
                                      : _kod.text.length;
                                  final end = sel.isValid ? sel.end : start;
                                  if (_kod.text.length - (end - start) + 4 >
                                      32000) {
                                    return;
                                  }
                                  _kod.value = TextEditingValue(
                                    text: _kod.text.replaceRange(
                                      start,
                                      end,
                                      '    ',
                                    ),
                                    selection: TextSelection.collapsed(
                                      offset: start + 4,
                                    ),
                                  );
                                  setState(() => _sonuc = null);
                                },
                          icon: const Icon(Icons.format_indent_increase),
                          label: const Text('4 boşluk ekle'),
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            key: ValueKey('kodCalistir'),
                            onPressed: _calisiyor
                                ? null
                                : () => _calistir(false),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Çalıştır'),
                          ),
                          OutlinedButton.icon(
                            key: ValueKey('kodTest'),
                            onPressed: _calisiyor
                                ? null
                                : () => _calistir(true),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Test et'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Taslaklar görevler arasında korunur; bu ders ekranını kapatınca silinir.',
                      ),
                      if (_calisiyor)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: LinearProgressIndicator(),
                        ),
                      if (_hata != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _hata!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      if (_sonuc != null)
                        _Sonuc(
                          sonuc: _sonuc!,
                          kontrol: g.kontrol!,
                          test: _testSonucu,
                        ),
                    ],
                  ],
                ],
              ],
            ),
    );
  }
}

class _Sonuc extends StatelessWidget {
  final GorevSonucu sonuc;
  final GorevKontrolu kontrol;
  final bool test;
  const _Sonuc({
    required this.sonuc,
    required this.kontrol,
    required this.test,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Text(switch (sonuc.durum) {
        'zaman_asimi' => 'Süre sınırı aşıldı',
        'cikti_siniri' => 'Çıktı sınırı aşıldı',
        _ =>
          test
              ? (sonuc.testGecti ? 'Test geçti' : 'Test geçmedi')
              : (sonuc.basarili && sonuc.durum == 'tamamlandi'
                    ? 'Çalıştırma tamamlandı'
                    : 'Çalıştırma tamamlanamadı'),
      }, style: Theme.of(context).textTheme.titleLarge),
      if (!test)
        const Text('Çalıştırma sonucu; test değerlendirmesi yapılmadı.'),
      if (test && sonuc.gonderimId != null)
        const Text('Gönderim geçmişine kaydedildi.'),
      const SizedBox(height: 12),
      if (test)
        _Cikti(
          baslik: 'Beklenen çıktı',
          metin: kontrol.beklenenCikti,
          anahtar: 'beklenenCikti',
        ),
      _Cikti(
        baslik: 'Program çıktısı',
        metin: sonuc.cikti,
        anahtar: 'gercekCikti',
      ),
      if (sonuc.hata.isNotEmpty)
        _Cikti(
          baslik: 'Hata çıktısı',
          metin: sonuc.hata,
          anahtar: 'hataCiktisi',
        ),
      Text('Çıkış kodu: ${sonuc.cikisKodu ?? 'Alınamadı'}'),
      if (test) ...[
        Text('Beklenen çıkış kodu: ${kontrol.beklenenCikisKodu}'),
        Text('Çıktı: ${_eslesme(sonuc.ciktiEslesiyor)}'),
        Text('Çıkış kodu kontrolü: ${_eslesme(sonuc.cikisKoduEslesiyor)}'),
        for (final kural in sonuc.kuralIhlalleri) Text('Kural ihlali: $kural'),
      ],
    ],
  );
  String _eslesme(bool? deger) => deger == null
      ? 'Değerlendirilemedi'
      : deger
      ? 'Eşleşiyor'
      : 'Eşleşmiyor';
}

class _Cikti extends StatelessWidget {
  final String baslik, metin, anahtar;
  const _Cikti({
    required this.baslik,
    required this.metin,
    required this.anahtar,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (metin.isEmpty) const Text('Çıktı boş.'),
          SelectableText(
            metin,
            key: ValueKey(anahtar),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Boşlukları ve satır sonlarını göster'),
            children: [
              SelectableText(
                jsonEncode(metin),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
