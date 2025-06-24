import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportMasukPage extends StatefulWidget {
  const ExportMasukPage({Key? key}) : super(key: key);

  @override
  State<ExportMasukPage> createState() => _ExportMasukPageState();
}

class _ExportMasukPageState extends State<ExportMasukPage> {
  List<Map<String, dynamic>> _allData = [];
  String _selectedWaktu = 'Semua';

  final List<String> waktuList = [
    'Semua',
    'Mingguan',
    'Bulanan',
    'Tahunan',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
      snapshot =
          await FirebaseFirestore.instance.collectionGroup('surat_masuk').get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('surat_masuk')
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
    print("Sekarang: $now");

    if (_selectedWaktu == 'Semua') return data;

    return data.where((item) {
      Timestamp? ts = item['tanggal_surat_masuk'] ?? item['tanggal_surat'];
      if (ts is! Timestamp) return false;
      DateTime tgl = ts.toDate();

      print("Item tgl: $tgl"); // Tambahan debug

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
        default:
          return true;
      }
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
        if (item['tanggal_surat_masuk'] is Timestamp) {
          DateTime date = (item['tanggal_surat_masuk'] as Timestamp).toDate();
          tanggalSurat =
              '${date.day.toString().padLeft(2, '0')} ${_getNamaBulan(date.month)} ${date.year}';
        } else {
          tanggalSurat = item['tanggal_surat_masuk']?.toString() ?? '';
        }

        tableData.add([
          '$index',
          tanggalSurat,
          item['no_surat'] ?? '',
          item['perihal'] ?? '',
          item['pengirim'] ?? '',
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
              pw.Text('Laporan Arsip Surat Masuk',
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'No',
                  'Tanggal Masuk',
                  'No Surat',
                  'Perihal',
                  'Pengirim',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Arsip Masuk',
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  await _loadData();
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
