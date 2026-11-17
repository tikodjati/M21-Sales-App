import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/visit_provider.dart';
import '../orders/create_order_screen.dart';
import 'add_store_screen.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      context.read<StoreProvider>().fetchStores(currentUserId: user?.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final visitProvider = context.watch<VisitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar & Teritori Toko'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Toko Saya (${storeProvider.myStores.length})'),
            Tab(text: 'Toko Rekan Lain (${storeProvider.otherStores.length})'),
          ],
        ),
      ),
      body: storeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Toko Saya (Akses Penuh: Check-in & Order)
                _buildMyStoresTab(storeProvider, visitProvider),
                // Tab 2: Toko Sales Lain (Read-Only Penanda Teritori)
                _buildOtherStoresTab(storeProvider),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Toko Baru', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddStoreScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMyStoresTab(StoreProvider storeProvider, VisitProvider visitProvider) {
    final stores = storeProvider.myStores;

    if (stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Belum ada toko yang Anda daftarkan.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol + Toko Baru di bawah untuk mendaftarkan toko.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final user = context.read<AuthProvider>().currentUser;
        await storeProvider.fetchStores(currentUserId: user?.id);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: stores.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final store = stores[index];
          final isCheckedIn = visitProvider.activeStore?.id == store.id;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Toko Binaan Anda',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pemilik: ${store.ownerName} • ${store.phoneNumber}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Actions: Check-in atau Buat Order
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isCheckedIn) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.gps_fixed, size: 16),
                          label: const Text('Check-in Kunjungan'),
                          onPressed: () async {
                            final success = await visitProvider.checkIn(store);
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Berhasil check-in di ${store.storeName}!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(visitProvider.errorMessage ?? 'Check-in gagal.'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: AppColors.success),
                              SizedBox(width: 6),
                              Text(
                                'Sesi Check-in Aktif',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                          label: const Text('Buat Order'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateOrderScreen(store: store),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtherStoresTab(StoreProvider storeProvider) {
    final stores = storeProvider.otherStores;

    if (stores.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada toko milik sales lain.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stores.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final store = stores[index];

        return Card(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        store.storeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sales: ${store.salesName ?? "Sales Lain"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Alamat: ${store.address}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Text(
                      'Toko Eksklusif (Hanya dapat diorder oleh sales penanggung jawab)',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
