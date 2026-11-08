import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ============================================================================
/// FILE KHUSUS MODEL & STATE GLOBAL: state_aplikasi.fungsi.dart
/// Dilengkapi:
/// 1. Polling Cepat WiFi Lokal ESP32 (/status)
/// 2. Live Stream Ntfy Tanpa Rate-Limit (OTP selalu masuk walau tap kartu 100x!)
/// 3. Pelacak Nomor Urut Sesi OTP (otpSessionSeq) agar kartu yang sama bisa di-tap berulang-ulang
/// ============================================================================

class PenggunaRfid {
  String uid;
  String nama;
  String peran;
  double jamKebiasaan;
  int percobaan10m;
  int kartuAsingMenular10m;
  int gagalOtp10m;
  int gagalBeruntun;
  double detikSejakTerakhir;

  PenggunaRfid({
    required this.uid,
    required this.nama,
    this.peran = 'Pengguna Sah',
    this.jamKebiasaan = 12.0,
    this.percobaan10m = 0,
    this.kartuAsingMenular10m = 0,
    this.gagalOtp10m = 0,
    this.gagalBeruntun = 0,
    this.detikSejakTerakhir = 3600.0,
  });
}

class ItemLogAkses {
  final String waktu;
  final String uid;
  final String nama;
  final String aksi;
  final String status;
  final String skorAi;
  final String kategori;

  ItemLogAkses({
    required this.waktu,
    required this.uid,
    required this.nama,
    required this.aksi,
    required this.status,
    required this.skorAi,
    required this.kategori,
  });
}

class StateAplikasi extends ChangeNotifier {
  String ipEsp32Lokal = '192.168.1.22';
  bool statusTerhubungEsp32 = false;
  bool terhubungLokalLangsung = false;
  String modeKoneksiAktif = 'Menghubungkan ke ESP32...';
  String ringkasanEventTerakhir = 'Sistem Siaga';

  bool pintuTerbuka = false;
  bool dibukaOlehSistem = false;
  bool reedSwitchTerbuka = false;
  bool tamperSwitchTerbuka = false;
  bool sensorPintuPaksa = false;
  bool sensorTamperBoks = false;

  bool menungguOtp = false;
  bool menungguPersetujuanAdmin = false;
  String kodeOtpAktif = '';
  int otpSeqTerakhir = 0;
  String uidSesiAktif = '';
  String namaSesiAktif = '';
  String uidKartuAsingTerakhir = '';
  int escalationCount = 0;
  int sisaDetikLockdown = 0;
  Timer? _timerLockdown;
  Timer? _timerSyncEsp32;
  int _counterFallBackNtfy = 0;
  http.Client? _streamClient;
  bool _streamAktif = false;

  final Set<String> _idEventNtfySudahDiproses = <String>{};
  bool _sedangEksekusiPerintah = false;

  String ssidUtama = 'Ani';
  String passwordUtama = 'ani140988';
  String ssidCadangan = 'TECNO CAMON 40';
  String passwordCadangan = 'Andregr01';

  String urlRelayNtfy = 'https://ntfy.sh/smartlock_andre_uigm_2026';
  String urlCmdEsp32 = 'https://ntfy.sh/smartlock_andre_uigm_2026_cmd';
  String botToken = '8785387178:AAG7-0NtSJe4HCw2I8DrK6yuGF8w1HOpR00';
  String chatId = '7593108793';
  int durasiRelayMs = 1500;
  int durasiCooldownMs = 60000;
  int durasiCooldownDetik = 60;
  int jamSimulasiRtc = 21;

  bool aktifM1Ewma = true;
  bool aktifM2Fusion = true;
  bool aktifM3Contagion = true;
  bool aktifM4Fuzzy = true;
  bool aktifM5Hitl = true;

  double skorPerilakuM1 = 0.00;
  double derajatFisikM2 = 0.00;
  double penaltiFisikM2 = 0.00;
  double skorAkhirAi = 0.00;
  int levelKeputusanFuzzy = 0;
  int totalTapKartuAsing = 0;

  final List<PenggunaRfid> daftarKartu = [
    PenggunaRfid(
      uid: '73 4B 3E E2',
      nama: 'Andre Irfansyah',
      peran: 'Admin Utama',
      jamKebiasaan: 12.0,
    ),
    PenggunaRfid(
      uid: '83 C7 17 E2',
      nama: 'Syahrul Rozikin',
      peran: 'Pengguna Sah',
      jamKebiasaan: 12.0,
    ),
    PenggunaRfid(
      uid: 'B3 50 2F E2',
      nama: 'Serli Angrayani',
      peran: 'Pengguna Sah',
      jamKebiasaan: 12.0,
    ),
    PenggunaRfid(
      uid: '83 24 38 E2',
      nama: 'Nafisa',
      peran: 'Pengguna Sah',
      jamKebiasaan: 12.0,
    ),
  ];

