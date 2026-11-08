import 'package:flutter/material.dart';
import 'tema_warna.tampilan.dart';
import 'state_aplikasi.fungsi.dart';
import 'riwayat_log.fungsi.dart';

/// ============================================================================
/// FILE KHUSUS TAMPILAN RIWAYAT LOG: riwayat_log.tampilan.dart
/// Menampilkan riwayat log otoritatif dari ESP32 (100% Akurat & Bebas Duplikat)
/// ============================================================================
class RiwayatLogTampilan extends StatefulWidget {
  final StateAplikasi state;

  const RiwayatLogTampilan({super.key, required this.state});

  @override
  State<RiwayatLogTampilan> createState() => _RiwayatLogTampilanState();
}

class _RiwayatLogTampilanState extends State<RiwayatLogTampilan> {
  String _filterKategori = 'ALL';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final daftarTampil =
        RiwayatLogFungsi.ambilLogTerfilter(state, _filterKategori);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: TemaWarna.dekorasiKartu(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUDIT TRAIL OTORITATIF ESP32',
                        style: TextStyle(
                          color: TemaWarna.cyanAksen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Riwayat Log Akses Pintu',
                        style: TextStyle(
                          color: TemaWarna.teksPutih,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Bersihkan Log untuk Uji Baru',
                  onPressed: () =>
                      RiwayatLogFungsi.tombolBersihkanLog(context, state),
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: TemaWarna.merahBahaya),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      RiwayatLogFungsi.tombolSalinCsvLog(context, state),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Salin CSV', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaWarna.indigoUtama,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _filterKategori,
              dropdownColor: TemaWarna.bgKartu,
              decoration: InputDecoration(
                labelText: 'Filter Status Pengujian (${daftarTampil.length} Data)',
                filled: true,
                fillColor: TemaWarna.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Semua Log Akses')),
                DropdownMenuItem(
                    value: 'AMAN', child: Text('Aman / Pintu Terbuka (TP)')),
                DropdownMenuItem(
                    value: 'PERINGATAN',
                    child: Text('Menunggu OTP / Konfirmasi')),
                DropdownMenuItem(
                    value: 'DITOLAK',
                    child: Text('Akses Ditolak / Kartu Asing (TN)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _filterKategori = v);
              },
            ),
            const SizedBox(height: 14),

            if (daftarTampil.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Belum ada riwayat log. Silakan tap kartu RFID atau buka pintu untuk mulai mencatat data pengujian.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TemaWarna.teksAbu, fontSize: 12),
                ),
              ),

            ...daftarTampil.map((log) {
              final warna = log.kategori == 'AMAN'
                  ? TemaWarna.hijauAman
                  : log.kategori == 'PERINGATAN'
                      ? TemaWarna.kuningPeringatan
                      : TemaWarna.merahBahaya;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaWarna.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TemaWarna.garisBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.nama} (${log.uid})',
                            style: const TextStyle(
                              color: TemaWarna.teksPutih,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${log.waktu} • ${log.aksi}',
                            style: const TextStyle(
                              color: TemaWarna.teksAbu,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Skor Risiko AI: ${log.skorAi}',
                            style: const TextStyle(
                              color: TemaWarna.cyanAksen,
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TemaWarna.badgeStatus(teks: log.status, warna: warna),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
