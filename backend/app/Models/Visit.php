<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Visit extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'store_id',
        'checkin_latitude',
        'checkin_longitude',
        'distance_meters',
        'status',
        'checkin_time',
    ];

    protected $casts = [
        'checkin_latitude' => 'float',
        'checkin_longitude' => 'float',
        'distance_meters' => 'float',
        'checkin_time' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function order()
    {
        return $this->hasOne(Order::class);
    }
}
