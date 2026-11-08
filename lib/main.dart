import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'beranda.tampilan.dart';
import 'beranda.fungsi.dart';
import 'rfid.tampilan.dart';
import 'otp_admin.tampilan.dart';
import 'monitor_ai.tampilan.dart';
import 'riwayat_log.tampilan.dart';
import 'pengaturan.tampilan.dart';

/// ============================================================================
/// ENTRY POINT UTAMA APLIKASI FLUTTER: main.dart
/// Dilengkapi Logo Resmi "SMART KEYLESS 2FA" pada AppBar & Beranda
/// ============================================================================
void main() {
  runApp(const SmartLockAiApp());
}

class SmartLockAiApp extends StatefulWidget {
  const SmartLockAiApp({super.key});

  @override
  State<SmartLockAiApp> createState() => _SmartLockAiAppState();
}

class _SmartLockAiAppState extends State<SmartLockAiApp> {
  final StateAplikasi _state = StateAplikasi();
  int _indeksTabAktif = 0;

  @override
  void initState() {
    super.initState();
    _state.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final daftarHalaman = [
      BerandaTampilan(
        state: _state,
        pindahKeTabRfid: () => setState(() => _indeksTabAktif = 1),
        pindahKeTabOtp: () => setState(() => _indeksTabAktif = 2),
      ),
      RfidTampilan(state: _state),
      OtpAdminTampilan(state: _state),
      MonitorAiTampilan(state: _state),
      RiwayatLogTampilan(state: _state),
      PengaturanTampilan(state: _state),
    ];

    return MaterialApp(
      title: 'SMART KEYLESS 2FA',
      debugShowCheckedModeBanner: false,
      theme: TemaWarna.temaGelap,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              TemaWarna.logoSmartKeyless(ukuran: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMART KEYLESS 2FA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      _state.statusTerhubungEsp32
                          ? '🟢 Terhubung (${_state.modeKoneksiAktif})'
                          : '🟡 WiFi: ${_state.ssidUtama} • Siap Koneksi',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TemaWarna.teksAbu,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (_state.sisaDetikLockdown > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: TemaWarna.merahBahaya,
                  label: Text(
                    'LOCKDOWN ${_state.sisaDetikLockdown}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      BerandaFungsi.tombolResetSemuaProfilRisiko(context, _state),
                ),
              ),
          ],
        ),
        body: daftarHalaman[_indeksTabAktif],
        bottomNavigationBar: NavigationBar(
          backgroundColor: TemaWarna.bgKartu,
          indicatorColor: TemaWarna.indigoUtama.withValues(alpha: 0.25),
          selectedIndex: _indeksTabAktif,
          onDestinationSelected: (idx) => setState(() => _indeksTabAktif = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.credit_card_outlined),
              selectedIcon: Icon(Icons.credit_card_rounded),
              label: 'RFID',
            ),
            NavigationDestination(
              icon: Icon(Icons.pin_outlined),
              selectedIcon: Icon(Icons.pin_rounded),
              label: 'OTP',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology_rounded),
              label: 'Metode AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Log',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Setelan',
            ),
          ],
        ),
      ),
    );
  }
}
