import 'package:flutter/material.dart';
import 'state_aplikasi.fungsi.dart';
import 'monitor_ai.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS FUNGSI OTP & ESKALASI ADMIN: otp_admin.fungsi.dart
/// Mengirim OTP 6-Digit & Keputusan Admin langsung ke ESP32 (Bebas Log Ganda!)
/// ============================================================================
class OtpAdminFungsi {
  static Future<void> tombolVerifikasiOtp({
    required BuildContext context,
    required StateAplikasi state,
    required String inputOtp,
    required VoidCallback bersihkanInput,
  }) async {
    final kodeBersih = inputOtp.trim();
    if (kodeBersih.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Masukkan 6 digit angka OTP terlebih dahulu!'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final hasil = await state.kirimPerintahKeEsp32('CMD:OTP:$kodeBersih');
    if (hasil['busy'] == true) return;
    bersihkanInput();

    if (!context.mounted) return;

    if (hasil['otpResult'] == 'VALID') {
      state.menungguOtp = false;
      state.kodeOtpAktif = '';
      state.pintuTerbuka = true;
      state.segarkanTampilan();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ OTP BENAR! Solenoid Pintu Terbuka & Risiko Direset!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (hasil['otpResult'] == 'INVALID') {
      final int gagalKe = int.tryParse(hasil['failCount'].toString()) ?? 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ OTP SALAH di ESP32! (Gagal ke-$gagalKe)'),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
    } else if (hasil['cloud'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📡 Kode OTP ($kodeBersih) dikirim ke ESP32!'),
          backgroundColor: const Color(0xFF2563EB),
        ),
      );
    } else {
      final String pesanErr =
          (hasil['msg'] ?? 'Tap kartu RFID di ESP32 terlebih dahulu.').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ℹ️ $pesanErr'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
    }
  }

  static Future<void> tombolAdminSetujuBuka(
      BuildContext context, StateAplikasi state) async {
    state.menungguPersetujuanAdmin = false;
    state.pintuTerbuka = true;
    state.segarkanTampilan();

    final hasil = await state.kirimPerintahKeEsp32('CMD:APPROVE_OPEN');
    if (hasil['busy'] == true) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil['ok'] == true
            ? '✅ Akses Disetujui! Solenoid Pintu Terbuka & Profil Risiko Direset.'
            : '⚠️ Gagal menghubungi ESP32.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  static Future<void> tombolAdminTolakBlokir(
      BuildContext context, StateAplikasi state) async {
    state.menungguPersetujuanAdmin = false;
    state.segarkanTampilan();

    final hasil = await state.kirimPerintahKeEsp32('CMD:APPROVE_BLOCK');
    if (hasil['busy'] == true) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil['ok'] == true
            ? '❌ Permintaan buka pintu telah DITOLAK & DIBLOKIR di ESP32.'
            : '⚠️ Perintah blokir dikirim.'),
        backgroundColor: const Color(0xFFF43F5E),
      ),
    );
  }

  static void simulasiEskalasiLokal(StateAplikasi state) {
    state.sensorPintuPaksa = true;
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    state.menungguPersetujuanAdmin = true;
    state.segarkanTampilan();
  }
}
