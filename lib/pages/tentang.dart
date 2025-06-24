import 'package:flutter/material.dart';

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tentang IPPNU',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Konten Utama
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/ippnu.png', // ganti sesuai lokasi file gambar
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visi
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: const Text(
                          'Visi IPPNU',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: const Text(
                          'Terbentuknya kesempurnaan Pelajar Putri Indonesia yang '
                          'bertakwa, berakhlakul karimah, berilmu, dan '
                          'berwawasan kebangsaan.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Misi
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: const Text(
                          'Misi IPPNU',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: const Text(
                          '1. Membangun kader NU yang berkualitas, berakhlakul karimah, '
                          'bersikap demokratis dalam kehidupan bermasyarakat, berbangsa dan bernegara.\n'
                          '2. Mengembangkan wacana dan kualitas sumber daya kader menuju terciptanya kesetaraan gender.\n'
                          '3. Membentuk kader yang dinamis, kreatif, dan inovatif.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
