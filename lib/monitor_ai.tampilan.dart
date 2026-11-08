import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'monitor_ai.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS TAMPILAN MONITOR 5 METODE AI: monitor_ai.tampilan.dart
/// Berfungsi sebagai REMOTE HARDWARE untuk mengaktifkan/mematikan Metode 1 s/d 5
/// secara langsung di papan ESP32 tanpa perlu upload ulang dari Arduino IDE!
/// ============================================================================
class MonitorAiTampilan extends StatelessWidget {
  final StateAplikasi state;

  const MonitorAiTampilan({super.key, required this.state});

  Future<void> _kirimRemoteAiKeEsp32(BuildContext context) async {
    MonitorAiFungsi.evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    final terkirim = await state.sinkronkanSakelarAiKeEsp32();
    state.segarkanTampilan();
    if (!context.mounted) return;
    final kodeAktif =
        'M1:${state.aktifM1Ewma ? 1 : 0} | M2:${state.aktifM2Fusion ? 1 : 0} | M3:${state.aktifM3Contagion ? 1 : 0} | M4:${state.aktifM4Fuzzy ? 1 : 0} | M5:${state.aktifM5Hitl ? 1 : 0}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(terkirim
            ? '🧠 Remote AI Diterapkan di ESP32! ($kodeAktif)'
            : '⚠️ Disimpan di APK ($kodeAktif). Hubungkan IP ESP32 di Pengaturan.'),
        backgroundColor:
            terkirim ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _pilihPresetUji(
    BuildContext context, {
    required bool m1,
    required bool m2,
    required bool m3,
    required bool m4,
    required bool m5,
  }) {
    state.aktifM1Ewma = m1;
    state.aktifM2Fusion = m2;
    state.aktifM3Contagion = m3;
    state.aktifM4Fuzzy = m4;
    state.aktifM5Hitl = m5;
    _kirimRemoteAiKeEsp32(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER REMOTE PENGUJIAN 1-PER-1 TANPA UPLOAD ULANG ARDUINO
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: TemaWarna.indigoUtama.withValues(alpha: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'REMOTE SAKELAR PENGUJIAN ESP32',
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
                          ? 'SINKRON ESP32'
                          : 'MODE SIMULASI',
                      warna: state.statusTerhubungEsp32
                          ? TemaWarna.hijauAman
                          : TemaWarna.kuningPeringatan,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Remote Pengujian 5 Metode AI (Tanpa Upload Ulang)',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ubah sakelar di bawah atau klik tombol Preset Uji Cepat untuk menyalakan/mematikan metode AI langsung di memori ESP32:',
                  style: TextStyle(color: TemaWarna.teksAbu, fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Tombol Preset Pengujian Skripsi Satu-per-Satu
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tombolPreset(
                      label: 'Uji M1 Saja (1,0,0,0,0)',
                      onTap: () => _pilihPresetUji(
                        context,
                        m1: true,
                        m2: false,
                        m3: false,
                        m4: false,
                        m5: false,
                      ),
                    ),
                    _tombolPreset(
                      label: 'Uji M1+M2 (1,1,0,0,0)',
                      onTap: () => _pilihPresetUji(
                        context,
                        m1: true,
                        m2: true,
                        m3: false,
                        m4: false,
                        m5: false,
                      ),
                    ),
                    _tombolPreset(
                      label: 'Uji M1+M2+M3 (1,1,1,0,0)',
                      onTap: () => _pilihPresetUji(
                        context,
                        m1: true,
                        m2: true,
                        m3: true,
                        m4: false,
                        m5: false,
                      ),
                    ),
                    _tombolPreset(
                      label: 'Uji M1 s/d M4 (1,1,1,1,0)',
                      onTap: () => _pilihPresetUji(
                        context,
                        m1: true,
                        m2: true,
                        m3: true,
                        m4: true,
                        m5: false,
                      ),
                    ),
                    _tombolPreset(
                      label: 'Aktifkan Semua M1-M5 (1,1,1,1,1)',
                      onTap: () => _pilihPresetUji(
                        context,
                        m1: true,
                        m2: true,
                        m3: true,
                        m4: true,
                        m5: true,
                      ),
                    ),
                    _tombolPreset(
                      label: 'Model Lama (0,0,0,0,0)',
                      onTap: () => _pilihPresetUji(
                        context,
                        m1: false,
                        m2: false,
                        m3: false,
                        m4: false,
                        m5: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. SAKELAR 5 METODE AI INDIVIDUAL
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sakelar Individual 5 Metode AI',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _itemSakelarAi(
                  kode: 'Metode 1: EWMA Habit Profile (USE_NEW_METHOD_1)',
                  deskripsi: state.aktifM1Ewma
                      ? 'AKTIF (1): Pakai ai_method1_ewma.h (ALPHA 0.20, Decay 5m)'
                      : 'NONAKTIF (0): Pakai ml_model.h lama (TRAINED_V1)',
                  nilai: state.aktifM1Ewma,
                  onChanged: (v) {
                    state.aktifM1Ewma = v;
                    _kirimRemoteAiKeEsp32(context);
                  },
                ),
                const Divider(color: TemaWarna.garisBorder),
                _itemSakelarAi(
                  kode: 'Metode 2: Physical Sensor Fusion (USE_NEW_METHOD_2)',
                  deskripsi: state.aktifM2Fusion
                      ? 'AKTIF (1): Pintu Paksa (+50) & Tamper Boks (+100) menambah skor AI'
                      : 'NONAKTIF (0): Sensor fisik tidak menambah skor AI',
                  nilai: state.aktifM2Fusion,
                  onChanged: (v) {
                    state.aktifM2Fusion = v;
                    _kirimRemoteAiKeEsp32(context);
                  },
                ),
                const Divider(color: TemaWarna.garisBorder),
                _itemSakelarAi(
                  kode: 'Metode 3: Threat Contagion (USE_NEW_METHOD_3)',
                  deskripsi: state.aktifM3Contagion
                      ? 'AKTIF (1): Tap kartu asing menular ke seluruh profil user sah'
                      : 'NONAKTIF (0): Kartu asing tidak menular ke user sah',
                  nilai: state.aktifM3Contagion,
                  onChanged: (v) {
                    state.aktifM3Contagion = v;
                    _kirimRemoteAiKeEsp32(context);
                  },
                ),
                const Divider(color: TemaWarna.garisBorder),
                _itemSakelarAi(
                  kode: 'Metode 4: Fuzzy Decision & Cooldown (USE_NEW_METHOD_4)',
                  deskripsi: state.aktifM4Fuzzy
                      ? 'AKTIF (1): Pakai ai_method4_fuzzy.h (Level 0 OTP, 1 Admin, 2 Lockdown)'
                      : 'NONAKTIF (0): Pakai fungsi guardApproval lama (risk_model.h)',
                  nilai: state.aktifM4Fuzzy,
                  onChanged: (v) {
                    state.aktifM4Fuzzy = v;
                    _kirimRemoteAiKeEsp32(context);
                  },
                ),
                const Divider(color: TemaWarna.garisBorder),
                _itemSakelarAi(
                  kode: 'Metode 5: HITL Adaptive Reset (USE_NEW_METHOD_5)',
                  deskripsi: state.aktifM5Hitl
                      ? 'AKTIF (1): Reset adaptif + update jam kebiasaan user (updateHabit)'
                      : 'NONAKTIF (0): Reset standar tanpa mengubah jam kebiasaan',
                  nilai: state.aktifM5Hitl,
                  onChanged: (v) {
                    state.aktifM5Hitl = v;
                    _kirimRemoteAiKeEsp32(context);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _kirimRemoteAiKeEsp32(context),
                  icon: const Icon(Icons.send_to_mobile_rounded),
                  label: const Text('Kirim & Terapkan Sakelar AI ke ESP32 Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaWarna.indigoUtama,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. TERMINAL SERIAL MONITOR ESP32
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaWarna.garisBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🖥️ Log Telemetri & Serial Monitor ESP32',
                      style: TextStyle(
                        color: TemaWarna.hijauAman,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          MonitorAiFungsi.bersihkanSerialMonitor(state),
                      child: const Text('Bersihkan',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const Divider(color: TemaWarna.garisBorder),
                SizedBox(
                  height: 180,
                  child: SingleChildScrollView(
                    child: Text(
                      state.logSerial.join('\n'),
                      style: const TextStyle(
                        color: TemaWarna.teksPutih,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolPreset({required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: TemaWarna.bgInput,
        foregroundColor: TemaWarna.cyanAksen,
        side: BorderSide(color: TemaWarna.cyanAksen.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _itemSakelarAi({
    required String kode,
    required String deskripsi,
    required bool nilai,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        kode,
        style: const TextStyle(
          color: TemaWarna.teksPutih,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        deskripsi,
        style: TextStyle(
          color: nilai ? TemaWarna.hijauAman : TemaWarna.teksAbu,
          fontSize: 11,
        ),
      ),
      value: nilai,
      activeColor: TemaWarna.hijauAman,
      onChanged: onChanged,
    );
  }
}
