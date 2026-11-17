<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use App\Models\Visit;
use Illuminate\Http\Request;

class VisitController extends Controller
{
    /**
     * Check-in kunjungan lapangan dengan validasi radius GPS (BR-03: Max 100 meter)
     */
    public function checkIn(Request $request)
    {
        $currentUser = $request->user();

        $validated = $request->validate([
            'store_id' => 'required|exists:stores,id',
            'checkin_latitude' => 'required|numeric',
            'checkin_longitude' => 'required|numeric',
        ]);

        $store = Store::findOrFail($validated['store_id']);

        // BR-01: Verifikasi hak kepemilikan toko
        if ($store->user_id !== $currentUser->id && !$currentUser->isAdmin()) {
            return response()->json([
                'message' => 'Akses ditolak. Toko ini merupakan teritori eksklusif milik sales lain.',
            ], 403);
        }

        // Hitung jarak menggunakan formula Haversine
        $distance = $this->calculateHaversineDistance(
            (float) $validated['checkin_latitude'],
            (float) $validated['checkin_longitude'],
            (float) $store->latitude,
            (float) $store->longitude
        );

        // BR-03: Maksimal toleransi radius 100 meter
        if ($distance > 100.0) {
            return response()->json([
                'message' => 'Check-in gagal! Anda berada ' . round($distance, 1) . ' meter dari koordinat toko. Batas toleransi maksimal adalah 100 meter.',
                'distance_meters' => round($distance, 2),
            ], 422);
        }

        $visit = Visit::create([
            'user_id' => $currentUser->id,
            'store_id' => $store->id,
            'checkin_latitude' => $validated['checkin_latitude'],
            'checkin_longitude' => $validated['checkin_longitude'],
            'distance_meters' => round($distance, 2),
            'status' => 'valid',
            'checkin_time' => now(),
        ]);

        return response()->json([
            'message' => 'Check-in kunjungan berhasil diverifikasi.',
            'visit_id' => $visit->id,
            'distance_meters' => round($distance, 2),
        ], 200);
    }

    /**
     * Helper kalkulasi jarak Haversine (dalam satuan meter)
     */
    private function calculateHaversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000; // Radius bumi dalam meter

        $latDelta = deg2rad($lat2 - $lat1);
        $lonDelta = deg2rad($lon2 - $lon1);

        $a = sin($latDelta / 2) * sin($latDelta / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($lonDelta / 2) * sin($lonDelta / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
