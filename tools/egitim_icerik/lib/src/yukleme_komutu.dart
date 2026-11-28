import 'dart:io';
import '../egitim_icerik.dart';
import 'api_yukleyici.dart';
import 'artimli_aktarim.dart';
import 'yukleme_plani.dart';

const yuklemeYardimi = '''Yükleme:
  dart run bin/egitim_icerik.dart yukle --kaynak <klasor> --api <temel-adres> --ders PY-01 [--dry-run]
  --ders PY-01,PY-02          Açık seçim; TM-DEMO-00,TM-DEMO-01 de desteklenir.
  --surum 2                  Varsayılan v2 görev sözleşmesi; eski pytest için 1.
  --kismi-aktarimi-onayla     Eksik alanlar raporlandıktan sonra kısmi aktarımı kabul eder.
  --v2-gecisini-onayla       DB yedeği sonrası mevcut dersin açık v2 dönüşümü.
  --zaman-asimi <saniye>      1–120; varsayılan 20.
  --artimli                  Yalnız yeni/değişmiş dersleri yükler.
  --durum-dosyasi <dosya>     Artımlı kayıt; varsayılan build/aktarim-durumu.json.
Gerçek yükleme yalnız loopback adreslere yapılır. EGITIM_EPOSTA/EGITIM_SIFRE gerekir.
Dry-run hiçbir HTTP isteği göndermez. Veri kaybı varsayılan olarak engellenir.''';

