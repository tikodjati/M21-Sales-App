import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/location_helper.dart';
import '../../../providers/store_provider.dart';

class AddStoreScreen extends StatefulWidget {
  const AddStoreScreen({super.key});

  @override
  State<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    final pos = await LocationHelper.getCurrentPosition();
    setState(() => _isGettingLocation = false);

    if (pos != null) {
      _latController.text = pos.latitude.toString();
      _longController.text = pos.longitude.toString();
    } else {
      // Default koordinat wilayah operasional D.I. Yogyakarta (Tugu / Malioboro)
      _latController.text = '-7.7956000';
      _longController.text = '110.3695000';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (_) {}
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    final long = double.tryParse(_longController.text.trim()) ?? 0.0;

    final storeProvider = context.read<StoreProvider>();
    final success = await storeProvider.registerStore(
      storeName: _storeNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      latitude: lat,
      longitude: long,
      storeImage: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toko baru berhasil didaftarkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Pendaftaran Gagal'),
            ],
          ),
          content: Text(storeProvider.errorMessage ?? 'Gagal menyimpan data toko.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendaftaran Toko Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto Toko
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Ambil dari Kamera Langsung'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Pilih dari Galeri'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text(
                              'Unggah Foto Toko / Plang',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sentuh untuk mengambil foto',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Nama Toko
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko *',
                  hintText: 'Contoh: Toko Berkah Malioboro',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Nama Pemilik
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemilik / PIC *',
                  hintText: 'Contoh: Bapak H. Ahmad Susanto',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pemilik wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Nomor Telepon (Unique identifier)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp / Telepon *',
                  hintText: 'Contoh: 081234567890 (1 nomor unik)',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor telepon wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Alamat
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap *',
                  hintText: 'Contoh: Jl. Malioboro No. 25, Danurejan, Kota Yogyakarta, DIY',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat toko wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // Koordinat Lokasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Titik Koordinat Toko',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: const Text('Ambil GPS Sekarang'),
                    onPressed: _isGettingLocation ? null : _fetchCurrentLocation,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: storeProvider.isLoading ? null : _handleSubmit,
                child: storeProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Simpan & Daftarkan Toko',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
