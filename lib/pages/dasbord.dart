import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        role = snapshot.data()?['role'] ?? 'user';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'label': 'Arsip Masuk',
        'icon': Icons.download,
        'route': '/arsipmasuk',
        'show': role == 'admin' || role == 'user',
      },
      {
        'label': 'Arsip Keluar',
        'icon': Icons.upload,
        'route': '/arsipkeluar',
        'show': role == 'admin' || role == 'user',
      },
      {
        'label': 'Laporan Arsip Masuk',
        'icon': Icons.picture_as_pdf,
        'route': '/exportmasuk',
        'show': role == 'admin' || role == 'ketua',
      },
      {
        'label': 'Laporan Arsip Keluar',
        'icon': Icons.picture_as_pdf_outlined,
        'route': '/exportkeluar',
        'show': role == 'admin' || role == 'ketua',
      },
      {
        'label': 'Tentang',
        'icon': Icons.info,
        'route': '/tentang',
        'show': true,
      },
      {
        'label': 'Log Out',
        'icon': Icons.logout,
        'route': '/sign_in',
        'show': true,
      },
    ];

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visibleItems =
        menuItems.where((item) => item['show'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: visibleItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 20,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return GestureDetector(
                  onTap: () async {
                    if (item['label'] == 'Log Out') {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Konfirmasi Logout'),
                          content:
                              const Text('Apakah kamu yakin ingin keluar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          item['route'] as String,
                          (route) => false,
                        );
                      }
                    } else {
                      Navigator.pushNamed(context, item['route'] as String);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber[600],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item['icon'] as IconData,
                            size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          item['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