Future<int> yuklemeKomutu(
  List<String> args, {
  Map<String, String>? ortam,
  HttpGonder? gonder,
  void Function(String)? yaz,
}) async {
  final void Function(String) cikti = yaz ?? (s) => stdout.writeln(s);
  final degerler = <String, String>{};
  final bayraklar = <String>{};
  try {
    for (var i = 0; i < args.length; i++) {
      final ad = args[i];
      if ({
        '--dry-run',
        '--artimli',
        '--kismi-aktarimi-onayla',
        '--v2-gecisini-onayla',
      }.contains(ad)) {
        if (!bayraklar.add(ad)) throw YuklemeHatasi('Yinelenen seçenek.');
      } else if ({
        '--kaynak',
        '--api',
        '--ders',
        '--zaman-asimi',
        '--surum',
        '--durum-dosyasi',
      }.contains(ad)) {
        if (degerler.containsKey(ad) ||
            i + 1 >= args.length ||
            args[i + 1].startsWith('--')) {
          throw YuklemeHatasi('Seçenek değeri eksik/yinelenmiş.');
        }
        degerler[ad] = args[++i];
      } else {
        throw YuklemeHatasi(
          'Bilinmeyen yükleme seçeneği. --help kullanın; parola/token komut satırına verilmez.',
        );
      }
    }
    if (!['--kaynak', '--api', '--ders'].every(degerler.containsKey)) {
      throw YuklemeHatasi('--kaynak, --api ve --ders zorunludur.');
    }
    final kodlar = degerler['--ders']!.split(',').map((k) => k.trim()).toSet();
    if (degerler.containsKey('--durum-dosyasi') &&
        !bayraklar.contains('--artimli')) {
      throw YuklemeHatasi('--durum-dosyasi yalnız --artimli ile kullanılır.');
    }
    if (kodlar.any((k) => !RegExp(r'^(PY|TM-DEMO)-\d+$').hasMatch(k))) {
      throw YuklemeHatasi(
        'Ders kodları PY-01 veya TM-DEMO-00 biçiminde olmalı.',
      );
    }
    final sure = int.tryParse(degerler['--zaman-asimi'] ?? '20');
    if (sure == null || sure < 1 || sure > 120) {
      throw YuklemeHatasi('Zaman aşımı 1–120 saniye olmalı.');
    }
    final temel = apiAdresi(degerler['--api']!);
    final surum = int.tryParse(degerler['--surum'] ?? '2');
    if (surum != 1 && surum != 2) {
      throw YuklemeHatasi('--surum 1 veya 2 olmalı.');
    }
    if (surum == 1 && bayraklar.contains('--v2-gecisini-onayla')) {
      throw YuklemeHatasi('V2 geçiş onayı v1 paketinde kullanılamaz.');
    }
    final veri = egitimleriAktar(degerler['--kaynak']!, dersKodlari: kodlar);
    final plan = yuklemePlani(veri, kodlar, surum: surum!);
    final durum = bayraklar.contains('--artimli')
        ? ArtimliDurum(
            degerler['--durum-dosyasi'] ?? 'build/aktarim-durumu.json',
            kaynak: degerler['--kaynak']!,
          )
        : null;
    cikti(
      'Kategori: ${(plan.paket['kategoriler'] as List).map((dynamic k) => "${k['kisaltma']} — ${k['ad']}").join(', ')}',
    );
    cikti('Hedef: $temel | Sözleşme v$surum | ${plan.ozet}');
    if (surum == 2) {
      final gorevler = plan.dersler
          .expand((d) => (d['gorevler'] as List).cast<Map<String, dynamic>>())
          .toList();
      cikti(
        'V2: ${gorevler.where((g) => g['tur'] == 'kod').length} kod, ${gorevler.where((g) => g['tur'] == 'aciklama').length} açıklama görevi. Başlangıçlar ve çıktı kontrolleri görev üzerinde taşınıyor.',
      );
      cikti(
        'V2 geçişi yalnız seçilen derslerin tam görev listesini yeniler; eksik eski görevler pasifleşir, silinmez. Mevcut dersin boş kod/test alanları için DB yedeği ve --v2-gecisini-onayla gerekir.',
      );
    }
    for (final uyari in plan.uyarilar) {
      cikti('Kaynak uyarısı: $uyari');
    }
    for (final kayip in plan.kayiplar) {
      cikti('Dışarıda kalacak: $kayip');
    }
    cikti(
      'İşlem: kategori kısaltması / ders kodu / görev numarası ile ekle-güncelle; kimlikler sunucuda üretilir, silme yok.',
    );
    if (bayraklar.contains('--dry-run')) {
      if (durum != null) {
        durum.oku();
        artimliOzeti(durum.ayir(plan, temel), cikti);
      }
      cikti(
        'DRY-RUN: HTTP isteği yok; sunucudaki mevcut kod/test alanları ve oturum kontrol edilmedi.',
      );
      if (plan.kayiplar.isNotEmpty &&
          !bayraklar.contains('--kismi-aktarimi-onayla')) {
        cikti(
          surum == 2
              ? 'ENGELLİ: V2 görev kod/kontrolleri taşınıyor; ayrı kaynak arşivi alanları dışarıda. Bu kapsam ancak --kismi-aktarimi-onayla ile kabul edilebilir.'
              : 'ENGELLİ: Tam aktarım için sözleşme eksik. Kısmi deneme ancak --kismi-aktarimi-onayla ile mümkündür.',
        );
        return 2;
      }
      cikti('Yerel plan hazır. Bu sonuç gerçek aktarım değildir.');
      return 0;
    }
    if (!yerelAdres(temel)) {
      throw YuklemeHatasi(
        'Ortak/canlı hedefe yazma desteklenmiyor; hedef ve dersler için ayrıca onay gerekir.',
      );
    }
    if (plan.kayiplar.isNotEmpty &&
        !bayraklar.contains('--kismi-aktarimi-onayla')) {
      cikti(
        'ENGELLİ: API alan kaybı nedeniyle yükleme yapılmadı. --dry-run raporunu inceleyin.',
      );
      return 2;
    }
    final env = ortam ?? Platform.environment;
    final baglanti = gonder == null
        ? ApiBaglantisi(zamanAsimi: Duration(seconds: sure))
        : null;
    try {
      if (durum != null) {
        final basarili =
            await ArtimliYukleyici(
              IcerikYukleyici(temel, gonder ?? baglanti!.gonder),
              durum,
            ).yukle(
              plan,
              eposta: env['EGITIM_EPOSTA'] ?? '',
              sifre: env['EGITIM_SIFRE'] ?? '',
              yaz: cikti,
              kayipOnayi: bayraklar.contains('--kismi-aktarimi-onayla'),
              v2GecisOnayi: bayraklar.contains('--v2-gecisini-onayla'),
            );
        return basarili ? 0 : 1;
      }
      final sonuc = await IcerikYukleyici(temel, gonder ?? baglanti!.gonder)
          .yukle(
            plan,
            eposta: env['EGITIM_EPOSTA'] ?? '',
            sifre: env['EGITIM_SIFRE'] ?? '',
            kayipOnayi: bayraklar.contains('--kismi-aktarimi-onayla'),
            v2GecisOnayi: bayraklar.contains('--v2-gecisini-onayla'),
          );
      cikti(
        '${plan.kayiplar.isEmpty ? 'Aktarım' : 'Kısmi aktarım denemesi'}: ${sonuc.ozet}',
      );
      if (sonuc.hata != null) cikti('Hata: ${sonuc.hata}');
      return sonuc.basarili ? 0 : 1;
    } finally {
      baglanti?.kapat();
    }
  } on YuklemeHatasi catch (e) {
    cikti('Hata: ${e.mesaj}');
    return 1;
  } on FileSystemException catch (e) {
    cikti('Kaynak dosyası okunamadı: ${e.path}');
    return 1;
  } on FormatException catch (e) {
    cikti('İçerik hatası: ${e.message}');
    return 1;
  }
}
