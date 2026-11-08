import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state_aplikasi.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS FUNGSI RIWAYAT LOG: riwayat_log.fungsi.dart
/// Menangani filter log, salin CSV, dan bersihkan riwayat log di ESP32 & APK
/// ============================================================================
class RiwayatLogFungsi {
  static List<ItemLogAkses> ambilLogTerfilter(
      StateAplikasi state, String kategoriFilter) {
    if (kategoriFilter == 'ALL') return state.daftarLog;
    return state.daftarLog
        .where((item) => item.kategori == kategoriFilter)
        .toList();
  }

  static void tombolSalinCsvLog(BuildContext context, StateAplikasi state) {
    final buffer = StringBuffer();
    buffer.writeln('Waktu,UID,Nama,Aksi,Status,Skor_AI');
    for (final l in state.daftarLog) {
      buffer.writeln(
          '"${l.waktu}","${l.uid}","${l.nama}","${l.aksi}","${l.status}","${l.skorAi}"');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            '📥 Data CSV Pengujian berhasil disalin! Siap ditempel ke Excel/Laporan.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  static Future<void> tombolBersihkanLog(
      BuildContext context, StateAplikasi state) async {
    state.daftarLog.clear();
    await state.kirimPerintahKeEsp32('CMD:CLEAR_LOGS');
    state.segarkanTampilan();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 Riwayat log di APK & ESP32 telah dibersihkan untuk sesi uji baru!'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }
}
