import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportKeluarPage extends StatefulWidget {
  const ExportKeluarPage({super.key});

  @override
  State<ExportKeluarPage> createState() => _ExportKeluarPageState();
}

class _ExportKeluarPageState extends State<ExportKeluarPage> {
  String _selectedWaktu = 'Semua';
  List<Map<String, dynamic>> _allData = [];

  final List<String> waktuList = [
    'Semua',
    'Mingguan',
    'Bulanan',
    'Tahunan',
  ];

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = userDoc.data()?['role'] ?? 'user';

    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (role == 'admin' || role == 'ketua') {
      snapshot = await FirebaseFirestore.instance
          .collectionGroup('surat_keluar')
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('surat_keluar')
          .get();
    }

    final List<Map<String, dynamic>> tempList = [];
    for (var doc in snapshot.docs) {
      final item = doc.data();
      item['id'] = doc.id;
      tempList.add(item);
    }

    setState(() {
      _allData = tempList;
    });
  }

  List<Map<String, dynamic>> _filterByWaktu(List<Map<String, dynamic>> data) {
    final now = DateTime.now();

    if (_selectedWaktu == 'Semua') return data;

    return data.where((item) {
      if (item['tanggal_surat'] is! Timestamp) return false;
      DateTime tgl = (item['tanggal_surat'] as Timestamp).toDate();

      switch (_selectedWaktu) {
        case 'Mingguan':
          DateTime mingguAwal = now.subtract(Duration(days: now.weekday - 1));
          DateTime mingguAkhir = mingguAwal.add(const Duration(days: 6));
          return tgl.isAfter(mingguAwal.subtract(const Duration(days: 1))) &&
              tgl.isBefore(mingguAkhir.add(const Duration(days: 1)));
        case 'Bulanan':
          return tgl.year == now.year && tgl.month == now.month;
        case 'Tahunan':
          return tgl.year == now.year;
      }
      return true;
    }).toList();
  }

  Future<void> exportPDF(BuildContext context) async {
    try {
      if (_allData.isEmpty) {
        await _loadData();
      }

      final filteredData = _filterByWaktu(_allData);

      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data sesuai filter waktu')),
        );
        return;
      }

      final pdf = pw.Document();
      final List<List<String>> tableData = [];
      int index = 1;

      for (final item in filteredData) {
        String tanggalSurat = '';
        if (item['tanggal_surat'] is Timestamp) {
          DateTime date = (item['tanggal_surat'] as Timestamp).toDate();
          tanggalSurat =
              '${date.day.toString().padLeft(2, '0')} ${_getNamaBulan(date.month)} ${date.year}';
        } else {
          tanggalSurat = item['tanggal_surat']?.toString() ?? '';
        }

        tableData.add([
          '$index',
          tanggalSurat,
          item['no_surat'] ?? '',
          item['perihal'] ?? '',
          item['tujuan'] ?? '',
          item['lampiran'] ?? '',
          item['status'] ?? '',
        ]);
        index++;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Arsip Surat Keluar',
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'No',
                  'Tanggal Surat',
                  'No Surat',
                  'Perihal',
                  'Tujuan',
                  'Lampiran',
                  'Status',
                ],
                data: tableData,
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Error saat export PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e')),
      );
    }
  }

  String _getNamaBulan(int month) {
    const bulanList = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return bulanList[month - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Arsip Keluar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.amber,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedWaktu,
              decoration: const InputDecoration(
                labelText: 'Filter Waktu',
                border: OutlineInputBorder(),
              ),
              items: waktuList
                  .map((waktu) =>
                      DropdownMenuItem(value: waktu, child: Text(waktu)))
                  .toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    _selectedWaktu = value;
                  });
                  await _loadData(); // Perbarui data saat filter berubah
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => exportPDF(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download ke PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
