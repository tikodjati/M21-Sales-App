<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. STORES TABLE
        Schema::create('stores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('store_name');
            $table->string('owner_name');
            $table->string('phone_number')->unique(); // BR-02: Pencegahan duplikasi nomor telepon
            $table->text('address');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('store_image_url')->nullable();
            $table->timestamps();
        });

        // 2. VISITS TABLE
        Schema::create('visits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('store_id')->constrained('stores')->onDelete('cascade');
            $table->decimal('checkin_latitude', 10, 7);
            $table->decimal('checkin_longitude', 10, 7);
            $table->decimal('distance_meters', 8, 2);
            $table->enum('status', ['valid', 'invalid'])->default('valid');
            $table->timestamp('checkin_time')->useCurrent();
            $table->timestamps();
        });

        // 3. PRODUCTS TABLE
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('product_name');
            $table->text('description')->nullable();
            $table->decimal('price_pcs', 15, 2);
            $table->decimal('price_pack', 15, 2);
            $table->decimal('price_box', 15, 2);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 4. ORDERS TABLE
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('store_id')->constrained('stores')->onDelete('cascade');
            $table->foreignId('visit_id')->nullable()->constrained('visits')->onDelete('set null');
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->enum('order_status', ['approved', 'processing', 'completed', 'cancelled'])->default('approved'); // BR-05 Auto-approved
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        // 5. ORDER_ITEMS TABLE
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->onDelete('cascade');
            $table->foreignId('product_id')->constrained('products')->onDelete('cascade');
            $table->enum('unit', ['pcs', 'pack', 'box'])->default('pcs');
            $table->integer('quantity');
            $table->decimal('unit_price', 15, 2);
            $table->boolean('is_discount_requested')->default(false); // Sakelar ON/OFF diskon
            $table->decimal('discount_percentage', 5, 2)->default(0); // Ditentukan & diinput oleh Admin
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('subtotal', 15, 2);
            $table->timestamps();
        });

        // 6. PAYMENTS TABLE
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->onDelete('cascade');
            $table->enum('payment_method', ['cash', 'tempo', 'transfer'])->default('cash');
            $table->enum('payment_status', ['pending', 'paid', 'overdue'])->default('pending');
            $table->date('due_date')->nullable(); // Tanggal jatuh tempo H+14 untuk tempo
            $table->string('bank_account_destination')->default('BRI 300601003045505')->nullable();
            $table->string('proof_of_transfer_url')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
        Schema::dropIfExists('visits');
        Schema::dropIfExists('stores');
    }
};
