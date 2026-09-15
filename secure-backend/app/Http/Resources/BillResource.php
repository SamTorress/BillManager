<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BillResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'payeeName' => $this->payee_name,
            'dueDate' => $this->due_date->format('Y-m-d'),
            'paymentDue' => $this->payment_due,
            'paid' => $this->paid,
            'version' => $this->version,
        ];
    }
}
