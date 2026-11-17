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
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Akun Pengguna (Username & Password, tanpa email sesuai SRS)
        $admin = User::create([
            'username' => 'admin',
            'name' => 'Administrator M21',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
            'status' => 'active',
        ]);

        $sales1 = User::create([
            'username' => 'sales1',
            'name' => 'Budi Pratama (Sales 1)',
            'password' => Hash::make('sales123'),
            'role' => 'sales',
            'status' => 'active',
        ]);

        $sales2 = User::create([
            'username' => 'sales2',
            'name' => 'Doni Setiawan (Sales 2)',
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

        // 3. Sample Toko Binaan (Toko Sales 1 vs Toko Sales 2)
        Store::create([
            'user_id' => $sales1->id,
            'store_name' => 'Toko Berkah Jaya',
            'owner_name' => 'Bapak H. Ahmad',
            'phone_number' => '081234567890',
            'address' => 'Jl. Merdeka No. 45, Jakarta Pusat',
            'latitude' => -6.2088000,
            'longitude' => 106.8456000,
        ]);

        Store::create([
            'user_id' => $sales2->id,
            'store_name' => 'Minimarket Barokah Mandiri',
            'owner_name' => 'Ibu Siti Aminah',
            'phone_number' => '089876543210',
            'address' => 'Jl. Diponegoro No. 12, Jakarta Timur',
            'latitude' => -6.2105000,
            'longitude' => 106.8520000,
        ]);
    }
}
