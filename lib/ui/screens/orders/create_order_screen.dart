import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/store_model.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/visit_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  final StoreModel store;

  const CreateOrderScreen({super.key, required this.store});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String _selectedPaymentMethod = 'cash'; // 'cash', 'tempo', 'transfer'
  File? _proofOfTransferImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchProducts();
    });
  }

  Future<void> _pickProofImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() {
          _proofOfTransferImage = File(file.path);
        });
      }
    } catch (_) {}
  }

  void _showAddProductDialog(ProductModel product) {
    String selectedUnit = 'pcs';
    int quantity = 1;
    bool isDiscountRequested = false; // Sesuai SRS: Toggle ON/OFF

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final price = product.getPriceByUnit(selectedUnit);
            final subtotal = price * quantity;

            return AlertDialog(
              title: Text(product.productName, style: const TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Satuan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['pcs', 'pack', 'box'].map((unit) {
                      final isSelected = selectedUnit == unit;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(unit.toUpperCase()),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() => selectedUnit = unit);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('Harga per ${selectedUnit.toUpperCase()}: ${CurrencyFormatter.format(price)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),

                  // Kuantitas
                  const Text('Kuantitas (Qty):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: quantity > 1
                            ? () => setDialogState(() => quantity--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => setDialogState(() => quantity++),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Sesuai SRS: Sakelar / Toggle Permintaan Diskon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Permintaan Diskon',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Kirim sinyal ke admin untuk evaluasi diskon',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isDiscountRequested,
                          activeThumbColor: AppColors.accent,
                          onChanged: (val) {
                            setDialogState(() => isDiscountRequested = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtotal Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        CurrencyFormatter.format(subtotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<OrderProvider>().addToCart(
                          product: product,
                          unit: selectedUnit,
                          quantity: quantity,
                          isDiscountRequested: isDiscountRequested,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tambah ke Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitOrder() async {
    final orderProvider = context.read<OrderProvider>();
    final visitProvider = context.read<VisitProvider>();

    if (orderProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 produk ke dalam pesanan.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'transfer' && _proofOfTransferImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib mengunggah foto bukti transfer bank BRI!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final success = await orderProvider.submitOrder(
      storeId: widget.store.id,
      visitId: visitProvider.activeVisitId,
      paymentMethod: _selectedPaymentMethod,
      proofOfTransferImage: _proofOfTransferImage,
    );

    if (!mounted) return;

    if (success) {
      visitProvider.clearActiveVisit();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Pesanan Berhasil'),
            ],
          ),
          content: const Text(
            'Pesanan telah terkirim dan otomatis disetujui (Auto-Approved) untuk diproses oleh Admin.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Gagal membuat pesanan.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Order: ${widget.store.storeName}'),
      ),
      body: Column(
        children: [
          // Header Info Toko
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryLight.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.store.storeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'PIC: ${widget.store.ownerName} • ${widget.store.phoneNumber}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Daftar Produk & Keranjang
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Bagian 1: Keranjang Saat Ini
                if (orderProvider.cartItems.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Item Pesanan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () => orderProvider.clearCart(),
                        child: const Text('Kosongkan', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...orderProvider.cartItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantity} ${item.unit} x ${CurrencyFormatter.format(item.unitPrice)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (item.isDiscountRequested)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  '• Permintaan diskon aktif (Menunggu input admin)',
                                  style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                              onPressed: () => orderProvider.removeFromCart(idx),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 24),
                ],

                // Bagian 2: Katalog Produk Tersedia
                const Text(
                  'Katalog Produk Tersedia:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (orderProvider.isLoading && orderProvider.products.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (orderProvider.products.isEmpty)
                  const Text('Belum ada produk aktif yang tersedia.', style: TextStyle(color: AppColors.textMuted))
                else
                  ...orderProvider.products.map((product) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surfaceVariant,
                          child: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                        ),
                        title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Pcs: ${CurrencyFormatter.format(product.pricePcs)} | '
                          'Pack: ${CurrencyFormatter.format(product.pricePack)} | '
                          'Box: ${CurrencyFormatter.format(product.priceBox)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddProductDialog(product),
                          child: const Text('Pilih'),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Bagian 3: Opsi Pembayaran (Cash, Tempo 14 Hari, TF BRI)
                const Text(
                  'Metode Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'cash',
                        groupValue: _selectedPaymentMethod,
                        title: const Text('Cash (Tunai Langsung)'),
                        subtitle: const Text('Pembayaran lunas seketika di tempat'),
                        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                      ),
                      RadioListTile<String>(
                        value: 'tempo',
                        groupValue: _selectedPaymentMethod,
                        title: const Text('Tempo 14 Hari (Kredit)'),
                        subtitle: const Text('Jatuh tempo 2 minggu. Lebih dari itu otomatis Overdue'),
                        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                      ),
                      RadioListTile<String>(
                        value: 'transfer',
                        groupValue: _selectedPaymentMethod,
                        title: const Text('Transfer Bank BRI'),
                        subtitle: const Text('Rekening: 300601003045505 (Wajib upload bukti)'),
                        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                      ),
                      if (_selectedPaymentMethod == 'transfer') ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tujuan Transfer:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    SizedBox(height: 2),
                                    Text('Bank BRI • 300601003045505',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('a.n. PT M21 Corporation', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _proofOfTransferImage != null
                                      ? 'Bukti Dipilih (${_proofOfTransferImage!.path.split('/').last})'
                                      : 'Unggah Foto Bukti Transfer *',
                                ),
                                onPressed: _pickProofImage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Bottom Bar Checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pembelian:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          CurrencyFormatter.format(orderProvider.cartTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: orderProvider.isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: orderProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Kirim Pesanan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
