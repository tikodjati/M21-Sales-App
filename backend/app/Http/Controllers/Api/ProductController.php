<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * Tampilkan katalog produk aktif
     */
    public function index()
    {
        $products = Product::where('is_active', true)
            ->get()
            ->map(function ($product) {
                return [
                    'id' => $product->id,
                    'product_name' => $product->product_name,
                    'description' => $product->description,
                    'price_pcs' => (float) $product->price_pcs,
                    'price_pack' => (float) $product->price_pack,
                    'price_box' => (float) $product->price_box,
                    'is_active' => (bool) $product->is_active,
                ];
            });

        return response()->json([
            'data' => $products,
        ]);
    }
}
