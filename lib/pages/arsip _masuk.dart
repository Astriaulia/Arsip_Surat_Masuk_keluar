import 'package:arsip_surat/pages/liat_arsip_masuk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ArsipMasuk extends StatefulWidget {
  const ArsipMasuk({super.key});

  @override
  State<ArsipMasuk> createState() => _ArsipMasukState();
}

class _ArsipMasukState extends State<ArsipMasuk> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<DocumentSnapshot> _suratMasuk = [];

  @override
  void initState() {
    super.initState();
    _loadSuratMasuk();
  }

  void _loadSuratMasuk() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('surat_masuk')
          .orderBy('created_at', descending: true)
          .get();

      print('Dokumen ditemukan: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('Surat Masuk: ${doc.data()}');
      }

      setState(() {
        _suratMasuk = snapshot.docs;
      });
    }
  }

  void _addOrEditSuratMasuk({DocumentSnapshot? existingSurat}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isEdit = existingSurat != null;
    final data = existingSurat?.data() as Map<String, dynamic>? ?? {};

    final pengirimController =
        TextEditingController(text: data['pengirim'] ?? '');

    final tanggalSuratController = TextEditingController(
        text: (data['tanggal_surat'] != null &&
                data['tanggal_surat'] is Timestamp)
            ? (data['tanggal_surat'] as Timestamp)
                .toDate()
                .toString()
                .split(' ')[0]
            : data['tanggal_surat'] ?? '');
    final tanggalSuratMasukController = TextEditingController(
        text: (data['tanggal_surat_masuk'] != null &&
                data['tanggal_surat_masuk'] is Timestamp)
            ? (data['tanggal_surat_masuk'] as Timestamp)
                .toDate()
                .toString()
                .split(' ')[0]
            : data['tanggal_surat_masuk'] ?? '');
    final perihalController =
        TextEditingController(text: data['perihal'] ?? '');
    final untukController = TextEditingController(text: data['untuk'] ?? '');
    final kategoriController =
        TextEditingController(text: data['lampiran'] ?? '');
    final statusController = TextEditingController(text: data['status'] ?? '');
    final noSuratController =
        TextEditingController(text: data['no_surat'] ?? '');

    PlatformFile? pickedFile;
    UploadTask? uploadTask;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.amber[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(isEdit ? 'Edit Surat Masuk' : 'Tambah Surat Masuk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: noSuratController,
                  decoration: const InputDecoration(labelText: 'No Surat')),
              TextField(
                  controller: pengirimController,
                  decoration: const InputDecoration(labelText: 'Pengirim')),
              TextField(
                  controller: untukController,
                  decoration: const InputDecoration(labelText: 'untuk')),
              TextField(
                  controller: tanggalSuratController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                      labelText: 'Tanggal Surat (yyyy-MM-dd)')),
              TextField(
                  controller: tanggalSuratMasukController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                      labelText: 'Tanggal Surat Masuk (yyyy-MM-dd)')),
              TextField(
                  controller: perihalController,
                  decoration: const InputDecoration(labelText: 'Perihal')),
              TextField(
                  controller: kategoriController,
                  decoration: const InputDecoration(labelText: 'Lampiran')),
              TextField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Isi Surat')),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null) {
                    pickedFile = result.files.first;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('File dipilih: ${pickedFile!.name}')),
                    );
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Pilih File'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if ([
                noSuratController,
                pengirimController,
                tanggalSuratController,
                tanggalSuratMasukController,
                perihalController,
                untukController,
                kategoriController,
                statusController
              ].any((c) => c.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field harus diisi')),
                );
                return;
              }

              DateTime? tanggalSurat;
              DateTime? tanggalSuratMasuk;

              try {
                tanggalSurat = DateTime.parse(tanggalSuratController.text);
                tanggalSuratMasuk =
                    DateTime.parse(tanggalSuratMasukController.text);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Format tanggal tidak valid (yyyy-MM-dd)')),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              String? fileUrl = data['file_url'];
              if (pickedFile != null) {
                try {
                  final ref = _storage.ref().child(
                        'surat_masuk/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}',
                      );
                  uploadTask = ref.putFile(File(pickedFile!.path!));
                  final snapshot = await uploadTask!.whenComplete(() {});
                  fileUrl = await snapshot.ref.getDownloadURL();
                } catch (e) {
                  Navigator.pop(context); // Tutup loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload file gagal.')),
                  );
                  return;
                }
              }

              final docId = isEdit
                  ? existingSurat!.id
                  : 'M-${DateTime.now().millisecondsSinceEpoch}';

              final docRef = _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('surat_masuk')
                  .doc(docId);

              try {
                await docRef.set({
                  'id': docId,
                  'no_surat': noSuratController.text,
                  'pengirim': pengirimController.text,
                  'untuk': untukController.text,
                  'tanggal_surat': Timestamp.fromDate(tanggalSurat),
                  'tanggal_surat_masuk': Timestamp.fromDate(tanggalSuratMasuk),
                  'perihal': perihalController.text,
                  'lampiran': kategoriController.text,
                  'status': statusController.text,
                  'file_url': fileUrl,
                  'created_at': isEdit
                      ? (data['created_at'] ?? FieldValue.serverTimestamp())
                      : FieldValue.serverTimestamp(),
                  'created_by': user.email,
                });

                Navigator.pop(context); // Tutup loading
                Navigator.pop(context); // Tutup form
                _loadSuratMasuk(); // Refresh data
              } catch (e) {
                Navigator.pop(context); // Tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menyimpan data.')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteSuratMasuk(DocumentSnapshot surat) async {
    await surat.reference.delete();
    _loadSuratMasuk();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surat masuk berhasil dihapus')));
  }

  void _showDetailDialog(DocumentSnapshot surat) {
    final data = surat.data() as Map<String, dynamic>;
    final tanggalSurat = data['tanggal_surat'] is Timestamp
        ? (data['tanggal_surat'] as Timestamp).toDate().toString().split(' ')[0]
        : data['tanggal_surat'].toString();
    final tanggalMasuk = data['tanggal_surat_masuk'] is Timestamp
        ? (data['tanggal_surat_masuk'] as Timestamp)
            .toDate()
            .toString()
            .split(' ')[0]
        : data['tanggal_surat_masuk'].toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Surat Masuk'),
        backgroundColor: Colors.amber[50],
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No Surat: ${data['no_surat']}'),
              Text('Pengirim: ${data['pengirim']}'),
              Text('Untuk: ${data['untuk']}'),
              Text('Tanggal Surat: $tanggalSurat'),
              Text('Tanggal Masuk: $tanggalMasuk'),
              Text('Perihal: ${data['perihal']}'),
              Text('Lampiran: ${data['lampiran']}'),
              Text('Isi Surat: ${data['status']}'),
              if (data['file_url'] != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PdfViewerPage(pdfUrl: data['file_url']),
                      ),
                    );
                  },
                  child: const Text('Lihat Lampiran'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
          TextButton(
              onPressed: () => _addOrEditSuratMasuk(existingSurat: surat),
              child: const Text('Edit')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Arsip Surat Masuk',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                TextEditingController searchController =
                    TextEditingController();
                TextEditingController dateController = TextEditingController();
                String selectedKategori = 'Pengirim';

                showDialog(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setStateDialog) => AlertDialog(
                      title: const Text('Cari Surat Masuk'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedKategori,
                            items: ['Pengirim', 'Perihal', 'Tanggal']
                                .map((kategori) {
                              return DropdownMenuItem(
                                value: kategori,
                                child: Text(kategori),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedKategori = value!;
                                searchController.clear();
                                dateController.clear();
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Kategori Pencarian',
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (selectedKategori == 'Tanggal')
                            TextField(
                              controller: dateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Pilih Tanggal Surat',
                              ),
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    dateController.text = picked
                                        .toIso8601String()
                                        .substring(0, 10);
                                  });
                                }
                              },
                            )
                          else
                            TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                labelText: 'Cari berdasarkan $selectedKategori',
                              ),
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              final value = selectedKategori == 'Tanggal'
                                  ? dateController.text.trim()
                                  : searchController.text.trim().toLowerCase();

                              if (value.isEmpty) {
                                _loadSuratMasuk();
                              } else {
                                _suratMasuk = _suratMasuk.where((surat) {
                                  final data =
                                      surat.data() as Map<String, dynamic>;
                                  if (selectedKategori == 'Pengirim') {
                                    final pengirim =
                                        data['pengirim']?.toLowerCase() ?? '';
                                    return pengirim.contains(value);
                                  } else if (selectedKategori == 'Perihal') {
                                    final perihal =
                                        data['perihal']?.toLowerCase() ?? '';
                                    return perihal.contains(value);
                                  } else if (selectedKategori == 'Tanggal') {
                                    final timestamp = data['tanggal_surat'];
                                    if (timestamp is Timestamp) {
                                      final tanggal = timestamp
                                          .toDate()
                                          .toIso8601String()
                                          .substring(0, 10);
                                      return tanggal == value;
                                    }
                                  }
                                  return false;
                                }).toList();
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Cari'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _suratMasuk.length,
        itemBuilder: (context, index) {
          final surat = _suratMasuk[index];
          final data = surat.data() as Map<String, dynamic>;
          final tanggal = data['tanggal_surat'] is Timestamp
              ? (data['tanggal_surat'] as Timestamp)
                  .toDate()
                  .toString()
                  .split(' ')[0]
              : data['tanggal_surat'].toString();
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(data['perihal'] ?? data['pengirim'] ?? ''),
                subtitle:
                    Text('Pengirim: ${data['pengirim']} | Tanggal: $tanggal'),
                onTap: () => _showDetailDialog(surat),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _addOrEditSuratMasuk(existingSurat: surat)),
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteSuratMasuk(surat)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () => _addOrEditSuratMasuk(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
