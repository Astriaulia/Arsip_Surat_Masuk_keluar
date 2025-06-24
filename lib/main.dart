// main.dart
import 'package:arsip_surat/pages/arsip%20_masuk.dart';
import 'package:arsip_surat/pages/dasbord.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:arsip_surat/pages/sign_in.dart';

import 'package:arsip_surat/pages/arsip_keluar.dart';
import 'package:arsip_surat/pages/export_masuk.dart';
import 'package:arsip_surat/pages/export_keluar.dart';
import 'package:arsip_surat/pages/tentang.dart';
import 'package:syncfusion_flutter_core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SyncfusionLicense.registerLicense(
      '737399'); // Bisa daftar gratis di website Syncfusion

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arsip Surat',
      debugShowCheckedModeBanner: false,
      initialRoute: '/sign_in',
      routes: {
        '/sign_in': (context) => const SignInPage(),
        '/dashboard': (context) => const Dashboard(),
        '/arsipmasuk': (context) => const ArsipMasuk(),
        '/arsipkeluar': (context) => const ArsipKeluar(),
        '/exportmasuk': (context) => const ExportMasukPage(),
        '/exportkeluar': (context) => const ExportKeluarPage(),
        '/tentang': (context) => const TentangPage(),

        // ✅ Tambahkan ini
        '/admin': (context) => const Dashboard(),
        '/ketua': (context) => const Dashboard(),
        '/user': (context) => const Dashboard(),
      },
    );
  }
}
