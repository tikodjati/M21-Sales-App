<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Product;
use App\Models\Store;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database with Daerah Istimewa Yogyakarta (DIY) territory.
     */
    public function run(): void
    {
        // 1. Akun Pengguna (Username & Password, tanpa email sesuai SRS)
        $admin = User::create([
            'username' => 'admin',
            'name' => 'Administrator M21 Jogja',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
            'status' => 'active',
        ]);

        $sales1 = User::create([
            'username' => 'sales1',
            'name' => 'Budi Pratama (Sales Jogja Kota & Sleman)',
            'password' => Hash::make('sales123'),
            'role' => 'sales',
            'status' => 'active',
        ]);

        $sales2 = User::create([
            'username' => 'sales2',
            'name' => 'Doni Setiawan (Sales Bantul & Kulon Progo)',
            'password' => Hash::make('sales123'),
            'role' => 'sales',
            'status' => 'active',
        ]);

        // 2. Master Produk
        Product::create([
            'product_name' => 'Kopi M21 Signature Blend',
            'description' => 'Kopi bubuk premium arabika-robusta kemasan kedap udara',
            'price_pcs' => 15000,
            'price_pack' => 140000,
            'price_box' => 520000,
            'is_active' => true,
        ]);

        Product::create([
            'product_name' => 'Teh Celup M21 Melati',
            'description' => 'Teh celup wangi melati alami isi 25 kantong per pack',
            'price_pcs' => 8500,
            'price_pack' => 80000,
            'price_box' => 300000,
            'is_active' => true,
        ]);

        Product::create([
            'product_name' => 'Biskuit Gandum M21 Crunchy',
            'description' => 'Biskuit kaya serat dan gandum utuh',
            'price_pcs' => 12000,
            'price_pack' => 110000,
            'price_box' => 410000,
            'is_active' => true,
        ]);

        Product::create([
            'product_name' => 'Minyak Goreng M21 1 Liter',
            'description' => 'Minyak kelapa sawit murni fortifikasi vitamin A',
            'price_pcs' => 18000,
            'price_pack' => 105000,
            'price_box' => 205000,
            'is_active' => true,
        ]);

        // 3. Data Toko Wilayah Operasional Daerah Istimewa Yogyakarta (DIY)
        // Toko Binaan Sales 1 (Area Kota Jogja & Sleman)
        Store::create([
            'user_id' => $sales1->id,
            'store_name' => 'Toko Sembako Berkah Malioboro',
            'owner_name' => 'Bapak H. Ahmad Susanto',
            'phone_number' => '081234567890',
            'address' => 'Jl. Malioboro No. 45, Sosromenduran, Gedong Tengen, Kota Yogyakarta, DIY',
            'latitude' => -7.7928420,
            'longitude' => 110.3658420,
        ]);

        Store::create([
            'user_id' => $sales1->id,
            'store_name' => 'Kelontong Bu Menik Kaliurang',
            'owner_name' => 'Ibu Menik Rahayu',
            'phone_number' => '081398765432',
            'address' => 'Jl. Kaliurang KM 5.8, Caturtunggal, Depok, Sleman, DIY',
            'latitude' => -7.7580120,
            'longitude' => 110.3812400,
        ]);

        // Toko Binaan Sales 2 (Area Bantul & sekitarnya)
        Store::create([
            'user_id' => $sales2->id,
            'store_name' => 'Minimarket Barokah Mandiri Sewon',
            'owner_name' => 'Ibu Hj. Siti Aminah',
            'phone_number' => '089876543210',
            'address' => 'Jl. Bantul KM 6.5, Panggungharjo, Sewon, Bantul, DIY',
            'latitude' => -7.8345210,
            'longitude' => 110.3550180,
        ]);

        Store::create([
            'user_id' => $sales2->id,
            'store_name' => 'Toko Murah Rejeki Gejayan',
            'owner_name' => 'Bapak Bambang Wijaya',
            'phone_number' => '087712348899',
            'address' => 'Jl. Affandi (Gejayan) No. 28, Condongcatur, Depok, Sleman, DIY',
            'latitude' => -7.7712450,
            'longitude' => 110.3890320,
        ]);
    }
}
