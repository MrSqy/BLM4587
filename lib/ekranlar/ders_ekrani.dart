import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../modeller/egitim.dart';
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
  Egitim? _ders;
  Map<String, dynamic>? _sonuc;
  String? _hata;
  bool _yukleniyor = true;
  bool _calisiyor = false;
  bool _girisGerekli = false;
  int _istek = 0;

  @override
  void initState() {
    super.initState();
    oturumServisi.addListener(_oturumDegisti);
    _yukle();
  }

  void _oturumDegisti() {
    // Oturum değiştiğinde önceki kullanıcıya ait içerik ekranda kalmaz.
    _kod.clear();
    _sonuc = null;
    _yukle();
  }

  Future<void> _yukle() async {
    final istek = ++_istek;
    setState(() {
      _ders = null;
      _yukleniyor = true;
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
        } else if (_kod.text.isEmpty) {
          _kod.text = ders.baslangicKodu;
        }
      });
    } on ApiHatasi catch (e) {
      if (!mounted || istek != _istek) return;
      setState(() {
        _hata = e.mesaj;
        _girisGerekli = e.durum == 401;
      });
    } catch (_) {
      if (mounted && istek == _istek) {
        setState(() => _hata = 'Ders yüklenemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted && istek == _istek) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _calistir(bool test) async {
    if (_calisiyor) return;
    if (_kod.text.length > 32000) {
      setState(() => _hata = 'Kod en fazla 32000 karakter olabilir.');
      return;
    }
    if (_kod.text.trim().isEmpty) {
      setState(() => _hata = 'Çalıştırılacak kodu yazın.');
      return;
    }
    final istek = _istek;
    FocusScope.of(context).unfocus();
    setState(() {
      _calisiyor = true;
      _sonuc = null;
      _hata = null;
    });
    try {
      final sonuc = await (widget.api ?? apiIstemcisi).iste(
        'egitimler/${widget.ozet.id}/${test ? 'test' : 'calistir'}',
        veri: {'kod': _kod.text},
      );
      if (mounted && istek == _istek) {
        setState(() => _sonuc = sonuc as Map<String, dynamic>);
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
        setState(() => _hata = 'Sonuç alınamadı. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _calisiyor = false);
    }
  }

  @override
  void dispose() {
    oturumServisi.removeListener(_oturumDegisti);
    _kod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.ozet.kod)),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                Text(widget.ozet.baslik, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                if (_girisGerekli) ...[
                  Text(widget.ozet.ozet),
                  const SizedBox(height: 16),
                  const Text('Bu derse devam etmek için hesabınla giriş yap.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Rotalar.giris),
                    child: const Text('Giriş yap'),
                  ),
                ] else if (_ders == null) ...[
                  Text(_hata ?? 'Ders yüklenemedi.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _yukle,
                    child: const Text('Tekrar dene'),
                  ),
                ] else ...[
                  if (_ders!.misafireAcik && !oturumServisi.girisYapildi)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'İlk ders · Misafir olarak okuyabilir, kod çalıştırabilir ve test edebilirsin.',
                      ),
                    ),
                  MarkdownBody(data: _ders!.icerikMarkdown, selectable: true),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 20),
                  Text('Kod çalışması', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text(
                    'Python · Kodunu düzenle, çıktıyı incele ve görevleri test et.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('kodEditoru'),
                    controller: _kod,
                    enabled: !_calisiyor,
                    minLines: 10,
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
                    decoration: const InputDecoration(
                      labelText: 'calisma.py',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) {
                      if (_sonuc != null) setState(() => _sonuc = null);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _calisiyor
                          ? null
                          : () {
                              final selection = _kod.selection;
                              final start = selection.isValid
                                  ? selection.start
                                  : _kod.text.length;
                              final end = selection.isValid
                                  ? selection.end
                                  : start;
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
                        key: const ValueKey('kodCalistir'),
                        onPressed: _calisiyor ? null : () => _calistir(false),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Çalıştır'),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('kodTest'),
                        onPressed: _calisiyor ? null : () => _calistir(true),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Test et'),
                      ),
                    ],
                  ),
                  if (_calisiyor)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Kodun çalıştırılıyor…'),
                        ],
                      ),
                    ),
                  if (_hata != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _hata!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  if (_sonuc != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _sonuc!['basarili'] == true &&
                              _sonuc!['durum'] == 'tamamlandi'
                          ? 'Çalışma tamamlandı'
                          : switch (_sonuc!['durum']) {
                              'zaman_asimi' => 'Süre sınırı aşıldı',
                              'test_yok' => 'Otomatik test bulunamadı',
                              _ => 'Kodunu gözden geçir',
                            },
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          '${_sonuc!['cikti'] ?? ''}${(_sonuc!['hata'] as String? ?? '').isEmpty ? '' : '\n${_sonuc!['hata']}'}'
                                  .trim()
                                  .isEmpty
                              ? 'Kod çıktı üretmedi.'
                              : '${_sonuc!['cikti'] ?? ''}\n${_sonuc!['hata'] ?? ''}'
                                    .trim(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    for (final g in (_sonuc!['gorevler'] as List? ?? []))
                      Card(
                        child: ListTile(
                          leading: Icon(
                            g['durum'] == 'basarili'
                                ? Icons.check_circle_outline
                                : g['durum'] == 'basarisiz'
                                ? Icons.error_outline
                                : Icons.info_outline,
                          ),
                          title: Text('Görev ${g['no']}'),
                          subtitle: Text(switch (g['durum']) {
                            'basarili' => 'Testler geçti',
                            'basarisiz' => 'Testler geçmedi',
                            'atlanmis' => 'Test atlandı',
                            _ =>
                              'Otomatik test yok; dersin kabul ölçütlerini kontrol et.',
                          }),
                        ),
                      ),
                  ],
                ],
              ],
            ),
    );
  }
}
