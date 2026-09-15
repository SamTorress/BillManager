<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class BillFactory extends Factory
{
    public function definition(): array
    {
        return [
            'payee_name' => $this->faker->company(),
            'due_date' => now()->addWeeks(2)->format('Y-m-d'),
            'payment_due' => $this->faker->randomFloat(2, 2, 100),
            'paid' => false,
        ];
    }
}
