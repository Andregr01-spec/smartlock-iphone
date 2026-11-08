import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'beranda.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS TAMPILAN BERANDA: beranda.tampilan.dart
/// Menyusun tata letak visual & warna halaman Beranda (Dashboard)
/// Seluruh aksi tombol memanggil fungsi di BerandaFungsi (beranda.fungsi.dart)
/// ============================================================================
class BerandaTampilan extends StatelessWidget {
  final StateAplikasi state;
  final VoidCallback pindahKeTabRfid;
  final VoidCallback pindahKeTabOtp;

  const BerandaTampilan({
    super.key,
    required this.state,
    required this.pindahKeTabRfid,
    required this.pindahKeTabOtp,
  });

  @override
  Widget build(BuildContext context) {
    final warnaSkor = state.levelKeputusanFuzzy == 2
        ? TemaWarna.merahBahaya
        : state.levelKeputusanFuzzy == 1
            ? TemaWarna.kuningPeringatan
            : TemaWarna.hijauAman;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 0. BANNER IDENTITAS LOGO SMART KEYLESS 2FA
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: TemaWarna.cyanAksen.withValues(alpha: 0.45),
            ),
            child: Row(
              children: [
                TemaWarna.logoSmartKeyless(ukuran: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SMART KEYLESS 2FA - AI SMART DOOR LOCK',
                        style: TextStyle(
                          color: TemaWarna.cyanAksen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Sistem Keamanan Pintu Ganda RFID + OTP & 5 Metode AI',
                        style: TextStyle(
                          color: TemaWarna.teksPutih,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status Terakhir: ${state.ringkasanEventTerakhir}',
                        style: const TextStyle(
                          color: TemaWarna.teksAbu,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // BANNER POPUP OTP AKTIF DI BERANDA (MUNCUL OTOMATIS SAAT KARTU DI-TAP!)
          if (state.kodeOtpAktif.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: TemaWarna.dekorasiKartu(
                warnaBorder: TemaWarna.hijauAman,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔑 KODE OTP BARU (${state.namaSesiAktif}):',
                          style: const TextStyle(
                            color: TemaWarna.hijauAman,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.kodeOtpAktif,
                          style: const TextStyle(
                            color: TemaWarna.teksPutih,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: pindahKeTabOtp,
                    icon: const Icon(Icons.pin_rounded, size: 16),
                    label: const Text('Buka Tab OTP →'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaWarna.hijauAman,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          // 1. KARTU UTAMA: KONTROL SOLENOID DOOR LOCK
          Container(
            padding: const EdgeInsets.all(20),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: state.pintuTerbuka
                  ? TemaWarna.kuningPeringatan.withValues(alpha: 0.6)
                  : TemaWarna.hijauAman.withValues(alpha: 0.4),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS AKUATOR UTAMA',
                          style: TextStyle(
                            color: TemaWarna.indigoUtama,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Solenoid Door Lock',
                          style: TextStyle(
                            color: TemaWarna.teksPutih,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TemaWarna.badgeStatus(
                      teks: state.pintuTerbuka
                          ? 'TERBUKA'
                          : 'TERKUNCI AMAN',
                      warna: state.pintuTerbuka
                          ? TemaWarna.kuningPeringatan
                          : TemaWarna.hijauAman,
                      ikon: state.pintuTerbuka
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tombol Bulat Besar Solenoid
                GestureDetector(
                  onTap: () =>
                      BerandaFungsi.tombolBukaPintuManual(context, state),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.pintuTerbuka
                          ? TemaWarna.kuningPeringatan.withValues(alpha: 0.15)
                          : const Color(0xFF131C31),
                      border: Border.all(
                        color: state.pintuTerbuka
                            ? TemaWarna.kuningPeringatan
                            : TemaWarna.hijauAman,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (state.pintuTerbuka
                                  ? TemaWarna.kuningPeringatan
                                  : TemaWarna.hijauAman)
                              .withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.pintuTerbuka
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                          size: 44,
                          color: state.pintuTerbuka
                              ? TemaWarna.kuningPeringatan
                              : TemaWarna.hijauAman,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.pintuTerbuka ? 'Terbuka...' : 'Buka Pintu',
                          style: const TextStyle(
                            color: TemaWarna.teksPutih,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memicu triggerDoorUnlock() • Durasi ${(state.durasiRelayMs / 1000).toStringAsFixed(1)} dtk (Anti-Brownout)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TemaWarna.teksAbu,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. KARTU SKOR RISIKO AI & KEPUTUSAN FUZZY (METODE 1 - 5)
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
                      'TELEMETRI KEPUTUSAN AI',
                      style: TextStyle(
                        color: TemaWarna.cyanAksen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TemaWarna.badgeStatus(
                      teks: state.levelKeputusanFuzzy == 2
                          ? 'Level 2: Auto-Lockdown'
                          : state.levelKeputusanFuzzy == 1
                              ? 'Level 1: Eskalasi Admin'
                              : 'Level 0: Aman (OTP)',
                      warna: warnaSkor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.skorAkhirAi.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: warnaSkor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'M1 Perilaku (EWMA): ${state.skorPerilakuM1.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: TemaWarna.teksAbu, fontSize: 12),
                        ),
                        Text(
                          'M2 Sensor Fisik: +${state.penaltiFisikM2.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: TemaWarna.teksAbu, fontSize: 12),
                        ),
                        Text(
                          'M3 Tap Kartu Asing: ${state.totalTapKartuAsing}x',
                          style: const TextStyle(
                              color: TemaWarna.teksAbu, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      BerandaFungsi.tombolResetSemuaProfilRisiko(context, state),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset Profil Risiko Adaptif (M5 HITL)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaWarna.teksPutih,
                    side: const BorderSide(color: TemaWarna.garisBorder),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. KARTU SENSOR FISIK PINTU & TAMPER BOKS (METODE 2 FUSION)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sensor Keamanan Fisik (Metode 2)',
                      style: TextStyle(
                        color: TemaWarna.teksPutih,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          BerandaFungsi.tombolResetSensorFisik(context, state),
                      child: const Text('Reset Latch',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Baris Reed Switch Pintu
                _barisSensor(
                  judul: 'Sensor Pintu (REED_PIN)',
                  subjudul: state.sensorPintuPaksa
                      ? '🚨 TERBUKA PAKSA (HIGH - Latch Aktif)'
                      : 'Tertutup Rapat (LOW - Aman)',
                  bahaya: state.sensorPintuPaksa,
                  labelTombol: 'Simulasi Congkel',
                  onTap: () =>
                      BerandaFungsi.tombolSimulasiPintuPaksa(context, state),
                ),
                const SizedBox(height: 10),
                // Baris Tamper Switch Boks
                _barisSensor(
                  judul: 'Boks Panel (TAMPER_PIN)',
                  subjudul: state.sensorTamperBoks
                      ? '⚠️ BOKS DICONGGEL! (HIGH - Latch Aktif)'
                      : 'Boks Terkunci Rapat (LOW - Aman)',
                  bahaya: state.sensorTamperBoks,
                  labelTombol: 'Buka Paksa Boks',
                  onTap: () =>
                      BerandaFungsi.tombolSimulasiTamperBoks(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. SIMULASI TAP KARTU CEPAT (MFRC522)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Uji Tap Kartu RFID (MFRC522)',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih kartu terdaftar untuk menguji respons OTP atau eskalasi AI:',
                  style: TextStyle(color: TemaWarna.teksAbu, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...state.daftarKartu.map(
                  (u) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                              u.nama,
                              style: const TextStyle(
                                color: TemaWarna.teksPutih,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'UID: ${u.uid} • Habit: ${u.jamKebiasaan.toStringAsFixed(1)}:00',
                              style: const TextStyle(
                                color: TemaWarna.indigoUtama,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            BerandaFungsi.tombolTapKartuSah(context, state, u);
                            pindahKeTabOtp();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TemaWarna.indigoUtama,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                          child: const Text('Tap Kartu',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            BerandaFungsi.tombolTapKartuAsing(context, state),
                        icon: const Icon(Icons.warning_amber_rounded, size: 16),
                        label: const Text('Tap Kartu Asing (M3)',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TemaWarna.merahBahaya,
                          side: const BorderSide(color: TemaWarna.merahBahaya),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: pindahKeTabRfid,
                      icon: const Icon(Icons.add_card_rounded, size: 16),
                      label: const Text('+ Kartu Baru',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaWarna.cyanAksen,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisSensor({
    required String judul,
    required String subjudul,
    required bool bahaya,
    required String labelTombol,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaWarna.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bahaya
              ? TemaWarna.merahBahaya.withValues(alpha: 0.5)
              : TemaWarna.garisBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    color: TemaWarna.teksPutih,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subjudul,
                  style: TextStyle(
                    color: bahaya ? TemaWarna.merahBahaya : TemaWarna.teksAbu,
                    fontSize: 11,
                    fontWeight: bahaya ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  bahaya ? TemaWarna.merahBahaya : TemaWarna.teksPutih,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(labelTombol, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
