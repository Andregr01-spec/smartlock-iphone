import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'state_aplikasi.fungsi.dart';
import 'monitor_ai.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS FUNGSI TOMBOL BERANDA: beranda.fungsi.dart
/// Eksekusi Buka Pintu Solenoid Tunggal (Anti Double-Click) & Sinkronisasi ESP32
/// ============================================================================
class BerandaFungsi {
  /// 1. Fungsi Tombol Buka Kunci Pintu Solenoid (1 Klik = 1 Kali Buka, Instan!)
  static Future<void> tombolBukaPintuManual(
      BuildContext context, StateAplikasi state) async {
    if (state.pintuTerbuka) return;

    state.pintuTerbuka = true;
    state.dibukaOlehSistem = true;
    state.segarkanTampilan();

    final hasil = await state.kirimPerintahKeEsp32('CMD:UNLOCK');
    if (hasil['busy'] == true) return;

    if (!state.terhubungLokalLangsung) {
      state.daftarLog.insert(
        0,
        ItemLogAkses(
          waktu: state.waktuSekarangStr(),
          uid: '-',
          nama: 'APK Flutter',
          aksi: 'Buka Pintu Manual',
          status: 'Pintu Terbuka (TP)',
          skorAi: '${state.skorAkhirAi.toStringAsFixed(2)}%',
          kategori: 'AMAN',
        ),
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔓 Solenoid Terbuka selama ${(state.durasiRelayMs / 1000).toStringAsFixed(1)} detik!',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Timer(Duration(milliseconds: state.durasiRelayMs), () {
      state.pintuTerbuka = false;
      state.dibukaOlehSistem = false;
      state.segarkanTampilan();
    });
  }

  /// 2. Fungsi Tombol Simulasi Congkel Pintu (REED_PIN)
  static void tombolSimulasiPintuPaksa(
      BuildContext context, StateAplikasi state) {
    state.sensorPintuPaksa = !state.sensorPintuPaksa;
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    state.segarkanTampilan();
  }

  /// 3. Fungsi Tombol Simulasi Buka Paksa Boks Panel (TAMPER_PIN)
  static void tombolSimulasiTamperBoks(
      BuildContext context, StateAplikasi state) {
    state.sensorTamperBoks = !state.sensorTamperBoks;
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    state.segarkanTampilan();
  }

  /// 4. Fungsi Tombol Reset Latch Sensor Fisik
  static Future<void> tombolResetSensorFisik(
      BuildContext context, StateAplikasi state) async {
    state.sensorPintuPaksa = false;
    state.sensorTamperBoks = false;
    await state.kirimPerintahKeEsp32('CMD:RESET_AI');
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    state.segarkanTampilan();
  }

  /// 5. Fungsi Tombol Reset Profil Risiko Adaptif (M5 HITL)
  static Future<void> tombolResetSemuaProfilRisiko(
      BuildContext context, StateAplikasi state) async {
    await state.kirimPerintahKeEsp32('CMD:RESET_AI');

    for (final u in state.daftarKartu) {
      u.percobaan10m = 0;
      u.kartuAsingMenular10m = 0;
      u.gagalOtp10m = 0;
      u.gagalBeruntun = 0;
    }
    state.totalTapKartuAsing = 0;
    state.sensorPintuPaksa = false;
    state.sensorTamperBoks = false;
    state.skorPerilakuM1 = 0.0;
    state.skorAkhirAi = 0.0;
    state.levelKeputusanFuzzy = 0;
    state.hentikanTimerLockdown();
    state.segarkanTampilan();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Profil Risiko & Sensor Fisik di ESP32 berhasil di-reset!'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 6. Fungsi Simulasi Tap Kartu Sah
  static void tombolTapKartuSah(
    BuildContext context,
    StateAplikasi state,
    PenggunaRfid user,
  ) {
    user.percobaan10m++;
    user.detikSejakTerakhir = 5.0;
    state.uidSesiAktif = user.uid;
    state.namaSesiAktif = user.nama;
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, user);

    if (state.levelKeputusanFuzzy >= 1) {
      state.menungguPersetujuanAdmin = true;
      state.menungguOtp = false;
    } else {
      state.menungguOtp = true;
      state.menungguPersetujuanAdmin = false;
      if (state.kodeOtpAktif.isEmpty) {
        state.kodeOtpAktif = (100000 + Random().nextInt(900000)).toString();
      }
    }
    state.segarkanTampilan();
  }

  /// 7. Fungsi Simulasi Tap Kartu Asing
  static void tombolTapKartuAsing(BuildContext context, StateAplikasi state) {
    state.totalTapKartuAsing++;
    if (state.aktifM3Contagion) {
      for (final u in state.daftarKartu) {
        u.kartuAsingMenular10m++;
        u.gagalBeruntun++;
        u.detikSejakTerakhir = 2.0;
      }
    }
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    state.segarkanTampilan();
  }
}
