<?php

namespace App\Http\Controllers;

use App\Models\Bill;
use App\Http\Resources\BillResource;
use App\Http\Requests\StoreBillRequest;
use Illuminate\Http\Request;
use App\Http\Requests\UpdateBillRequest;

class BillController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $bills = Bill::all();
        return BillResource::collection($bills);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreBillRequest $request)
    {
    $validated = $request->validated();

    $bill = Bill::create([
        'payee_name' => $validated['payeeName'],
        'due_date' => $validated['dueDate'],
        'payment_due' => $validated['paymentDue'],
        'paid' => $validated['paid'] ?? false,
    ]);

    $bill->refresh();

    return response()
        ->json(new BillResource($bill), 201)
        ->header('Location', route('bills.show', $bill));
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $bill = Bill::findOrFail($id);
        return new BillResource($bill);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateBillRequest $request, string $id)
{
    $bill = Bill::findOrFail($id);

    $validated = $request->validated();

    if ($bill->version !== $validated['version']) {
        return response()->json([
            'message' => 'The data you are trying to update has changed since your last read request.',
        ], 400);
    }

    $bill->payee_name = $validated['payeeName'];
    $bill->due_date = $validated['dueDate'];
    $bill->payment_due = $validated['paymentDue'];
    $bill->paid = $validated['paid'] ?? false;
    $bill->version = $bill->version + 1;

    $bill->save();
    $bill->refresh();

    return new BillResource($bill);
}

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
{
    $bill = Bill::findOrFail($id);
    $bill->delete();

    return response()->json(null, 204);
}
}
