import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lms_qr_generator/app/helper/scanned_helper.dart';
import 'package:lms_qr_generator/app/models/customer_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CustomerController extends GetxController {
  final customers = <CustomerItem>[].obs;
  final isLoading = false.obs;

  final box = GetStorage();
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  var selectedDevice = Rxn<BluetoothDevice>();
  var isConnect = false.obs;
  var loadingScanDevice = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initPrinter();
    loadCustomers();
  }

  Future<void> _initPrinter() async {
    var device = box.read('bluetoothDevice');
    if (device != null) {
      printer.isConnected.then((result) {
        selectedDevice.value = BluetoothDevice(device['name'], device['address']);
        if (result == true) {
          isConnect.value = true;
        } else {
          connectDevice(selectedDevice.value!);
        }
      });
    }
  }

  Future<void> loadCustomers() async {
    isLoading.value = true;
    try {
      final result = await DatabaseHelper.instance.getCustomers();
      customers.value = result.map((data) => CustomerItem.fromMap(data)).toList();
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Tidak bisa memuat data customer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveCustomer(CustomerItem item) async {
    final isNew = item.id == null;
    try {
      if (isNew) {
        await DatabaseHelper.instance.insertCustomer(item.toMap());
      } else {
        await DatabaseHelper.instance.updateCustomer(item.toMap());
      }
      await loadCustomers();
      Get.snackbar(
        "Berhasil",
        isNew ? "Customer berhasil disimpan" : "Customer berhasil diperbarui",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Tidak bisa menyimpan customer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<void> deleteCustomer(CustomerItem item) async {
    if (item.id == null) return;
    try {
      await DatabaseHelper.instance.deleteCustomer(item.id!);
      await loadCustomers();
      Get.snackbar(
        "Berhasil",
        "Customer berhasil dihapus",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Tidak bisa menghapus customer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<bool> connectDevice(BluetoothDevice device) async {
    try {
      selectedDevice.value = device;
      loadingScanDevice.value = true;
      await printer.connect(selectedDevice.value!);
      isConnect.value = true;
      loadingScanDevice.value = false;
      await box.write('bluetoothDevice', {'name': device.name, 'address': device.address});
      return true;
    } catch (e) {
      isConnect.value = false;
      loadingScanDevice.value = false;
      Get.snackbar("Gagal", "Tidak bisa terhubung ke perangkat", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  String buildQrPayload(CustomerItem item) {
    final dataMap = {
      'it': item.it,
      'nt': item.nt,
      'at': item.at,
      'pt': item.pt,
      'kp': 'LG',
      'ws': item.ws,
      'np': item.np,
    };
    return jsonEncode(dataMap);
  }

  Future<void> printCustomerCard(CustomerItem item) async {
    printer.isConnected.then((isConnected) async {
      if (isConnected == true) {
        final dataMap = {
          'it': item.it,
          'nt': item.nt,
          'at': item.at,
          'pt': item.pt,
          'ws': item.ws,
          'np': item.np,
          'kp': 'LG',
        };

        final qrData = jsonEncode(dataMap);

        printer.printCustom("ID CUSTOMER", 2, 1);
        printer.printNewLine();
        printer.printCustom("ID        : ${dataMap["it"]}", 1, 0);
        printer.printCustom("Nama      : ${dataMap["nt"]}", 1, 0);
        printer.printCustom("Area      : ${dataMap["at"]}", 1, 0);
        printer.printCustom("Pelanggan : ${dataMap["pt"]}", 1, 0);
        final String noTlp = (dataMap['np'] ?? '').toString().trim();
        if (noTlp.isNotEmpty) {
          printer.printCustom("No. Tlp   : $noTlp", 1, 0);
        }
        printer.printNewLine();

        final textLine1 = (dataMap['kp'] ?? 'LG').toString();
        final textLine2 = (() {
          final raw = dataMap['ws']?.toString();
          if (raw == null || raw.trim().isEmpty) return 'SA';
          final ws = raw.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ');
          if (ws == 'BT JKT') return 'BMJ';
          if (ws == 'BT SBY') return 'BMS';
          if (ws == 'BT SMG') return 'BM';
          return 'BM';
        })();

        final qrBytes = await generateQrWithText(
          data: qrData,
          textLine1: textLine1,
          textLine2: textLine2,
          qrSize: 150,
        );

        printer.printImageBytes(qrBytes);
        printer.printNewLine();
        printer.printNewLine();
        printer.printNewLine();
      } else {
        Get.snackbar("Printer", "Bluetooth belum terhubung", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    });
  }

  Future<Uint8List> generateQrWithText({
    required String data,
    required String textLine1,
    required String textLine2,
    double qrSize = 150.0,
    double textWidth = 100.0,
    double timestampWidth = 100.0,
    double padding = 8.0,
    double fontSize = 40.0,
    double timeFontSize = 24.0,
    double dateFontSize = 22.0,
  }) async {
    final now = DateTime.now();
    final shortYear = now.year.toString().substring(2);
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${shortYear}";

    final totalWidth = (timestampWidth + padding + textWidth + padding + qrSize).toInt();
    final totalHeight = qrSize.toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth.toDouble(), totalHeight.toDouble()),
      bgPaint,
    );

    final tsSpan = TextSpan(
      children: [
        TextSpan(
          text: "$dateStr\n",
          style: TextStyle(
            color: Colors.black,
            fontSize: dateFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: timeStr,
          style: TextStyle(
            color: Colors.black87,
            fontSize: timeFontSize,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );

    final tsPainter = TextPainter(
      text: tsSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tsPainter.layout(minWidth: 0, maxWidth: timestampWidth);
    final offsetXTs = (timestampWidth - tsPainter.width) / 2;
    final offsetYTs = (totalHeight - tsPainter.height) / 2;
    tsPainter.paint(canvas, Offset(offsetXTs, offsetYTs));

    final textSpan = TextSpan(
      text: '$textLine1\n$textLine2',
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: textWidth);
    final offsetXText = timestampWidth + padding + (textWidth - textPainter.width) / 2;
    final offsetYText = (totalHeight - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(offsetXText, offsetYText));

    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );

    canvas.save();
    canvas.translate(timestampWidth + padding + textWidth + padding, 0);
    qrPainter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(totalWidth, totalHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}