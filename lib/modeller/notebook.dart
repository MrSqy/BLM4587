import 'dart:convert';

class NotebookBelgesi {
  final int nbformat;
  final int nbformatMinor;
  final Map<String, dynamic> metadata;
  final List<NotebookHucresi> hucreler;

  NotebookBelgesi({
    required this.nbformat,
    required this.nbformatMinor,
    required Map<String, dynamic> metadata,
    required List<NotebookHucresi> hucreler,
  }) : metadata = Map<String, dynamic>.from(metadata),
       hucreler = List<NotebookHucresi>.unmodifiable(hucreler);

  factory NotebookBelgesi.fromJson(Map<String, dynamic> json) {
    final nbformat = _intOku(json['nbformat'], 'nbformat');
    final nbformatMinor = _intOku(json['nbformat_minor'], 'nbformat_minor');
    final hucreListesi = _listeOku(json['cells'], 'cells');
    return NotebookBelgesi(
      nbformat: nbformat,
      nbformatMinor: nbformatMinor,
      metadata: _haritaOku(json['metadata'], 'metadata'),
      hucreler: hucreListesi.indexed.map((kayit) {
        final (indeks, hucre) = kayit;
        final yol = 'cells[$indeks]';
        return NotebookHucresi.fromJson(
          _haritaOku(hucre, yol),
          yol: yol,
          kimlikZorunlu: nbformat == 4 && nbformatMinor >= 5,
        );
      }).toList(),
    );
  }

  factory NotebookBelgesi.fromJsonString(String kaynak) {
    return NotebookBelgesi.fromJson(_haritaOku(jsonDecode(kaynak), 'notebook'));
  }

  Map<String, dynamic> toJson() {
    return {
      'cells': hucreler.map((hucre) => hucre.toJson()).toList(),
      'metadata': Map<String, dynamic>.from(metadata),
      'nbformat': nbformat,
      'nbformat_minor': nbformatMinor,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

sealed class NotebookHucresi {
  final String? id;
  final Map<String, dynamic> metadata;
  final String kaynak;

  NotebookHucresi({
    required this.id,
    required Map<String, dynamic> metadata,
    required this.kaynak,
  }) : metadata = Map<String, dynamic>.from(metadata);

  factory NotebookHucresi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'cell',
    bool kimlikZorunlu = false,
  }) {
    final turYolu = '$yol.cell_type';
    final tur = _metinOku(json['cell_type'], turYolu);
    return switch (tur) {
      'markdown' => MarkdownHucresi.fromJson(
        json,
        yol: yol,
        kimlikZorunlu: kimlikZorunlu,
      ),
      'code' => KodHucresi.fromJson(
        json,
        yol: yol,
        kimlikZorunlu: kimlikZorunlu,
      ),
      'raw' => HamHucresi.fromJson(
        json,
        yol: yol,
        kimlikZorunlu: kimlikZorunlu,
      ),
      _ => throw FormatException(
        '$turYolu desteklenen bir hücre türü olmalı; gelen: $tur.',
      ),
    };
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> temelJson(String hucreTuru) {
    return {
      'cell_type': hucreTuru,
      if (id != null) 'id': id,
      'metadata': Map<String, dynamic>.from(metadata),
      'source': kaynak,
    };
  }
}

final class MarkdownHucresi extends NotebookHucresi {
  final Map<String, dynamic> ekler;

  MarkdownHucresi({
    required super.id,
    required super.metadata,
    required super.kaynak,
    required Map<String, dynamic> ekler,
  }) : ekler = Map<String, dynamic>.from(ekler);

  factory MarkdownHucresi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'cell',
    bool kimlikZorunlu = false,
  }) {
    return MarkdownHucresi(
      id: _hucreKimliginiOku(json, yol, kimlikZorunlu),
      metadata: _haritaOku(json['metadata'], '$yol.metadata'),
      kaynak: _cokSatirliMetniOku(json['source'], '$yol.source'),
      ekler: _opsiyonelHaritaOku(json, 'attachments', yol),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...temelJson('markdown'),
      if (ekler.isNotEmpty) 'attachments': Map<String, dynamic>.from(ekler),
    };
  }
}

final class KodHucresi extends NotebookHucresi {
  final int? calistirmaSayisi;
  final List<NotebookCiktisi> ciktilar;

  KodHucresi({
    required super.id,
    required super.metadata,
    required super.kaynak,
    required this.calistirmaSayisi,
    required List<NotebookCiktisi> ciktilar,
  }) : ciktilar = List<NotebookCiktisi>.unmodifiable(ciktilar);

