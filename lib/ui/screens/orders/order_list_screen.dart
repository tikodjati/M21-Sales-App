import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/order_provider.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  void _confirmCancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan #${order.orderNumber} untuk ${order.storeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<OrderProvider>().cancelOrder(order.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan berhasil dibatalkan.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan (Orders)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderProvider.fetchOrders(),
          ),
        ],
      ),
      body: orderProvider.isLoading && orderProvider.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.errorMessage != null && orderProvider.orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(
                          orderProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          onPressed: () => orderProvider.fetchOrders(),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => orderProvider.fetchOrders(),
                  child: orderProvider.orders.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Belum ada transaksi pesanan.',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Lakukan check-in di toko binaan Anda untuk membuat pesanan baru.',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orderProvider.orders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = orderProvider.orders[index];
                            final payment = order.payment;
                            final isOverdue = payment?.isOverdue ?? false;

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                childrenPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: order.isCancelled
                                      ? AppColors.danger.withValues(alpha: 0.1)
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    order.isCancelled ? Icons.cancel : Icons.shopping_bag_outlined,
                                    color: order.isCancelled ? AppColors.danger : AppColors.primary,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '#${order.orderNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: order.isCancelled
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.orderStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: order.isCancelled ? AppColors.danger : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Toko: ${order.storeName ?? "Toko"}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      DateFormatter.formatDateTime(order.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Metode: ${(payment?.paymentMethod ?? "cash").toUpperCase()}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(order.totalAmount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                children: [
                                  const Divider(),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Rincian Item Produk:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  if (order.items.isEmpty)
                                    const Text('Tidak ada rincian item.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                                  else
                                    ...order.items.map((item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.productName,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '${item.quantity} ${item.unit} x ${CurrencyFormatter.format(item.unitPrice)}',
                                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                        ),
                                                        if (item.isDiscountRequested) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.accent.withValues(alpha: 0.15),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Text(
                                                              'Diskon Diminta',
                                                              style: TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                CurrencyFormatter.format(item.subtotal),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        )),

                                  const Divider(height: 20),

                                  // Info Pembayaran Lengkap
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Status Pembayaran: ${(payment?.paymentStatus ?? "pending").toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                                            ),
                                          ),
                                          if (payment?.paymentMethod == 'tempo' && payment?.dueDate != null)
                                            Text(
                                              'Jatuh Tempo: ${DateFormatter.formatDate(payment!.dueDate)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          if (payment?.paymentMethod == 'transfer')
                                            const Text(
                                              'Rekening: BRI 300601003045505',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  if (!order.isCancelled) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(color: AppColors.danger),
                                        ),
                                        icon: const Icon(Icons.cancel_outlined, size: 16),
                                        label: const Text('Batalkan Pesanan'),
                                        onPressed: () => _confirmCancelOrder(order),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
