<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class StoreController extends Controller
{
    /**
     * Tampilkan seluruh toko (Toko milik sales + Toko sales lain untuk visualisasi teritori)
     */
    public function index(Request $request)
    {
        $currentUser = $request->user();

        $stores = Store::with('user:id,name,username')
            ->latest()
            ->get()
            ->map(function ($store) use ($currentUser) {
                return [
                    'id' => $store->id,
                    'user_id' => $store->user_id,
                    'sales_name' => $store->user?->name ?? 'Sales Lain',
                    'store_name' => $store->store_name,
                    'owner_name' => $store->owner_name,
                    'phone_number' => $store->phone_number,
                    'address' => $store->address,
                    'latitude' => (float) $store->latitude,
                    'longitude' => (float) $store->longitude,
                    'store_image_url' => $store->store_image_url ? url('storage/' . $store->store_image_url) : null,
                    'is_my_store' => ($store->user_id === $currentUser->id),
                    'created_at' => $store->created_at,
                ];
            });

        return response()->json([
            'data' => $stores,
        ]);
    }

    /**
     * Pendaftaran toko baru oleh sales (dengan upload foto & validasi no. HP unik BR-02)
     */
    public function store(Request $request)
    {
        $currentUser = $request->user();

        $validated = $request->validate([
            'store_name' => 'required|string|max:255',
            'owner_name' => 'required|string|max:255',
            'phone_number' => 'required|string|unique:stores,phone_number',
            'address' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'store_image' => 'nullable|image|max:2048', // maks 2MB
        ], [
            'phone_number.unique' => 'Nomor telepon toko sudah terdaftar di sistem. Toko ini telah dikelola oleh sales lain.',
        ]);

        $imagePath = null;
        if ($request->hasFile('store_image')) {
            $imagePath = $request->file('store_image')->store('stores', 'public');
        }

        $store = Store::create([
            'user_id' => $currentUser->id,
            'store_name' => $validated['store_name'],
            'owner_name' => $validated['owner_name'],
            'phone_number' => $validated['phone_number'],
            'address' => $validated['address'],
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'store_image_url' => $imagePath,
        ]);

        return response()->json([
            'message' => 'Toko baru berhasil didaftarkan.',
            'data' => [
                'id' => $store->id,
                'user_id' => $store->user_id,
                'sales_name' => $currentUser->name,
                'store_name' => $store->store_name,
                'owner_name' => $store->owner_name,
                'phone_number' => $store->phone_number,
                'address' => $store->address,
                'latitude' => (float) $store->latitude,
                'longitude' => (float) $store->longitude,
                'store_image_url' => $store->store_image_url ? url('storage/' . $store->store_image_url) : null,
                'is_my_store' => true,
            ],
        ], 201);
    }

    /**
     * Detail toko
     */
    public function show($id, Request $request)
    {
        $currentUser = $request->user();
        $store = Store::with('user:id,name,username')->findOrFail($id);

        return response()->json([
            'data' => [
                'id' => $store->id,
                'user_id' => $store->user_id,
                'sales_name' => $store->user?->name,
                'store_name' => $store->store_name,
                'owner_name' => $store->owner_name,
                'phone_number' => $store->phone_number,
                'address' => $store->address,
                'latitude' => (float) $store->latitude,
                'longitude' => (float) $store->longitude,
                'store_image_url' => $store->store_image_url ? url('storage/' . $store->store_image_url) : null,
                'is_my_store' => ($store->user_id === $currentUser->id),
            ],
        ]);
    }
}