  factory KodHucresi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'cell',
    bool kimlikZorunlu = false,
  }) {
    final ciktiListesi = _listeOku(json['outputs'], '$yol.outputs');
    return KodHucresi(
      id: _hucreKimliginiOku(json, yol, kimlikZorunlu),
      metadata: _haritaOku(json['metadata'], '$yol.metadata'),
      kaynak: _cokSatirliMetniOku(json['source'], '$yol.source'),
      calistirmaSayisi: _nullableIntOku(
        _zorunluAlanOku(json, 'execution_count', yol),
        '$yol.execution_count',
      ),
      ciktilar: ciktiListesi.indexed.map((kayit) {
        final (indeks, cikti) = kayit;
        final ciktiYolu = '$yol.outputs[$indeks]';
        return NotebookCiktisi.fromJson(
          _haritaOku(cikti, ciktiYolu),
          yol: ciktiYolu,
        );
      }).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...temelJson('code'),
      'execution_count': calistirmaSayisi,
      'outputs': ciktilar.map((cikti) => cikti.toJson()).toList(),
    };
  }
}

final class HamHucresi extends NotebookHucresi {
  final Map<String, dynamic> ekler;

  HamHucresi({
    required super.id,
    required super.metadata,
    required super.kaynak,
    required Map<String, dynamic> ekler,
  }) : ekler = Map<String, dynamic>.from(ekler);

  factory HamHucresi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'cell',
    bool kimlikZorunlu = false,
  }) {
    return HamHucresi(
      id: _hucreKimliginiOku(json, yol, kimlikZorunlu),
      metadata: _haritaOku(json['metadata'], '$yol.metadata'),
      kaynak: _cokSatirliMetniOku(json['source'], '$yol.source'),
      ekler: _opsiyonelHaritaOku(json, 'attachments', yol),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...temelJson('raw'),
      if (ekler.isNotEmpty) 'attachments': Map<String, dynamic>.from(ekler),
    };
  }
}

sealed class NotebookCiktisi {
  const NotebookCiktisi();

  factory NotebookCiktisi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'output',
  }) {
    final turYolu = '$yol.output_type';
    final tur = _metinOku(json['output_type'], turYolu);
    return switch (tur) {
      'stream' => AkisCiktisi.fromJson(json, yol: yol),
      'display_data' => GosterimCiktisi.fromJson(json, yol: yol),
      'execute_result' => CalistirmaSonucu.fromJson(json, yol: yol),
      'error' => HataCiktisi.fromJson(json, yol: yol),
      _ => throw FormatException(
        '$turYolu desteklenen bir çıktı türü olmalı; gelen: $tur.',
      ),
    };
  }

  Map<String, dynamic> toJson();
}

final class AkisCiktisi extends NotebookCiktisi {
  final String akisAdi;
  final String metin;

  const AkisCiktisi({required this.akisAdi, required this.metin});

  factory AkisCiktisi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'output',
  }) {
    return AkisCiktisi(
      akisAdi: _metinOku(json['name'], '$yol.name'),
      metin: _cokSatirliMetniOku(json['text'], '$yol.text'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'output_type': 'stream', 'name': akisAdi, 'text': metin};
  }
}

final class GosterimCiktisi extends NotebookCiktisi {
  final Map<String, dynamic> veri;
  final Map<String, dynamic> metadata;

  GosterimCiktisi({
    required Map<String, dynamic> veri,
    required Map<String, dynamic> metadata,
  }) : veri = Map<String, dynamic>.from(veri),
       metadata = Map<String, dynamic>.from(metadata);

  factory GosterimCiktisi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'output',
  }) {
    return GosterimCiktisi(
      veri: _haritaOku(json['data'], '$yol.data'),
      metadata: _haritaOku(json['metadata'], '$yol.metadata'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'output_type': 'display_data',
      'data': Map<String, dynamic>.from(veri),
      'metadata': Map<String, dynamic>.from(metadata),
    };
  }
}

final class CalistirmaSonucu extends NotebookCiktisi {
  final int? calistirmaSayisi;
  final Map<String, dynamic> veri;
  final Map<String, dynamic> metadata;

  CalistirmaSonucu({
    required this.calistirmaSayisi,
    required Map<String, dynamic> veri,
    required Map<String, dynamic> metadata,
  }) : veri = Map<String, dynamic>.from(veri),
       metadata = Map<String, dynamic>.from(metadata);

