import 'dart:math';
import 'state_aplikasi.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS FUNGSI 5 METODE AI: monitor_ai.fungsi.dart
/// Mengimplementasikan rumus persis dari:
/// - ai_method1_ewma.h & ml_model.h (TRAINED_V1)
/// - ai_method2_fusion.h
/// - ai_method3_contagion.h
/// - ai_method4_fuzzy.h & risk_model.h (guardApproval)
/// - ai_method5_hitl.h
/// ============================================================================
class MonitorAiFungsi {
  // Konstanta Metode 1 (ai_method1_ewma.h)
  static const double alphaEwma = 0.20;      // ALPHA_EWMA = 0.20f (Laju belajar 20%)
  static const double decayLambda = 0.00231; // DECAY_LAMBDA = 0.00231f (Waktu paruh 5 menit)

  // Konstanta Model Lama (ml_model.h - TRAINED_V1)
  static const List<double> _mlMean = [
    0.5, -0.866, -0.7818, 0.6235, 0.3333, 0.5556, 2.0, 19.6667, 0.8889
  ];
  static const List<double> _mlScale = [
    1.0, 1.0, 1.0, 1.0, 0.4714, 0.8315, 0.9428, 7.9162, 0.9938
  ];
  static const List<double> _mlCoef = [
    -0.0, 0.0, 0.0, 0.0, 0.6289, 0.7587, -1.0886, 0.3048, 0.368
  ];
  static const double _mlIntercept = -0.3033;

  /// Rumus Model Lama risk::infer(generated_model::MODEL, raw, score)
  static double hitungInferModelLama(StateAplikasi state, PenggunaRfid user) {
    final double hour = state.jamSimulasiRtc.toDouble();
    final double dow = (DateTime.now().weekday % 7).toDouble();
    final double sinceLast = user.detikSejakTerakhir.clamp(0.0, 3600.0);

    final List<double> x = [
      sin(2 * pi * hour / 24.0),
      cos(2 * pi * hour / 24.0),
      sin(2 * pi * dow / 7.0),
      cos(2 * pi * dow / 7.0),
      user.gagalOtp10m.toDouble(),
      user.kartuAsingMenular10m.toDouble(),
      user.percobaan10m.toDouble(),
      sinceLast,
      user.gagalBeruntun.toDouble(),
    ];

    double z = _mlIntercept;
    for (int i = 0; i < 9; i++) {
      z += _mlCoef[i] * ((x[i] - _mlMean[i]) / _mlScale[i]);
    }
    final double sigmoid = z >= 0 ? 1.0 / (1.0 + exp(-z)) : exp(z) / (1.0 + exp(z));
    return double.parse((100.0 * sigmoid).toStringAsFixed(2));
  }

  /// Rumus Metode 1: ai_method1::calculateScore(userIdx, raw)
  static double hitungMetode1Ewma(StateAplikasi state, PenggunaRfid user) {
    final double targetHour = user.jamKebiasaan;
    final double diff = (state.jamSimulasiRtc.toDouble() - targetHour).abs();
    final double circularDev = (diff > 12.0) ? (24.0 - diff) : diff;
    final double timeScore = (circularDev / 12.0) * 35.0;

    final double decay = exp(-decayLambda * user.detikSejakTerakhir);
    final double aggression = (user.gagalOtp10m * 22.0) +
        (user.kartuAsingMenular10m * 28.0) +
        (user.gagalBeruntun * 15.0);

    return min(100.0, double.parse((timeScore + (aggression * decay)).toStringAsFixed(2)));
  }

  /// Evaluasi Lengkap sesuai handleAuthorized() pada sketch_oct3b.ino
  static void evaluasiSkorRisikoUser(
      StateAplikasi state, PenggunaRfid user) {
    // 1. Evaluasi Skor Perilaku (Metode 1 EWMA vs ml_model.h Lama)
    if (state.aktifM1Ewma) {
      state.skorPerilakuM1 = hitungMetode1Ewma(state, user);
    } else {
      state.skorPerilakuM1 = hitungInferModelLama(state, user);
    }

    // 2. Evaluasi Fusi Sensor Fisik Pintu & Tamper (ai_method2_fusion.h)
    double physicalDeg = 0.0;
    double physicalPoints = 0.0;
    if (state.aktifM2Fusion) {
      if (state.sensorTamperBoks) {
        physicalDeg = 1.00; // Bahaya mutlak (100%)
      } else if (state.sensorPintuPaksa) {
        physicalDeg = 0.60; // Bahaya menengah-tinggi (60%)
      }
      double penalty = 0.0;
      if (state.sensorPintuPaksa) penalty += 50.0;
      if (state.sensorTamperBoks) penalty += 100.0;
      physicalPoints = min(100.0, penalty);
    }
    state.derajatFisikM2 = physicalDeg;
    state.penaltiFisikM2 = physicalPoints;

    // 3. Evaluasi Keputusan Akhir (Metode 4 Fuzzy vs guardApproval Lama)
    if (state.aktifM4Fuzzy) {
      final double muB = min(1.0, state.skorPerilakuM1 / 100.0);
      final double muV = (user.detikSejakTerakhir < 15.0 && user.percobaan10m > 2)
          ? min(1.0, (15.0 - user.detikSejakTerakhir) / 15.0)
          : 0.0;
      final double muP = physicalDeg;

      final double fuzzyCombined = (0.55 * muB) + (0.25 * muV) + (0.85 * muP);
      state.skorAkhirAi =
          min(100.0, double.parse((fuzzyCombined * 100.0).toStringAsFixed(2)));

      if (state.skorAkhirAi >= 85.0 || muP >= 1.0 || user.gagalBeruntun >= 4) {
        state.levelKeputusanFuzzy = 2; // Auto-Lockdown
      } else if (state.skorAkhirAi >= 45.0 ||
          muP >= 0.6 ||
          user.gagalOtp10m >= 2 ||
          user.kartuAsingMenular10m >= 1) {
        state.levelKeputusanFuzzy = 1; // Eskalasi Admin
      } else {
        state.levelKeputusanFuzzy = 0; // Normal (Kirim OTP)
      }
    } else {
      state.skorAkhirAi =
          min(100.0, double.parse((state.skorPerilakuM1 + physicalPoints).toStringAsFixed(2)));
      // risk::guardApproval lama
      final bool oldApproval = user.gagalOtp10m >= 2 ||
          user.kartuAsingMenular10m >= 5 ||
          user.percobaan10m >= 10 ||
          user.gagalBeruntun >= 3 ||
          state.skorAkhirAi >= 70.0;
      state.levelKeputusanFuzzy = oldApproval ? 1 : 0;
    }
  }

  /// Fungsi Metode 1: ai_method1::updateHabit (ALPHA_EWMA = 0.20f)
  static void updateHabitUser(PenggunaRfid user, int currentHour) {
    user.jamKebiasaan = double.parse(
      (((1.0 - alphaEwma) * user.jamKebiasaan) + (alphaEwma * currentHour))
          .toStringAsFixed(2),
    );
  }

  static void ubahJamSimulasiRtc(StateAplikasi state, int jamBaru) {
    state.jamSimulasiRtc = jamBaru;
    evaluasiSkorRisikoUser(state, state.daftarKartu.first);
    state.segarkanTampilan();
  }

  static void bersihkanSerialMonitor(StateAplikasi state) {
    state.logSerial.clear();
    state.logSerial.add('[SERIAL] Layar Serial Monitor dibersihkan.');
    state.segarkanTampilan();
  }
}
