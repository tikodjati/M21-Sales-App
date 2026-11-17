import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final user = authProvider.currentUser;

    final totalOmzet = orderProvider.orders
        .where((o) => !o.isCancelled)
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    final overdueOrders = orderProvider.orders
        .where((o) => o.payment?.isOverdue == true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.fetchOrders(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner Admin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user?.name ?? "Administrator"}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'M21 Sales Management Dashboard Mobile',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Omzet Masuk', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.format(totalOmzet),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tagihan Overdue', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text(
                            '${overdueOrders.length} Pesanan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daftar Pesanan Masuk
            const Text(
              'Seluruh Pesanan Lapangan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (orderProvider.isLoading && orderProvider.orders.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (orderProvider.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Belum ada data pesanan.', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              ...orderProvider.orders.map((order) {
                final isOverdue = order.payment?.isOverdue ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('#${order.orderNumber} • ${order.storeName ?? "Toko"}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sales: ${order.salesName ?? "Sales"} • ${DateFormatter.formatDate(order.createdAt)}'),
                        if (isOverdue)
                          const Text(
                            'JATUH TEMPO (OVERDUE > 14 HARI)',
                            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                      ],
                    ),
                    trailing: Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
