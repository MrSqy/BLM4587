import 'package:flutter/material.dart';

import '../rotalar.dart';

// Giriş yapan kullanıcının bilgileri 3. haftada (JWT ile giriş) buraya gelecek.
class ProfilEkrani extends StatelessWidget {
  const ProfilEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        const Center(
          child: CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('Misafir', style: Theme.of(context).textTheme.titleLarge),
        ),
        const Center(child: Text('Henüz giriş yapılmadı')),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.login),
          title: const Text('Giriş yap'),
          subtitle: const Text('Demo giriş formu'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, Rotalar.giris),
        ),
        ListTile(
          leading: const Icon(Icons.person_add_outlined),
          title: const Text('Kayıt ol'),
          subtitle: const Text('Demo kayıt formu'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, Rotalar.kayit),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Hakkında'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, Rotalar.hakkinda),
        ),
      ],
    );
  }
}
