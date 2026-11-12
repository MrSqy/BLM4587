import 'package:flutter/material.dart';

import '../modeller/gonderim.dart';
import '../rotalar.dart';
import '../servisler/api_istemcisi.dart';
import '../servisler/gonderim_servisi.dart';
import '../servisler/oturum_servisi.dart';

class IlerlemeEkrani extends StatefulWidget {
  final bool etkin;
  final GonderimServisi? servis;
  const IlerlemeEkrani({super.key, this.etkin = true, this.servis});

  @override
  State<IlerlemeEkrani> createState() => _IlerlemeEkraniState();
}

class _IlerlemeEkraniState extends State<IlerlemeEkrani> {
  late final _oturum = oturumServisi;
  late final _servis = widget.servis ?? GonderimServisi(_oturum.api);
  final _kayitlar = <GonderimOzeti>[];
  int _istek = 0, _sayfa = 0, _toplam = 0;
  bool _yukleniyor = false, _sonrakiVar = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _oturum.addListener(_oturumDegisti);
    _yukle();
  }

  @override
  void didUpdateWidget(covariant IlerlemeEkrani oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.etkin && !oldWidget.etkin) _yukle();
  }

  void _listeyiTemizle() {
    _kayitlar.clear();
    _sayfa = 0;
    _toplam = 0;
    _sonrakiVar = false;
    _hata = null;
  }

  void _oturumDegisti() {
    _istek++;
    setState(() {
      _listeyiTemizle();
      _yukleniyor = false;
    });
    _yukle();
  }

  Future<void> _yukle({bool sonraki = false}) async {
    if (!widget.etkin ||
        !_oturum.girisYapildi ||
        (sonraki && (_yukleniyor || !_sonrakiVar))) {
      return;
    }
    final sira = ++_istek;
    final token = _oturum.token;
    final sayfa = sonraki ? _sayfa + 1 : 1;
    bool gecerli() => mounted && sira == _istek && token == _oturum.token;
    setState(() {
      if (!sonraki) _listeyiTemizle();
      _hata = null;
      _yukleniyor = true;
    });
    try {
      final sonuc = await _servis.liste(sayfa);
      if (!gecerli()) return;
      setState(() {
        final kimlikler = _kayitlar.map((g) => g.id).toSet();
        _kayitlar.addAll(sonuc.kayitlar.where((g) => kimlikler.add(g.id)));
        _sayfa = sonuc.sayfa;
        _toplam = sonuc.toplam;
        _sonrakiVar = sonuc.sonrakiVar;
      });
    } on ApiHatasi catch (e) {
      if (gecerli()) setState(() => _hata = e.mesaj);
    } catch (_) {
      if (gecerli()) setState(() => _hata = 'Gönderim geçmişi okunamadı.');
    } finally {
      if (gecerli()) setState(() => _yukleniyor = false);
    }
  }

  @override
  void dispose() {
    _oturum.removeListener(_oturumDegisti);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_oturum.girisYapildi) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gönderim geçmişini görmek için giriş yap.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, Rotalar.giris),
                child: const Text('Giriş yap'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Gönderim geçmişi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_sayfa > 0) Text('$_toplam gönderim'),
          const SizedBox(height: 12),
          for (final kayit in _kayitlar)
            Card(
              child: ListTile(
                key: ValueKey('gonderim_${kayit.id}'),
                title: Text(kayit.ders),
                subtitle: Text(
                  [
                    if (kayit.gorev != null) kayit.gorev!,
                    kayit.sonucEtiketi,
                    _tarih(context, kayit.tarih),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _GonderimDetayEkrani(
                      id: kayit.id,
                      servis: _servis,
                      oturum: _oturum,
                    ),
                  ),
                ),
              ),
            ),
          if (_yukleniyor)
            const Center(child: CircularProgressIndicator())
          else if (_hata != null) ...[
            Text(
              _hata!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            OutlinedButton(
              onPressed: () => _yukle(sonraki: _sayfa > 0),
              child: const Text('Tekrar dene'),
            ),
          ] else if (_kayitlar.isEmpty)
            const Text('Henüz gönderimin yok.')
          else if (_sonrakiVar)
            OutlinedButton(
              onPressed: () => _yukle(sonraki: true),
              child: const Text('Daha fazla göster'),
            ),
        ],
      ),
    );
  }
}

String _tarih(BuildContext context, DateTime tarih) {
  final yerel = tarih.toLocal();
  final dil = MaterialLocalizations.of(context);
  return '${dil.formatShortDate(yerel)} ${dil.formatTimeOfDay(TimeOfDay.fromDateTime(yerel))}';
}

class _GonderimDetayEkrani extends StatefulWidget {
  final int id;
  final GonderimServisi servis;
  final OturumServisi oturum;
  const _GonderimDetayEkrani({
    required this.id,
    required this.servis,
    required this.oturum,
  });

  @override
  State<_GonderimDetayEkrani> createState() => _GonderimDetayEkraniState();
}

class _GonderimDetayEkraniState extends State<_GonderimDetayEkrani> {
  late final _token = widget.oturum.token;
  late final _sahip = widget.oturum.kullaniciId;
  Future<GonderimDetayi>? _gelecek;

  @override
  void initState() {
    super.initState();
    // Kimliği istek başlamadan sabitle. Başka oturumda bu ayrıntı açılmaz.
    if (_token != null && _sahip != null) {
      _gelecek = widget.servis.detay(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Gönderim #${widget.id}')),
    body: ListenableBuilder(
      listenable: widget.oturum,
      builder: (context, _) {
        if (_gelecek == null ||
            _token == null ||
            _token != widget.oturum.token ||
            _sahip != widget.oturum.kullaniciId) {
          return const Center(
            child: Text('Gönderimi görmek için geçmişi yeniden aç.'),
          );
        }
        return FutureBuilder<GonderimDetayi>(
          future: _gelecek,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final hata = snapshot.error;
              final bulunamadi = hata is ApiHatasi && hata.durum == 404;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    bulunamadi
                        ? 'Gönderim bulunamadı.'
                        : hata is ApiHatasi
                        ? hata.mesaj
                        : 'Gönderim ayrıntısı okunamadı.',
                  ),
                  if (!bulunamadi)
                    OutlinedButton(
                      onPressed: () => setState(
                        () => _gelecek = widget.servis.detay(widget.id),
                      ),
                      child: const Text('Tekrar dene'),
                    ),
                ],
              );
            }
            final detay = snapshot.requireData;
            final ozet = detay.gonderim;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(ozet.ders, style: Theme.of(context).textTheme.titleLarge),
                if (ozet.gorev != null) Text(ozet.gorev!),
                Text(_tarih(context, ozet.tarih)),
                Text('${ozet.sonucEtiketi} · ${ozet.sureMs} ms'),
                if (ozet.cikisKodu != null)
                  Text('Çıkış kodu: ${ozet.cikisKodu}'),
                _Metin(baslik: 'Kod', metin: detay.kod),
                _Metin(baslik: 'Program çıktısı', metin: detay.cikti),
                _Metin(baslik: 'Hata çıktısı', metin: detay.hata),
              ],
            );
          },
        );
      },
    ),
  );
}

class _Metin extends StatelessWidget {
  final String baslik, metin;
  const _Metin({required this.baslik, required this.metin});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: Theme.of(context).textTheme.titleMedium),
        SelectableText(
          metin.isEmpty ? '(Boş)' : metin,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ],
    ),
  );
}
