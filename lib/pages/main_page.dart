import 'package:arsip_surat/pages/arsip%20_masuk.dart';
import 'package:arsip_surat/pages/arsip_keluar.dart';
import 'package:arsip_surat/pages/dasbord.dart';
import 'package:arsip_surat/pages/export_masuk.dart';
import 'package:arsip_surat/pages/export_keluar.dart';
import 'package:arsip_surat/pages/tentang.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late String role;
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    role = ModalRoute.of(context)?.settings.arguments as String? ?? 'user';
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/sign_in', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[];

    if (role == 'admin' || role == 'user') {
      pages
          .addAll([const Dashboard(), const ArsipMasuk(), const ArsipKeluar()]);
    }

    if (role == 'admin' || role == 'ketua') {
      pages.addAll([const ExportMasukPage(), const ExportKeluarPage()]);
    }

    pages.addAll([const TentangPage()]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arsip Surat'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          if (role == 'admin' || role == 'user')
            const BottomNavigationBarItem(
                icon: Icon(Icons.download), label: 'Masuk'),
          if (role == 'admin' || role == 'user')
            const BottomNavigationBarItem(
                icon: Icon(Icons.upload), label: 'Keluar'),
          if (role == 'admin' || role == 'ketua')
            const BottomNavigationBarItem(
                icon: Icon(Icons.picture_as_pdf), label: 'Export Masuk'),
          if (role == 'admin' || role == 'ketua')
            const BottomNavigationBarItem(
                icon: Icon(Icons.picture_as_pdf_outlined),
                label: 'Export Keluar'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.info), label: 'Tentang'),
        ],
      ),
    );
  }
}
