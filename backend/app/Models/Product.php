<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_name',
        'description',
        'price_pcs',
        'price_pack',
        'price_box',
        'is_active',
    ];

    protected $casts = [
        'price_pcs' => 'float',
        'price_pack' => 'float',
        'price_box' => 'float',
        'is_active' => 'boolean',
    ];

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }
}
