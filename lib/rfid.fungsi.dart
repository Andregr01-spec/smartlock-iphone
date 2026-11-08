import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state_aplikasi.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS FUNGSI KARTU RFID: rfid.fungsi.dart
/// Menangani pindai UID baru, simpan kartu RFID baru, hapus kartu, & salin C++
/// ============================================================================
class RfidFungsi {
  /// 1. Fungsi Buat UID Hex 4-Byte Acak (Simulasi Pindai MFRC522)
  static String buatUidHexAcak() {
    final rnd = Random();
    String hexByte() =>
        (16 + rnd.nextInt(239)).toRadixString(16).toUpperCase().padLeft(2, '0');
    return '${hexByte()} ${hexByte()} ${hexByte()} ${hexByte()}';
  }

  /// 2. Fungsi Tombol Pindai Kartu dari Reader MFRC522
  static void tombolPindaiKartuBaru({
    required BuildContext context,
    required StateAplikasi state,
    required TextEditingController controllerUid,
  }) {
    final uidTerbaca = state.uidKartuAsingTerakhir.isNotEmpty ? state.uidKartuAsingTerakhir : buatUidHexAcak();
    controllerUid.text = uidTerbaca;
    state.tambahLogSerial(
        '[RFID ENROLL] Kartu baru terdeteksi pada MFRC522 -> UID: $uidTerbaca');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📡 Kartu Terdeteksi dari MFRC522: $uidTerbaca'),
        backgroundColor: const Color(0xFF6366F1),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 3. Fungsi Tombol Simpan & Daftarkan Kartu RFID Baru
  static void tombolSimpanKartuBaru({
    required BuildContext context,
    required StateAplikasi state,
    required TextEditingController controllerUid,
    required TextEditingController controllerNama,
    required String peranDipilih,
    required double jamHabitAwal,
  }) {
    final uid = controllerUid.text.trim().toUpperCase();
    final nama = controllerNama.text.trim();

    if (uid.isEmpty || nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon isi UID Kartu dan Nama Pemilik terlebih dahulu!'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final sudahAda =
        state.daftarKartu.any((u) => u.uid.toUpperCase() == uid);
    if (sudahAda) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Kartu dengan UID $uid sudah terdaftar!'),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
      return;
    }

    state.daftarKartu.add(
      PenggunaRfid(
        uid: uid,
        nama: nama,
        peran: peranDipilih,
        jamKebiasaan: jamHabitAwal,
      ),
    );

    state.daftarLog.insert(
      0,
      ItemLogAkses(
        waktu: state.waktuSekarangStr(),
        uid: uid,
        nama: nama,
        aksi: 'Registrasi Kartu RFID Baru',
        status: 'Kartu Terdaftar',
        skorAi: '0.00%',
        kategori: 'AMAN',
      ),
    );

    state.tambahLogSerial(
      '[DATABASE] Kartu RFID baru didaftarkan: $nama ($uid) - Habit: $jamHabitAwal:00',
    );
    state.kirimPerintahKeEsp32('CMD:ADDCARD:$uid|$nama');
    state.kirimPesanTelegram('💳 *Kartu Baru Didaftarkan via Aplikasi Flutter*\nNama: *$nama*\nUID: `$uid`');
    state.kirimLogKeServerNtfy(
      uid: uid,
      nama: nama,
      aksi: 'Registrasi Kartu RFID via APK',
      status: 'Kartu Terdaftar',
    );

    controllerUid.clear();
    controllerNama.clear();
    state.segarkanTampilan();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Kartu $nama ($uid) berhasil disimpan & dikirim ke ESP32!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  /// 4. Fungsi Tombol Hapus Kartu RFID
  static void tombolHapusKartu({
    required BuildContext context,
    required StateAplikasi state,
    required int index,
  }) {
    if (state.daftarKartu.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Minimal harus ada 1 kartu Admin terdaftar!'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }
    final dihapus = state.daftarKartu.removeAt(index);
    state.tambahLogSerial(
        '[DATABASE] Kartu ${dihapus.nama} (${dihapus.uid}) dihapus.');
    state.segarkanTampilan();
  }

  /// 5. Fungsi Buat & Salin Snippet Array C++ AUTHORIZED_CARDS
  static String buatKodeCppAuthorizedCards(StateAplikasi state) {
    final buffer = StringBuffer();
    buffer.writeln('const AuthorizedUser AUTHORIZED_CARDS[] = {');
    for (int i = 0; i < state.daftarKartu.length; i++) {
      final u = state.daftarKartu[i];
      final koma = i < state.daftarKartu.length - 1 ? ',' : '';
      buffer.writeln('  {"${u.uid}", "${u.nama}"}$koma');
    }
    buffer.writeln('};');
    buffer.write('const int TOTAL_AUTHORIZED = ${state.daftarKartu.length};');
    return buffer.toString();
  }

  static void tombolSalinKodeCpp(BuildContext context, StateAplikasi state) {
    final kode = buatKodeCppAuthorizedCards(state);
    Clipboard.setData(ClipboardData(text: kode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Kode C++ AUTHORIZED_CARDS berhasil disalin!'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }
}
