import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lms_qr_generator/app/helper/scanned_helper.dart';
import 'package:lms_qr_generator/app/models/scanned_model.dart';
import 'package:lms_qr_generator/app/modules/home/controllers/home_controller.dart';



class RiwayatPage extends StatefulWidget {
  const RiwayatPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // List untuk menyimpan hasil scan
  List<ScannedItem> scannedBarcodes = [];

  @override
  void initState() {
    super.initState();
    // _loadDummyData();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    final data = await DatabaseHelper.instance.getRiwayatScan();
    setState(() {
      scannedBarcodes = data;
    });
  }

  Future<void> _confirmPrint(ScannedItem item) async {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Cetak ulang QR untuk riwayat ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await controller.printTicket(item: item);
              },
              child: const Text('Cetak'),
            ),
          ],
        );
      },
    );
  }

  // void _loadDummyData() {
  //   scannedBarcodes = [
  //     BarcodeData(code: '1234567890123', type: 'EAN-13', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
  //     BarcodeData(code: '9876543210987', type: 'EAN-13', timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
  //     BarcodeData(code: 'ABC123XYZ', type: 'CODE-128', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
  //   ];
  // }

  Future<void> _truncateData() async {
    try{
      final drop = await DatabaseHelper.instance.truncateTable();
      await _loadRiwayat();
      print('Successfull Truncate');
    }catch(e){
      print('Error inserting scanned item: $e');
    }

  }

  String _formatTimestamp(String timeString) {
    final now = DateTime.now();
    final DateTime timestamp = DateTime.parse(timeString);
    final difference = now.difference(timestamp);



    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Scan'),
        backgroundColor: Color(0xFF913030),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [if (scannedBarcodes.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () =>
            showDialog(context: context, builder: (BuildContext context){
              return AlertDialog(
                title: Text('Konfirmasi'),
                content: Text('Hapus semua riwayat scan ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
                  TextButton(onPressed: ()  async {
                    Navigator.pop(context);
                    await _truncateData();
                    }, child: Text('Hapus'))
                ],
              );
            })


            , tooltip: 'Hapus Semua')],
      ),
      body: scannedBarcodes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada hasil scan',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          :

      ListView.builder(
        itemCount: scannedBarcodes.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final barcode = scannedBarcodes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Color(0xFF913030),
                child: Icon(Icons.qr_code_2, color: Colors.white),
              ),
              title: Text(barcode.it, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text('${barcode.nt} - ${barcode.at}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  if (barcode.pt != null && barcode.pt.isNotEmpty)...[
                    const SizedBox(height: 1),
                    Text('${barcode.pt}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                  if (barcode.telp != null && barcode.telp.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      barcode.telp,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 1),
                  Text(barcode.ws, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 1),
                  Text( _formatTimestamp(barcode.date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),


                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.print),
                color: const Color(0xFF913030),
                tooltip: 'Cetak ulang',
                onPressed: () => _confirmPrint(barcode),
              ),
            ),
          );
        },
      ),
    );
  }
}
