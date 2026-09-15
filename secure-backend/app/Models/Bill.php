<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bill extends Model
{
    use HasFactory;

    protected $fillable = [
    'payee_name',
    'due_date',
    'payment_due',
    'paid',
    'owner',
];

    //Due date matches the same way as assignment 6
    protected $casts = [
        'due_date'    => 'date:Y-m-d',
        'paid'        => 'boolean',
        'payment_due' => 'decimal:2',
    ];
}
