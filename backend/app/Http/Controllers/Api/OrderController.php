<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    /**
     * Riwayat pesanan (Sales melihat order miliknya, Admin melihat seluruh order)
     */
    public function index(Request $request)
    {
        $currentUser = $request->user();

        $query = Order::with(['store:id,store_name', 'user:id,name', 'items.product', 'payment'])
            ->latest();

        if ($currentUser->isSales()) {
            $query->where('user_id', $currentUser->id);
        }

        $orders = $query->get()->map(function ($order) {
            $payment = $order->payment;
            $isOverdue = false;

            if ($payment && $payment->payment_method === 'tempo' && $payment->due_date) {
                $isOverdue = now()->greaterThan($payment->due_date) && $payment->payment_status !== 'paid';
            }

            return [
                'id' => $order->id,
                'order_number' => $order->order_number,
                'user_id' => $order->user_id,
                'sales_name' => $order->user?->name ?? 'Sales',
                'store_id' => $order->store_id,
                'store_name' => $order->store?->store_name ?? 'Toko',
                'visit_id' => $order->visit_id,
                'total_amount' => (float) $order->total_amount,
                'order_status' => $order->order_status,
                'notes' => $order->notes,
                'created_at' => $order->created_at,
                'payment' => $payment ? [
                    'id' => $payment->id,
                    'order_id' => $payment->order_id,
                    'payment_method' => $payment->payment_method,
                    'payment_status' => $isOverdue ? 'overdue' : $payment->payment_status,
                    'due_date' => $payment->due_date?->format('Y-m-d'),
                    'bank_account_destination' => $payment->bank_account_destination,
                    'proof_of_transfer_url' => $payment->proof_of_transfer_url ? url('storage/' . $payment->proof_of_transfer_url) : null,
                    'is_overdue' => $isOverdue,
                ] : null,
                'items' => $order->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'product_id' => $item->product_id,
                        'product_name' => $item->product?->product_name ?? 'Produk',
                        'unit' => $item->unit,
                        'quantity' => $item->quantity,
                        'unit_price' => (float) $item->unit_price,
                        'is_discount_requested' => (bool) $item->is_discount_requested,
                        'discount_percentage' => (float) $item->discount_percentage,
                        'discount_amount' => (float) $item->discount_amount,
                        'subtotal' => (float) $item->subtotal,
                    ];
                }),
            ];
        });

        return response()->json([
            'data' => $orders,
        ]);
    }

    /**
     * Submit pesanan baru oleh Sales (BR-05: Auto-approved)
     */
    public function store(Request $request)
    {
        $currentUser = $request->user();

        $request->validate([
            'store_id' => 'required|exists:stores,id',
            'visit_id' => 'nullable|exists:visits,id',
            'payment_method' => 'required|in:cash,tempo,transfer',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.unit' => 'required|in:pcs,pack,box',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.is_discount_requested' => 'nullable|boolean',
            'proof_of_transfer' => 'nullable|image|max:2048',
        ]);

        $store = Store::findOrFail($request->store_id);

        // BR-01: Verifikasi toko milik sales
        if ($store->user_id !== $currentUser->id && !$currentUser->isAdmin()) {
            return response()->json([
                'message' => 'Anda tidak memiliki wewenang membuat pesanan pada toko milik sales lain.',
            ], 403);
        }

        // Jika transfer, wajib ada bukti transfer
        if ($request->payment_method === 'transfer' && !$request->hasFile('proof_of_transfer')) {
            return response()->json([
                'message' => 'Pembayaran via transfer bank BRI wajib melampirkan foto struk bukti transfer.',
            ], 422);
        }

        return DB::transaction(function () use ($request, $currentUser, $store) {
            $orderNumber = 'M21-' . date('Ymd') . '-' . strtoupper(Str::random(5));
            $grandTotal = 0;
            $itemsData = [];

            foreach ($request->items as $item) {
                $product = Product::findOrFail($item['product_id']);
                $unit = strtolower($item['unit']);
                $quantity = (int) $item['quantity'];

                $unitPrice = match ($unit) {
                    'box' => (float) $product->price_box,
                    'pack' => (float) $product->price_pack,
                    default => (float) $product->price_pcs,
                };

                $isDiscountRequested = filter_var($item['is_discount_requested'] ?? false, FILTER_VALIDATE_BOOLEAN);
                $discountPercentage = 0.0;
                $discountAmount = 0.0;
                $subtotal = $unitPrice * $quantity;

                $grandTotal += $subtotal;

                $itemsData[] = [
                    'product_id' => $product->id,
                    'unit' => $unit,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'is_discount_requested' => $isDiscountRequested,
                    'discount_percentage' => $discountPercentage,
                    'discount_amount' => $discountAmount,
                    'subtotal' => $subtotal,
                ];
            }

            // 1. Buat Order (Auto-approved)
            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => $currentUser->id,
                'store_id' => $store->id,
                'visit_id' => $request->visit_id,
                'total_amount' => $grandTotal,
                'order_status' => 'approved',
                'notes' => $request->notes,
            ]);

            // 2. Simpan Order Items
            foreach ($itemsData as $data) {
                $order->items()->create($data);
            }

            // 3. Simpan Payment
            $dueDate = null;
            $paymentStatus = 'pending';

            if ($request->payment_method === 'tempo') {
                $dueDate = now()->addDays(14)->toDateString(); // Jatuh tempo 14 hari
            } elseif ($request->payment_method === 'cash') {
                $paymentStatus = 'paid';
            }

            $proofPath = null;
            if ($request->hasFile('proof_of_transfer')) {
                $proofPath = $request->file('proof_of_transfer')->store('proofs', 'public');
            }

            Payment::create([
                'order_id' => $order->id,
                'payment_method' => $request->payment_method,
                'payment_status' => $paymentStatus,
                'due_date' => $dueDate,
                'bank_account_destination' => 'BRI 300601003045505',
                'proof_of_transfer_url' => $proofPath,
            ]);

            return response()->json([
                'message' => 'Pesanan berhasil dibuat dan otomatis disetujui (Auto-approved).',
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'total_amount' => $order->total_amount,
            ], 201);
        });
    }

    /**
     * Membatalkan pesanan oleh Sales (BR-06)
     */
    public function cancel($id, Request $request)
    {
        $currentUser = $request->user();
        $order = Order::findOrFail($id);

        if ($order->user_id !== $currentUser->id && !$currentUser->isAdmin()) {
            return response()->json([
                'message' => 'Anda tidak memiliki hak untuk membatalkan pesanan ini.',
            ], 403);
        }

        $order->update([
            'order_status' => 'cancelled',
        ]);

        return response()->json([
            'message' => 'Pesanan #' . $order->order_number . ' berhasil dibatalkan.',
        ]);
    }
}
