import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'rfid.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS TAMPILAN KARTU RFID: rfid.tampilan.dart
/// Menyusun tampilan halaman Pendaftaran Kartu RFID Baru & Daftar Kartu Sah
/// Seluruh aksi tombol memanggil fungsi di RfidFungsi (rfid.fungsi.dart)
/// ============================================================================
class RfidTampilan extends StatefulWidget {
  final StateAplikasi state;

  const RfidTampilan({super.key, required this.state});

  @override
  State<RfidTampilan> createState() => _RfidTampilanState();
}

class _RfidTampilanState extends State<RfidTampilan> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  String _peranDipilih = 'Anggota Keluarga';
  double _jamHabit = 12.0;

  @override
  void dispose() {
    _uidController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. KOTAK PINDAI & FORM TAMBAH KARTU RFID BARU
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ENROLLMENT MODUL MFRC522',
                  style: TextStyle(
                    color: TemaWarna.indigoUtama,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tempat Memasukkan Kartu RFID Baru',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Kotak Pindai Otomatis
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TemaWarna.bgInput,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: TemaWarna.indigoUtama.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contactless_rounded,
                        size: 42,
                        color: TemaWarna.indigoUtama,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mode Pindai Kartu MFRC522 Siap',
                        style: TextStyle(
                          color: TemaWarna.teksPutih,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tempelkan kartu baru ke reader RFID atau klik tombol di bawah untuk mengambil UID otomatis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: TemaWarna.teksAbu, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => RfidFungsi.tombolPindaiKartuBaru(
                          context: context,
                          state: state,
                          controllerUid: _uidController,
                        ),
                        icon: const Icon(Icons.nfc_rounded, size: 18),
                        label: const Text('Pindai UID dari Reader RFID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaWarna.indigoUtama,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Input UID Kartu
                const Text(
                  'UID Kartu RFID (Format Hex 4-Byte)',
                  style: TextStyle(
                      color: TemaWarna.teksAbu,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _uidController,
                  style: const TextStyle(
                    color: TemaWarna.teksPutih,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: A4 9B 3C 11',
                    filled: true,
                    fillColor: TemaWarna.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Input Nama Lengkap
                const Text(
                  'Nama Lengkap Pemilik Kartu',
                  style: TextStyle(
                      color: TemaWarna.teksAbu,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _namaController,
                  style: const TextStyle(color: TemaWarna.teksPutih),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama pemilik kartu...',
                    filled: true,
                    fillColor: TemaWarna.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Pilihan Peran & Jam Kebiasaan Awal
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _peranDipilih,
                        dropdownColor: TemaWarna.bgKartu,
                        decoration: InputDecoration(
                          labelText: 'Peran Akses',
                          filled: true,
                          fillColor: TemaWarna.bgInput,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Admin Utama', child: Text('Admin Utama')),
                          DropdownMenuItem(
                              value: 'Anggota Keluarga',
                              child: Text('Anggota Keluarga')),
                          DropdownMenuItem(
                              value: 'Tamu Terdaftar',
                              child: Text('Tamu Terdaftar')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _peranDipilih = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam Habit (M1): ${_jamHabit.toStringAsFixed(1)}:00',
                            style: const TextStyle(
                                color: TemaWarna.teksAbu, fontSize: 12),
                          ),
                          Slider(
                            value: _jamHabit,
                            min: 0,
                            max: 23,
                            divisions: 46,
                            activeColor: TemaWarna.cyanAksen,
                            onChanged: (v) => setState(() => _jamHabit = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tombol Simpan Kartu Baru
                ElevatedButton.icon(
                  onPressed: () => RfidFungsi.tombolSimpanKartuBaru(
                    context: context,
                    state: state,
                    controllerUid: _uidController,
                    controllerNama: _namaController,
                    peranDipilih: _peranDipilih,
                    jamHabitAwal: _jamHabit,
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan & Daftarkan Kartu RFID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaWarna.hijauAman,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. DAFTAR KARTU TERDAFTAR (AUTHORIZED_CARDS)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Kartu Sah Terdaftar',
                      style: TextStyle(
                        color: TemaWarna.teksPutih,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TemaWarna.badgeStatus(
                      teks: '${state.daftarKartu.length} Kartu',
                      warna: TemaWarna.indigoUtama,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(state.daftarKartu.length, (idx) {
                  final u = state.daftarKartu[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TemaWarna.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TemaWarna.garisBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${u.nama} (${u.peran})',
                              style: const TextStyle(
                                color: TemaWarna.teksPutih,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'UID: ${u.uid} • Habit: ${u.jamKebiasaan.toStringAsFixed(1)}:00',
                              style: const TextStyle(
                                color: TemaWarna.cyanAksen,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Gagal OTP: ${u.gagalOtp10m} • Contagion M3: ${u.kartuAsingMenular10m}',
                              style: const TextStyle(
                                color: TemaWarna.teksAbu,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => RfidFungsi.tombolHapusKartu(
                            context: context,
                            state: state,
                            index: idx,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: TemaWarna.merahBahaya),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // Preview Kode C++ AUTHORIZED_CARDS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TemaWarna.garisBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Snippet Array C++ (AUTHORIZED_CARDS):',
                            style: TextStyle(
                                color: TemaWarna.teksAbu, fontSize: 11),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                RfidFungsi.tombolSalinKodeCpp(context, state),
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Salin C++',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      Text(
                        RfidFungsi.buatKodeCppAuthorizedCards(state),
                        style: const TextStyle(
                          color: TemaWarna.hijauAman,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
