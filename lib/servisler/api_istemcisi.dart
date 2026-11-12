import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiHatasi implements Exception {
  final String mesaj;
  final int? durum;
  const ApiHatasi(this.mesaj, [this.durum]);
  @override
  String toString() => mesaj;
}

class ApiIstemcisi {
  static const _kodSuresi = int.fromEnvironment(
    'KOD_ZAMAN_ASIMI_SANIYE',
    defaultValue: 60,
  );
  static const kodZamanAsimi = Duration(
    seconds: _kodSuresi > 0 ? _kodSuresi : 60,
  );
  final http.Client istemci;
  final Uri adres;
  final Duration zamanAsimi;
  final bool httpsZorunlu;
  String? Function()? tokenOku;
  Future<void> Function()? oturumGecersiz;
  ApiIstemcisi({
    http.Client? istemci,
    String? adres,
    this.zamanAsimi = const Duration(seconds: 20),
    this.httpsZorunlu = kReleaseMode,
  }) : istemci = istemci ?? http.Client(),
       adres = Uri.parse(_adres(adres));

  static String _adres(String? verilen) {
    const ayar = String.fromEnvironment('API_ADRESI');
    final deger =
        verilen ??
        (ayar.isNotEmpty
            ? ayar
            : defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:5080/api/mobil/'
            : 'http://127.0.0.1:5080/api/mobil/');
    return deger.endsWith('/') ? deger : '$deger/';
  }

  Future<dynamic> iste(
    String yol, {
    Map<String, dynamic>? veri,
    bool kimlik = true,
    Duration? zamanAsimi,
  }) async {
    _adresiDogrula();
    final uri = adres.resolve(yol);
    if (uri.scheme != adres.scheme ||
        uri.origin != adres.origin ||
        uri.userInfo.isNotEmpty ||
        !uri.path.startsWith(adres.path)) {
      throw const ApiHatasi('Geçersiz API yolu.');
    }
    return _iste(uri, veri: veri, kimlik: kimlik, sure: zamanAsimi);
  }

  // Geçmiş, mobil önekinin dışında ama aynı backend adresindedir.
  Future<dynamic> gonderimGecmisiIste({int? id, int sayfa = 1}) async {
    _adresiDogrula();
    final yol = id == null
        ? '/api/gonderimler?sayfa=$sayfa&sayfaBoyutu=20'
        : '/api/gonderimler/$id';
    return _iste(adres.resolve(yol), kimlik: true);
  }

  void _adresiDogrula() {
    if (!['http', 'https'].contains(adres.scheme) ||
        adres.host.isEmpty ||
        adres.userInfo.isNotEmpty ||
        (httpsZorunlu && adres.scheme != 'https')) {
      throw const ApiHatasi(
        'Sunucu adresi geçersiz. Yayın ortamında HTTPS gereklidir.',
      );
    }
  }

  Future<dynamic> _iste(
    Uri uri, {
    Map<String, dynamic>? veri,
    required bool kimlik,
    Duration? sure,
  }) async {
    final token = kimlik ? tokenOku?.call() : null;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (veri != null) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await (veri == null
                  ? istemci.get(uri, headers: headers)
                  : istemci.post(uri, headers: headers, body: jsonEncode(veri)))
              .timeout(sure ?? zamanAsimi);
      dynamic body;
      try {
        body = response.body.isEmpty
            ? null
            : jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        body = null;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body == null && response.statusCode != 204) {
          throw const ApiHatasi('Sunucu yanıtı okunamadı.');
        }
        return body;
      }
      // Eski bir isteğin 401'i, sonradan açılmış yeni oturumu kapatmaz.
      if (response.statusCode == 401 &&
          kimlik &&
          token != null &&
          token == tokenOku?.call()) {
        await oturumGecersiz?.call();
      }
      final tekrar = int.tryParse(response.headers['retry-after'] ?? '');
      final mesaj =
          response.statusCode == 503 &&
              body is Map &&
              body['durum'] == 'kuyruk_dolu' &&
              tekrar != null &&
              tekrar > 0
          ? 'Sandbox yoğun. $tekrar saniye sonra yeniden deneyin.'
          : _mesaj(body, response.statusCode);
      throw ApiHatasi(mesaj, response.statusCode);
    } on TimeoutException {
      throw const ApiHatasi('Sunucu zamanında yanıt vermedi. Tekrar deneyin.');
    } on SocketException {
      throw const ApiHatasi(
        'Sunucuya ulaşılamıyor. Bağlantınızı kontrol edin.',
      );
    } on http.ClientException {
      throw const ApiHatasi(
        'Sunucuya ulaşılamıyor. Bağlantınızı kontrol edin.',
      );
    }
  }

  static String _mesaj(dynamic body, int status) {
    if (body is Map) {
      if (body['mesaj'] is String &&
          (body['mesaj'] as String).trim().isNotEmpty) {
        return body['mesaj'] as String;
      }
      final errors = body['errors'];
      if (errors is Map) {
        final mesajlar = errors.values
            .expand((v) => v is List ? v : [v])
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toSet();
        if (mesajlar.isNotEmpty) {
          return mesajlar.join('\n');
        }
      }
      if (body['title'] is String &&
          (body['title'] as String).trim().isNotEmpty) {
        return body['title'] as String;
      }
    }
    return switch (status) {
      401 => 'Devam etmek için giriş yapın.',
      403 => 'Bu işlem için yetkiniz bulunmuyor.',
      429 => 'Çok sık istek gönderdiniz. Bir dakika sonra tekrar deneyin.',
      503 => 'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
      400 => 'Bilgilerinizi kontrol edip tekrar deneyin.',
      404 => 'İstenen içerik bulunamadı.',
      409 =>
        'Görev içeriği güncellenmeli. Dersi yeniden yükleyip tekrar deneyin.',
      _ => 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
    };
  }
}

final apiIstemcisi = ApiIstemcisi();