  factory CalistirmaSonucu.fromJson(
    Map<String, dynamic> json, {
    String yol = 'output',
  }) {
    return CalistirmaSonucu(
      calistirmaSayisi: _nullableIntOku(
        _zorunluAlanOku(json, 'execution_count', yol),
        '$yol.execution_count',
      ),
      veri: _haritaOku(json['data'], '$yol.data'),
      metadata: _haritaOku(json['metadata'], '$yol.metadata'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'output_type': 'execute_result',
      'execution_count': calistirmaSayisi,
      'data': Map<String, dynamic>.from(veri),
      'metadata': Map<String, dynamic>.from(metadata),
    };
  }
}

final class HataCiktisi extends NotebookCiktisi {
  final String hataAdi;
  final String hataDegeri;
  final List<String> iz;

  HataCiktisi({
    required this.hataAdi,
    required this.hataDegeri,
    required List<String> iz,
  }) : iz = List<String>.unmodifiable(iz);

  factory HataCiktisi.fromJson(
    Map<String, dynamic> json, {
    String yol = 'output',
  }) {
    return HataCiktisi(
      hataAdi: _metinOku(json['ename'], '$yol.ename'),
      hataDegeri: _metinOku(json['evalue'], '$yol.evalue'),
      iz: _metinListesiOku(json['traceback'], '$yol.traceback'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'output_type': 'error',
      'ename': hataAdi,
      'evalue': hataDegeri,
      'traceback': List<String>.from(iz),
    };
  }
}

Map<String, dynamic> _haritaOku(dynamic deger, String yol) {
  if (deger is Map) {
    try {
      return Map<String, dynamic>.from(deger);
    } on TypeError {
      throw FormatException('$yol alanının bütün anahtarları metin olmalı.');
    }
  }
  throw _tipHatasi(yol, 'JSON nesnesi', deger);
}

dynamic _zorunluAlanOku(Map<String, dynamic> json, String alan, String yol) {
  if (!json.containsKey(alan)) {
    throw FormatException('$yol.$alan alanı zorunludur.');
  }
  return json[alan];
}

String? _hucreKimliginiOku(
  Map<String, dynamic> json,
  String yol,
  bool zorunlu,
) {
  if (zorunlu) {
    return _metinOku(_zorunluAlanOku(json, 'id', yol), '$yol.id');
  }
  return _nullableMetinOku(json['id'], '$yol.id');
}

Map<String, dynamic> _opsiyonelHaritaOku(
  Map<String, dynamic> json,
  String alan,
  String yol,
) {
  if (!json.containsKey(alan)) {
    return <String, dynamic>{};
  }
  return _haritaOku(json[alan], '$yol.$alan');
}

List<dynamic> _listeOku(dynamic deger, String yol) {
  if (deger is List<dynamic>) {
    return deger;
  }
  throw _tipHatasi(yol, 'liste', deger);
}

int _intOku(dynamic deger, String yol) {
  if (deger is int) {
    return deger;
  }
  throw _tipHatasi(yol, 'tamsayı', deger);
}

int? _nullableIntOku(dynamic deger, String yol) {
  if (deger == null || deger is int) {
    return deger as int?;
  }
  throw _tipHatasi(yol, 'tamsayı veya null', deger);
}

String _metinOku(dynamic deger, String yol) {
  if (deger is String) {
    return deger;
  }
  throw _tipHatasi(yol, 'metin', deger);
}

String? _nullableMetinOku(dynamic deger, String yol) {
  if (deger == null || deger is String) {
    return deger as String?;
  }
  throw _tipHatasi(yol, 'metin veya null', deger);
}

String _cokSatirliMetniOku(dynamic deger, String yol) {
  if (deger is String) {
    return deger;
  }
  if (deger is List<dynamic>) {
    return deger.indexed.map((kayit) {
      final (indeks, satir) = kayit;
      return _metinOku(satir, '$yol[$indeks]');
    }).join();
  }
  throw _tipHatasi(yol, 'metin veya metin listesi', deger);
}

List<String> _metinListesiOku(dynamic deger, String yol) {
  final liste = _listeOku(deger, yol);
  return liste.indexed.map((kayit) {
    final (indeks, satir) = kayit;
    return _metinOku(satir, '$yol[$indeks]');
  }).toList();
}

FormatException _tipHatasi(String yol, String beklenen, dynamic deger) {
  final gelen = deger == null ? 'null' : deger.runtimeType.toString();
  return FormatException('$yol alanı $beklenen olmalı; gelen tür: $gelen.');
}
