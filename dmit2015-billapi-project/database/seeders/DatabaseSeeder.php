<?php

namespace Database\Seeders;

use App\Models\Bill;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (Bill::count() === 0) {
            Bill::factory()->count(10)->create();
        }
    }
}
