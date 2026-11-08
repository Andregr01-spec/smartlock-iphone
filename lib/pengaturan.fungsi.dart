import 'package:flutter/material.dart';
import 'state_aplikasi.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS FUNGSI PENGATURAN PERANGKAT: pengaturan.fungsi.dart
/// Menangani Koneksi IP ESP32, Simpan WiFi 1 & 2 beserta Password-nya,
/// serta Durasi Buka Solenoid (ms) & Cooldown Lockdown (ms) tanpa pembatasan sempit!
/// ============================================================================
class PengaturanFungsi {
  /// Ekstrak angka murni walaupun user mengetik "10000ms" atau "100 ms"
  static int ekstrakAngkaMs(String teks, int nilaiDefault) {
    final bersih = teks.replaceAll(RegExp(r'[^0-9]'), '');
    if (bersih.isEmpty) return nilaiDefault;
    return int.tryParse(bersih) ?? nilaiDefault;
  }

  static Future<void> tombolTesKoneksiEsp32(
      BuildContext context, StateAplikasi state, String ipInput) async {
    state.ipEsp32Lokal = ipInput.trim();
    final hasil = await state.tesKoneksiEsp32();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil),
        backgroundColor: state.statusTerhubungEsp32
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B),
      ),
    );
  }

  static Future<void> tombolCariIpOtomatis(
      BuildContext context,
      StateAplikasi state,
      TextEditingController ipCtrl) async {
    final ipDitemukan = await state.cariIpEsp32DariCloud();
    if (ipDitemukan.isNotEmpty) {
      ipCtrl.text = ipDitemukan;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ipDitemukan.isNotEmpty
            ? '📡 IP ESP32 Berhasil Ditemukan Otomatis: $ipDitemukan'
            : 'ℹ️ IP belum ditemukan di Cloud. Cek pesan Telegram saat ESP32 menyala.'),
        backgroundColor: ipDitemukan.isNotEmpty
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B),
      ),
    );
  }

  static Future<void> tombolSimpanWifiKeEsp32({
    required BuildContext context,
    required StateAplikasi state,
    required String ssid1,
    required String pass1,
    required String ssid2,
    required String pass2,
  }) async {
    state.ssidUtama = ssid1.trim().isEmpty ? 'Ani' : ssid1.trim();
    state.passwordUtama = pass1.trim();
    state.ssidCadangan =
        ssid2.trim().isEmpty ? 'TECNO CAMON 40' : ssid2.trim();
    state.passwordCadangan = pass2.trim();

    final perintah =
        'CMD:SET_WIFI:${state.ssidUtama}|${state.passwordUtama}|${state.ssidCadangan}|${state.passwordCadangan}';
    final res = await state.kirimPerintahKeEsp32(perintah);
    state.segarkanTampilan();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['ok'] == true
            ? '📶 SSID & Password WiFi berhasil disimpan ke Flash ESP32!'
            : '⚠️ Disimpan di APK. Pastikan IP ESP32 terhubung.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  /// 4. Kirim & Simpan Durasi Buka Solenoid (ms) & Cooldown Lockdown (ms) ke ESP32
  static Future<void> tombolSimpanTimingDanUmum({
    required BuildContext context,
    required StateAplikasi state,
    required String ipEsp32,
    required String teksRelayMs,
    required String teksCooldownMs,
  }) async {
    state.ipEsp32Lokal = ipEsp32.trim();

    final int relayMs =
        ekstrakAngkaMs(teksRelayMs, state.durasiRelayMs).clamp(100, 60000);
    int cooldownMs =
        ekstrakAngkaMs(teksCooldownMs, state.durasiCooldownMs);
    // Jika user mengetik angka kecil <= 60 (misal 1 atau 10), otomatis konversi ke ms (1000ms / 10000ms)
    // Jika user mengetik >= 100 (misal 100ms, 1000ms, 60000ms), gunakan langsung sebagai ms!
    if (cooldownMs > 0 && cooldownMs <= 60) {
      cooldownMs = cooldownMs * 1000;
    }
    cooldownMs = cooldownMs.clamp(100, 3600000);

    state.durasiRelayMs = relayMs;
    state.durasiCooldownMs = cooldownMs;
    state.durasiCooldownDetik = (cooldownMs / 1000).ceil();

    final res = await state
        .kirimPerintahKeEsp32('CMD:SET_TIMING:$relayMs|$cooldownMs');
    state.segarkanTampilan();

    if (!context.mounted) return;
    final String dtkRelay = (relayMs / 1000.0).toStringAsFixed(1);
    final String dtkCool = (cooldownMs / 1000.0).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['ok'] == true
            ? '✅ Diterapkan di ESP32! Solenoid: ${relayMs}ms (${dtkRelay}s) | Cooldown: ${cooldownMs}ms (${dtkCool}s)'
            : '⚙️ Tersimpan di APK: Solenoid ${relayMs}ms | Cooldown ${cooldownMs}ms'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
