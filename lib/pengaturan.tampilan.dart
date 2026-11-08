import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'pengaturan.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS TAMPILAN PENGATURAN PERANGKAT: pengaturan.tampilan.dart
/// Menampilkan pengaturan IP ESP32, WiFi 1 & 2 beserta Password,
/// serta Durasi Buka Solenoid (ms) & Cooldown Lockdown (ms) dengan konversi detik!
/// ============================================================================
class PengaturanTampilan extends StatefulWidget {
  final StateAplikasi state;

  const PengaturanTampilan({super.key, required this.state});

  @override
  State<PengaturanTampilan> createState() => _PengaturanTampilanState();
}

class _PengaturanTampilanState extends State<PengaturanTampilan> {
  late TextEditingController _ipEspCtrl;
  late TextEditingController _ssid1Ctrl;
  late TextEditingController _pass1Ctrl;
  late TextEditingController _ssid2Ctrl;
  late TextEditingController _pass2Ctrl;
  late TextEditingController _relayCtrl;
  late TextEditingController _cooldownCtrl;

  bool _sembunyikanPass1 = true;
  bool _sembunyikanPass2 = true;

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    _ipEspCtrl = TextEditingController(text: s.ipEsp32Lokal);
    _ssid1Ctrl = TextEditingController(text: s.ssidUtama);
    _pass1Ctrl = TextEditingController(text: s.passwordUtama);
    _ssid2Ctrl = TextEditingController(text: s.ssidCadangan);
    _pass2Ctrl = TextEditingController(text: s.passwordCadangan);
    _relayCtrl = TextEditingController(text: s.durasiRelayMs.toString());
    _cooldownCtrl = TextEditingController(text: s.durasiCooldownMs.toString());
  }

  @override
  void dispose() {
    _ipEspCtrl.dispose();
    _ssid1Ctrl.dispose();
    _pass1Ctrl.dispose();
    _ssid2Ctrl.dispose();
    _pass2Ctrl.dispose();
    _relayCtrl.dispose();
    _cooldownCtrl.dispose();
    super.dispose();
  }

  String _hitungDetikLabel(String teks, {bool izinkanDetikKecil = false}) {
    final bersih = teks.replaceAll(RegExp(r'[^0-9]'), '');
    final angka = int.tryParse(bersih) ?? 0;
    if (angka <= 0) return '0.0 detik';
    if (izinkanDetikKecil && angka <= 60) {
      return '$angka.0 detik (${angka * 1000} ms)';
    }
    return '${(angka / 1000.0).toStringAsFixed(2)} detik';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====================================================================
          // BAGIAN 1: KONEKSI LANGSUNG KE ESP32
          // ====================================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: state.statusTerhubungEsp32
                  ? TemaWarna.hijauAman.withValues(alpha: 0.6)
                  : TemaWarna.indigoUtama.withValues(alpha: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '1. KONEKSI KE PAPAN ESP32',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TemaWarna.cyanAksen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TemaWarna.badgeStatus(
                      teks: state.statusTerhubungEsp32
                          ? 'TERHUBUNG'
                          : 'SIAP KONEKSI',
                      warna: state.statusTerhubungEsp32
                          ? TemaWarna.hijauAman
                          : TemaWarna.kuningPeringatan,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Alamat IP Lokal ESP32 (Kontrol Instan < 0.1 Detik)',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jalur Aktif: ${state.modeKoneksiAktif}',
                  style: const TextStyle(color: TemaWarna.hijauAman, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _inputTeks(
                  label: 'IP Lokal ESP32 (Contoh: 192.168.1.22)',
                  ctrl: _ipEspCtrl,
                  ikon: Icons.router_rounded,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => PengaturanFungsi.tombolCariIpOtomatis(
                            context, state, _ipEspCtrl),
                        icon: const Icon(Icons.travel_explore_rounded, size: 16),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Cari IP Otomatis', maxLines: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => PengaturanFungsi.tombolTesKoneksiEsp32(
                            context, state, _ipEspCtrl.text),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaWarna.hijauAman,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Hubungkan ESP32',
                            maxLines: 1,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ====================================================================
          // BAGIAN 2: PENGATURAN DURASI SOLENOID (ms) & COOLDOWN LOCKDOWN (ms)
          // ====================================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: TemaWarna.cyanAksen.withValues(alpha: 0.45),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '2. AKUATOR SOLENOID & COOLDOWN LOCKDOWN',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TemaWarna.hijauAman,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TemaWarna.badgeStatus(
                      teks: 'AKTIF: ${state.durasiRelayMs}ms',
                      warna: TemaWarna.cyanAksen,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Durasi Buka Kunci Solenoid & Cooldown Lockdown',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tersimpan di ESP32 saat ini: Solenoid = ${state.durasiRelayMs} ms (${(state.durasiRelayMs / 1000.0).toStringAsFixed(1)} dtk) • Cooldown = ${state.durasiCooldownMs} ms (${(state.durasiCooldownMs / 1000.0).toStringAsFixed(1)} dtk)',
                  style: const TextStyle(color: TemaWarna.cyanAksen, fontSize: 11),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _relayCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      color: TemaWarna.teksPutih,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText:
                        'Durasi Buka Relay Solenoid dalam ms (10000 = 10 detik)',
                    helperText:
                        'Konversi Waktu: ${_hitungDetikLabel(_relayCtrl.text)} (Rentang: 100 ms – 60000 ms)',
                    helperStyle: const TextStyle(color: TemaWarna.hijauAman),
                    prefixIcon: const Icon(Icons.timer_outlined,
                        size: 18, color: TemaWarna.teksAbu),
                    filled: true,
                    fillColor: TemaWarna.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cooldownCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      color: TemaWarna.teksPutih,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText:
                        'Durasi Cooldown Lockdown dalam ms (1000 = 1 detik)',
                    helperText:
                        'Konversi Waktu: ${_hitungDetikLabel(_cooldownCtrl.text, izinkanDetikKecil: true)}',
                    helperStyle: const TextStyle(color: TemaWarna.cyanAksen),
                    prefixIcon: const Icon(Icons.lock_clock_outlined,
                        size: 18, color: TemaWarna.teksAbu),
                    filled: true,
                    fillColor: TemaWarna.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => PengaturanFungsi.tombolSimpanTimingDanUmum(
                    context: context,
                    state: state,
                    ipEsp32: _ipEspCtrl.text,
                    teksRelayMs: _relayCtrl.text,
                    teksCooldownMs: _cooldownCtrl.text,
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text(
                      'Simpan & Terapkan Durasi Solenoid ke ESP32'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaWarna.cyanAksen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ====================================================================
          // BAGIAN 3: PENGATURAN WIFI 1 & WIFI 2 BESERTA PASSWORD-NYA
          // ====================================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '3. JARINGAN WIFI & PASSWORD ESP32',
                  style: TextStyle(
                    color: TemaWarna.indigoUtama,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pengaturan Hotspot / WiFi Utama & Cadangan',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'WiFi 1 (Hotspot Utama)',
                  style: TextStyle(
                    color: TemaWarna.cyanAksen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _inputTeks(
                  label: 'Nama WiFi / SSID 1 (ssid1)',
                  ctrl: _ssid1Ctrl,
                  ikon: Icons.wifi_rounded,
                ),
                _inputPassword(
                  label: 'Password WiFi 1 (password1)',
                  ctrl: _pass1Ctrl,
                  sembunyi: _sembunyikanPass1,
                  onToggle: () =>
                      setState(() => _sembunyikanPass1 = !_sembunyikanPass1),
                ),
                const SizedBox(height: 8),
                const Text(
                  'WiFi 2 (Hotspot Cadangan / Failover)',
                  style: TextStyle(
                    color: TemaWarna.cyanAksen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _inputTeks(
                  label: 'Nama WiFi / SSID 2 (ssid2)',
                  ctrl: _ssid2Ctrl,
                  ikon: Icons.wifi_find_rounded,
                ),
                _inputPassword(
                  label: 'Password WiFi 2 (password2)',
                  ctrl: _pass2Ctrl,
                  sembunyi: _sembunyikanPass2,
                  onToggle: () =>
                      setState(() => _sembunyikanPass2 = !_sembunyikanPass2),
                ),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () => PengaturanFungsi.tombolSimpanWifiKeEsp32(
                    context: context,
                    state: state,
                    ssid1: _ssid1Ctrl.text,
                    pass1: _pass1Ctrl.text,
                    ssid2: _ssid2Ctrl.text,
                    pass2: _pass2Ctrl.text,
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan & Kirim WiFi + Password ke ESP32'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaWarna.indigoUtama,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputTeks({
    required String label,
    required TextEditingController ctrl,
    required IconData ikon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(
            color: TemaWarna.teksPutih, fontSize: 13, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(ikon, size: 18, color: TemaWarna.teksAbu),
          filled: true,
          fillColor: TemaWarna.bgInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _inputPassword({
    required String label,
    required TextEditingController ctrl,
    required bool sembunyi,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: sembunyi,
        style: const TextStyle(
            color: TemaWarna.teksPutih, fontSize: 13, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.key_rounded, size: 18, color: TemaWarna.teksAbu),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              sembunyi
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: TemaWarna.cyanAksen,
            ),
          ),
          filled: true,
          fillColor: TemaWarna.bgInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
