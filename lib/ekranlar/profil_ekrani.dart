import 'package:flutter/material.dart';
import '../rotalar.dart';
import '../servisler/api_istemcisi.dart';
import '../servisler/oturum_servisi.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});
  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  bool _bekliyor = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: oturumServisi,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const Icon(Icons.person_outline, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            oturumServisi.adSoyad,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            oturumServisi.girisYapildi
                ? oturumServisi.eposta
                : 'Henüz giriş yapılmadı',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        if (!oturumServisi.girisYapildi) ...[
          const Text(
            'Her eğitimin ilk dersini ücretsiz keşfet. Tüm derslere devam etmek için hesabınla giriş yap.',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, Rotalar.giris),
            child: const Text('Giriş yap'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, Rotalar.kayit),
            child: const Text('Kayıt ol'),
          ),
        ] else
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(_bekliyor ? 'Çıkış yapılıyor…' : 'Çıkış yap'),
              onTap: _bekliyor
                  ? null
                  : () async {
                      setState(() => _bekliyor = true);
                      try {
                        await oturumServisi.cikis();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e is ApiHatasi
                                    ? e.mesaj
                                    : 'Çıkış tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _bekliyor = false);
                      }
                    },
            ),
          ),
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('Hakkında'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, Rotalar.hakkinda),
        ),
      ],
    ),
  );
}
