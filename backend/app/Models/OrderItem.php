<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'product_id',
        'unit',
        'quantity',
        'unit_price',
        'is_discount_requested',
        'discount_percentage',
        'discount_amount',
        'subtotal',
    ];

    protected $casts = [
        'unit_price' => 'float',
        'is_discount_requested' => 'boolean',
        'discount_percentage' => 'float',
        'discount_amount' => 'float',
        'subtotal' => 'float',
        'quantity' => 'integer',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
