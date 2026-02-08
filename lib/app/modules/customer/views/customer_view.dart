import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lms_qr_generator/app/models/customer_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/customer_controller.dart';

class CustomerView extends GetView<CustomerController> {
  const CustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer', style: Get.textTheme.headlineSmall),
        actions: [
          Obx(() {
            return Icon(
              controller.isConnect.value ? Icons.bluetooth : Icons.bluetooth_disabled,
              color: controller.isConnect.value ? Colors.green : Colors.red,
            );
          }),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCustomerForm(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.customers.isEmpty) {
          return Center(child: Image.asset('assets/images/no_data.png', scale: 2));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.customers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = controller.customers[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(item.nt, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${item.it} • ${item.at}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => _openPrintPreview(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openCustomerForm(context, customer: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _openCustomerForm(BuildContext context, {CustomerItem? customer}) {
    final formKey = GlobalKey<FormState>();
    final itController = TextEditingController(text: customer?.it ?? '');
    final ntController = TextEditingController(text: customer?.nt ?? '');
    final atController = TextEditingController(text: customer?.at ?? '');
    final ptController = TextEditingController(text: customer?.pt ?? '');
    final wsController = TextEditingController(text: customer?.ws ?? '');
    final npController = TextEditingController(text: customer?.np ?? '');
    final isSaving = false.obs;

    Get.dialog(
      AlertDialog(
        title: Text(customer == null ? 'Tambah Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: itController,
                  decoration: const InputDecoration(labelText: 'ID Toko'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: ntController,
                  decoration: const InputDecoration(labelText: 'Nama Toko'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: atController,
                  decoration: const InputDecoration(labelText: 'Alamat Toko'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: ptController,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                ),
                TextFormField(
                  controller: wsController,
                  decoration: const InputDecoration(labelText: 'Grosir (WS)'),
                ),
                TextFormField(
                  controller: npController,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          Obx(() {
            return FilledButton(
              onPressed: isSaving.value
                  ? null
                  : () async {
                if (formKey.currentState?.validate() ?? false) {
                  isSaving.value = true;
                  final item = CustomerItem(
                    id: customer?.id,
                    it: itController.text.trim(),
                    nt: ntController.text.trim(),
                    at: atController.text.trim(),
                    pt: ptController.text.trim(),
                    ws: wsController.text.trim(),
                    np: npController.text.trim(),
                    createdAt: customer?.createdAt ?? DateTime.now().toIso8601String(),
                  );
                  final saved = await controller.saveCustomer(item);
                  isSaving.value = false;
                  if (saved) {
                    Get.back();
                  }
                }
              },
              child: isSaving.value
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Simpan'),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerItem item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Customer'),
        content: Text('Yakin ingin menghapus ${item.nt}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              await controller.deleteCustomer(item);
              Get.back();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _openPrintPreview(BuildContext context, CustomerItem item) {
    final qrData = controller.buildQrPayload(item);
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Preview ID Customer', style: Get.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('ID', item.it),
                            _infoRow('Nama', item.nt),
                            _infoRow('Alamat', item.at),
                            if (item.pt.isNotEmpty) _infoRow('Pelanggan', item.pt),
                            if (item.ws.isNotEmpty) _infoRow('Grosir', item.ws),
                            if (item.np.isNotEmpty) _infoRow('No. Tlp', item.np),
                            const SizedBox(height: 16),
                            Center(
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 160,
                                gapless: false,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _customerIdCardTemplate(item),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            child: const Text('Tutup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await controller.printCustomerCard(item);
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Cetak'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _customerIdCardTemplate(CustomerItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2E6F), Color(0xFF1B4FA3), Color(0xFF0B2E6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMER ID CARD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: controller.buildQrPayload(item),
                  version: QrVersions.auto,
                  size: 90,
                  gapless: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.at,
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 14,
                      ),
                    ),
                    if (item.pt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.pt,
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.ws.isEmpty ? 'SA' : item.ws,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.it,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}