  final List<ItemLogAkses> daftarLog = [];

  final List<String> logSerial = [
    '[RTC] Modul RTC DS3231 berhasil terdeteksi.',
    '[SYNC] Sinkronisasi Real-Time OTP & Log Aktif.',
  ];

  StateAplikasi() {
    sinkronisasiStatusEsp32();
    mulaiLiveStreamNtfy();
    _timerSyncEsp32 = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      sinkronisasiStatusEsp32();
    });
    cariIpEsp32DariCloud();
  }

  /// ==========================================================================
  /// LIVE STREAM NTFY (1 KONEKSI TERBUKA TERUS-MENERUS - BEBAS RATE LIMIT 429!)
  /// Begitu kartu di-tap di ESP32 (walaupun kartu yang sama 100x), OTP langsung
  /// didorong masuk ke APK dalam 0.1 detik tanpa harus buka Telegram!
  /// ==========================================================================
  Future<void> mulaiLiveStreamNtfy() async {
    if (_streamAktif) return;
    _streamAktif = true;
    try {
      _streamClient?.close();
      _streamClient = http.Client();
      final req = http.Request('GET', Uri.parse('$urlRelayNtfy/json'));
      final res = await _streamClient!.send(req);
      if (res.statusCode == 200) {
        res.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (baris) {
            if (baris.trim().isNotEmpty) {
              _prosesSatuBarisJsonNtfy(baris.trim());
            }
          },
          onDone: () {
            _streamAktif = false;
            Future.delayed(const Duration(seconds: 3), mulaiLiveStreamNtfy);
          },
          onError: (_) {
            _streamAktif = false;
            Future.delayed(const Duration(seconds: 4), mulaiLiveStreamNtfy);
          },
        );
      } else {
        _streamAktif = false;
      }
    } catch (_) {
      _streamAktif = false;
    }
  }

  void _prosesSatuBarisJsonNtfy(String baris) {
    try {
      final Map<String, dynamic> amplop = jsonDecode(baris);
      final String eventType = (amplop['event'] ?? '').toString();
      if (eventType != 'message') return;

      final String idEvent = (amplop['id'] ?? '').toString();
      if (idEvent.isEmpty || _idEventNtfySudahDiproses.contains(idEvent)) {
        return;
      }
      _idEventNtfySudahDiproses.add(idEvent);

      final String pesanMentah = (amplop['message'] ?? '').toString();
      if (!pesanMentah.startsWith('{')) return;

      final Map<String, dynamic> dataEsp = jsonDecode(pesanMentah);
      final String uid = (dataEsp['uid'] ?? '-').toString();
      final String nama = (dataEsp['name'] ?? '-').toString();
      final String aksi = (dataEsp['action'] ?? '-').toString();
      final String status = (dataEsp['status'] ?? '-').toString();
      final String waktuLog =
          (dataEsp['time'] ?? waktuSekarangStr()).toString();
      final double skorLog =
          double.tryParse((dataEsp['score'] ?? '0').toString()) ?? skorAkhirAi;

      // Update IP Lokal ESP32 secara otomatis setiap ada paket masuk!
      if (dataEsp['ip'] != null &&
          dataEsp['ip'].toString().isNotEmpty &&
          dataEsp['ip'].toString() != '0.0.0.0') {
        ipEsp32Lokal = dataEsp['ip'].toString().trim();
      }

      statusTerhubungEsp32 = true;
      skorAkhirAi = skorLog;

      // TANGKAP OTP BARU DARI FIELD 'otp' ATAU 'action' ('OTP:123456')
      final String otpField = (dataEsp['otp'] ?? '').toString().trim();
      if (otpField.length == 6) {
        kodeOtpAktif = otpField;
        menungguOtp = true;
        menungguPersetujuanAdmin = false;
        uidSesiAktif = uid;
        namaSesiAktif = nama;
        ringkasanEventTerakhir = 'OTP Baru ($nama): $kodeOtpAktif';
        tambahLogSerial('[OTP BARU MASUK] $nama -> Kode OTP: $kodeOtpAktif');
      } else if (aksi.startsWith('OTP:')) {
        kodeOtpAktif = aksi.substring(4).trim();
        menungguOtp = true;
        menungguPersetujuanAdmin = false;
        uidSesiAktif = uid;
        namaSesiAktif = nama;
        ringkasanEventTerakhir = 'OTP Baru ($nama): $kodeOtpAktif';
        tambahLogSerial('[OTP BARU MASUK] $nama -> Kode OTP: $kodeOtpAktif');
      } else if (status.contains('Terbuka (TP)') || status.contains('Aman (0%)')) {
        menungguOtp = false;
        menungguPersetujuanAdmin = false;
        kodeOtpAktif = '';
      }

      if (status.contains('Menunggu Konfirmasi') ||
          status.contains('Sistem Dibekukan')) {
        menungguPersetujuanAdmin = true;
        menungguOtp = false;
        kodeOtpAktif = '';
        uidSesiAktif = uid;
        namaSesiAktif = nama;
      }

      if (nama == 'Tidak Dikenal' && uid != '-') {
        uidKartuAsingTerakhir = uid;
      }

      if (!terhubungLokalLangsung) {
        daftarLog.insert(
          0,
          ItemLogAkses(
            waktu: waktuLog,
            uid: uid,
            nama: nama,
            aksi: aksi,
            status: status,
            skorAi: '${skorLog.toStringAsFixed(2)}%',
            kategori: _tentukanKategoriLog(status, aksi),
          ),
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  void tambahLogSerial(String baris) {
    if (logSerial.isNotEmpty && logSerial.last == baris) return;
    logSerial.add(baris);
    if (logSerial.length > 80) {
      logSerial.removeAt(0);
    }
    notifyListeners();
  }

  String waktuSekarangStr() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  int picuDynamicCooldown() {
    escalationCount++;
    final shift = (escalationCount > 4) ? 4 : (escalationCount - 1);
    final durasiDetik = durasiCooldownDetik * (1 << shift);
    mulaiTimerLockdown(durasiDetik);
    return durasiDetik;
  }

  void mulaiTimerLockdown(int detik) {
    sisaDetikLockdown = detik;
    _timerLockdown?.cancel();
    _timerLockdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sisaDetikLockdown > 0) {
        sisaDetikLockdown--;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void hentikanTimerLockdown() {
    _timerLockdown?.cancel();
    sisaDetikLockdown = 0;
    escalationCount = 0;
    notifyListeners();
  }

  static String _tentukanKategoriLog(String status, String aksi) {
    final s = status.toUpperCase();
    final a = aksi.toUpperCase();
    if (s.contains('TERBUKA (TP)') ||
        s.contains('TERDAFTAR') ||
        s.contains('AMAN') ||
        s.contains('ONLINE')) {
      return 'AMAN';
    }
    if (s.contains('MENUNGGU') ||
        s.contains('PERINGATAN') ||
        a.contains('OTP:')) {
      return 'PERINGATAN';
    }
    return 'DITOLAK';
  }

  Future<Map<String, dynamic>> kirimPerintahKeEsp32(String kodePerintah) async {
    if (_sedangEksekusiPerintah) {
      return {'ok': false, 'busy': true, 'msg': 'Perintah sedang diproses...'};
    }
    _sedangEksekusiPerintah = true;

    try {
      if (ipEsp32Lokal.trim().isNotEmpty) {
        try {
          final uriLokal = Uri.parse(
            'http://${ipEsp32Lokal.trim()}/cmd?c=${Uri.encodeComponent(kodePerintah)}',
          );
          final res = await http
              .get(uriLokal)
              .timeout(const Duration(milliseconds: 2500));
          if (res.statusCode == 200) {
            statusTerhubungEsp32 = true;
            terhubungLokalLangsung = true;
            modeKoneksiAktif = 'WiFi Lokal (${ipEsp32Lokal.trim()})';
            tambahLogSerial('[WIFI LOKAL -> ESP32] Sukses: $kodePerintah');

            Map<String, dynamic> hasil = {'ok': true};
            if (res.body.trim().startsWith('{')) {
              hasil = jsonDecode(res.body.trim());
            }
            Future.delayed(const Duration(milliseconds: 200), () {
              sinkronisasiStatusEsp32();
            });
            notifyListeners();
            return hasil;
          }
        } catch (_) {
          terhubungLokalLangsung = false;
        }
      }

      try {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final paket = '$stamp#$kodePerintah';
        final resCloud = await http
            .post(
              Uri.parse(urlCmdEsp32),
              headers: {'Content-Type': 'text/plain'},
              body: paket,
            )
            .timeout(const Duration(milliseconds: 3000));
        if (resCloud.statusCode == 200) {
          statusTerhubungEsp32 = true;
          modeKoneksiAktif = 'Cloud Relay (Ntfy)';
          tambahLogSerial('[CLOUD NTFY -> ESP32] Terkirim: $kodePerintah');
          notifyListeners();
          return {
            'ok': true,
            'cloud': true,
            'msg': 'Perintah dikirim via Cloud Relay ke ESP32!'
          };
        }
      } catch (_) {}

      return {'ok': false, 'msg': 'Gagal menghubungi ESP32. Periksa koneksi WiFi.'};
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sedangEksekusiPerintah = false;
      });
    }
  }

  Future<void> sinkronisasiStatusEsp32() async {
    if (ipEsp32Lokal.trim().isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse('http://${ipEsp32Lokal.trim()}/status'))
            .timeout(const Duration(milliseconds: 900));
        if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
          final Map<String, dynamic> d = jsonDecode(res.body.trim());
          statusTerhubungEsp32 = true;
          terhubungLokalLangsung = true;
          final String connSsid = (d['connectedSsid'] ?? '').toString();
          modeKoneksiAktif = connSsid.isNotEmpty
              ? '$connSsid (${ipEsp32Lokal.trim()})'
              : 'WiFi Lokal (${ipEsp32Lokal.trim()})';

          if (d['relayMs'] != null) {
            durasiRelayMs = int.tryParse(d['relayMs'].toString()) ?? durasiRelayMs;
          }
          if (d['lockoutMs'] != null) {
            durasiCooldownMs = int.tryParse(d['lockoutMs'].toString()) ?? durasiCooldownMs;
            durasiCooldownDetik = (durasiCooldownMs / 1000).ceil();
          }
          pintuTerbuka = d['doorUnlocked'] == true;
          reedSwitchTerbuka = d['reedOpen'] == true;
          tamperSwitchTerbuka = d['tamperOpen'] == true;
          sensorPintuPaksa = d['doorForced'] == true;
          sensorTamperBoks = d['boxTamper'] == true;

          // SINKRONISASI OTP SETIAP KALI KARTU DI-TAP BERULANG KALI!
          final bool espWaitingOtp = d['waitingOTP'] == true;
          final String espOtp = (d['currentOTP'] ?? '').toString().trim();
          final int espOtpSeq = int.tryParse((d['otpSeq'] ?? '0').toString()) ?? 0;

          menungguOtp = espWaitingOtp;
          if (espWaitingOtp && espOtp.isNotEmpty) {
            if (espOtp != kodeOtpAktif || espOtpSeq != otpSeqTerakhir) {
              kodeOtpAktif = espOtp;
              otpSeqTerakhir = espOtpSeq;
              tambahLogSerial('[OTP BARU DARI ESP32] Kode OTP: $kodeOtpAktif');
            }
          } else if (!espWaitingOtp) {
            kodeOtpAktif = '';
          }

          menungguPersetujuanAdmin = d['waitingApproval'] == true;
          uidSesiAktif = (d['activeUid'] ?? '').toString();
          namaSesiAktif = (d['activeName'] ?? '').toString();

          final String unk = (d['lastUnknownUid'] ?? '').toString();
          if (unk.isNotEmpty) uidKartuAsingTerakhir = unk;

          final String lastEv = (d['lastEvent'] ?? '').toString();
          if (lastEv.isNotEmpty && lastEv != ringkasanEventTerakhir) {
            ringkasanEventTerakhir = lastEv;
            tambahLogSerial('[ESP32] $lastEv');
          }

          if (d['lockedOut'] == true) {
            sisaDetikLockdown = int.tryParse(d['lockoutRemSec'].toString()) ?? 0;
          } else {
            sisaDetikLockdown = 0;
          }

          aktifM1Ewma = d['m1'] == true;
          aktifM2Fusion = d['m2'] == true;
          aktifM3Contagion = d['m3'] == true;
          aktifM4Fuzzy = d['m4'] == true;
          aktifM5Hitl = d['m5'] == true;

          skorPerilakuM1 =
              double.tryParse(d['behaviorScore'].toString()) ?? skorPerilakuM1;
          derajatFisikM2 =
              double.tryParse(d['physicalDeg'].toString()) ?? derajatFisikM2;
          skorAkhirAi =
              double.tryParse(d['finalScore'].toString()) ?? skorAkhirAi;
          levelKeputusanFuzzy =
              int.tryParse(d['decisionLevel'].toString()) ?? levelKeputusanFuzzy;
          jamSimulasiRtc =
              int.tryParse(d['hour'].toString()) ?? jamSimulasiRtc;

          if (d['cards'] is List) {
            final List<dynamic> listC = d['cards'];
            daftarKartu.clear();
            for (final item in listC) {
              daftarKartu.add(
                PenggunaRfid(
                  uid: item['uid'].toString(),
                  nama: item['name'].toString(),
                  jamKebiasaan: double.tryParse(item['habit'].toString()) ?? 12.0,
                  gagalOtp10m: int.tryParse(item['failedOtp'].toString()) ?? 0,
                  kartuAsingMenular10m:
                      int.tryParse(item['invalidRfid'].toString()) ?? 0,
                  gagalBeruntun:
                      int.tryParse(item['consecutive'].toString()) ?? 0,
                ),
              );
            }
          }

          if (d['logs'] is List) {
            final List<dynamic> espLogs = d['logs'];
            daftarLog.clear();
            for (final l in espLogs) {
              final String st = (l['status'] ?? '-').toString();
              final String ak = (l['action'] ?? '-').toString();
              daftarLog.add(
                ItemLogAkses(
                  waktu: (l['time'] ?? '-').toString(),
                  uid: (l['uid'] ?? '-').toString(),
                  nama: (l['name'] ?? '-').toString(),
                  aksi: ak,
                  status: st,
                  skorAi: (l['score'] ?? '0.00%').toString(),
                  kategori: _tentukanKategoriLog(st, ak),
                ),
              );
            }
          }

          notifyListeners();
          return;
        }
      } catch (_) {
        terhubungLokalLangsung = false;
      }
    }

    // Pastikan Live Stream Ntfy selalu menyala jika lokal belum terhubung
    if (!_streamAktif) {
      mulaiLiveStreamNtfy();
    }
    // Polling ringan hanya setiap 5 detik sekali sebagai cadangan agar TIDAK kena HTTP 429 Rate Limit!
    _counterFallBackNtfy++;
    if (_counterFallBackNtfy % 5 == 0) {
      await tarikDataTerbaruDariNtfy();
    }
  }

  Future<String> cariIpEsp32DariCloud() async {
    try {
      final res = await http
          .get(Uri.parse('$urlRelayNtfy/json?poll=1&since=12h'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        final barisList = res.body.trim().split('\n');
        for (final baris in barisList.reversed) {
          final Map<String, dynamic> amplop = jsonDecode(baris);
          final String pesanMentah = (amplop['message'] ?? '').toString();
          if (pesanMentah.startsWith('{')) {
            final Map<String, dynamic> dataEsp = jsonDecode(pesanMentah);
            final String ipDitemukan = (dataEsp['ip'] ?? '').toString().trim();
            if (ipDitemukan.isNotEmpty &&
                ipDitemukan != '0.0.0.0' &&
                !ipDitemukan.startsWith('-')) {
              ipEsp32Lokal = ipDitemukan;
              tambahLogSerial('[AUTO-IP] IP ESP32 ditemukan: $ipEsp32Lokal');
              await sinkronisasiStatusEsp32();
              notifyListeners();
              return ipEsp32Lokal;
            }
          }
        }
      }
    } catch (_) {}
    return '';
  }

  Future<void> tarikDataTerbaruDariNtfy() async {
    try {
      final res = await http
          .get(Uri.parse('$urlRelayNtfy/json?poll=1&since=25s'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        final barisList = res.body.trim().split('\n');
        for (final baris in barisList) {
          _prosesSatuBarisJsonNtfy(baris);
        }
      }
    } catch (_) {}
  }

  Future<bool> sinkronkanSakelarAiKeEsp32() async {
    final f1 = aktifM1Ewma ? '1' : '0';
    final f2 = aktifM2Fusion ? '1' : '0';
    final f3 = aktifM3Contagion ? '1' : '0';
    final f4 = aktifM4Fuzzy ? '1' : '0';
    final f5 = aktifM5Hitl ? '1' : '0';
    final res = await kirimPerintahKeEsp32('CMD:SET_AI:$f1,$f2,$f3,$f4,$f5');
    return res['ok'] == true;
  }

  Future<String> tesKoneksiEsp32() async {
    if (ipEsp32Lokal.trim().isEmpty) {
      await cariIpEsp32DariCloud();
    }
    if (ipEsp32Lokal.trim().isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse('http://${ipEsp32Lokal.trim()}/status'))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          await sinkronisasiStatusEsp32();
          return '✅ Terhubung Langsung ke ESP32 ($ipEsp32Lokal)! Semua OTP & Log 100% Sinkron.';
        }
      } catch (_) {}
    }

    return '❌ IP $ipEsp32Lokal belum merespons. Pastikan HP terhubung ke Hotspot yang sama dengan ESP32.';
  }

  Future<void> kirimLogKeServerNtfy({
    required String uid,
    required String nama,
    required String aksi,
    required String status,
  }) async {}

  Future<void> kirimPesanTelegram(String pesan) async {}

  void segarkanTampilan() {
    notifyListeners();
  }
}
