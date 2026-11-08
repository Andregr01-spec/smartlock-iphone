import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'otp_admin.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS TAMPILAN OTP & ADMIN: otp_admin.tampilan.dart
/// Menampilkan Kotak Kode OTP Real-Time dari ESP32 (Tanpa Perlu Buka Telegram!),
/// Keypad Numerik OTP 6-Digit, & Kartu Persetujuan Eskalasi Admin
/// ============================================================================
class OtpAdminTampilan extends StatefulWidget {
  final StateAplikasi state;

  const OtpAdminTampilan({super.key, required this.state});

  @override
  State<OtpAdminTampilan> createState() => _OtpAdminTampilanState();
}

class _OtpAdminTampilanState extends State<OtpAdminTampilan> {
  String _ketikanOtp = '';
  String _otpTerakhirOtomatis = '';

  void _tekanAngka(String angka) {
    if (_ketikanOtp.length < 6) {
      setState(() => _ketikanOtp += angka);
    }
  }

  void _hapusSatuAngka() {
    if (_ketikanOtp.isNotEmpty) {
      setState(
          () => _ketikanOtp = _ketikanOtp.substring(0, _ketikanOtp.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // Jika ada OTP baru masuk dari ESP32 yang berbeda dari sebelumnya, otomatis perbarui tampilan
    if (state.kodeOtpAktif.isNotEmpty &&
        state.kodeOtpAktif != _otpTerakhirOtomatis) {
      _otpTerakhirOtomatis = state.kodeOtpAktif;
    } else if (state.kodeOtpAktif.isEmpty) {
      _otpTerakhirOtomatis = '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TERMINAL KEYPAD INPUT OTP 6-DIGIT (DILENGKAPI LAYAR OTP LANGSUNG DARI ESP32!)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: state.menungguOtp
                  ? TemaWarna.hijauAman
                  : TemaWarna.indigoUtama.withValues(alpha: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AUTENTIKASI 2 FAKTOR (LEVEL 0)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TemaWarna.hijauAman,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TemaWarna.badgeStatus(
                      teks: state.menungguOtp
                          ? 'OTP AKTIF!'
                          : 'SIAP KIRIM',
                      warna: state.menungguOtp
                          ? TemaWarna.hijauAman
                          : TemaWarna.indigoUtama,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Terminal Verifikasi OTP 6-Digit',
                        style: TextStyle(
                          color: TemaWarna.teksPutih,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Segarkan OTP dari ESP32',
                      onPressed: () {
                        state.sinkronisasiStatusEsp32();
                        state.tarikDataTerbaruDariNtfy();
                      },
                      icon: const Icon(Icons.sync_rounded,
                          color: TemaWarna.cyanAksen, size: 20),
                    ),
                  ],
                ),

                // KOTAK TAMPILAN KODE OTP LANGSUNG DI APK (TANPA PERLU BUKA TELEGRAM!)
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: state.kodeOtpAktif.isNotEmpty
                        ? TemaWarna.hijauAman.withValues(alpha: 0.14)
                        : TemaWarna.bgInput,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: state.kodeOtpAktif.isNotEmpty
                          ? TemaWarna.hijauAman
                          : TemaWarna.garisBorder,
                      width: 1.5,
                    ),
                  ),
                  child: state.kodeOtpAktif.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '🔑 OTP AKTIF (${state.namaSesiAktif.isNotEmpty ? state.namaSesiAktif : "Kartu Sah"}):',
                                    style: const TextStyle(
                                      color: TemaWarna.hijauAman,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Skor AI: ${state.skorAkhirAi.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: TemaWarna.cyanAksen,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  state.kodeOtpAktif,
                                  style: const TextStyle(
                                    color: TemaWarna.teksPutih,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 4,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(
                                        () => _ketikanOtp = state.kodeOtpAktif);
                                  },
                                  icon: const Icon(Icons.touch_app_rounded,
                                      size: 16),
                                  label: const Text('Isi ke Keypad',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TemaWarna.indigoUtama,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(Icons.nfc_rounded,
                                color: TemaWarna.cyanAksen, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Silakan tap kartu RFID pada alat ESP32. Kode OTP 6-digit akan otomatis muncul di kotak ini tanpa perlu membuka Telegram.',
                                style: TextStyle(
                                    color: TemaWarna.teksAbu, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                ),

                // Layar Ketikan Angka OTP
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: TemaWarna.bgInput,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _ketikanOtp.length == 6
                          ? TemaWarna.hijauAman
                          : TemaWarna.indigoUtama,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      Text(
                        _ketikanOtp.padRight(6, '•').split('').join(' '),
                        style: const TextStyle(
                          color: TemaWarna.teksPutih,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 4,
                        ),
                      ),
                      IconButton(
                        onPressed: _hapusSatuAngka,
                        icon: const Icon(Icons.backspace_outlined,
                            color: TemaWarna.teksAbu, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Grid Keypad Numerik 3x4
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                      (angka) => OutlinedButton(
                        onPressed: () => _tekanAngka(angka),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF162038),
                          foregroundColor: TemaWarna.teksPutih,
                          side: const BorderSide(color: TemaWarna.garisBorder),
                        ),
                        child: Text(
                          angka,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _ketikanOtp = ''),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TemaWarna.merahBahaya,
                      ),
                      child: const Text('RESET',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton(
                      onPressed: () => _tekanAngka('0'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF162038),
                        foregroundColor: TemaWarna.teksPutih,
                      ),
                      child: const Text('0',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: () => OtpAdminFungsi.tombolVerifikasiOtp(
                        context: context,
                        state: state,
                        inputOtp: _ketikanOtp,
                        bersihkanInput: () => setState(() => _ketikanOtp = ''),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaWarna.hijauAman,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'KIRIM OTP',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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

          // 2. PANEL ESKALASI ADMIN (APPROVE_OPEN / APPROVE_BLOCK)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: TemaWarna.dekorasiKartu(
              warnaBorder: state.menungguPersetujuanAdmin
                  ? TemaWarna.kuningPeringatan
                  : TemaWarna.garisBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ESKALASI ADMIN (LEVEL 1 & 2)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TemaWarna.kuningPeringatan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TemaWarna.badgeStatus(
                      teks: state.menungguPersetujuanAdmin
                          ? 'PERLU KONFIRMASI'
                          : 'SIAP EKSEKUSI',
                      warna: state.menungguPersetujuanAdmin
                          ? TemaWarna.kuningPeringatan
                          : TemaWarna.cyanAksen,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Persetujuan Manual Admin (Setuju / Blokir)',
                  style: TextStyle(
                    color: TemaWarna.teksPutih,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TemaWarna.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TemaWarna.garisBorder),
                  ),
                  child: Text(
                    state.menungguPersetujuanAdmin
                        ? '⚠️ PERINGATAN AI: RISIKO TINGGI (${state.skorAkhirAi.toStringAsFixed(2)}%)\nPemilik Kartu: ${state.namaSesiAktif.isNotEmpty ? state.namaSesiAktif : "Terdeteksi"}\nSilakan tekan Setuju/Buka atau Tolak/Blokir di bawah:'
                        : '🟢 Tombol Setuju/Buka dan Tolak/Blokir di bawah terhubung langsung ke ESP32 (sama dengan tombol Inline Keyboard di Telegram).',
                    style: const TextStyle(
                      color: TemaWarna.teksPutih,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            OtpAdminFungsi.tombolAdminSetujuBuka(context, state),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Setuju / Buka'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaWarna.hijauAman,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => OtpAdminFungsi.tombolAdminTolakBlokir(
                            context, state),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: const Text('Tolak / Blokir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaWarna.merahBahaya,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
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
}
