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
        content: Text('Apakah Anda yakin ingin membatalkan pesanan #${order.orderNumber} untuk ${order.storeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
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
      ),
      body: orderProvider.isLoading && orderProvider.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => orderProvider.fetchOrders(),
              child: orderProvider.orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada transaksi pesanan.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          ),
                        ],
                      ),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${order.orderNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: order.isCancelled
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.orderStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: order.isCancelled ? AppColors.danger : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Toko: ${order.storeName ?? "Toko"}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  DateFormatter.formatDateTime(order.createdAt),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                const Divider(height: 20),

                                // Status Pembayaran
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Metode: ${(payment?.paymentMethod ?? "cash").toUpperCase()}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        if (isOverdue)
                                          const Text(
                                            'Status: OVERDUE (> 14 Hari)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.danger,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else
                                          Text(
                                            'Status: ${(payment?.paymentStatus ?? "pending").toUpperCase()}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      CurrencyFormatter.format(order.totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),

                                if (!order.isCancelled) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                                      label: const Text('Batalkan Pesanan', style: TextStyle(color: AppColors.danger)),
                                      onPressed: () => _confirmCancelOrder(order),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
